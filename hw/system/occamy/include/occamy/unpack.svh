// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Florian Zaruba <zarubaf@iis.ee.ethz.ch>

/// Generate an unpacked version of an 1D array of structs.
/// Struct is driven externally.
`define UNPACK_IN(__type, __base, __signal, __dim)                  \
  ``__type`` [``__dim``-1:0] ``__base``_``__signal``;               \
  for (genvar i = 0; i < ``__dim``; i++) begin                      \
    assign ``__base``_``__signal``[i] = ``__base``[i].``__signal``; \
  end

/// Struct is driven internally.
`define UNPACK_OUT(__type, __base, __signal, __dim)                  \
  ``__type`` [``__dim``-1:0] ``__base``_``__signal``;               \
  for (genvar i = 0; i < ``__dim``; i++) begin                      \
    assign ``__base``[i].``__signal`` = ``__base``_``__signal``[i]; \
  end
