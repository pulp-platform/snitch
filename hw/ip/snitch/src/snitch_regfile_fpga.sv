// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Engineer:       Francesco Conti - f.conti@unibo.it
//
// Additional contributions by:
//                 Markus Wegmann - markus.wegmann@technokrat.ch
//                 Noam Gallmann - gnoam@live.com
//
// Design Name:    RISC-V register file
// Project Name:   Snitch (originally from: zero-riscy)
// Language:       SystemVerilog
//
// Description:    This register file is optimized for implementation on
//                 FPGAs. The register file features one distributed RAM block per implemented
//                 sync-write port, each with a parametrized number of async-read ports.
//                 Read-accesses are multiplexed from the relevant block depending on which block
//                 was last written to. For that purpose an additional array of registers is
//                 maintained keeping track of write acesses.
//

// verilog_lint: waive module-filename
module snitch_regfile #(
  parameter int unsigned DATA_WIDTH     = 32,
  parameter int unsigned NR_READ_PORTS  = 2,
  parameter int unsigned NR_WRITE_PORTS = 1,
  parameter bit          ZERO_REG_ZERO  = 0,
  parameter int unsigned ADDR_WIDTH     = 4
)(
  // clock and reset
  input  logic                                      clk_i,
  // read port
  input  logic [NR_READ_PORTS-1:0][4:0]             raddr_i,
  output logic [NR_READ_PORTS-1:0][DATA_WIDTH-1:0]  rdata_o,
  // write port
  input  logic [NR_WRITE_PORTS-1:0][4:0]            waddr_i,
  input  logic [NR_WRITE_PORTS-1:0][DATA_WIDTH-1:0] wdata_i,
  input  logic [NR_WRITE_PORTS-1:0]                 we_i
);

  localparam int unsigned NumWords        = 2**ADDR_WIDTH;
  localparam int unsigned LogNrWritePorts = NR_WRITE_PORTS == 1 ? 1 : $clog2(NR_WRITE_PORTS);

  // The register values are stored in distinct separate RAM blocks each featuring 1 sync-write and
  // N async-read ports. A set of narrow flip-flops keeps track of which RAM block contains the
  // valid entry for each register.

  // Distributed RAM usually supports one write port per block. We need one block per write port.
  logic [NumWords-1:0][DATA_WIDTH-1:0]     mem [NR_WRITE_PORTS];


  logic [NR_WRITE_PORTS-1:0][NumWords-1:0]     we_dec;
  logic [NumWords-1:0][LogNrWritePorts-1:0] mem_block_sel;
  logic [NumWords-1:0][LogNrWritePorts-1:0] mem_block_sel_q;

  // write adress decoder (for block selector)
  always_comb begin
    for (int unsigned j = 0; j < NR_WRITE_PORTS; j++) begin
      for (int unsigned i = 0; i < NumWords; i++) begin
        if (waddr_i[j] == i) begin
          we_dec[j][i] = we_i[j];
        end else begin
          we_dec[j][i] = 1'b0;
        end
      end
    end
  end

  // update block selector:
  // signal mem_block_sel records where the current valid value is stored.
  // if multiple ports try to write to the same address simultaneously, the port with the highest
  // index has priority.
  always_comb begin
    mem_block_sel = mem_block_sel_q;
    for (int i = 0; i<NumWords; i++) begin
      for (int j = 0; j<NR_WRITE_PORTS; j++) begin
        if (we_dec[j][i] == 1'b1) begin
          mem_block_sel[i] = LogNrWritePorts'(j);
        end
      end
    end
  end

  // block selector flops
  always_ff @(posedge clk_i) begin
    mem_block_sel_q <= mem_block_sel;
  end

  // distributed RAM blocks
  logic [NR_READ_PORTS-1:0] [DATA_WIDTH-1:0] mem_read [NR_WRITE_PORTS];
  for (genvar j=0; j<NR_WRITE_PORTS; j++) begin : gen_regfile_ram_block
    always_ff @(posedge clk_i) begin
      if (we_i[j]) begin
        mem[j][waddr_i[j]] <= wdata_i[j];
      end
    end
    for (genvar k=0; k<NR_READ_PORTS; k++) begin : gen_block_read
      assign mem_read[j][k] = mem[j][raddr_i[k]];
    end
  end

  // output MUX
  logic [NR_READ_PORTS-1:0][LogNrWritePorts-1:0] block_addr;
  for (genvar k = 0; k < NR_READ_PORTS; k++) begin : gen_regfile_read_port
    assign block_addr[k] = mem_block_sel_q[raddr_i[k]];
    assign rdata_o[k] =
        (ZERO_REG_ZERO && raddr_i[k] == '0 ) ? '0 : mem_read[block_addr[k]][k];
  end

endmodule
