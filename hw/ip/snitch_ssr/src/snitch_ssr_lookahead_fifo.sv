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

//  logic push, pop;
//  logic empty, full;
//  logic stream_in_valid, stream_in_ready, stream_out_valid, stream_out_ready;
  
//  assign push = valid_i & ~full;
//  assign pop = ready_i & ~empty & stream_in_ready;
     
 /* fifo_v3 #(
    .FALL_THROUGH ( FALL_THROUGH ),
    .DATA_WIDTH   ( DATA_WIDTH   ),
    .DEPTH        ( DEPTH )
  ) i_fifo (
    .clk_i,
    .rst_ni,
    .testmode_i,
    .flush_i    ( clr_i      ),
    .full_o     ( full       ),
    .empty_o    ( empty      ),
    .usage_o,
    .data_i     ( data_i     ),
    .push_i     ( push       ),
    .data_o     ( data_d_o   ),
    .pop_i      ( pop        )
  );
*/
  logic fifo_in_ready, fifo_out_valid;
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
    .ready_i (stream_in_ready & ready_i)
  );
  assign stream_in_valid = fifo_out_valid & ready_i;
//  assign stream_out_ready = ready_i;
   
  stream_register #(
    .T(T)
  ) i_stream_register(
    .clk_i,
    .rst_ni,
    .clr_i,
    .testmode_i,
    .valid_i (stream_in_valid),
    .ready_o (stream_in_ready),
    .data_i  (data_d_o),
    .valid_o,
    .ready_i,
    .data_o  (data_q_o)
  );

  //assign ready_o = stream_in_ready;
  //assign valid_o = stream_out_valid;

endmodule 
                            
