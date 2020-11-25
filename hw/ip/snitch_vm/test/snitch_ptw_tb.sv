// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

class pa_lookup;
  rand snitch_pkg::pa_t pa;
  rand snitch_pkg::pte_flags_t flags;
  rand bit is_4mega;
  rand bit legal;
  rand bit v;

  constraint legal_flags_c {
    is_4mega dist { 1 := 2, 0 := 8};
    // make sure that we don't use reserved values.
    if (legal) {
      v == 1;
      if (flags.w) {
        flags.x != 0 || flags.r != 0;
      }
      if (flags.x && flags.w) {
        flags.r != 0;
      }
      // illegal mapping
    } else {
      // for a legal mapping the ppn0 must be 0 for a 4 mega mapping.
      // if (is_4mega) ;
      v == 0 || (flags.r == 0 && flags.w == 1) || (is_4mega && pa.ppn0 != 0);
    }
  }
  constraint legal_mapping_c { legal dist { 0 := 1, 1 := 9}; }
endclass

module snitch_ptw_tb;
  import snitch_pkg::*;

  localparam time ClkPeriod = 10ns;
  localparam time TA = 2ns;
  localparam time TT = 8ns;

  localparam int unsigned DW = 64;
  // pte size
  localparam int unsigned PS = DW/8;

  logic clk, rst;
  va_t dut_va;
  logic [PPN_SIZE-1:0] dut_ppn;
  logic dut_valid, dut_ready;
  l0_pte_t dut_pte;
  logic dut_is_4mega;

  mailbox addr_mbx = new();
  logic [DW-1:0] memory [logic [$bits(addr_t)-1:0]];

  typedef struct packed {
    logic error;
    logic [DW-1:0] data;
  } dut_in_t;

  /// Return type of address mapper.
  typedef struct packed {
    logic is_4mega;
    l0_pte_t pte;
    bit legal;
  } mapper_ret_t;

  typedef stream_test::stream_driver #(
    .payload_t (dut_in_t),
    .TA (TA),
    .TT (TT)
  ) stream_driver_in_t;

  typedef stream_test::stream_driver #(
    .payload_t (addr_t),
    .TA (TA),
    .TT (TT)
  ) stream_driver_out_t;

  STREAM_DV #(
    .payload_t (dut_in_t)
  ) dut_in (
    .clk_i (clk)
  );

  STREAM_DV #(
    .payload_t (addr_t)
  ) dut_out (
    .clk_i (clk)
  );

  stream_driver_in_t in_driver = new(dut_in);
  stream_driver_out_t out_driver = new(dut_out);

  snitch_ptw #(
    .DW ( DW )
  ) i_snitch_ptw (
    .clk_i (clk),
    .rst_i (rst),
    .ppn_i (dut_ppn),
    .valid_i (dut_valid),
    .ready_o (dut_ready),
    .va_i (dut_va),
    .pte_o (dut_pte),
    .is_4mega_o (dut_is_4mega),
    .data_qaddr_o (dut_out.data),
    .data_qvalid_o (dut_out.valid),
    .data_qready_i (dut_out.ready),
    .data_pdata_i (dut_in.data.data),
    .data_perror_i (dut_in.data.error),
    .data_pvalid_i (dut_in.valid),
    .data_pready_o (dut_in.ready)
  );

  task static cycle_start;
    #TT;
  endtask

  task static cycle_end;
    @(posedge clk);
  endtask

  task static reset;
    dut_ppn = '0;
    dut_valid = '0;
    dut_va = '0;
  endtask

  /// Drive DUT request side.
  task static send_req (
    /// Base pointer (from `satp`).
    input pa_t ppn,
    /// Virtual address to translate.
    input va_t va,
    /// Obtained mapping.
    output mapper_ret_t mapping
  );
      dut_valid  <= #TA 1;
      dut_ppn    <= #TA ppn;
      dut_va     <= #TA va;
      cycle_start();
      while (dut_ready != 1) begin cycle_end(); cycle_start(); end
      mapping.pte      <= dut_pte;
      mapping.is_4mega <= dut_is_4mega;
      cycle_end();
      dut_valid  <= 0;
      dut_ppn    <= 0;
      dut_va     <= 0;
  endtask

  // Generate Translation requests.
  initial begin : gen_translation_requests
    automatic int unsigned stall_cycles;
    automatic mapper_ret_t mapping_golden;
    automatic mapper_ret_t mapping_actual;
    automatic va_t va;
    automatic pa_t ppn;
    reset();
    @(negedge rst);
    repeat (5) @(posedge clk);
    // Drive requests to the DUT. `gen_address_mapping` generates randomized
    // translations and returns the golden model.
    forever begin
      stall_cycles = $urandom_range(0, 20);
      repeat (stall_cycles) @(posedge clk);
      assert(std::randomize(ppn));
      assert(std::randomize(va));
      mapping_golden = gen_address_mapping(ppn, va);
      send_req(ppn, va, mapping_actual);
      if (mapping_golden.legal) begin
        mapping_actual.legal = 1'b1;
        assert (mapping_actual == mapping_golden)
        else $fatal(1, "Got: %p Epxected: %p", mapping_actual, mapping_golden);
      end else begin
        assert (mapping_actual.pte.flags.a == 0)
        else $fatal(1, "An illegal mapping must have a cleared access flag.");
      end
    end
  end

  /// Generate a mapping from the virtual address to the physical address.
  /// This function write the memory array as a side effect.
  /// @return Whether the mapping is a super-page mapping or not and expected flags.
  function static mapper_ret_t gen_address_mapping (addr_t base, va_t va);
    automatic pte_sv32_t pte_l0, pte_l1;
    automatic pa_lookup base_pte_l0 = new; // second base!
    automatic pa_lookup base_pte_l1 = new; // second base!

    assert(base_pte_l0.randomize() with {
      pa != base;
      if (legal && is_4mega) {
        pa.ppn0 == 0;
        (flags.r | flags.w | flags.x) == 1;
      }
      if (legal && !is_4mega) {
        flags.r == 0;
        flags.w == 0;
        flags.x == 0;
      }
    });

    // The page index must be the same.
    pte_l0 = '{
      pa: base_pte_l0.pa,
      d:  base_pte_l0.flags.d,
      a:  base_pte_l0.flags.a,
      u:  base_pte_l0.flags.u,
      x:  base_pte_l0.flags.x,
      w:  base_pte_l0.flags.w,
      r:  base_pte_l0.flags.r,
      g:  1'b0,
      v:  base_pte_l0.v,
      default: 0
    };

    memory[(base << PAGE_SHIFT) + va.vpn1 * PS] = pte_l0;
    $info("Translation 0: %p", base_pte_l0);

    if (!base_pte_l0.is_4mega) begin
      assert(base_pte_l1.randomize() with {
        is_4mega == 0;
        pa != base_pte_l0.pa;
      });
      pte_l1 = '{
        pa: base_pte_l1.pa,
        d:  base_pte_l1.flags.d,
        a:  base_pte_l1.flags.a,
        u:  base_pte_l1.flags.u,
        x:  base_pte_l1.flags.x,
        w:  base_pte_l1.flags.w,
        r:  base_pte_l1.flags.r,
        g:  1'b0,
        v:  base_pte_l1.v,
        default: 0
      };
      memory[(pte_l0.pa << PAGE_SHIFT) + va.vpn0 * PS] = pte_l1;
      $info("Translation 1: %p", base_pte_l1);

    end else begin
      // signal the pte l1 as pte l0;
      pte_l1 = pte_l0;
      base_pte_l1.legal = 1'b1; // its automatically legal if we don't need it.
    end

    $info("Adding translation from 0x%h to 0x%h", va << PAGE_SHIFT, pte_l1.pa << PAGE_SHIFT);
    return '{
      is_4mega: base_pte_l0.is_4mega,
      pte: '{
        pa: pte_l1.pa,
        flags: '{
          d: pte_l1.d,
          a: pte_l1.a,
          u: pte_l1.u,
          x: pte_l1.x,
          w: pte_l1.w,
          r: pte_l1.r
        }
      },
      legal: base_pte_l0.legal & base_pte_l1.legal
    };
  endfunction


  // Answer memory refill requests.
  initial begin : rcv_refill_requests
    automatic int unsigned stall_cycles;
    automatic addr_t lookup_addr;
    out_driver.reset_out();
    @(negedge rst);
    repeat (5) @(posedge clk);

    forever begin
      stall_cycles = $urandom_range(0, 5);
      repeat (stall_cycles) @(posedge clk);
      out_driver.recv(lookup_addr);
      addr_mbx.put(lookup_addr);
    end
  end

  initial begin : send_refill_requests
    automatic int unsigned stall_cycles;
    automatic addr_t lookup_addr;
    automatic dut_in_t send_data;
    automatic bit [DW-1:0] rand_data;
    in_driver.reset_in();
    @(negedge rst);
    repeat (5) @(posedge clk);

    forever begin
      addr_mbx.get(lookup_addr);
      stall_cycles = $urandom_range(1, 5);
      repeat (stall_cycles) @(posedge clk);
      // $display("Address: %h", lookup_addr);
      if (!memory.exists(lookup_addr)) begin
        send_data.error = 1'b1;
        assert(std::randomize(rand_data));
        send_data.data = rand_data;
      end else begin
        send_data.error = 1'b0;
        send_data.data = memory[lookup_addr];
      end
      in_driver.send(send_data);
    end
  end

  // Clock generation.
  initial begin
    rst = 1;
    repeat (3) begin
      #(ClkPeriod/2) clk = 0;
      #(ClkPeriod/2) clk = 1;
    end
    rst = 0;
    forever begin
      #(ClkPeriod/2) clk = 0;
      #(ClkPeriod/2) clk = 1;
    end
  end
endmodule
