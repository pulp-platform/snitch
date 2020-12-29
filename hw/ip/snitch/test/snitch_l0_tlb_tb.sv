// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Florian Zaruba <zarubaf@iis.ee.ethz.ch>
`include "snitch_vm/typedef.svh"
// verilog_lint: waive-start package-filename
package snitch_l0_tlb_tb_pkg;
  `SNITCH_VM_TYPEDEF(48)
endpackage
// verilog_lint: waive-stop package-filename

class translation_request;
  rand snitch_pkg::va_t addr;
  rand bit write;
  rand bit execute;
  rand snitch_pkg::priv_lvl_t priv_lvl;
  rand bit keep;

  // execute flag does not imply write
  constraint if_execute_no_write_c {
    if (execute) {
      !write;
    }
  }

  constraint priv_lvl_c {
    priv_lvl inside {snitch_pkg::PrivLvlS, snitch_pkg::PrivLvlU};
  }

endclass

class page_table_entry;

  rand snitch_l0_tlb_tb_pkg::pa_t    pa;
  rand logic               d;
  rand logic               a;
  rand logic               g;
  rand logic               u;
  rand logic               x;
  rand logic               w;
  rand logic               r;

  function snitch_l0_tlb_tb_pkg::l0_pte_t get_pte ();
    return '{
              pa: '{
                ppn1: pa.ppn1,
                ppn0: pa.ppn0
              },
              flags: '{
                d: d,
                a: a,
                u: u,
                x: x,
                w: w,
                r: r
              }
            };
  endfunction
  // make sure that we don't use reserved values.
  constraint legal_flags_c {
    if (w) {
      x != 0 || r != 0;
    }
    if (x && w) {
      r != 0;
    }
  }

endclass

module snitch_l0_tlb_tb #(
  parameter int unsigned NrEntries = 16
);

  localparam time ClkPeriod = 10ns;
  localparam time TA = 2ns;
  localparam time TT = 8ns;

  logic clk, rst;
  snitch_pkg::priv_lvl_t dut_priv_lvl;
  logic dut_flush;
  logic dut_valid, valid_refill;
  logic dut_ready, ready_refill;
  snitch_pkg::va_t dut_va, va_refill;
  snitch_l0_tlb_tb_pkg::l0_pte_t pte_refill;
  logic is_4mega;
  logic dut_write;
  logic dut_execute;
  snitch_l0_tlb_tb_pkg::pa_t dut_pa;
  logic dut_page_fault;

  // save translation entries here
  snitch_l0_tlb_tb_pkg::l0_pte_t memory [bit [$bits(snitch_pkg::va_t)-1:0]];

  snitch_l0_tlb #(
    .NrEntries (NrEntries),
    .pa_t (snitch_l0_tlb_tb_pkg::pa_t),
    .l0_pte_t (snitch_l0_tlb_tb_pkg::l0_pte_t)
  ) i_dut (
    .clk_i (clk),
    .rst_i (rst),
    .flush_i (dut_flush),
    .priv_lvl_i (dut_priv_lvl),
    .valid_i (dut_valid),
    .ready_o (dut_ready),
    .va_i (dut_va),
    .write_i (dut_write),
    .read_i (~dut_write),
    .execute_i (dut_execute),
    .page_fault_o (dut_page_fault),
    .pa_o (dut_pa),
    .valid_o (valid_refill),
    .ready_i (ready_refill),
    .va_o (va_refill),
    .pte_i (pte_refill),
    .is_4mega_i (is_4mega)
  );

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

  task static reset;
    dut_valid = 1'b0;
    dut_flush = 1'b0;
    dut_write = 1'b0;
    dut_execute = 1'b0;
    dut_priv_lvl = snitch_pkg::PrivLvlS;
  endtask

  task static send_req (
    input translation_request tr,
    output snitch_l0_tlb_tb_pkg::pa_t pa,
    output logic page_fault
  );
      dut_valid    <= #TA 1;
      dut_va       <= #TA tr.addr;
      dut_write    <= #TA tr.write;
      dut_execute  <= #TA tr.execute;
      dut_priv_lvl <= #TA tr.priv_lvl;
      cycle_start();
      while (dut_ready != 1) begin cycle_end(); cycle_start(); end
      pa <= dut_pa;
      page_fault <= dut_page_fault;
      cycle_end();
      dut_va       <= #TA 0;
      dut_valid    <= #TA 0;
      dut_write    <= #TA 0;
      dut_execute  <= #TA 0;
      dut_priv_lvl <= snitch_pkg::PrivLvlS;
  endtask

  // Drive Requests
  initial begin
    automatic int unsigned stall_cycles;
    automatic translation_request tr = new;
    automatic snitch_l0_tlb_tb_pkg::pa_t pa;
    automatic logic page_fault;
    automatic snitch_pkg::va_t va_old = '0;
    reset();
    @(negedge rst);
    repeat (3) @(posedge clk);

    forever begin
      stall_cycles = $urandom_range(0, 20);
      // randomize requests
      repeat (stall_cycles) @(posedge clk);
      assert(tr.randomize());
      // maybe keep the old request address
      if (tr.keep && va_old != 0) tr.addr = va_old;
      send_req(tr, pa, page_fault);
      // save address for next request
      va_old = tr.addr;
      // check results
      assert(pa == {memory[tr.addr].pa.ppn1, memory[tr.addr].pa.ppn0})
      else $error("Expected: %h Got: %h", {memory[tr.addr].pa.ppn1, memory[tr.addr].pa.ppn0}, pa);
      assert((tr.write -> memory[tr.addr].flags.w) || page_fault);
      assert((!tr.write -> memory[tr.addr].flags.r) || page_fault);
      assert((tr.execute -> memory[tr.addr].flags.x) || page_fault);
      assert(memory[tr.addr].flags.a || page_fault);
      assert((tr.write -> memory[tr.addr].flags.d) || page_fault);
      assert(((tr.priv_lvl == snitch_pkg::PrivLvlU) -> memory[tr.addr].flags.u) || page_fault);
      assert(((tr.priv_lvl == snitch_pkg::PrivLvlS) -> !memory[tr.addr].flags.u) || page_fault);
    end
  end

  // TODO(zarubaf): Assert cacheability

  task static cycle_start;
    #TT;
  endtask

  task static cycle_end;
    @(posedge clk);
  endtask

  // Answer on re-fill port.
  initial begin
    automatic int unsigned stall_cycles;
    automatic page_table_entry pte = new;
    forever begin
      ready_refill <= #TA '0;
      pte_refill   <= #TA '0;
      is_4mega     <= #TA '0;
      // artificially delay request
      stall_cycles = $urandom_range(0, 20);
      repeat (stall_cycles) @(posedge clk);
      cycle_start();
      while (valid_refill != 1) begin cycle_end(); cycle_start(); end
      cycle_end();
      // we've got a new refill request
      ready_refill <= #TA 1;
      if (memory.exists(va_refill)) begin
        pte_refill <= #TA memory[va_refill];
      end else begin
        assert(pte.randomize());
        pte_refill <= #TA pte.get_pte();
          // save information
          memory [va_refill] = pte.get_pte();
      end
      is_4mega     <= #TA 0;
      cycle_start();
      cycle_end();
      ready_refill <= #TA '0;
      pte_refill   <= #TA '0;
      is_4mega     <= #TA '0;
    end
  end

endmodule
