// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Florian Zaruba <zarubaf@iis.ee.ethz.ch>
`include "common_cells/registers.svh"
`include "common_cells/assertions.svh"

/// Shim in front of SRAMs which translates atomic (and normal)
/// memory operations to RMW sequences. The requests are atomic except
/// for the DMA which can request priority. The current model is
/// that the DMA will never write to the same memory location.
/// We provide `amo_conflict_o` to detect such event and
/// indicate a fault to the programmer.

/// LR/SC reservations are happening on `DataWidth` granularity.
module snitch_amo_shim
  import snitch_pkg::*;
  import reqrsp_pkg::*;
#(
  /// Address width.
  parameter int unsigned AddrMemWidth = 32,
  /// Word width.
  parameter int unsigned DataWidth    = 64,
  /// Core ID type.
  parameter int unsigned CoreIDWidth  = 1,
  /// Do not override. Derived parameter.
  parameter int unsigned StrbWidth    = DataWidth/8
) (
  input   logic                     clk_i,
  input   logic                     rst_ni,
  // Request Side
  /// Request is valid.
  input   logic                     valid_i,
  /// Request is ready.
  output  logic                     ready_o,
  /// Request is DMA transfer.
  /// Bypass AMO, stall current AMO operation
  input   logic                     dma_access_i,
  /// Request address. Word aligned (not byte aligned!)
  input   logic [AddrMemWidth-1:0]  addr_i,
  /// Request AMO type. Must AMONone if `dma_access_i` is set.
  input   amo_op_e      amo_i,
  /// Request is a write. Must be `0` for AMOs.
  input   logic                     write_i,
  /// Data to write, second operand for AMOs.
  input   logic [DataWidth-1:0]     wdata_i,
  /// Write byte mask for AMOs. For AMOs the byte mask must
  /// be all `1` for the 32 bits which are read by the AMO.
  input   logic [StrbWidth-1:0]     wstrb_i,
  /// Read data, first operand for AMOs.
  output  logic [DataWidth-1:0]     rdata_o,
  /// Core making the request. Only valid if not a DMA transfer.
  /// This is needed for determining if the reservation should be
  /// killed or not.
  input   logic [CoreIDWidth-1:0]   core_id_i,
  /// The request is made by a core. Only valid if not a DMA transfer.
  /// Another source of transfers can be coming from the AXI bus.
  input   logic                     is_core_i,
  // SRAM interface. Data always comes a cycle later.
  /// Bank request.
  output  logic                     mem_req_o,
  /// Address.
  output  logic [AddrMemWidth-1:0]  mem_add_o,
  /// 1: Store, 0: Load
  output  logic                     mem_wen_o,
  /// Write data.
  output  logic [DataWidth-1:0]     mem_wdata_o,
  /// Byte enable.
  output  logic [StrbWidth-1:0]     mem_be_o,
  /// Read data.
  input   logic [DataWidth-1:0]     mem_rdata_i,
  /// Status signal, AMO clashed with DMA transfer.
  output  logic                     amo_conflict_o
);

  logic idx_q, idx_d;
  logic [31:0] operand_a, operand_b_q, amo_result, amo_result_q;
  logic [AddrMemWidth-1:0] addr_q;
  amo_op_e amo_op_q;
  logic load_amo;
  logic sc_successful, sc_successful_q;
  logic sc_q;

  typedef enum logic [1:0] {
    Idle, DoAMO, WriteBackAMO
  } state_e;
  state_e state_q, state_d;

  typedef struct packed {
    /// Is the reservation valid.
    logic valid;
    /// On which address is the reservation placed.
    /// This address is aligned to the memory size
    /// implying that the reservation happen on a set size
    /// equal to the word width of the memory (32 or 64 bit).
    logic [AddrMemWidth-1:0] addr;
    /// Which core made this reservation. Important to
    /// track the reservations from different cores and
    /// to prevent any live-locking.
    logic [CoreIDWidth-1:0]  core;
  } reservation_t;
  reservation_t reservation_d, reservation_q;

  logic                    core_valid;
  logic                    core_ready;
  logic [AddrMemWidth-1:0] core_add;
  logic                    core_wen;
  logic [DataWidth-1:0]    core_wdata;
  logic [StrbWidth-1:0]    core_be;
  // Core got access to the memory port.
  logic                    core_arb_ready;

  // ----------------
  // Priority arbiter
  // ----------------
  //  DMA has priority.
  always_comb begin
    mem_req_o = core_valid;
    ready_o = core_ready;
    mem_add_o = core_add;
    mem_wen_o = core_wen;
    mem_wdata_o = core_wdata;
    mem_be_o = core_be;
    core_arb_ready = 1'b1;

    if (dma_access_i) begin
      mem_req_o = valid_i;
      ready_o = 1'b1;
      mem_add_o = addr_i;
      mem_wen_o = write_i;
      mem_wdata_o = wdata_i;
      mem_be_o = wstrb_i;
      core_arb_ready = 1'b0;
    end
  end

  // In case of a SC we must forward SC result from the cycle earlier.
  assign rdata_o = sc_q ? $unsigned(~sc_successful_q) : mem_rdata_i;
  assign amo_conflict_o = dma_access_i & (state_q != Idle) & (addr_q == addr_i);

  // -----
  // LR/SC
  // -----
  `FF(sc_successful_q, sc_successful, 1'b0)
  `FF(sc_q, valid_i & ready_o & (amo_i == AMOSC), 1'b0)
  `FF(reservation_q, reservation_d, '0)

  always_comb begin
    reservation_d = reservation_q;
    sc_successful = 1'b0;
    // new valid transaction
    if (valid_i && ready_o) begin

      // An SC can only pair with the most recent LR in program order.
      // Place a reservation on the address if there isn't already a valid reservation.
      // We prevent a live-lock by don't throwing away the reservation of a hart unless
      // it makes a new reservation in program order or issues any SC.
      if (amo_i == AMOLR && (!reservation_q.valid || reservation_q.core == core_id_i)) begin
        reservation_d.valid = 1'b1;
        reservation_d.addr = addr_i;
        reservation_d.core = core_id_i;
      end

      // An SC may succeed only if no store from another hart (or other device) to
      // the reservation set can be observed to have occurred between
      // the LR and the SC, and if there is no other SC between the
      // LR and itself in program order.

      // check whether another core has made a write attempt
      if ((!is_core_i || dma_access_i || core_id_i != reservation_q.core) &&
          (addr_i == reservation_q.addr) &&
          (!(amo_i inside {AMONone, AMOLR, AMOSC}) || write_i)) begin
        reservation_d.valid = 1'b0;
      end

      // An SC from the same hart clears any pending reservation.
      if (reservation_q.valid && amo_i == AMOSC && reservation_q.core == core_id_i) begin
        reservation_d.valid = 1'b0;
        sc_successful = reservation_q.addr == addr_i;
      end
    end
  end

  // -------
  // Atomics
  // -------
  logic [63:0] wdata;
  assign wdata = $unsigned(wdata_i);

  `FF(state_q, state_d, Idle)
  `FFLNR(amo_op_q, amo_i, load_amo, clk_i)
  `FFLNR(addr_q, addr_i, load_amo, clk_i)
  // Which word to pick.
  `FFLNR(idx_q, idx_d, load_amo, clk_i)
  `FFLNR(operand_b_q, (wstrb_i[0] ? wdata[31:0]  : wdata[63:32]), load_amo, clk_i)
  `FFLNR(amo_result_q, amo_result, (state_q == DoAMO), clk_i)

  assign idx_d = ((DataWidth == 64) ? wstrb_i[DataWidth/8/2] : 0);
  assign load_amo = valid_i & ready_o &
          ~(amo_i inside {AMONone, AMOLR, AMOSC});
  assign operand_a = mem_rdata_i[32*idx_q+:32];

  always_comb begin
    // pass-through by default
    core_valid = valid_i;
    core_ready = 1'b1;
    core_add = addr_i;
    core_wen = write_i | (sc_successful & (amo_i == AMOSC));
    core_wdata = wdata_i;
    core_be = wstrb_i;

    state_d = state_q;

    unique case (state_q)
      // First cycle: Read operand a.
      Idle: if (load_amo) state_d = DoAMO;
      // Second cycle: Do atomic.
      DoAMO: begin
        core_valid = 1'b0;
        core_ready = 1'b0;
        state_d = WriteBackAMO;
      end
      // Third cycle: Try to write-back result.
      WriteBackAMO: begin
        core_valid = 1'b1;
        core_ready = 1'b0;
        core_wen = 1'b1;
        core_add = addr_q;
        core_be = 'b1111 << (idx_q*4);
        core_wdata = amo_result_q << (idx_q*32);
        if (core_arb_ready) state_d = Idle;
      end
      default:;
    endcase
  end

  snitch_amo_alu i_amo_alu (
    .amo_op_i (amo_op_q),
    .operand_a_i (operand_a),
    .operand_b_i (operand_b_q),
    .result_o (amo_result)
  );

  // ----------
  // Assertions
  // ----------
  // Check that data width is legal (a power of two and at least 32 bit).
  `ASSERT_INIT(DataWidthCheck,
    DataWidth >= 32 &&  DataWidth <= 64 && 2**$clog2(DataWidth) == DataWidth)
  // Make sure that write is never set for AMOs.
  `ASSERT(AMOWriteEnable, valid_i && !amo_i inside {AMONone} |-> !write_i)
  // Make sure DMA transfers are not AMOs.
  `ASSERT(DMANoAMO, valid_i && dma_access_i |-> amo_i == AMONone)
  // Byte enable mask is correct
  `ASSERT(ByteMaskCorrect, valid_i && !amo_i inside {AMONone} |-> wstrb_i[4*idx_d+:4] == '1)

endmodule

/// Simple ALU supporting atomic memory operations.
module snitch_amo_alu import reqrsp_pkg::*; (
  input  amo_op_e amo_op_i,
  input  logic [31:0]         operand_a_i,
  input  logic [31:0]         operand_b_i,
  output logic [31:0]         result_o
);
    // ----------------
    // AMO ALU
    // ----------------
    logic [33:0] adder_sum;
    logic [32:0] adder_operand_a, adder_operand_b;

    assign adder_sum = adder_operand_a + adder_operand_b;
    /* verilator lint_off WIDTH */
    always_comb begin : amo_alu

        adder_operand_a = $signed(operand_a_i);
        adder_operand_b = $signed(operand_b_i);

        result_o = operand_b_i;

        unique case (amo_op_i)
            // the default is to output operand_b
            AMOSwap:;
            AMOAdd: result_o = adder_sum[31:0];
            AMOAnd: result_o = operand_a_i & operand_b_i;
            AMOOr:  result_o = operand_a_i | operand_b_i;
            AMOXor: result_o = operand_a_i ^ operand_b_i;
            AMOMax: begin
                adder_operand_b = -$signed(operand_b_i);
                result_o = adder_sum[32] ? operand_b_i : operand_a_i;
            end
            AMOMin: begin
                adder_operand_b = -$signed(operand_b_i);
                result_o = adder_sum[32] ? operand_a_i : operand_b_i;
            end
            AMOMaxu: begin
                adder_operand_a = $unsigned(operand_a_i);
                adder_operand_b = -$unsigned(operand_b_i);
                result_o = adder_sum[32] ? operand_b_i : operand_a_i;
            end
            AMOMinu: begin
                adder_operand_a = $unsigned(operand_a_i);
                adder_operand_b = -$unsigned(operand_b_i);
                result_o = adder_sum[32] ? operand_a_i : operand_b_i;
            end
            default: result_o = '0;
        endcase
    end
endmodule
