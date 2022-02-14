// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Florian Zaruba <zarubaf@iis.ee.ethz.ch>
// Author: Fabian Schuiki <fschuiki@iis.ee.ethz.ch>

`include "common_cells/registers.svh"

/// Hardware barrier to synchronize all cores in a cluster.
module snitch_barrier
  import snitch_pkg::*;
  import snitch_cluster_peripheral_reg_pkg::*;
#(
  parameter int unsigned AddrWidth = 0,
  parameter int  NrPorts = 0,
  parameter type dreq_t = logic,
  parameter type drsp_t = logic,
  /// Derived parameter *Do not override*
  parameter type addr_t = logic [AddrWidth-1:0]
) (
  input  logic clk_i,
  input  logic rst_ni,
  input  dreq_t [NrPorts-1:0] in_req_i,
  output drsp_t [NrPorts-1:0] in_rsp_o,

  output dreq_t [NrPorts-1:0] out_req_o,
  input  drsp_t [NrPorts-1:0] out_rsp_i,

  input  addr_t              cluster_periph_start_address_i
);

  typedef enum logic [1:0] {
    Idle,
    Wait,
    Take
  } barrier_state_e;
  barrier_state_e [NrPorts-1:0] state_d, state_q;
  logic [NrPorts-1:0] is_barrier;
  logic take_barrier;

  assign take_barrier = &is_barrier;

  always_comb begin
    state_d     = state_q;
    is_barrier  = '0;
    out_req_o = in_req_i;
    in_rsp_o = out_rsp_i;

    for (int i = 0; i < NrPorts; i++) begin
      case (state_q[i])
        Idle: begin
          if (in_req_i[i].q_valid &&
            (in_req_i[i].q.addr ==
                cluster_periph_start_address_i +
                SNITCH_CLUSTER_PERIPHERAL_HW_BARRIER_OFFSET)) begin
            state_d[i] = Wait;
            out_req_o[i].q_valid = 0;
            in_rsp_o[i].q_ready  = 0;
          end
        end
        Wait: begin
          is_barrier[i]  = 1;
          out_req_o[i].q_valid = 0;
          in_rsp_o[i].q_ready  = 0;
          if (take_barrier) state_d[i] = Take;
        end
        Take: begin
          if (out_req_o[i].q_valid && in_rsp_o[i].q_ready) state_d[i] = Idle;
        end
        default: state_d[i] = Idle;
      endcase
    end
  end

  for (genvar i = 0; i < NrPorts; i++) begin : gen_ff
    `FFARN(state_q[i], state_d[i], Idle, clk_i, rst_ni)
  end

endmodule
