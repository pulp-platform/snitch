// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

`include "common_cells/registers.svh"
`include "common_cells/assert.svh"
// Author: Florian Zaruba <zarubaf@iis.ee.ethz.ch>
// Description: Page table walker (PTW) for RISC-V
//              (Custom)Sv32 address translation.
module snitch_ptw import snitch_pkg::*; #(
  parameter int unsigned DW = 64
) (
  input  logic                clk_i,
  input  logic                rst_i,
  /// Possibly extended physical page number (base)
  input  logic [PPN_SIZE-1:0] ppn_i,
  input  logic                valid_i,
  output logic                ready_o,
  input  va_t                 va_i,
  output l0_pte_t             pte_o,
  /// Is this a 4 mega page i.e,. super-page
  output logic                is_4mega_o,
  /// Memory interface
  output addr_t               data_qaddr_o,
  output logic                data_qvalid_o,
  input  logic                data_qready_i,

  input  logic [DW-1:0]       data_pdata_i,
  input  logic                data_perror_i,
  input  logic                data_pvalid_i,
  output logic                data_pready_o
);

  // Address offset dependent on PTE size.
  localparam int unsigned PteAddrOffset = $clog2(PTE_SIZE);

  typedef enum logic [1:0] {
    Idle,
    LookupPTE,
    WaitPTE,
    ReturnPTE
  } state_e;
  state_e state_q, state_d;

  logic [1:0] lvl_d, lvl_q;

  `FFSR(state_q, state_d, Idle, clk_i, rst_i)

  pte_sv32_t pte;
  l0_pte_t pte_d, pte_q;
  logic is_4mega_d, is_4mega_q;
  assign pte = pte_sv32_t'(data_pdata_i[$size(pte_sv32_t)-1:0]);
  `FFLNR(pte_q, pte_d, (data_pvalid_i & data_pready_o), clk_i)
  `FFNR(is_4mega_q, is_4mega_d, clk_i)

  `FFNR(lvl_q, lvl_d, clk_i)

  assign pte_o = pte_q;
  assign is_4mega_o = is_4mega_q;

  //-------------------
  // Page table walker
  //-------------------
  // A virtual address va is translated into a physical address pa as follows:
  // 1. Let a be sptbr.ppn x PAGESIZE, and let i = LEVELS-1.
  ///   (For CustomSv32, PAGESIZE=2^14 and LEVELS=2.)
  ///   (For Sv32, PAGESIZE=2^12 and LEVELS=2. )
  // 2. Let pte be the value of the PTE at address a+va.vpn[i] x PTESIZE.
  ///   (For CustomSv32, PTESIZE=8.)
  ///   (For Sv32, PTESIZE=4. )
  // 3. If pte.v = 0, or if pte.r = 0 and pte.w = 1, stop and raise a page-fault exception corresponding
  //    to the original access type.
  // 4. Otherwise, the PTE is valid. If pte.r = 1 or pte.x = 1, go to step 5.
  //    Otherwise, this PTE is a pointer to the next level of the page table.
  //    Let i=i-1. If i < 0, stop and raise an access exception. Otherwise, let
  //    a = pte.ppn x PAGESIZE and go to step 2.
  // 5. A leaf PTE has been found. Determine if the requested memory access is allowed by the
  //    pte.r, pte.w, pte.x, and pte.u bits, given the current privilege mode and the value of the
  //    SUM and MXR fields of the mstatus register. If not, stop and raise a page-fault exception
  //    corresponding to the original access type.
  // 6. If i > 0 and pte.ppn [i-1:0] != 0, this is a misaligned superpage; stop and raise a page-fault
  //    exception corresponding to the original access type.
  always_comb begin
    automatic logic [PAGE_SHIFT-1:0] page_table_index;
    lvl_d = lvl_q;
    state_d = state_q;

    page_table_index = $unsigned({va_i.vpn1, {{PteAddrOffset}{1'b0}}});
    data_qaddr_o = $unsigned({ppn_i, page_table_index});

    data_qvalid_o = 1'b0;
    data_pready_o = 1'b1;

    ready_o = 1'b0;
    // unpack the PTE to the more space efficient L0 PTE.
    pte_d.pa = pte.pa;
    pte_d.flags = '{
      d: pte.d,
      a: pte.a,
      u: pte.u,
      x: pte.x,
      w: pte.w,
      r: pte.r
    };
    is_4mega_d = is_4mega_q;

    unique case (state_q)
      //  Let's accept a new incoming lookup here.
      Idle:  begin
        lvl_d = 0;
        data_qvalid_o = valid_i;
        // First look-up can be done here.
        if (valid_i && data_qready_i) begin
          state_d = WaitPTE;
        end
      end
      // Do the lookup
      LookupPTE: begin
        // Check that we are not infinitely recursing.
        if (lvl_q < 2) begin
          data_qvalid_o = 1'b1;
          // Compose virtual address;
          page_table_index = $unsigned({va_i.vpn0, {{PteAddrOffset}{1'b0}}});
          data_qaddr_o = $unsigned({pte_q.pa, page_table_index});
          if (data_qready_i) state_d = WaitPTE;
        end else begin
          pte_d.flags.a = '0; // clear PTE.a making it invalid for downstream
          state_d = ReturnPTE;
        end
      end
      // Wait for the PTE to return from memory
      WaitPTE: begin
        is_4mega_d = 1'b0;
        if (data_pvalid_i) begin
          // increase lvl
          lvl_d++;
          // Something went wrong. Clear the access bit.
          if (pte.v == 0 || (pte.r == 0 && pte.w == 1)) begin
            pte_d.flags.a = 1'b0;
            state_d = ReturnPTE;
          // This is a legit page.
          end else if (pte.r == 1 || pte.x == 1) begin
            // is this a super-page?
            if (lvl_q < 1) begin
              is_4mega_d = 1'b1;
              // Check for misaligned super pages.
              if (pte_d.pa.ppn0 != 0) pte_d.flags.a = '0;
            end
            state_d = ReturnPTE;
          // This is a pointer to the next level.
          end else state_d = LookupPTE;
          // in case we got an access error
          if (data_perror_i) begin
            pte_d.flags.a = '0;
            state_d = ReturnPTE;
          end
        end
      end
      // Communicate the result.
      ReturnPTE: begin
        ready_o = 1'b1;
        state_d = Idle;
      end
      default : /* default */;
    endcase
  end

  // check that we use the full virtual address
  `ASSERT_INIT(SanityVirtualAddress, PAGE_SHIFT + VPN_SIZE * 2 == 32)
  // Check that definitions are coherent
  `ASSERT_INIT(SanityPhysicalAddress, PPN_SIZE == $bits(pa_t))
  // check that we can address the entire physical address space
  `ASSERT_INIT(SanityPhysicalAddressSpace, PPN_SIZE + PAGE_SHIFT == $bits(addr_t))
  // check data width is sane
  `ASSERT_INIT(SanityDataWidth, DW >= PPN_SIZE && DW >= 32 && DW == PTE_SIZE * 8)
  // assert stability
  // translation request
  `ASSERT(VAReqStable, valid_i && !ready_o |=> valid_i, clk_i, rst_i)
  `ASSERT(VAReqDataStable, valid_i && !ready_o |=> ($stable(va_i) && $stable(ppn_i)), clk_i, rst_i)
  // data request
  `ASSERT(RefillReqStable, data_qvalid_o && !data_qready_i |=> data_qvalid_o, clk_i, rst_i)
  `ASSERT(RefillReqDataStable,
      data_qvalid_o && !data_qready_i |=> $stable(data_qaddr_o), clk_i, rst_i)
  // data response
  `ASSERT(RefillRspStable, data_pvalid_i && !data_pready_o |=> data_pvalid_i, clk_i, rst_i)
  `ASSERT(RefillRspDataStable,
      data_pvalid_i && !data_pready_o |=> $stable(data_pdata_i) && $stable(data_perror_i),
      clk_i, rst_i)
  // make sure that the VPN and the addressing needed for the size of the PTE fits within
  // the page index.
  `ASSERT_INIT(VPNSanity, VPN_SIZE + $clog2(PTE_SIZE) <= PAGE_SHIFT)
endmodule
