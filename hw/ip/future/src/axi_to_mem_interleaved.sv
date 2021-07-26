// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

// Author:
// Thomas Benz <tbenz@iis.ee.ethz.ch>

/// axi_to_mem_interleved prevents deadlocks by allowing reads to
/// bypass writes and vice versa
/// Warning: currently only supports NumBanks == 1!

module axi_to_mem_interleaved #(
  parameter type         axi_req_t  = logic, // AXI request type
  parameter type         axi_resp_t = logic, // AXI response type
  parameter int unsigned AddrWidth  = 0,     // address width
  parameter int unsigned DataWidth  = 0,     // AXI data width
  parameter int unsigned IdWidth    = 0,     // AXI ID width
  parameter int unsigned NumBanks   = 0,     // number of banks at output
  parameter int unsigned BufDepth   = 1,     // depth of memory response buffer
  // Dependent parameters, do not override.
  localparam type addr_t     = logic [AddrWidth-1:0],
  localparam type mem_atop_t = logic [5:0],
  localparam type mem_data_t = logic [DataWidth/NumBanks-1:0],
  localparam type mem_strb_t = logic [DataWidth/NumBanks/8-1:0]
) (
  input  logic                      clk_i,
  input  logic                      rst_ni,

  output logic                      busy_o,

  input  axi_req_t                  axi_req_i,
  output axi_resp_t                 axi_resp_o,

  output logic      [NumBanks-1:0]  mem_req_o,
  input  logic      [NumBanks-1:0]  mem_gnt_i,
  output addr_t     [NumBanks-1:0]  mem_addr_o,   // byte address
  output mem_data_t [NumBanks-1:0]  mem_wdata_o,  // write data
  output mem_strb_t [NumBanks-1:0]  mem_strb_o,   // byte-wise strobe
  output mem_atop_t [NumBanks-1:0]  mem_atop_o,   // atomic operation
  output logic      [NumBanks-1:0]  mem_we_o,     // write enable
  input  logic      [NumBanks-1:0]  mem_rvalid_i, // response valid
  input  mem_data_t [NumBanks-1:0]  mem_rdata_i   // read data
);

  // internal signals
  logic w_busy, r_busy;
  logic arb_outcome, arb_outcome_head;

  // internal AXI buses
  axi_req_t  r_axi_req,  w_axi_req;
  axi_resp_t r_axi_resp, w_axi_resp;

  // internal TCDM buses
  logic      [NumBanks-1:0]  r_mem_req,    w_mem_req;
  logic      [NumBanks-1:0]  r_mem_gnt,    w_mem_gnt;
  addr_t     [NumBanks-1:0]  r_mem_addr,   w_mem_addr;
  mem_data_t [NumBanks-1:0]  r_mem_wdata,  w_mem_wdata;
  mem_strb_t [NumBanks-1:0]  r_mem_strb,   w_mem_strb;
  mem_atop_t [NumBanks-1:0]  r_mem_atop,   w_mem_atop;
  logic      [NumBanks-1:0]  r_mem_we,     w_mem_we;
  logic      [NumBanks-1:0]  r_mem_rvalid, w_mem_rvalid;
  mem_data_t [NumBanks-1:0]  r_mem_rdata,  w_mem_rdata;

  // split AXI bus in read and write
  always_comb begin : proc_axi_rw_split
    axi_resp_o.r          = r_axi_resp.r;
    axi_resp_o.r_valid    = r_axi_resp.r_valid;
    axi_resp_o.ar_ready   = r_axi_resp.ar_ready;
    axi_resp_o.b          = w_axi_resp.b;
    axi_resp_o.b_valid    = w_axi_resp.b_valid;
    axi_resp_o.w_ready    = w_axi_resp.w_ready;
    axi_resp_o.aw_ready   = w_axi_resp.aw_ready;

    w_axi_req             = '0;
    w_axi_req.aw          = axi_req_i.aw;
    w_axi_req.aw_valid    = axi_req_i.aw_valid;
    w_axi_req.w           = axi_req_i.w;
    w_axi_req.w_valid     = axi_req_i.w_valid;
    w_axi_req.b_ready     = axi_req_i.b_ready;

    r_axi_req             = '0;
    r_axi_req.ar          = axi_req_i.ar;
    r_axi_req.ar_valid    = axi_req_i.ar_valid;
    r_axi_req.r_ready     = axi_req_i.r_ready;
  end

  axi_to_mem #(
    .axi_req_t   ( axi_req_t  ),
    .axi_resp_t  ( axi_resp_t ),
    .AddrWidth   ( AddrWidth  ),
    .DataWidth   ( DataWidth  ),
    .IdWidth     ( IdWidth    ),
    .NumBanks    ( NumBanks   ),
    .BufDepth    ( BufDepth   )
  ) i_axi_to_mem_write (
    .clk_i        ( clk_i         ),
    .rst_ni       ( rst_ni        ),
    .busy_o       ( w_busy        ),
    .axi_req_i    ( w_axi_req     ),
    .axi_resp_o   ( w_axi_resp    ),
    .mem_req_o    ( w_mem_req     ),
    .mem_gnt_i    ( w_mem_gnt     ),
    .mem_addr_o   ( w_mem_addr    ),
    .mem_wdata_o  ( w_mem_wdata   ),
    .mem_strb_o   ( w_mem_strb    ),
    .mem_atop_o   ( w_mem_atop    ),
    .mem_we_o     ( w_mem_we      ),
    .mem_rvalid_i ( w_mem_rvalid  ),
    .mem_rdata_i  ( w_mem_rdata   )
  );

  axi_to_mem #(
    .axi_req_t   ( axi_req_t  ),
    .axi_resp_t  ( axi_resp_t ),
    .AddrWidth   ( AddrWidth  ),
    .DataWidth   ( DataWidth  ),
    .IdWidth     ( IdWidth    ),
    .NumBanks    ( NumBanks   ),
    .BufDepth    ( BufDepth   )
  ) i_axi_to_mem_read (
    .clk_i        ( clk_i         ),
    .rst_ni       ( rst_ni        ),
    .busy_o       ( r_busy        ),
    .axi_req_i    ( r_axi_req     ),
    .axi_resp_o   ( r_axi_resp    ),
    .mem_req_o    ( r_mem_req     ),
    .mem_gnt_i    ( r_mem_gnt     ),
    .mem_addr_o   ( r_mem_addr    ),
    .mem_wdata_o  ( r_mem_wdata   ),
    .mem_strb_o   ( r_mem_strb    ),
    .mem_atop_o   ( r_mem_atop    ),
    .mem_we_o     ( r_mem_we      ),
    .mem_rvalid_i ( r_mem_rvalid  ),
    .mem_rdata_i  ( r_mem_rdata   )
  );

  // create a struct for the rr-arb-tree
  typedef struct packed {
    addr_t     addr;
    mem_data_t wdata;
    mem_strb_t strb;
    logic      we;
    mem_atop_t atop;
  } mem_req_payload_t;

  mem_req_payload_t r_payload, w_payload, payload;

  // pack the mem
  assign r_payload.addr  = r_mem_addr;
  assign r_payload.wdata = r_mem_wdata;
  assign r_payload.strb  = r_mem_strb;
  assign r_payload.we    = r_mem_we;
  assign r_payload.atop  = r_mem_atop;

  assign w_payload.addr  = w_mem_addr;
  assign w_payload.wdata = w_mem_wdata;
  assign w_payload.strb  = w_mem_strb;
  assign w_payload.we    = w_mem_we;
  assign w_payload.atop  = w_mem_atop;

  assign mem_addr_o  = payload.addr;
  assign mem_wdata_o = payload.wdata;
  assign mem_strb_o  = payload.strb;
  assign mem_we_o    = payload.we;
  assign mem_atop_o  = payload.atop;

  // route data back to both channels
  assign w_mem_rdata  = mem_rdata_i;
  assign r_mem_rdata  = mem_rdata_i;

  assign w_mem_rvalid = mem_rvalid_i & !arb_outcome_head;
  assign r_mem_rvalid = mem_rvalid_i &  arb_outcome_head;

  // fine-grain arbitration
  rr_arb_tree #(
    .NumIn     ( 2                 ),
    .DataType  ( mem_req_payload_t )
  ) i_rr_arb_tree (
    .clk_i    ( clk_i                    ),
    .rst_ni   ( rst_ni                   ),
    .flush_i  ( 1'b0                     ),
    .rr_i     (  '0                      ),
    .req_i    ( { r_mem_req, w_mem_req } ),
    .gnt_o    ( { r_mem_gnt, w_mem_gnt } ),
    .data_i   ( { r_payload, w_payload } ),
    .req_o    ( mem_req_o                ),
    .gnt_i    ( mem_gnt_i                ),
    .data_o   ( payload                  ),
    .idx_o    ( arb_outcome              )
  );

  // back-routing store
  fifo_v3 #(
    .DATA_WIDTH ( 1            ),
    .DEPTH      ( BufDepth + 1 )
  ) i_fifo_v3_response_trgt_store (
    .clk_i      ( clk_i                 ),
    .rst_ni     ( rst_ni                ),
    .flush_i    ( 1'b0                  ),
    .testmode_i ( 1'b0                  ),
    .full_o     ( ),
    .empty_o    ( ),
    .usage_o    ( ),
    .data_i     ( arb_outcome           ),
    .push_i     ( mem_req_o & mem_gnt_i ),
    .data_o     ( arb_outcome_head      ),
    .pop_i      ( mem_rvalid_i          )
  );

endmodule : axi_to_mem_interleaved
