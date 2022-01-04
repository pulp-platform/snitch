#!/usr/bin/env python
import numpy as np
import torch
import torch.nn as nn
import argparse
import pathlib
import hjson

np.random.seed(42)
torch.manual_seed(42)


def array_to_cstr(a):
    out = '{'
    if isinstance(a, np.ndarray):
        a = a.flat
    if isinstance(a, torch.Tensor):
        a = a.numpy().flat
    for el in a:
        out += '{}, '.format(el)
    out = out[:-2] + '}'
    return out


def emit_header_file(layer_type: str, **kwargs):

    file_path = pathlib.Path(__file__).parent / 'data'
    emit_str = ''

    if layer_type == 'Conv2d':
        file = file_path / 'data_conv2d.h'
        emit_str += emit_conv2d_layer(**kwargs)
    elif layer_type == 'GEMM':
        file = file_path / 'data_gemm.h'
        emit_str += emit_GEMM_layer(**kwargs)
    elif layer_type == 'BatchNorm':
        file = file_path / 'data_batchnorm.h'
        emit_str += emit_batchnorm_layer(**kwargs)
    elif layer_type == 'MaxPool':
        file = file_path / 'data_maxpool.h'
        emit_str += emit_maxpool_layer(**kwargs)
    elif layer_type == 'FusedConv':
        file = file_path / 'data_fusedconv.h'
        emit_str += emit_fusedconv(**kwargs)
    with file.open('w') as f:
        f.write(emit_str)


def emit_conv2d_layer(name='conv2d', **kwargs):
    ifmap = kwargs['ifmap']
    ofmap = kwargs['ofmap']
    weights = kwargs['weights']

    n, ih, iw, ci = ifmap.shape
    _, oh, ow, co = ofmap.shape
    _, fh, fw, _ = weights.shape

    layer_str = ''
    layer_str += '#include "layer.h"\n\n'
    layer_str += f'layer {name}_l = {{\n'
    layer_str += f'\t.CO = {co},\n'
    layer_str += f'\t.CI = {ci},\n'
    layer_str += f'\t.IH = {ih},\n'
    layer_str += f'\t.IW = {iw},\n'
    layer_str += f'\t.OH = {oh},\n'
    layer_str += f'\t.OW = {ow},\n'
    layer_str += f'\t.FH = {fh},\n'
    layer_str += f'\t.FW = {fw}\n'
    layer_str += '};\n\n\n'

    layer_str += f'static double {name}_result[{oh}][{ow}][{co}] __attribute__((section(".data")));\n\n'
    layer_str += f'static double {name}_checksum[{oh}][{ow}] = ' + array_to_cstr(torch.sum(ofmap, dim=-1)) + ';\n\n\n'
    layer_str += f'static double {name}_ifmap_dram[{ih}][{iw}][{ci}] = ' + array_to_cstr(ifmap) + ';\n\n\n'
    layer_str += f'static double {name}_weights_dram[{co}][{ci}][{fh}][{fw}] = ' + array_to_cstr(weights) + ';\n\n\n'
    layer_str += f'static double {name}_ofmap_dram[{oh}][{ow}][{co}] = ' + array_to_cstr(ofmap) + ';\n\n\n'

    return layer_str


def emit_linear_layer(input, weights, ofmap):

    layer_str = ''
    return layer_str


