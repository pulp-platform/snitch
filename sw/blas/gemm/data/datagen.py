#!/usr/bin/env python3
# Copyright 2022 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

# Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

import numpy as np
import torch
import argparse
import pathlib
import hjson

np.random.seed(42)

C_TYPES = {
  '64': 'double',
  '32': 'float',
  '16': '__fp16',
  '8': 'char'
}

NUMPY_TYPES = {
  '64': np.double,
  '32': np.single,
  '16': np.half,
  '8': np.byte
}


def format_vector_definition(id, vector, typ):
    s = f'{typ} {id}[{len(vector)}] = ' + '{\n'
    for i, el in enumerate(vector):
        s += f'\t{el},'
        if i % 8 == 7:
            s += '\n'
    s += '};'
    return s


def format_vector_declaration(id, vector, typ):
    s = f'{typ} {id}[{len(vector)}];'
    return s


def format_scalar_definition(id, scalar, typ):
    s = f'{typ} {id} = {scalar};'
    return s


def emit_header_file(**kwargs):

    emit_str = "// Copyright 2023 ETH Zurich and University of Bologna.\n" + \
               "// Licensed under the Apache License, Version 2.0, see LICENSE for details.\n" + \
               "// SPDX-License-Identifier: Apache-2.0\n\n"
    emit_str += emit_gemm_data(**kwargs)
    return emit_str


def emit_gemm_data(**kwargs):

    # Generate random input matrices
    dtype = NUMPY_TYPES[str(kwargs['prec'])]
    if (kwargs['prec']) == 8:
        # sign -1 or 1
        sign_a = torch.randint(0, 2, (kwargs['M'], kwargs['K']), requires_grad=False, dtype=torch.uint8)
        # esponent < 0b01111
        exponent_a = torch.randint(0, 16, (kwargs['M'], kwargs['K']), requires_grad=False, dtype=torch.uint8)
         # mantissa can be arbitrary
        mantissa_a = torch.randint(0, 4, (kwargs['M'], kwargs['K']), requires_grad=False, dtype=torch.uint8)
        # sign -1 or 1
        sign_b = torch.randint(0, 2, (kwargs['K'], kwargs['N']), requires_grad=False, dtype=torch.uint8)
        # esponent < 0b01111
        exponent_b = torch.randint(0, 16, (kwargs['K'], kwargs['N']), requires_grad=False, dtype=torch.uint8)
         # mantissa can be arbitrary
        mantissa_b = torch.randint(0, 4, (kwargs['K'], kwargs['N']), requires_grad=False, dtype=torch.uint8)
        # sign -1 or 1
        sign_c = torch.randint(0, 2, (kwargs['M'], kwargs['N']), requires_grad=False, dtype=torch.uint8)
        # esponent < 0b01111
        exponent_c = torch.randint(0, 16, (kwargs['M'], kwargs['N']), requires_grad=False, dtype=torch.uint8)
         # mantissa can be arbitrary
        mantissa_c = torch.randint(0, 4, (kwargs['M'], kwargs['N']), requires_grad=False, dtype=torch.uint8)
        a = ((-1.0)**sign_a.double())*(2.0**(exponent_a.double()-15.0))*(1.0 + mantissa_a.double() / (2**2))
        b = ((-1.0)**sign_b.double())*(2.0**(exponent_b.double()-15.0))*(1.0 + mantissa_b.double() / (2**2))
        c = ((-1.0)**sign_c.double())*(2.0**(exponent_c.double()-15.0))*(1.0 + mantissa_c.double() / (2**2))
    else:
        a = np.random.rand(kwargs['M'], kwargs['K']).astype(dtype)
        b = np.random.rand(kwargs['K'], kwargs['N']).astype(dtype)
        c = np.random.rand(kwargs['M'], kwargs['N']).astype(dtype)

    result = np.matmul(a, b) + kwargs['alpha'] * c

    # Store matrices in transposed form if requested
    a = a.T if kwargs['ta'] else a
    b = b.T if kwargs['tb'] else b

    data_str = []
    data_str += [format_scalar_definition('M', kwargs['M'], 'uint32_t')]
    data_str += [format_scalar_definition('N', kwargs['N'], 'uint32_t')]
    data_str += [format_scalar_definition('K', kwargs['K'], 'uint32_t')]
    data_str += [format_scalar_definition('TA', int(kwargs['ta']), 'uint32_t')]
    data_str += [format_scalar_definition('TB', int(kwargs['tb']), 'uint32_t')]
    data_str += [format_scalar_definition('ALPHA', kwargs['alpha'], 'uint32_t')]
    data_str += [format_scalar_definition('dtype_size', kwargs['prec']//8, 'uint32_t')]
    data_str += [format_scalar_definition('expand', kwargs['expand'], 'uint32_t')]
    data_str += [format_vector_definition('a', a.flatten(), C_TYPES[str(kwargs['prec'])])]
    data_str += [format_vector_definition('b', b.flatten(), C_TYPES[str(kwargs['prec'])])]
    data_str += [format_vector_definition('c', c.flatten(), C_TYPES[str(kwargs['prec'])])]
    data_str += [format_vector_definition('result', result.flatten(), C_TYPES[str(kwargs['prec'])])]
    data_str = '\n\n'.join(data_str)

    return data_str


def main():

    parser = argparse.ArgumentParser(description='Generate data for kernels')
    parser.add_argument(
        "-c", "--cfg",
        type=pathlib.Path,
        required=True,
        help='Select param config file kernel'
    )
    args = parser.parse_args()

    # Load param config file
    with args.cfg.open() as f:
        param = hjson.loads(f.read())

    # Emit header file
    print(emit_header_file(**param))


if __name__ == '__main__':
    main()
