// Copyright (c) 2018 ETH Zurich, University of Bologna
//
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

// Test infrastructure for APB interfaces
package apb_test;

  // Simple APB driver with thread-safe read and write functions
  class apb_driver #(
    parameter int unsigned ADDR_WIDTH = 32'd32, // APB4 address width
    parameter int unsigned DATA_WIDTH = 32'd32, // APB4 data width
    parameter time         TA         = 0ns,    // application time
    parameter time         TT         = 0ns     // test time
  );
    localparam int unsigned STRB_WIDTH = cf_math_pkg::ceil_div(DATA_WIDTH, 8);
    typedef logic [ADDR_WIDTH-1:0] addr_t;
    typedef logic [DATA_WIDTH-1:0] data_t;
    typedef logic [STRB_WIDTH-1:0] strb_t;
    virtual APB_DV #(
      .ADDR_WIDTH(ADDR_WIDTH),
      .DATA_WIDTH(DATA_WIDTH)
    ) apb;
    semaphore lock;

    function new(virtual APB_DV #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH)) apb);
      this.apb = apb;
      this.lock = new(1);
    endfunction

    function void reset_master();
      apb.paddr   <= '0;
      apb.pprot   <= '0;
      apb.psel    <= 1'b0;
      apb.penable <= 1'b0;
      apb.pwrite  <= 1'b0;
      apb.pwdata  <= '0;
      apb.pstrb   <= '0;
    endfunction

    function void reset_slave();
      apb.pready  <= 1'b0;
      apb.prdata  <= '0;
      apb.pslverr <= 1'b0;
    endfunction

    task cycle_start;
      #TT;
    endtask

    task cycle_end;
      @(posedge apb.clk_i);
    endtask

    // this task reads from an APB4 slave, acts as master
    task read(
      input  addr_t addr,
      output data_t data,
      output logic  err
    );
      while (!lock.try_get()) begin
        cycle_end();
      end
      apb.paddr   <= #TA addr;
      apb.pwrite  <= #TA 1'b0;
      apb.psel    <= #TA 1'b1;
      cycle_end();
      apb.penable <= #TA 1'b1;
      cycle_start();
      while (!apb.pready) begin
        cycle_end();
        cycle_start();
      end
      data  = apb.prdata;
      err   = apb.pslverr;
      cycle_end();
      apb.paddr   <= #TA '0;
      apb.psel    <= #TA 1'b0;
      apb.penable <= #TA 1'b0;
      lock.put();
    endtask

    // this task writes to an APB4 slave, acts as master
    task write(
      input  addr_t addr,
      input  data_t data,
      input  strb_t strb,
      output logic  err
    );
      while (!lock.try_get()) begin
        cycle_end();
      end
      apb.paddr   <= #TA addr;
      apb.pwdata  <= #TA data;
      apb.pstrb   <= #TA strb;
      apb.pwrite  <= #TA 1'b1;
      apb.psel    <= #TA 1'b1;
      cycle_end();
      apb.penable <= #TA 1'b1;
      cycle_start();
      while (!apb.pready) begin
        cycle_end();
        cycle_start();
      end
      err = apb.pslverr;
      cycle_end();
      apb.paddr   <= #TA '0;
      apb.pwdata  <= #TA '0;
      apb.pstrb   <= #TA '0;
      apb.pwrite  <= #TA 1'b0;
      apb.psel    <= #TA 1'b0;
      apb.penable <= #TA 1'b0;
      lock.put();
    endtask

  endclass

endpackage
