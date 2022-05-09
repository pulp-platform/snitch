module snitch_ipu_simd_logic
  #(
  parameter int unsigned Width = 32,
  parameter int unsigned Factor = 4
) (
  input  logic simd_signed,
  input  logic simd_dotp_op_a_signed,
  input  logic simd_dotp_op_b_signed,
  input  logic simd_dotp_acc,
  input  logic [5:0] imm6,
  input  logic [Width-1:0]   op_c_i,
  input  logic [7:0][3:0] simd_op_a,
  input  logic [7:0][3:0] simd_op_b,
  input  logic [7:0][3:0] simd_op_c,
  input  logic [3:0][3:0] simd_imm,
  output logic [7:0][3:0] simd_result,
  input snitch_ipu_pkg::simd_op_t simd_op
);

  import snitch_ipu_pkg::SimdNop;
  import snitch_ipu_pkg::SimdAdd;
  import snitch_ipu_pkg::SimdSub;
  import snitch_ipu_pkg::SimdAvg;
  import snitch_ipu_pkg::SimdMin;
  import snitch_ipu_pkg::SimdMax;
  import snitch_ipu_pkg::SimdSrl;
  import snitch_ipu_pkg::SimdSra;
  import snitch_ipu_pkg::SimdSll;
  import snitch_ipu_pkg::SimdOr;
  import snitch_ipu_pkg::SimdXor;
  import snitch_ipu_pkg::SimdAnd;
  import snitch_ipu_pkg::SimdAbs;
  import snitch_ipu_pkg::SimdExt;
  import snitch_ipu_pkg::SimdIns;
  import snitch_ipu_pkg::SimdDotp;
  import snitch_ipu_pkg::SimdShuffle;

  always_comb begin
    unique case (simd_op)
      SimdAdd:
        for (int i = 0; i < Width/(4*Factor); i++)
          simd_result[Factor*i +: Factor] = $signed(simd_op_a[Factor*i +: Factor]) +
                                                             $signed(simd_op_b[Factor*i +: Factor]);
      SimdSub:
        for (int i = 0; i < Width/(4*Factor); i++)
          simd_result[Factor*i +: Factor] = $signed(simd_op_a[Factor*i +: Factor]) -
                                                             $signed(simd_op_b[Factor*i +: Factor]);
      SimdAvg:
        for (int i = 0; i < Width/(4*Factor); i++) begin
          simd_result[Factor*i +: Factor] = $signed(simd_op_a[Factor*i +: Factor]) +
                                                             $signed(simd_op_b[Factor*i +: Factor]);
          simd_result[Factor*i +: Factor] = {simd_result[Factor*(i+1)-1][3] & simd_signed, 
                                                             simd_result[Factor*i +: Factor]} >> 1;
        end
      SimdMin:
        for (int i = 0; i < Width/(4*Factor); i++)
          simd_result[Factor*i +: Factor] = $signed({simd_op_a[Factor*(i+1)-1][3] & simd_signed, 
                                                             simd_op_a[Factor*i +: Factor]}) <=
                                            $signed({simd_op_b[Factor*(i+1)-1][3] & simd_signed, 
                                                             simd_op_b[Factor*i +: Factor]}) ?
                                                             simd_op_a[Factor*i +: Factor] : 
                                                             simd_op_b[Factor*i +: Factor];
      SimdMax:
        for (int i = 0; i < Width/(4*Factor); i++)
          simd_result[Factor*i +: Factor] = $signed({simd_op_a[Factor*(i+1)-1][3] & simd_signed, 
                                                             simd_op_a[Factor*i +: Factor]}) >
                                            $signed({simd_op_b[Factor*(i+1)-1][3] & simd_signed, 
                                                             simd_op_b[Factor*i +: Factor]}) ?
                                                             simd_op_a[Factor*i +: Factor] : 
                                                             simd_op_b[Factor*i +: Factor];
      SimdSrl:
        for (int i = 0; i < Width/(4*Factor); i++)
          simd_result[Factor*i +: Factor] = $unsigned(simd_op_a[Factor*i +: Factor]) >>
                                                            simd_op_b[Factor*i][$clog2(Factor)+1:0];
      SimdSra:
        for (int i = 0; i < Width/(4*Factor); i++)
          simd_result[Factor*i +: Factor] = $signed(simd_op_a[Factor*i +: Factor]) >>>
                                                            simd_op_b[Factor*i][$clog2(Factor)+1:0];
      SimdSll:
        for (int i = 0; i < Width/(4*Factor); i++)
          simd_result[Factor*i +: Factor] = $unsigned(simd_op_a[Factor*i +: Factor]) <<
                                                            simd_op_b[Factor*i][$clog2(Factor)+1:0];
      SimdOr: simd_result = simd_op_a | simd_op_b;
      SimdXor: simd_result = simd_op_a ^ simd_op_b;
      SimdAnd: simd_result = simd_op_a & simd_op_b;
      SimdAbs:
        for (int i = 0; i < Width/(4*Factor); i++)
          simd_result[Factor*i +: Factor] = $signed(simd_op_a[Factor*i +: Factor]) > 0 ?
                                                             simd_op_a[Factor*i +: Factor] :
                                                            -$signed(simd_op_a[Factor*i +: Factor]);
      SimdExt: begin
        simd_result[Factor-1:0] = simd_op_a[Factor*imm6[$clog2(4/Factor):0] +: Factor];
        // sign- or zero-extend
        simd_result[7:Factor] = {(32-4*Factor){simd_op_a[Factor*(imm6[$clog2(4/Factor):0]+1)-1][3] &
                                                                                      simd_signed}};
      end
      SimdIns: begin
        simd_result = op_c_i;
        simd_result[Factor*(imm6[$clog2(4/Factor):0]) +: Factor] = simd_op_a[Factor-1:0];
      end
      SimdDotp: begin
        simd_result = op_c_i & {(Width){simd_dotp_acc}}; // accumulate on rd or start from zero
        for (int i = 0; i < Width/(4*Factor); i++)
          simd_result = $signed(simd_result) + 
                        $signed({simd_op_a[Factor*(i+1)-1][3] & simd_dotp_op_a_signed, 
                                                                simd_op_a[Factor*i +: Factor]}) *
                        $signed({simd_op_b[Factor*(i+1)-1][3] & simd_dotp_op_b_signed, 
                                                                simd_op_b[Factor*i +: Factor]});
      end
      SimdShuffle:
        for (int i = 0; i < Width/(4*Factor); i++)
          simd_result[Factor*i +: Factor] = simd_op_b[Factor*i][3-$clog2(Factor)] ? 
                     simd_op_a[Factor*simd_op_b[Factor*i][$clog2(4/Factor):0] +: Factor] : 
                     simd_op_c[Factor*simd_op_b[Factor*i][$clog2(4/Factor):0] +: Factor];
      default: ;
    endcase
  end
endmodule