def emit_GEMM_layer(name='gemm', **kwargs):
    mat_A = kwargs['A']
    mat_B = kwargs['B']
    mat_C = kwargs['C']
    result = kwargs['result']

    m = kwargs['M']
    n = kwargs['N']
    k = kwargs['K']

    layer_str = ''
    layer_str += '#include "layer.h"\n\n'
    layer_str += f'layer {name}_l = {{\n'
    layer_str += '\t.type = GEMM,\n'
    layer_str += f'\t.M = {m},\n'
    layer_str += f'\t.N = {n},\n'
    layer_str += f'\t.K = {k},\n'
    layer_str += f'\t.TA = {int(kwargs["ta"])},\n'
    layer_str += f'\t.TB = {int(kwargs["tb"])},\n'
    layer_str += f'\t.ALPHA = {kwargs["alpha"]},\n'
    layer_str += f'\t.dtype = FP{kwargs["prec"]}\n'
    layer_str += '};\n\n\n'

    ctypes = {
        '64': 'double',
        '32': 'float',
        '16': '__fp16',
        '8': 'char'
    }

    dtype = ctypes[str(kwargs['prec'])]

    layer_str += f'static {dtype} {name}_A_dram [{m}][{k}] = ' + array_to_cstr(mat_A) + ';\n\n\n'
    layer_str += f'static {dtype} {name}_B_dram [{k}][{n}] = ' + array_to_cstr(mat_B) + ';\n\n\n'
    layer_str += f'static {dtype} {name}_C_dram [{m}][{n}] = ' + array_to_cstr(mat_C) + ';\n\n\n'
    layer_str += f'static {dtype} {name}_result[{m}][{n}] __attribute__((section(".data")));\n\n'
    layer_str += f'static {dtype} {name}_checksum[{m}] = ' + array_to_cstr(torch.sum(result, dim=-1)) + ';\n\n\n'

    return layer_str


def emit_batchnorm_layer(name='batchnorm', **kwargs):

    ifmap = kwargs['ifmap']
    ofmap = kwargs['ofmap']
    beta = kwargs['beta']
    gamma = kwargs['gamma']

    n, ih, iw, ci = ifmap.shape
    _, oh, ow, co = ofmap.shape

    layer_str = ''
    layer_str += '#include "layer.h"\n\n'
    layer_str += f'layer {name}_l = {{\n'
    layer_str += f'\t.CO = {co},\n'
    layer_str += f'\t.CI = {ci},\n'
    layer_str += f'\t.IH = {ih},\n'
    layer_str += f'\t.IW = {iw},\n'
    layer_str += f'\t.OH = {oh},\n'
    layer_str += f'\t.OW = {ow},\n'
    layer_str += '};\n\n\n'

    layer_str += f'static double {name}_result[{oh}][{ow}][{co}] __attribute__((section(".data")));\n\n'
    layer_str += f'static double {name}_checksum[{oh}][{ow}] = ' + array_to_cstr(torch.sum(ofmap, dim=-1)) + ';\n\n\n'
    layer_str += f'static double {name}_ifmap_dram[{ih}][{iw}][{ci}] = ' + array_to_cstr(ifmap) + ';\n\n\n'
    layer_str += f'static double {name}_beta_dram[{ci}] = ' + array_to_cstr(beta) + ';\n\n\n'
    layer_str += f'static double {name}_gamma_dram[{ci}] = ' + array_to_cstr(gamma) + ';\n\n\n'
    layer_str += f'static double {name}_ofmap_dram[{oh}][{ow}][{co}] = ' + array_to_cstr(ofmap) + ';\n\n\n'

    return layer_str


def emit_maxpool_layer(name='maxpool', **kwargs):

    ifmap = kwargs['ifmap']
    ofmap = kwargs['ofmap']
    k = kwargs['kernel_size']

    n, ih, iw, ci = ifmap.shape
    _, oh, ow, co = ofmap.shape

    layer_str = ''
    layer_str += '#include "layer.h"\n\n'
    layer_str += f'layer {name}_l = {{\n'
    layer_str += f'\t.CO = {co},\n'
    layer_str += f'\t.CI = {ci},\n'
    layer_str += f'\t.IH = {ih},\n'
    layer_str += f'\t.IW = {iw},\n'
    layer_str += f'\t.OH = {oh},\n'
    layer_str += f'\t.OW = {ow},\n'
    layer_str += f'\t.FH = {k},\n'
    layer_str += f'\t.FW = {k},\n'
    layer_str += '};\n\n\n'

    layer_str += f'static double {name}_result[{oh}][{ow}][{co}] __attribute__((section(".data")));\n\n'
    layer_str += f'static double {name}_checksum[{oh}][{ow}] = ' + array_to_cstr(torch.sum(ofmap, dim=-1)) + ';\n\n\n'
    layer_str += f'static double {name}_ifmap_dram[{ih}][{iw}][{ci}] = ' + array_to_cstr(ifmap) + ';\n\n\n'
    layer_str += f'static double {name}_ofmap_dram[{oh}][{ow}][{co}] = ' + array_to_cstr(ofmap) + ';\n\n\n'

    return layer_str


