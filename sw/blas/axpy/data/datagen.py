#!/usr/bin/env python3
# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Author: Luca Colagrande <colluca@iis.ee.ethz.ch>

import sys
import argparse
import numpy as np

MIN = -1000
MAX = +1000


def format_vector_definition(id, vector):
    s = f'double {id}[{len(vector)}] = ' + '{\n'
    for el in vector:
        s += f'\t{el},\n'
    s += '};'
    return s


def format_vector_declaration(id, vector):
    s = f'double {id}[{len(vector)}];'
    return s


def format_scalar_definition(id, scalar, typ):
    s = f'{typ} {id} = {scalar};'
    return s


def main():
    # Argument parsing
    parser = argparse.ArgumentParser()
    parser.add_argument(
        'length',
        type=int,
        help='Vector length')
    args = parser.parse_args()
    length = args.length

    # Randomly generate inputs
    a = np.random.uniform(MIN, MAX, 1)
    x = np.random.uniform(MIN, MAX, length)
    y = np.random.uniform(MIN, MAX, length)
    z = np.zeros(length)

    # Format header file
    l_str = format_scalar_definition('l', length, 'uint32_t')
    a_str = format_scalar_definition('a', a[0], 'double')
    x_str = format_vector_definition('x', x)
    y_str = format_vector_definition('y', y)
    z_str = format_vector_declaration('z', z)
    f_str = '\n\n'.join([l_str, a_str, x_str, y_str, z_str])
    f_str += '\n'

    # Write to stdout
    print(f_str)


if __name__ == '__main__':
    sys.exit(main())
