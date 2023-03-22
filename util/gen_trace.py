#!/usr/bin/env python3
# Copyright 2020 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
# This script takes a trace generated for a Snitch hart and transforms the
# additional decode stage info into meaningful annotation. It also counts
# and computes various performance metrics up to each mcycle CSR read.

# Author: Paul Scheffler <paulsc@iis.ee.ethz.ch>

# TODO: OPER_TYPES and FPU_OPER_TYPES could break: optimization might alter enum mapping
# TODO: We annotate all FP16 LSU values as IEEE, not FP16ALT... can we do better?

import sys
import re
import math
import argparse
import json
from ctypes import c_int32, c_uint32
from collections import deque, defaultdict

EXTRA_WB_WARN = 'WARNING: {} transactions still in flight for {}.'

GENERAL_WARN = """WARNING: Inconsistent final state; performance metrics
may be inaccurate. Is this trace complete?\n"""

TRACE_IN_REGEX = r'(\d+)\s+(\d+)\s+(\d+)\s+(0x[0-9A-Fa-fz]+)\s+([^#;]*)(\s*#;\s*(.*))?'

TRACE_OUT_FMT = '{:>8} {:>8} {:>8} {:>10} {:<30}'

# -------------------- Tracer configuration  --------------------

# Below this absolute value: use signed int representation. Above: unsigned 32-bit hex
MAX_SIGNED_INT_LIT = 0xFFFF

# Performance keys which only serve to compute other metrics: omit on printing
PERF_EVAL_KEYS_OMIT = ('start', 'end', 'end_fpss', 'snitch_issues',
                       'snitch_load_latency', 'snitch_fseq_offloads',
                       'fseq_issues', 'fpss_issues', 'fpss_fpu_issues',
                       'fpss_load_latency', 'fpss_fpu_latency')

# -------------------- Architectural constants and enums  --------------------

REG_ABI_NAMES_I = ('zero', 'ra', 'sp', 'gp', 'tp', 't0', 't1', 't2', 's0',
                   's1', *('a{}'.format(i) for i in range(8)),
                   *('s{}'.format(i)
                     for i in range(2, 12)), *('t{}'.format(i)
                                               for i in range(3, 7)))

REG_ABI_NAMES_F = (*('ft{}'.format(i) for i in range(0, 8)), 'fs0', 'fs1',
                   'fa0', 'fa1', *('fa{}'.format(i) for i in range(2, 8)),
                   *('fs{}'.format(i)
                     for i in range(2, 12)), *('ft{}'.format(i)
                                               for i in range(8, 12)))

TRACE_SRCES = {'snitch': 0, 'fpu': 1, 'sequencer': 2}

LS_SIZES = ('Byte', 'Half', 'Word', 'Doub')

OPER_TYPES = {'gpr': 1, 'csr': 8}

FPU_OPER_TYPES = ('NONE', 'acc', 'rs1', 'rs2', 'rs3', 'rs1', 'rd')

FLOAT_FMTS = ((8, 23), (11, 52), (5, 10), (5, 2), (8, 7))

LS_TO_FLOAT = (3, 2, 0, 1)

