require_extension('D');
require_rv64;
require_fp;
softfloat_roundingMode = RM;
WRITE_FRD(i64_to_f64(RS1));
set_fp_exceptions;
