module snitch_ssr_lookahead_fifo #(
  parameter bit          FALL_THROUGH = 1'b0, // fifo is in fall-through mode
  parameter int unsigned DATA_WIDTH   = 3,    // default data width if the fifo is of type logic
  parameter int unsigned DEPTH        = 8,    // depth can be arbitrary from 0 to 2**32
  parameter type T                    = logic [DATA_WIDTH-1:0],
  // DO NOT OVERWRITE THIS PARAMETER
  parameter int unsigned ADDR_DEPTH  = (DEPTH > 1) ? $clog2(DEPTH) : 1                                 
) (
  input  logic                   clk_i,      // Clock
  input  logic                   rst_ni,     // Asynchronous active-low reset
  input  logic                   clr_i,      // Synchronous clear
  input  logic                   testmode_i, // Test mode to bypass clock gating
  output logic [ADDR_DEPTH-1:0]  usage_o,    // fill pointer
  // Input port
  input  logic                   valid_i,
  output logic                   ready_o,
  input  T                       data_i,
  // Output port
  output logic                   valid_o,
  input  logic                   ready_i,
  output T                       data_d_o,
  output T                       data_q_o
); 

  logic fifo_out_ready, fifo_out_valid;
  logic head_out_valid;
  logic stream_in_valid, stream_in_ready;

  stream_fifo #(
    .FALL_THROUGH (FALL_THROUGH),
    .DATA_WIDTH   (DATA_WIDTH),
    .DEPTH        (DEPTH),
    .T            (T)
  ) i_stream_fifo(
    .clk_i,
    .rst_ni,
    .flush_i (clr_i),  
    .testmode_i,
    .usage_o,  
    .data_i,
    .valid_i,
    .ready_o,
    .data_o  (data_d_o),
    .valid_o (fifo_out_valid),
    .ready_i (fifo_out_ready)
  );

  assign fifo_out_ready = ready_i & stream_in_ready;   
  assign stream_in_valid = fifo_out_valid & ready_i;

  stream_register #(
    .T(T)
  ) i_stream_register(
    .clk_i,
    .rst_ni,
    .clr_i,
    .testmode_i,
    .valid_i (stream_in_valid),
    .ready_o (stream_in_ready),
    .data_i  (data_d_o      ),
    .valid_o (head_out_valid),
    .ready_i,
    .data_o  (data_q_o)
  );

  assign valid_o = fifo_out_valid ? head_out_valid & fifo_out_valid : head_out_valid;
   
endmodule 
                            