CSR_NAMES = {
    0xc00: 'cycle',
    0xc01: 'time',
    0xc02: 'instret',
    0xc03: 'hpmcounter3',
    0xc04: 'hpmcounter4',
    0xc05: 'hpmcounter5',
    0xc06: 'hpmcounter6',
    0xc07: 'hpmcounter7',
    0xc08: 'hpmcounter8',
    0xc09: 'hpmcounter9',
    0xc0a: 'hpmcounter10',
    0xc0b: 'hpmcounter11',
    0xc0c: 'hpmcounter12',
    0xc0d: 'hpmcounter13',
    0xc0e: 'hpmcounter14',
    0xc0f: 'hpmcounter15',
    0xc10: 'hpmcounter16',
    0xc11: 'hpmcounter17',
    0xc12: 'hpmcounter18',
    0xc13: 'hpmcounter19',
    0xc14: 'hpmcounter20',
    0xc15: 'hpmcounter21',
    0xc16: 'hpmcounter22',
    0xc17: 'hpmcounter23',
    0xc18: 'hpmcounter24',
    0xc19: 'hpmcounter25',
    0xc1a: 'hpmcounter26',
    0xc1b: 'hpmcounter27',
    0xc1c: 'hpmcounter28',
    0xc1d: 'hpmcounter29',
    0xc1e: 'hpmcounter30',
    0xc1f: 'hpmcounter31',
    0x100: 'sstatus',
    0x104: 'sie',
    0x105: 'stvec',
    0x106: 'scounteren',
    0x140: 'sscratch',
    0x141: 'sepc',
    0x142: 'scause',
    0x143: 'stval',
    0x144: 'sip',
    0x180: 'satp',
    0x200: 'bsstatus',
    0x204: 'bsie',
    0x205: 'bstvec',
    0x240: 'bsscratch',
    0x241: 'bsepc',
    0x242: 'bscause',
    0x243: 'bstval',
    0x244: 'bsip',
    0x280: 'bsatp',
    0xa00: 'hstatus',
    0xa02: 'hedeleg',
    0xa03: 'hideleg',
    0xa80: 'hgatp',
    0x7: 'utvt',
    0x45: 'unxti',
    0x46: 'uintstatus',
    0x48: 'uscratchcsw',
    0x49: 'uscratchcswl',
    0x107: 'stvt',
    0x145: 'snxti',
    0x146: 'sintstatus',
    0x148: 'sscratchcsw',
    0x149: 'sscratchcswl',
    0x307: 'mtvt',
    0x345: 'mnxti',
    0x346: 'mintstatus',
    0x348: 'mscratchcsw',
    0x349: 'mscratchcswl',
    0x300: 'mstatus',
    0x301: 'misa',
    0x302: 'medeleg',
    0x303: 'mideleg',
    0x304: 'mie',
    0x305: 'mtvec',
    0x306: 'mcounteren',
    0x340: 'mscratch',
    0x341: 'mepc',
    0x342: 'mcause',
    0x343: 'mtval',
    0x344: 'mip',
    0x3a0: 'pmpcfg0',
    0x3a1: 'pmpcfg1',
    0x3a2: 'pmpcfg2',
    0x3a3: 'pmpcfg3',
    0x3b0: 'pmpaddr0',
    0x3b1: 'pmpaddr1',
    0x3b2: 'pmpaddr2',
    0x3b3: 'pmpaddr3',
    0x3b4: 'pmpaddr4',
    0x3b5: 'pmpaddr5',
    0x3b6: 'pmpaddr6',
    0x3b7: 'pmpaddr7',
    0x3b8: 'pmpaddr8',
    0x3b9: 'pmpaddr9',
    0x3ba: 'pmpaddr10',
    0x3bb: 'pmpaddr11',
    0x3bc: 'pmpaddr12',
    0x3bd: 'pmpaddr13',
    0x3be: 'pmpaddr14',
    0x3bf: 'pmpaddr15',
    0x7a0: 'tselect',
    0x7a1: 'tdata1',
    0x7a2: 'tdata2',
    0x7a3: 'tdata3',
    0x7b0: 'dcsr',
    0x7b1: 'dpc',
    0x7b2: 'dscratch',
    0xb00: 'mcycle',
    0xb02: 'minstret',
    0xb03: 'mhpmcounter3',
    0xb04: 'mhpmcounter4',
    0xb05: 'mhpmcounter5',
    0xb06: 'mhpmcounter6',
    0xb07: 'mhpmcounter7',
    0xb08: 'mhpmcounter8',
    0xb09: 'mhpmcounter9',
    0xb0a: 'mhpmcounter10',
    0xb0b: 'mhpmcounter11',
    0xb0c: 'mhpmcounter12',
    0xb0d: 'mhpmcounter13',
    0xb0e: 'mhpmcounter14',
    0xb0f: 'mhpmcounter15',
    0xb10: 'mhpmcounter16',
    0xb11: 'mhpmcounter17',
    0xb12: 'mhpmcounter18',
    0xb13: 'mhpmcounter19',
    0xb14: 'mhpmcounter20',
    0xb15: 'mhpmcounter21',
    0xb16: 'mhpmcounter22',
    0xb17: 'mhpmcounter23',
    0xb18: 'mhpmcounter24',
    0xb19: 'mhpmcounter25',
    0xb1a: 'mhpmcounter26',
    0xb1b: 'mhpmcounter27',
    0xb1c: 'mhpmcounter28',
    0xb1d: 'mhpmcounter29',
    0xb1e: 'mhpmcounter30',
    0xb1f: 'mhpmcounter31',
    0x323: 'mhpmevent3',
    0x324: 'mhpmevent4',
    0x325: 'mhpmevent5',
    0x326: 'mhpmevent6',
    0x327: 'mhpmevent7',
    0x328: 'mhpmevent8',
    0x329: 'mhpmevent9',
    0x32a: 'mhpmevent10',
    0x32b: 'mhpmevent11',
    0x32c: 'mhpmevent12',
    0x32d: 'mhpmevent13',
    0x32e: 'mhpmevent14',
    0x32f: 'mhpmevent15',
    0x330: 'mhpmevent16',
    0x331: 'mhpmevent17',
    0x332: 'mhpmevent18',
    0x333: 'mhpmevent19',
    0x334: 'mhpmevent20',
    0x335: 'mhpmevent21',
    0x336: 'mhpmevent22',
    0x337: 'mhpmevent23',
    0x338: 'mhpmevent24',
    0x339: 'mhpmevent25',
    0x33a: 'mhpmevent26',
    0x33b: 'mhpmevent27',
    0x33c: 'mhpmevent28',
    0x33d: 'mhpmevent29',
    0x33e: 'mhpmevent30',
    0x33f: 'mhpmevent31',
    0xf11: 'mvendorid',
    0xf12: 'marchid',
    0xf13: 'mimpid',
    0xf14: 'mhartid',
    0xc80: 'cycleh',
    0xc81: 'timeh',
    0xc82: 'instreth',
    0xc83: 'hpmcounter3h',
    0xc84: 'hpmcounter4h',
    0xc85: 'hpmcounter5h',
    0xc86: 'hpmcounter6h',
    0xc87: 'hpmcounter7h',
    0xc88: 'hpmcounter8h',
    0xc89: 'hpmcounter9h',
    0xc8a: 'hpmcounter10h',
    0xc8b: 'hpmcounter11h',
    0xc8c: 'hpmcounter12h',
    0xc8d: 'hpmcounter13h',
    0xc8e: 'hpmcounter14h',
    0xc8f: 'hpmcounter15h',
    0xc90: 'hpmcounter16h',
    0xc91: 'hpmcounter17h',
    0xc92: 'hpmcounter18h',
    0xc93: 'hpmcounter19h',
    0xc94: 'hpmcounter20h',
    0xc95: 'hpmcounter21h',
    0xc96: 'hpmcounter22h',
    0xc97: 'hpmcounter23h',
    0xc98: 'hpmcounter24h',
    0xc99: 'hpmcounter25h',
    0xc9a: 'hpmcounter26h',
    0xc9b: 'hpmcounter27h',
    0xc9c: 'hpmcounter28h',
    0xc9d: 'hpmcounter29h',
    0xc9e: 'hpmcounter30h',
    0xc9f: 'hpmcounter31h',
    0xb80: 'mcycleh',
    0xb82: 'minstreth',
    0xb83: 'mhpmcounter3h',
    0xb84: 'mhpmcounter4h',
    0xb85: 'mhpmcounter5h',
    0xb86: 'mhpmcounter6h',
    0xb87: 'mhpmcounter7h',
    0xb88: 'mhpmcounter8h',
    0xb89: 'mhpmcounter9h',
    0xb8a: 'mhpmcounter10h',
    0xb8b: 'mhpmcounter11h',
    0xb8c: 'mhpmcounter12h',
    0xb8d: 'mhpmcounter13h',
    0xb8e: 'mhpmcounter14h',
    0xb8f: 'mhpmcounter15h',
    0xb90: 'mhpmcounter16h',
    0xb91: 'mhpmcounter17h',
    0xb92: 'mhpmcounter18h',
    0xb93: 'mhpmcounter19h',
    0xb94: 'mhpmcounter20h',
    0xb95: 'mhpmcounter21h',
    0xb96: 'mhpmcounter22h',
    0xb97: 'mhpmcounter23h',
    0xb98: 'mhpmcounter24h',
    0xb99: 'mhpmcounter25h',
    0xb9a: 'mhpmcounter26h',
    0xb9b: 'mhpmcounter27h',
    0xb9c: 'mhpmcounter28h',
    0xb9d: 'mhpmcounter29h',
    0xb9e: 'mhpmcounter30h',
    0xb9f: 'mhpmcounter31h'
}

