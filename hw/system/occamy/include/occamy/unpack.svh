
// Generate an unpacked version of an 1D array of structs.
// Struct is driven externally.
`define UNPACK_IN(__type, __base, __signal, __dim)                  \
  ``__type`` [``__dim``-1:0] ``__base``_``__signal``;               \
  for (genvar i = 0; i < ``__dim``; i++) begin                      \
    assign ``__base``_``__signal``[i] = ``__base``[i].``__signal``; \
  end

// Struct is driven internally.
`define UNPACK_OUT(__type, __base, __signal, __dim)                  \
  ``__type`` [``__dim``-1:0] ``__base``_``__signal``;               \
  for (genvar i = 0; i < ``__dim``; i++) begin                      \
    assign ``__base``[i].``__signal`` = ``__base``_``__signal``[i]; \
  end
