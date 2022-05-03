# See LICENSE for license details.

#*****************************************************************************
# lrsr.S
#-----------------------------------------------------------------------------
#
# Test LR/SC instructions.
#

#include "riscv_test.h"
#include "test_macros.h"

RVTEST_RV64U
RVTEST_CODE_BEGIN

# make sure that sc without a reservation fails.
TEST_CASE( 2, a4, 1, \
  la a0, foo; \
  li a5, 0xdeadbeef; \
  sc.w a4, a5, (a0); \
)

# make sure the failing sc did not commit into memory
TEST_CASE( 3, a4, 0, \
  lw a4, foo; \
)


#
# Disable test case 4 for now. It assumes a <1K reservation granule, when
# in reality any size granule is valid. After discussion in issue #315,
# decided to simply disable the test for now.
# (See https://github.com/riscv/riscv-tests/issues/315)
#
## make sure that sc with the wrong reservation fails.
## TODO is this actually mandatory behavior?
#TEST_CASE( 4, a4, 1, \
#  la a0, foo; \
#  la a1, fooTest3; \
#  lr.w a1, (a1); \
#  sc.w a4, a1, (a0); \
#)

# try a simple lr sc
TEST_CASE( 5, a4, 0, \
  la a1, fooTest3; \
  li a5, 1; \
  lr.w a0, (a1); \
  sc.w a4, a5, (a1); \
)

# make sure that sc-after-successful-sc fails.
TEST_CASE( 6, a1, 1, \
  la a0, foo; \
  li a5, 0xdeadbeef; \
  lr.w a1, (a0); \
  sc.w a1, a5, (a0); \
  sc.w a1, a5, (a0); \
  )


TEST_PASSFAIL

RVTEST_CODE_END

  .data
RVTEST_DATA_BEGIN

  TEST_DATA

RVTEST_DATA_END

  .bss
  .align 3
foo:
  .dword 0
fooTest3:
  .dword 0