PRIV_LVL = {'3': 'M', '1': 'S', '0': 'U'}

# -------------------- FPU helpers  --------------------


def flt_oper(extras: dict, port: int) -> (str, str):
    op_sel = extras['op_sel_{}'.format(port)]
    oper_type = FPU_OPER_TYPES[op_sel]
    if oper_type == 'acc':
        return 'ac{}'.format(port + 1), int_lit(
            extras['acc_qdata_{}'.format(port)], extras['int_fmt'])
    elif oper_type == 'NONE':
        return oper_type, None
    else:
        fmt = LS_TO_FLOAT[
            extras['ls_size']] if extras['is_store'] else extras['src_fmt']
        return REG_ABI_NAMES_F[extras[oper_type]], flt_lit(
            extras['op_{}'.format(port)], fmt)


def flt_decode(val: int, fmt: int) -> float:
    # get format and bit vector
    w_exp, w_mnt = FLOAT_FMTS[fmt]
    width = 1 + w_exp + w_mnt
    bitstr = '{:064b}'.format(val)[-width:]
    # print(bitstr)
    # Read bit vector slices
    sgn = -1.0 if bitstr[0] == '1' else 1.0
    mnt = int(bitstr[w_exp + 1:], 2)
    exp_unb = int(bitstr[1:w_exp + 1], 2)
    # derive base and exponent
    bse = int('1' + bitstr[w_exp + 1:], 2) / (2**w_mnt)
    exp_bias = -(2**(w_exp - 1) - 1)
    exp = exp_unb + exp_bias
    # case analysis
    if exp_unb == 2**w_exp - 1:
        return sgn * float('inf' if mnt == 0 else 'nan')
    elif exp_unb == 0 and mnt == 0:
        return sgn * 0.0
    elif exp_unb == 0:
        return float(sgn * mnt / (2**w_mnt) * (2**(exp_bias + 1)))
    else:
        return float(sgn * bse * (2**exp))


