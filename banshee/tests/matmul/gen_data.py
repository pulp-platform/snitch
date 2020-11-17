#!/usr/bin/env python3

import numpy as np
import sys

def rand_matrix(N, M, seed):
	return np.arange(seed, seed+N*M, dtype=np.float64).reshape(N, M) * 3.141
	# return np.random.randn(N*M).astype(np.float64).reshape(N, M)

N = 16
A = rand_matrix(N, N, 1)
B = rand_matrix(N, N, 2)
C = rand_matrix(N, N, 3)

result = np.matmul(A, B) + C
checksum = np.sum(result, axis=1)

def emit(name, array):
	print(".global %s" % name)
	print(".align 3")
	print("%s:" % name)
	bs = array.tobytes()
	for i in range(0, len(bs), 4):
		s = ""
		for n in range(4):
			s += "%02x" % bs[i+3-n]
		print("    .word 0x%s" % s)

print(".section .l1,\"aw\",@progbits")
emit("input_size", np.array(N, dtype=np.uint32))
# emit("input_A", A)
# emit("input_B", B)
# emit("input_C", C)
# emit("output", result)
emit("output_checksum", checksum)
