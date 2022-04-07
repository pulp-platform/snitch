// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Andreas Traber <atraber@iis.ee.ethz.ch>
// Author: Florian Zaruba <zarubaf@iis.ee.ethz.ch>
// Author: Fabian Schuiki <fschuiki@iis.ee.ethz.ch>

package jtag_test;

  class jtag_driver #(
    parameter int IrLength = 0,
    parameter IDCODE    = 'h1,
    parameter time TA = 0ns , // stimuli application time
    parameter time TT = 0ns   // stimuli test time
  );

    virtual JTAG_DV jtag;

    // last IR register select
    protected logic [IrLength-1:0] ir_select;

    function new ( virtual JTAG_DV jtag);
      this.jtag = jtag;
      // Per JTAG specification the IDCODE should be at 'h1 and is selected by
      // default after reset.
      this.ir_select = 'h1;
    endfunction

    task reset_master;
      jtag.tms    <= #TA 1;
      jtag.tdi    <= #TA 0;
      jtag.trst_n <= #TA 0;
      repeat (2) clock();
      jtag.trst_n <= #TA 1;
      this.ir_select = 'h1;
      clock();
    endtask

    task soft_reset();
      jtag.tms <= #TA 1;
      jtag.tdi <= #TA 0;
      repeat (6) clock();
      jtag.tms <= #TA 0;
      clock();
      // After softreset the IR should be reset to IDCODE so we have to mirror
      // this in our internal state.
      this.ir_select = 'h1;
    endtask

    // Set IR, but only if it needs to be set.
    task set_ir(input logic [IrLength-1:0] opcode);
      logic opcode_unpacked [IrLength];
      // check whether IR is already set to the right value
      if (this.ir_select == opcode) return;
      {<<{opcode_unpacked}} = opcode;
      write_tms(1); // select DR scan
      write_tms(1); // select IR scan
      write_tms(0); // capture IR
      write_tms(0); // shift IR
      write_bits(opcode_unpacked, 1);
      write_tms(1); // update IR
      write_tms(0); // run test idle
      this.ir_select = opcode;
    endtask
    // Go from `run_test_idle` to `shift_dr`
    task shift_dr();
      write_tms(1); // select DR scan
      write_tms(0); // capture DR
      write_tms(0); // shift DR
    endtask

    // Go to `run_test_idle`
    task update_dr(bit exit_1_dr);
      // depending on the state `exit_1_dr` is already reached when shifting data (`tms_on_last`).
      if (exit_1_dr) write_tms(1); // exi 1 DR
      write_tms(1); // update DR
      write_tms(0); // run test idle
    endtask

    task write_bits(input logic wdata [$], input logic tms_last);
      for (int i = 0; i < $size(wdata); i++) begin
        jtag.tdi <= #TA wdata[i];
        if (i == ($size(wdata) - 1)) jtag.tms <= #TA tms_last;
        clock();
      end
      jtag.tms <= #TA 0;
    endtask

    task readwrite_bits(output logic rdata [$], input logic wdata [$], input logic tms_last);
      for (int i = 0; i < wdata.size(); i++) begin
        jtag.tdi <= #TA wdata[i];
        if (i == (wdata.size() - 1)) jtag.tms <= #TA tms_last;
        cycle_start();
        rdata[i] = jtag.tdo;
        cycle_end();
      end
      jtag.tms <= #TA 0;
    endtask

    task wait_idle(int cycles);
      repeat(cycles) clock();
    endtask

    // Protected methods
    task write_tms(input logic tms_val);
      jtag.tms <= #TA tms_val;
      clock();
    endtask

    protected task clock();
      cycle_start(); cycle_end();
    endtask

    protected task cycle_start;
      #TT;
    endtask

    // TODO(zarubaf): I am not sure on which clock edge to trigger
    protected task cycle_end;
      @(posedge jtag.clk_i);
    endtask
  endclass

  // abstracts the debug module
  class riscv_dbg #(
    parameter int IrLength = 5,
    parameter IDCODE    = 'h1,
    parameter DTMCSR    = 'h10,
    parameter DMIACCESS = 'h11,
    parameter time TA = 0ns, // stimuli application time
    parameter time TT = 0ns  // stimuli test time
  );

    typedef jtag_test::jtag_driver#(.IrLength(IrLength), .IDCODE(IDCODE), .TA(TA), .TT(TT)) jtag_driver_t;
    jtag_driver_t jtag;

    localparam DMIWidth = $bits(dm::dmi_req_t);

    function new (jtag_driver_t jtag);
      this.jtag = jtag;
    endfunction

    task reset_master();
      jtag.reset_master();
      jtag.soft_reset();
    endtask

    task wait_idle(int cycles);
      jtag.wait_idle(cycles);
    endtask

    task get_idcode(output logic [31:0] idcode);
      logic read_data [32], write_data [32];
      write_data = '{default: 1'b0};
      jtag.set_ir(IDCODE);
      jtag.shift_dr();
      jtag.readwrite_bits(read_data, write_data, 1'b0);
      jtag.update_dr(1'b1);
      idcode = {<<{read_data}};
    endtask

    task write_dtmcs(input logic [31:0] data);
      logic write_data [32];
      logic [31:0] write_data_packed = {data};
      {<<{write_data}} = write_data_packed;
      jtag.set_ir(DTMCSR);
      jtag.shift_dr();
      jtag.write_bits(write_data, 1'b1);
      jtag.update_dr(1'b0);
    endtask

    task read_dtmcs(output dm::dtmcs_t data, input int wait_cycles = 10);
      logic read_data [32], write_data [32];
      jtag.set_ir(DTMCSR);
      jtag.shift_dr();
      // shift out read data
      {<<{write_data}} = 32'b0;
      jtag.readwrite_bits(read_data, write_data, 1'b1);
      jtag.update_dr(1'b0);
      data = dm::dtmcs_t'({<<{read_data}});
    endtask

    task write_dmi(input dm::dm_csr_e address, input logic [31:0] data);
      logic write_data [DMIWidth];
      logic [DMIWidth-1:0] write_data_packed = {address, data, dm::DTM_WRITE};
      {<<{write_data}} = write_data_packed;
      jtag.set_ir(DMIACCESS);
      jtag.shift_dr();
      jtag.write_bits(write_data, 1'b1);
      jtag.update_dr(1'b0);
    endtask

    task read_dmi(input dm::dm_csr_e address, output logic [31:0] data, input int wait_cycles = 10);
      logic read_data [DMIWidth], write_data [DMIWidth];
      logic [DMIWidth-1:0] data_out = 0;
      automatic logic [DMIWidth-1:0] write_data_packed = {address, 32'b0, dm::DTM_READ};
      {<<{write_data}} = write_data_packed;
      jtag.set_ir(DMIACCESS);
      jtag.shift_dr();
      // send read command
      jtag.write_bits(write_data, 1'b1);
      jtag.update_dr(1'b0);
      jtag.wait_idle(wait_cycles);
      jtag.shift_dr();
      // shift out read data
      write_data_packed = {address, 32'b0, dm::DTM_NOP};
      {<<{write_data}} = write_data_packed;
      jtag.readwrite_bits(read_data, write_data, 1'b1);
      // I am pretty sure this should be `update_dr` here.
      // jtag.update_dr(1'b0);
      jtag.shift_dr();
      data_out = {<<{read_data}};
      data = data_out[33:2];
    endtask


  endclass
endpackage