def emit_fusedconv(name='fusedconv', **kwargs):

    ifmap = kwargs['ifmap']
    kernel = kwargs['kernel']
    k = kwargs['k']
    l = kwargs['l']
    ofmap = kwargs['ofmap']
    ofmap_before = kwargs['ofmap_before']
    ifmap_padded = kwargs['ifmap_padded']

    padding = kwargs['padding']

    ih, iw, ci = ifmap.shape
    oh, ow, co = ofmap.shape
    _, fh, fw, _ = kernel.shape
    ih_pad, iw_pad, _ = ifmap_padded.shape

    ctypes = {
        '64': 'double',
        '32': 'float',
        '16': '__fp16',
        '8': 'char'
    }

    dtype = ctypes[str(kwargs['prec'])]

    layer_str = '#include <stdint.h>\n\n'
    layer_str += f'uint16_t ch_in = {ci};\n'
    layer_str += f'uint16_t ch_out = {co};\n'
    layer_str += f'uint16_t dim_in_x = {iw};\n'
    layer_str += f'uint16_t dim_in_y = {ih};\n'
    layer_str += f'uint16_t dim_kernel_x = {fw};\n'
    layer_str += f'uint16_t dim_kernel_y = {fh};\n'
    layer_str += f'uint16_t dim_out_x = {ow};\n'
    layer_str += f'uint16_t dim_out_y = {oh};\n'
    layer_str += f'uint16_t padding_y_top = {padding["padding_y_top"]};\n'
    layer_str += f'uint16_t padding_y_bottom = {padding["padding_y_bottom"]};\n'
    layer_str += f'uint16_t padding_x_left = {padding["padding_x_left"]};\n'
    layer_str += f'uint16_t padding_x_right  = {padding["padding_x_right"]};\n'
    layer_str += f'uint16_t stride_x = {kwargs["stride"]["stride_x"]};\n'
    layer_str += f'uint16_t stride_y = {kwargs["stride"]["stride_y"]};\n'
    layer_str += 'int8_t *bias;\n'
    layer_str += 'uint16_t bias_shift;\n'
    layer_str += 'uint16_t out_shift;\n'
    layer_str += 'uint16_t out_mult;\n'
    layer_str += f'{dtype} lambda_dram[{co}] = {array_to_cstr(l)} ;\n'
    layer_str += f'{dtype} k_dram[{co}] = {array_to_cstr(k)};\n'
    layer_str += f'{dtype} *pIm2ColBuffer;\n'
    layer_str += f'int flag_relu = {kwargs["flags"]["flag_relu"]};\n'
    layer_str += f'int flag_batch_norm = {kwargs["flags"]["flag_batch_norm"]};\n'
    layer_str += f'int flag_y_accumulate_start = {kwargs["flags"]["flag_y_accumulate_start"]};\n'
    layer_str += f'int flag_y_accumulate_end = {kwargs["flags"]["flag_y_accumulate_end"]};\n'
    layer_str += 'unsigned int *memory_chan;\n\n'

    layer_str += f'static {dtype} {name}_pInBuffer_dram[{ih_pad}][{iw_pad}][{ci}] = ' + \
        array_to_cstr(ifmap_padded) + ';\n\n'
    layer_str += f'static {dtype} {name}_pWeight_dram[{co}][{fh}][{fw}][{ci}] = {array_to_cstr(kernel)};\n\n'
    layer_str += f'static {dtype} {name}_pOutBuffer_dram[{oh}][{ow}][{co}] = {array_to_cstr(ofmap_before)};\n\n'
    layer_str += f'static {dtype} {name}_pCheckOutBuffer_dram[{oh}][{ow}][{co}] = {array_to_cstr(ofmap)};\n\n'

    return layer_str


