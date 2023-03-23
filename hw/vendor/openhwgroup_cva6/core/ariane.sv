// Copyright 2017-2019 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// Author: Florian Zaruba, ETH Zurich
// Date: 19.03.2017
// Description: Ariane Top-level module


module ariane import ariane_pkg::*; #(
  parameter ariane_pkg::ariane_cfg_t ArianeCfg     = ariane_pkg::ArianeDefaultConfig,
  parameter int unsigned AxiAddrWidth = ariane_axi::AddrWidth,
  parameter int unsigned AxiDataWidth = ariane_axi::DataWidth,
  parameter int unsigned AxiIdWidth   = ariane_axi::IdWidth,
  parameter int unsigned AxiUserWidth = ariane_axi::UserWidth,
  parameter type axi_ar_chan_t = ariane_axi::ar_chan_t,
  parameter type axi_aw_chan_t = ariane_axi::aw_chan_t,
  parameter type axi_w_chan_t  = ariane_axi::w_chan_t,
  parameter type axi_req_t = ariane_axi::req_t,
  parameter type axi_rsp_t = ariane_axi::resp_t,
  parameter type sram_cfg_t = logic

) (
  input  logic                         clk_i,
  input  logic                         rst_ni,
  // Core ID, Cluster ID and boot address are considered more or less static
  input  logic [riscv::VLEN-1:0]       boot_addr_i,  // reset boot address
  input  logic [riscv::XLEN-1:0]       hart_id_i,    // hart id in a multicore environment (reflected in a CSR)
  // SRAM config
  input sram_cfg_t                     sram_cfg_idata_i,
  input sram_cfg_t                     sram_cfg_itag_i,
  input sram_cfg_t                     sram_cfg_ddata_i,
  input sram_cfg_t                     sram_cfg_dtag_i,
  input sram_cfg_t                     sram_cfg_dvalid_dirty_i,
  // Interrupt inputs
  input  logic [1:0]                   irq_i,        // level sensitive IR lines, mip & sip (async)
  input  logic                         ipi_i,        // inter-processor interrupts (async)
  // Timer facilities
  input  logic                         time_irq_i,   // timer interrupt in (async)
  input  logic                         debug_req_i,  // debug request (async)
`ifdef FIRESIM_TRACE
  // firesim trace port
  output traced_instr_pkg::trace_port_t trace_o,
`endif
`ifdef RVFI_TRACE
  // RISC-V formal interface port (`rvfi`):
  // Can be left open when formal tracing is not needed.
  output ariane_rvfi_pkg::rvfi_port_t  rvfi_o,
`endif
`ifdef PITON_ARIANE
  // L15 (memory side)
  output wt_cache_pkg::l15_req_t       l15_req_o,
  input  wt_cache_pkg::l15_rtrn_t      l15_rtrn_i
`else
  // memory side, AXI Master
  output axi_req_t                     axi_req_o,
  input  axi_rsp_t                     axi_resp_i
`endif
);

  cvxif_pkg::cvxif_req_t  cvxif_req;
  cvxif_pkg::cvxif_resp_t cvxif_resp;

  cva6 #(
    .ArianeCfg  ( ArianeCfg ),
    .AxiAddrWidth ( AxiAddrWidth ),
    .AxiDataWidth ( AxiDataWidth ),
    .AxiIdWidth ( AxiIdWidth ),
    .AxiUserWidth ( AxiUserWidth ),
    .axi_ar_chan_t (axi_ar_chan_t),
    .axi_aw_chan_t (axi_aw_chan_t),
    .axi_w_chan_t (axi_w_chan_t),
    .axi_req_t (axi_req_t),
    .axi_rsp_t (axi_rsp_t),
    .sram_cfg_t (sram_cfg_t)
  ) i_cva6 (
    .clk_i                ( clk_i                     ),
    .rst_ni               ( rst_ni                    ),
    .boot_addr_i          ( boot_addr_i               ),
    .hart_id_i            ( hart_id_i                 ),
    .sram_cfg_idata_i     ( sram_cfg_idata_i          ),
    .sram_cfg_itag_i      ( sram_cfg_itag_i           ),
    .sram_cfg_ddata_i     ( sram_cfg_ddata_i          ),
    .sram_cfg_dtag_i      ( sram_cfg_dtag_i           ),
    .sram_cfg_dvalid_dirty_i ( sram_cfg_dvalid_dirty_i ),
    .irq_i                ( irq_i                     ),
    .ipi_i                ( ipi_i                     ),
    .time_irq_i           ( time_irq_i                ),
    .debug_req_i          ( debug_req_i               ),
`ifdef FIRESIME_TRACE
    .trace_o              ( trace_o                   ),
`endif
`ifdef RVFI_TRACE
    .rvfi_o               ( rvfi_o                    ),
`endif
    .cvxif_req_o          ( cvxif_req                 ),
    .cvxif_resp_i         ( cvxif_resp                ),
`ifdef PITON_ARIANE
    .l15_req_o            ( l15_req_o                 ),
    .l15_rtrn_i           ( l15_rtrn_i                )
`else
    .axi_req_o            ( axi_req_o                 ),
    .axi_resp_i           ( axi_resp_i                )
`endif
  );

  if (ariane_pkg::CVXIF_PRESENT) begin : gen_example_coprocessor
    cvxif_example_coprocessor i_cvxif_coprocessor (
      .clk_i                ( clk_i                          ),
      .rst_ni               ( rst_ni                         ),
      .cvxif_req_i          ( cvxif_req                      ),
      .cvxif_resp_o         ( cvxif_resp                     )
    );
  end

endmodule // ariane