def flt_fmt(flt: float, width: int = 7) -> str:
    # If default literal shorter: use it
    default_str = str(flt)
    if len(default_str) - 1 <= width:
        return default_str
    # Else: fix significant digits, using exponential if needed
    exp, _ = math.frexp(flt)
    fmt = '{:1.' + str(width - 3) + 'e}'
    if not math.isnan(exp) and -1 < exp <= width:
        exp = int(exp)
        fmt = '{:' + str(exp) + '.' + str(width - exp) + 'f}'
    return fmt.format(flt)


# -------------------- Literal formatting  --------------------


def int_lit(num: int, size: int = 2, force_hex: bool = False) -> str:
    width = (8 * int(2**size))
    size_mask = (0x1 << width) - 1
    num = num & size_mask  # num is unsigned
    num_signed = c_int32(c_uint32(num).value).value
    if force_hex or abs(num_signed) > MAX_SIGNED_INT_LIT:
        return '0x{0:0{1}x}'.format(num, width // 4)
    else:
        return str(num_signed)


def flt_lit(num: int, fmt: int, width: int = 7) -> str:
    return flt_fmt(flt_decode(num, fmt), width)


# -------------------- FPU Sequencer --------------------


def dasm_seq(extras: dict, ) -> str:
    return '{:<8}'.format('frep') + ', '.join(
        [str(extras['max_rpt'] +
             1), str(extras['max_inst'] + 1)] +
        ([bin(extras['stg_mask']
              ), str(extras['stg_max'] + 1)] if extras['stg_mask'] else []))


def emul_seq(fseq_info: dict,
             permissive: bool = False) -> (str, int, str, tuple):
    fseq_annot = None
    # We are only called on FPSS issues, not on FSEQ issues -> we must consume FReps in same call
    cfg = fseq_info['curr_cfg']
    if cfg is None:
        is_frep = fseq_info['fpss_pcs'][-1][2] if len(
            fseq_info['fpss_pcs']) else False
        # Is an FRep incoming?
        if is_frep:
            fseq_info['fpss_pcs'].pop()
            cfg = fseq_info['cfg_buf'].pop()
            cfg['inst_iter'] = 0
            cfg['fpss_buf'] = deque()
            cfg['outer_buf'] = deque()
            fseq_info['curr_cfg'] = cfg
    # Are we working on an FRep ...
    if cfg is not None:
        # If we are still filling our loop buffer: add to it and replicate
        if cfg['inst_iter'] <= cfg['max_inst']:
            pc_str, curr_sec, is_frep = fseq_info['fpss_pcs'].pop()
            if is_frep:
                msg_type = 'WARNING' if permissive else 'FATAL'
                sys.stderr.write(
                    '{}: FRep at {} contains another nested FRep'.format(
                        msg_type, cfg['fseq_pc']))
                if not permissive:
                    sys.exit(1)
            # Outer loops: first consume loop body, then replicate buffer
            if cfg['is_outer']:
                buf_entry = (pc_str, curr_sec, (0, cfg['inst_iter']))
                cfg['fpss_buf'].appendleft(buf_entry)
                cfg['outer_buf'].appendleft(buf_entry)
                # Once all loop instructions received: replicate buffer in outer-loop order
                if cfg['inst_iter'] == cfg['max_inst']:
                    for curr_rep in range(1, cfg['max_rpt'] + 1):
                        ob_rev = reversed(cfg['outer_buf'])
                        for inst_idx, inst in enumerate(ob_rev):
                            pc_str, curr_sec, _ = inst
                            fseq_annot = (curr_rep, inst_idx)
                            cfg['fpss_buf'].appendleft(
                                (pc_str, curr_sec, fseq_annot))
            # Inner loops: replicate instructions during loop body consumption
            else:
                for curr_rep in range(0, cfg['max_rpt'] + 1):
                    fseq_annot = (curr_rep, cfg['inst_iter'])
                    cfg['fpss_buf'].appendleft((pc_str, curr_sec, fseq_annot))
            # Iterate loop body instruction consumed
            cfg['inst_iter'] += 1
        # Pull our instruction from the loop buffer
        pc_str, curr_sec, fseq_annot = cfg['fpss_buf'].pop()
        # If we reached last iteration: terminate this FRep
        if fseq_annot[0] == cfg['max_rpt'] and fseq_annot[1] == cfg['max_inst']:
            fseq_info['curr_cfg'] = None
    # ... or is this a regular pass-through?
    else:
        pc_str, curr_sec, _ = fseq_info['fpss_pcs'].pop()
    fseq_pc_str = None if cfg is None else cfg['fseq_pc']
    return pc_str, curr_sec, fseq_pc_str, fseq_annot


# -------------------- Annotation --------------------


def read_annotations(dict_str: str) -> dict:
    # return literal_eval(dict_str) 	# Could be used, but slow due to universality: needs compiler
    return {
        key: int(val, 16)
        for key, val in re.findall(r"'([^']+)'\s*:\s*([^\s,]+)", dict_str)
    }


def annotate_snitch(extras: dict,
                    sim_time: int,
                    cycle: int,
                    pc: int,
                    gpr_wb_info: dict,
                    perf_metrics: list,
                    annot_fseq_offl: bool = False,
                    force_hex_addr: bool = True,
                    permissive: bool = False) -> str:
    # Compound annotations in datapath order
    ret = []
    # If Sequencer offload: annotate if desired
    if annot_fseq_offl and extras['fpu_offload']:
        target_name = 'FSEQ' if extras['is_seq_insn'] else 'FPSS'
        ret.append('{} <~~ 0x{:08x}'.format(target_name, pc))
    # If exception, annotate
    if not (extras['stall']) and extras['exception']:
        ret.append('exception')
    # Regular linear datapath operation
    if not (extras['stall'] or extras['fpu_offload']):
        # Operand registers
        if extras['opa_select'] == OPER_TYPES['gpr'] and extras['rs1'] != 0:
            ret.append('{:<3} = {}'.format(REG_ABI_NAMES_I[extras['rs1']],
                                           int_lit(extras['opa'])))
        if extras['opb_select'] == OPER_TYPES['gpr'] and extras['rs2'] != 0:
            ret.append('{:<3} = {}'.format(REG_ABI_NAMES_I[extras['rs2']],
                                           int_lit(extras['opb'])))
        # CSR (always operand b)
        if extras['opb_select'] == OPER_TYPES['csr']:
            csr_addr = extras['csr_addr']
            csr_name = CSR_NAMES[
                csr_addr] if csr_addr in CSR_NAMES else 'csr@{:x}'.format(
                    csr_addr)
            cycles_past = extras['opb']
            if csr_name == 'mcycle':
                perf_metrics[-1]['tend'] = sim_time / 1000
                perf_metrics[-1]['end'] = cycles_past
                perf_metrics.append(defaultdict(int))
                perf_metrics[-1]['tstart'] = sim_time / 1000
                perf_metrics[-1]['start'] = cycles_past + 2
            ret.append('{} = {}'.format(csr_name, int_lit(cycles_past)))
        # Load / Store
        if extras['is_load']:
            perf_metrics[-1]['snitch_loads'] += 1
            gpr_wb_info[extras['rd']].appendleft(cycle)
            ret.append('{:<3} <~~ {}[{}]'.format(
                REG_ABI_NAMES_I[extras['rd']], LS_SIZES[extras['ls_size']],
                int_lit(extras['alu_result'], force_hex=force_hex_addr)))
        elif extras['is_store']:
            perf_metrics[-1]['snitch_stores'] += 1
            ret.append('{} ~~> {}[{}]'.format(
                int_lit(extras['gpr_rdata_1']), LS_SIZES[extras['ls_size']],
                int_lit(extras['alu_result'], force_hex=force_hex_addr)))
        # Branches: all reg-reg ops
        elif extras['is_branch']:
            ret.append(
                '{}taken'.format('' if extras['alu_result'] else 'not '))
        # Datapath (ALU / Jump Target / Bypass) register writeback
        if extras['write_rd'] and extras['rd'] != 0:
            ret.append('(wrb) {:<3} <-- {}'.format(
                REG_ABI_NAMES_I[extras['rd']], int_lit(extras['writeback'])))
    # Retired loads and accelerator (includes FPU) data: can come back on stall and during other ops
    if extras['retire_load'] and extras['lsu_rd'] != 0:
        try:
            start_time = gpr_wb_info[extras['lsu_rd']].pop()
            perf_metrics[-1]['snitch_load_latency'] += cycle - start_time
        except IndexError:
            msg_type = 'WARNING' if permissive else 'FATAL'
            sys.stderr.write(
                '{}: In cycle {}, LSU attempts writeback to {}, but none in flight.\n'
                .format(msg_type, cycle, REG_ABI_NAMES_F[extras['fpr_waddr']]))
            if not permissive:
                sys.exit(1)
        ret.append('(lsu) {:<3} <-- {}'.format(
            REG_ABI_NAMES_I[extras['lsu_rd']],
            int_lit(extras['ld_result_32'])))
    if extras['retire_acc'] and extras['acc_pid'] != 0:
        ret.append('(acc) {:<3} <-- {}'.format(
            REG_ABI_NAMES_I[extras['acc_pid']],
            int_lit(extras['acc_pdata_32'])))
    # Any kind of PC change: Branch, Jump, etc.
    if not extras['stall'] and extras['pc_d'] != pc + 4:
        ret.append('goto {}'.format(int_lit(extras['pc_d'])))
    # Return comma-delimited list
    return ', '.join(ret)


def annotate_fpu(
        extras: dict,
        cycle: int,
        fpr_wb_info: dict,
        perf_metrics: list,
        # Everything FPU does may have been issued in a previous section
        curr_sec: int = -1,
        force_hex_addr: bool = True,
        permissive: bool = False) -> str:
    ret = []
    # On issuing of instruction
    if extras['acc_q_hs']:
        # If computation initiated: remember FPU destination format
        if extras['use_fpu'] and not extras['fpu_in_acc']:
            fpr_wb_info[extras['fpu_in_rd']].appendleft(
                (extras['dst_fmt'], cycle))
        # Operands: omit on store
        if not extras['is_store']:
            for i_op in range(3):
                oper_name, val = flt_oper(extras, i_op)
                if oper_name != 'NONE':
                    ret.append('{:<4} = {}'.format(oper_name, val))
        # Load / Store requests
        if extras['lsu_q_hs']:
            s = extras['ls_size']
            if extras['is_load']:
                perf_metrics[curr_sec]['fpss_loads'] += 1
                # Load initiated: remember LSU destination format
                fpr_wb_info[extras['rd']].appendleft((LS_TO_FLOAT[s], cycle))
                ret.append('{:<4} <~~ {}[{}]'.format(
                    REG_ABI_NAMES_F[extras['rd']], LS_SIZES[s],
                    int_lit(extras['lsu_qaddr'], force_hex=force_hex_addr)))
            if extras['is_store']:
                perf_metrics[curr_sec]['fpss_stores'] += 1
                _, val = flt_oper(extras, 1)
                ret.append('{} ~~> {}[{}]'.format(
                    val, LS_SIZES[s],
                    int_lit(extras['lsu_qaddr'], force_hex=force_hex_addr)))
    # On FLOP completion
    if extras['fpu_out_hs']:
        perf_metrics[-1]['fpss_fpu_issues'] += 1
    # Register writeback
    if extras['fpr_we']:
        writer = 'acc' if extras['acc_q_hs'] and extras['acc_wb_ready'] else (
            'fpu'
            if extras['fpu_out_hs'] and not extras['fpu_out_acc'] else 'lsu')
        fmt = 0  # accelerator bus format is 0 for regular float32
        if writer == 'fpu' or writer == 'lsu':
            try:
                fmt, start_time = fpr_wb_info[extras['fpr_waddr']].pop()
                if writer == 'lsu':
                    perf_metrics[curr_sec][
                        'fpss_load_latency'] += cycle - start_time
                else:
                    perf_metrics[curr_sec][
                        'fpss_fpu_latency'] += cycle - start_time
            except IndexError:
                msg_type = 'WARNING' if permissive else 'FATAL'
                sys.stderr.write(
                    '{}: In cycle {}, {} attempts writeback to {}, but none in flight.\n'
                    .format(msg_type, cycle, writer.upper(),
                            REG_ABI_NAMES_F[extras['fpr_waddr']]))
                if not permissive:
                    sys.exit(1)
        ret.append('(f:{}) {:<4} <-- {}'.format(
            writer, REG_ABI_NAMES_F[extras['fpr_waddr']],
            flt_lit(extras['fpr_wdata'], fmt)))
    return ', '.join(ret)


# noinspection PyTypeChecker
def annotate_insn(
    line: str,
    gpr_wb_info:
    dict,  # One deque (FIFO) per GPR storing start cycles for each GPR WB
    fpr_wb_info:
    dict,  # One deque (FIFO) per FPR storing start cycles and formats for each FPR WB
    fseq_info:
    dict,  # Info on the sequencer to properly map tunneled instruction PCs
    perf_metrics: list,  # A list performance metric dicts
    dupl_time_info:
    bool = True,  # Show sim time and cycle again if same as previous line?
    last_time_info:
    tuple = None,  # Previous timestamp (keeps this method stateless)
    annot_fseq_offl:
    bool = False,  # Annotate whenever core offloads to CPU on own line
    force_hex_addr: bool = True,
    permissive: bool = True
) -> (str, tuple, bool
      ):  # Return time info, whether trace line contains no info, and fseq_len
    match = re.search(TRACE_IN_REGEX, line.strip('\n'))
    if match is None:
        raise ValueError('Not a valid trace line:\n{}'.format(line))
    time_str, cycle_str, priv_lvl, pc_str, insn, _, extras_str = match.groups()
    time_info = (int(time_str), int(cycle_str))
    show_time_info = (dupl_time_info or time_info != last_time_info)
    time_info_strs = tuple(
        (str(elem) if show_time_info else '') for elem in time_info)
    # Annotated trace
    if extras_str:
        extras = read_annotations(extras_str)
        # Annotate snitch
        if extras['source'] == TRACE_SRCES['snitch']:
            annot = annotate_snitch(extras, time_info[0], time_info[1],
                                    int(pc_str, 16), gpr_wb_info, perf_metrics,
                                    annot_fseq_offl, force_hex_addr, permissive)
            if extras['fpu_offload']:
                perf_metrics[-1]['snitch_fseq_offloads'] += 1
                fseq_info['fpss_pcs'].appendleft(
                    (pc_str, len(perf_metrics) - 1, extras['is_seq_insn']))
                if extras['is_seq_insn']:
                    fseq_info['fseq_pcs'].appendleft(pc_str)
            if extras['stall'] or extras['fpu_offload']:
                insn, pc_str = ('', '')
            else:
                perf_metrics[-1]['snitch_issues'] += 1
        # Annotate sequencer
        elif extras['source'] == TRACE_SRCES['sequencer']:
            if extras['cbuf_push']:
                fseq_info['cfg_buf'].appendleft(extras)
                frep_pc_str = fseq_info['fseq_pcs'].pop()
                insn, pc_str = (dasm_seq(extras), frep_pc_str)
                extras['fseq_pc'] = frep_pc_str
                annot = ', '.join([
                    'outer' if extras['is_outer'] else 'inner',
                    '{} issues'.format(
                        (extras['max_inst'] + 1) * (extras['max_rpt'] + 1))
                ])
            else:
                insn, pc_str, annot = ('', '', '')
        # Annotate FPSS
        elif extras['source'] == TRACE_SRCES['fpu']:
            annot_list = []
            if not extras['acc_q_hs']:
                insn, pc_str = ('', '')
            else:
                pc_str, curr_sec, fseq_pc_str, fseq_annot = emul_seq(
                    fseq_info, permissive)
                fseq_info['curr_sec'] = curr_sec
                perf_metrics[curr_sec]['end_fpss'] = time_info[
                    1]  # Record cycle in case this was last insn in section
                perf_metrics[curr_sec]['fpss_issues'] += 1
                if fseq_annot is not None:
                    annot_list.append('[{} {}:{}]'.format(
                        fseq_pc_str[-4:], *fseq_annot))
            annot_list.append(
                annotate_fpu(extras, time_info[1], fpr_wb_info, perf_metrics,
                             fseq_info['curr_sec'], force_hex_addr,
                             permissive))
            annot = ', '.join(annot_list)
        else:
            raise ValueError('Unknown trace source: {}'.format(
                extras['source']))
        empty = not (
            insn or annot
        )  # omit empty trace lines (due to double stalls, performance measures)
        if empty:
            # Reset time info if empty: last line on record is previous one!
            time_info = last_time_info
        return (TRACE_OUT_FMT + ' #; {}').format(*time_info_strs,
                                                 PRIV_LVL[priv_lvl], pc_str,
                                                 insn, annot), time_info, empty
    # Vanilla trace
    else:
        return TRACE_OUT_FMT.format(*time_info_strs, PRIV_LVL[priv_lvl],
                                    pc_str, insn), time_info, False


# -------------------- Performance metrics --------------------


def safe_div(dividend, divisor, zero_div=0):
    return dividend / divisor if divisor else zero_div


def eval_perf_metrics(perf_metrics: list):
    for seg in perf_metrics:
        fpss_latency = max(seg['end_fpss'] - seg['end'], 0)
        end = seg[
            'end'] + fpss_latency  # This can be argued over, but it's the most conservatice choice
        cycles = end - seg['start'] + 1
        fpss_fpu_rel_issues = safe_div(seg['fpss_fpu_issues'],
                                       seg['fpss_issues'])
        seg.update({
            # Snitch
            'snitch_avg_load_latency':
            safe_div(seg['snitch_load_latency'], seg['snitch_loads']),
            'snitch_occupancy':
            safe_div(seg['snitch_issues'], cycles),
            'snitch_fseq_rel_offloads':
            safe_div(seg['snitch_fseq_offloads'],
                     seg['snitch_issues'] + seg['snitch_fseq_offloads']),
            # FSeq
            'fseq_yield':
            safe_div(seg['fpss_issues'], seg['snitch_fseq_offloads']),
            'fseq_fpu_yield':
            safe_div(
                safe_div(seg['fpss_fpu_issues'], seg['snitch_fseq_offloads']),
                fpss_fpu_rel_issues),
            # FPSS
            'fpss_section_latency':
            fpss_latency,
            'fpss_avg_fpu_latency':
            safe_div(seg['fpss_fpu_latency'], seg['fpss_fpu_issues']),
            'fpss_avg_load_latency':
            safe_div(seg['fpss_load_latency'], seg['fpss_loads']),
            'fpss_occupancy':
            safe_div(seg['fpss_issues'], cycles),
            'fpss_fpu_occupancy':
            safe_div(seg['fpss_fpu_issues'], cycles),
            'fpss_fpu_rel_occupancy':
            fpss_fpu_rel_issues
        })
        seg['cycles'] = cycles
        seg['total_ipc'] = seg['fpss_occupancy'] + seg['snitch_occupancy']


def fmt_perf_metrics(perf_metrics: list, idx: int, omit_keys: bool = True):
    ret = [
        'Performance metrics for section {} @ ({}, {}):'.format(
            idx, perf_metrics[idx]['start'], perf_metrics[idx]['end'])
    ]
    for key, val in perf_metrics[idx].items():
        if omit_keys and key in PERF_EVAL_KEYS_OMIT:
            continue
        if val is None:
            val_str = str(None)
        elif isinstance(val, float):
            val_str = flt_fmt(val, 4)
        else:
            val_str = int_lit(val)
        ret.append('{:<40}{:>10}'.format(key, val_str))
    return '\n'.join(ret)


# -------------------- Main --------------------


# noinspection PyTypeChecker
def main():
    # Argument parsing and iterator creation
    parser = argparse.ArgumentParser()
    parser.add_argument(
        'infile',
        metavar='infile.dasm',
        nargs='?',
        type=argparse.FileType('r'),
        default=sys.stdin,
        help='A matching ASCII signal dump',
    )
    parser.add_argument(
        '-o',
        '--offl',
        action='store_true',
        help='Annotate FPSS and sequencer offloads when they happen in core')
    parser.add_argument(
        '-s',
        '--saddr',
        action='store_true',
        help='Use signed decimal (not unsigned hex) for small addresses')
    parser.add_argument(
        '-a',
        '--allkeys',
        action='store_true',
        help='Include performance metrics measured to compute others')
    parser.add_argument(
        '-p',
        '--permissive',
        action='store_true',
        help='Ignore some state-related issues when they occur')
    parser.add_argument('-d',
                        '--dump-perf',
                        nargs='?',
                        metavar='file',
                        type=argparse.FileType('w'),
                        help='Dump performance metrics as json text.')

    args = parser.parse_args()
    line_iter = iter(args.infile.readline, b'')
    # Prepare stateful data structures
    time_info = None
    gpr_wb_info = defaultdict(deque)
    fpr_wb_info = defaultdict(deque)
    fseq_info = {
        'curr_sec': 0,
        'fpss_pcs': deque(),
        'fseq_pcs': deque(),
        'cfg_buf': deque(),
        'curr_cfg': None
    }
    perf_metrics = [
        defaultdict(int)
    ]  # all values initially 0, also 'start' time of measurement 0
    perf_metrics[0]['start'] = None
    # Parse input line by line
    for line in line_iter:
        if line:
            ann_insn, time_info, empty = annotate_insn(
                line, gpr_wb_info, fpr_wb_info, fseq_info, perf_metrics, False,
                time_info, args.offl, not args.saddr, args.permissive)
            if perf_metrics[0]['start'] is None:
                perf_metrics[0]['tstart'] = time_info[0] / 1000
                perf_metrics[0]['start'] = time_info[1]
            if not empty:
                print(ann_insn)
        else:
            break  # Nothing more in pipe, EOF
    perf_metrics[-1]['tend'] = time_info[0] / 1000
    perf_metrics[-1]['end'] = time_info[1]
    # Compute metrics
    eval_perf_metrics(perf_metrics)
    # Emit metrics
    print('\n## Performance metrics')
    for idx in range(len(perf_metrics)):
        print('\n' + fmt_perf_metrics(perf_metrics, idx, not args.allkeys))

    if args.dump_perf:
        with args.dump_perf as file:
            file.write(json.dumps(perf_metrics, indent=4))

    # Check for any loose ends and warn before exiting
    seq_isns = len(fseq_info['fseq_pcs']) + len(fseq_info['cfg_buf'])
    unseq_left = len(fseq_info['fpss_pcs']) - len(fseq_info['fseq_pcs'])
    fseq_cfg = fseq_info['curr_cfg']
    warn_trip = False
    for fpr, que in fpr_wb_info.items():
        if len(que) != 0:
            warn_trip = True
            sys.stderr.write(
                EXTRA_WB_WARN.format(len(que), REG_ABI_NAMES_F[fpr]) + '\n')
    for gpr, que in fpr_wb_info.items():
        if len(que) != 0:
            warn_trip = True
            sys.stderr.write(
                EXTRA_WB_WARN.format(len(que), REG_ABI_NAMES_I[gpr]) + '\n')
    if seq_isns:
        warn_trip = True
        sys.stderr.write(
            'WARNING: {} Sequencer instructions were not issued.\n'.format(
                seq_isns))
    if unseq_left:
        warn_trip = True
        sys.stderr.write(
            'WARNING: {} unsequenced FPSS instructions were not issued.\n'.
            format(unseq_left))
    if fseq_cfg is not None:
        warn_trip = True
        pc_str = fseq_cfg['fseq_pc']
        sys.stderr.write(
            'WARNING: Not all FPSS instructions from sequence {} were issued.\n'
            .format(pc_str))
    if warn_trip:
        sys.stderr.write(GENERAL_WARN)
    return 0


if __name__ == '__main__':
    sys.exit(main())