def conv2d(ifmap, weights, padding=1, stride=1):
    n, ci, ih, iw = ifmap.shape
    co, _, fh, fw = weights.shape

    conv2d = nn.Conv2d(ci, co, (fh, fw), padding=((fh-1)//2, (fw-1)//2))
    conv2d.weight = nn.Parameter(weights, requires_grad=False)
    conv2d.bias = nn.Parameter(torch.zeros_like(conv2d.bias, dtype=weights.dtype), requires_grad=False)
    ofmap = conv2d(ifmap)

    return ofmap


def max_pooling(ifmap, kernel):
    n, ci, ih, iw = ifmap.shape
    max_pool = nn.MaxPool2d(kernel_size=kernel)
    ofmap = max_pool(ifmap)

    return ofmap


def batchnorm(ifmap):
    n, ci, ih, iw = ifmap.shape
    bn = torch.nn.BatchNorm2d(ci)
    bn.weight.requires_grad = False
    bn.bias.requires_grad = False
    running_mean = torch.randn_like(bn.running_mean, requires_grad=False)
    running_var = torch.rand_like(bn.running_var, requires_grad=False)
    gamma = bn.weight / torch.sqrt(running_var + bn.eps)
    beta = bn.bias - running_mean * bn.weight / torch.sqrt(running_var + bn.eps)
    ofmap = ifmap * gamma.unsqueeze(-1).unsqueeze(-1) + beta.unsqueeze(-1).unsqueeze(-1)

    return ofmap, gamma, beta


def fused_conv(ifmap, weights, k, l, padding, stride, bn, relu):

    ih, iw, ci = ifmap.shape
    co, fh, fw, _ = weights.shape

    ifmap_padded = torch.zeros(ih + padding['padding_y_top'] + padding['padding_y_bottom'], iw +
                               padding['padding_x_left'] + padding['padding_x_right'], ci, requires_grad=False, dtype=ifmap.dtype)
    ifmap_padded[padding['padding_y_top']:ih+padding['padding_y_top'],
                 padding['padding_x_left']:iw+padding['padding_x_left']] = ifmap

    # Don't cover undefined behaviour when there are steps without a complete kernel window
    assert (ifmap_padded.shape[0] - (fh - 1) - 1) % stride['stride_y'] == 0
    assert (ifmap_padded.shape[1] - (fw - 1) - 1) % stride['stride_x'] == 0

    ofmap = torch.zeros((ifmap_padded.shape[0] - (fh - 1) - 1) // stride['stride_y'] + 1,
                        (ifmap_padded.shape[1] - (fw - 1) - 1) // stride['stride_x'] + 1, co)

    print(ifmap.shape, ifmap_padded.shape, ofmap.shape)

    # Conv2d
    for h in range(0, ifmap_padded.shape[0] - (fh - 1), stride['stride_y']):
        for w in range(0, ifmap_padded.shape[1] - (fw - 1), stride['stride_x']):
            for c in range(co):
                ofmap[h//stride['stride_y'], w//stride['stride_x'],
                      c] = torch.dot(ifmap_padded[h:h+fh, w:w+fw].flatten(), weights[c].flatten())

    # BatchNorm
    if bn:
        ofmap = ofmap * k + l

    # ReLU
    if relu:
        ofmap *= (ofmap > 0)

    return ofmap, ifmap_padded


def main():

    parser = argparse.ArgumentParser(description='Generate data for kernels')
    parser.add_argument(
        "-c",
        "--cfg",
        type=pathlib.Path,
        required=True,
        help='Select param config file kernel'
    )

    args = parser.parse_args()

    with args.cfg.open() as f:
        param = hjson.loads(f.read())

    if param['prec'] == 64:
        dtype = torch.float64
    elif param['prec'] == 16:
        dtype = torch.float16
    else:
        dtype = torch.float32

    if param['kernel'] == 'Conv2d':
        ifmap = torch.randn(1, param['channels']['in'],
                            param['input_dim']['height'],
                            param['input_dim']['width'], requires_grad=False, dtype=dtype)
        weights = torch.randn(param['channels']['out'],
                              param['channels']['in'],
                              param['filter']['height'],
                              param['filter']['width'], requires_grad=False, dtype=dtype)

        ofmap = conv2d(ifmap, weights,
                       padding=param['filter']['padding'],
                       stride=param['filter']['stride'])

        # convert from CHW to HWC format
        ifmap = ifmap.permute(0, 2, 3, 1)
        ofmap = ofmap.permute(0, 2, 3, 1)
        weights = weights.permute(0, 2, 3, 1)
        kwargs = {'ifmap': ifmap, 'weights': weights, 'ofmap': ofmap}
        emit_header_file('Conv2d', **kwargs)

    elif param['kernel'] == 'GEMM':
        mat_A = torch.randn(param['M'], param['K'], requires_grad=False, dtype=dtype)
        mat_B = torch.randn(param['K'], param['N'], requires_grad=False, dtype=dtype)
        mat_C = torch.randn(param['M'], param['N'], requires_grad=False, dtype=dtype)

        result = param['alpha'] * mat_C + torch.matmul(mat_A, mat_B)

        if param['transpose_A']:
            mat_A = mat_A.T
        if param['transpose_B']:
            mat_B = mat_B.T

        kwargs = {
            'A': mat_A,
            'B': mat_B,
            'C': mat_C,
            'result': result,
            'M': param['M'],
            'N': param['N'],
            'K': param['K'],
            'ta': param['transpose_A'],
            'tb': param['transpose_B'],
            'alpha': param['alpha'],
            'prec': param['prec']
        }

        emit_header_file('GEMM', **kwargs)

    elif param['kernel'] == 'BatchNorm':
        ifmap = torch.randn(1, param['channels']['in'],
                            param['input_dim']['height'],
                            param['input_dim']['width'], requires_grad=False, dtype=dtype)

        ofmap, gamma, beta = batchnorm(ifmap)

        # convert from CHW to HWC format
        ifmap = ifmap.permute(0, 2, 3, 1)
        ofmap = ofmap.permute(0, 2, 3, 1)

        kwargs = {'ifmap': ifmap, 'beta': beta, 'gamma': gamma, 'ofmap': ofmap}
        emit_header_file('BatchNorm', **kwargs)

    elif param['kernel'] == 'MaxPool':
        ifmap = torch.randn(1, param['channels']['in'],
                            param['input_dim']['height'],
                            param['input_dim']['width'], requires_grad=False, dtype=dtype)

        ofmap = max_pooling(ifmap, param['kernel_size'])

        # convert from CHW to HWC format
        ifmap = ifmap.permute(0, 2, 3, 1)
        ofmap = ofmap.permute(0, 2, 3, 1)

        kwargs = {'ifmap': ifmap, 'ofmap': ofmap, 'kernel_size': param['kernel_size']}
        emit_header_file('MaxPool', **kwargs)

    elif param['kernel'] == 'FusedConv':
        ifmap = torch.randn(param['dim_in_y'], param['dim_in_x'], param['ch_in'], requires_grad=False, dtype=dtype)
        kernel = torch.randn(param['ch_out'], param['dim_kernel_y'], param['dim_kernel_x'],
                             param['ch_in'], requires_grad=False, dtype=dtype)
        k = torch.randn(param['ch_out'], requires_grad=False)
        l = torch.randn(param['ch_out'], requires_grad=False)

        ofmap, ifmap_padded = fused_conv(ifmap, kernel, k, l, param['padding'], param['stride'], param['flags']['flag_batch_norm'], param['flags']['flag_relu'])
        ofmap_before = torch.randn_like(ofmap, requires_grad=False)
        if not param['flags']['flag_y_accumulate_start']:
            ofmap += ofmap_before

        kwargs = {
            'ifmap': ifmap,
            'ifmap_padded': ifmap_padded,
            'ofmap': ofmap,
            'ofmap_before': ofmap_before,
            'kernel': kernel,
            'k': k,
            'l': l,
            'padding': param['padding'],
            'stride': param['stride'],
            'prec': param['prec'],
            'flags': param['flags']
        }
        emit_header_file('FusedConv', **kwargs)

    else:
        print("No valid kernel selected")


if __name__ == '__main__':
    main()
