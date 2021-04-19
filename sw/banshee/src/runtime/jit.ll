; Copyright 2020 ETH Zurich and University of Bologna.
; Licensed under the Apache License, Version 2.0, see LICENSE for details.
; SPDX-License-Identifier: Apache-2.0

; Initial code for the translated binary, before emitting code for the
; individual instructions.

; Annotate the debug info version of the module.
!llvm.module.flags = !{!0, !1}
!0 = !{i32 2, !"Debug Info Version", i32 3}
!1 = !{i32 2, !"Dwarf Version", i32 2}

; Opaque pointers we get from the Rust part of the runtime.
%Cpu = type opaque
%SsrState = type opaque
%DmaState = type opaque

; Forward declarations.
declare i32 @banshee_load(%Cpu* %cpu, i32 %addr, i8 %size)
declare void @banshee_store(%Cpu* %cpu, i32 %addr, i32 %value, i32 %mask, i8 %size)
declare i32 @banshee_rmw(%Cpu* %cpu, i32 %addr, i32 %value, i8 %op)
declare i32 @banshee_csr_read(%Cpu* %cpu, i16 %csr)
declare void @banshee_csr_write(%Cpu* %cpu, i16 %csr, i32 %value)
declare void @banshee_abort_escape(%Cpu* %cpu, i32 %addr)
declare void @banshee_abort_illegal_inst(%Cpu* %cpu, i32 %addr, i32 %raw)
declare void @banshee_abort_illegal_branch(%Cpu* %cpu, i32 %addr, i32 %target)
declare void @banshee_trace(%Cpu* %cpu, i32 %addr, i32 %raw, [2 x i64] %access_slice, [2 x i64] %data_slice)
declare i32 @banshee_wfi(%Cpu* %cpu)

declare void @banshee_ssr_write_cfg(%SsrState* %ssr,  %Cpu* %cpu, i32 %addr, i32 %value, i32 %mask)
declare i32 @banshee_ssr_read_cfg(%SsrState* readonly %ssr, i32 %addr)
declare i32 @banshee_ssr_next(%SsrState* %ssr, %Cpu* %cpu)
declare void @banshee_ssr_eoi(%SsrState* %ssr)

declare void @banshee_dma_src(%DmaState* writeonly %dma, i32 %lo, i32 %hi)
declare void @banshee_dma_dst(%DmaState* writeonly %dma, i32 %lo, i32 %hi)
declare i32 @banshee_dma_strt(%DmaState* %dma, %Cpu* %cpu, i32 %size, i32 %flags)
declare void @banshee_dma_str(%DmaState* writeonly %dma, i32 %src, i32 %dst)
declare void @banshee_dma_rep(%DmaState* writeonly %dma, i32 %reps)
declare i32 @banshee_dma_stat(%DmaState* readonly %dma, i32 %addr)

declare i32* @banshee_reg_ptr(%Cpu* %cpu, i32 %reg)
declare i64* @banshee_reg_cycle_ptr(%Cpu* %cpu, i32 %reg)
declare i64* @banshee_freg_ptr(%Cpu* %cpu, i32 %reg)
declare i64* @banshee_freg_cycle_ptr(%Cpu* %cpu, i32 %reg)
declare i32* @banshee_pc_ptr(%Cpu* %cpu)
declare i64* @banshee_cycle_ptr(%Cpu* %cpu)
declare i64* @banshee_instret_ptr(%Cpu* %cpu)
declare i32* @banshee_tcdm_ptr(%Cpu* %cpu)
declare %SsrState* @banshee_ssr_ptr(%Cpu* %cpu, i32 %ssr)
declare i32* @banshee_ssr_enabled_ptr(%Cpu* %cpu)
declare %DmaState* @banshee_dma_ptr(%Cpu* %cpu)
