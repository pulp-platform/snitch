; Initial code for the translated binary, before emitting code for the
; individual instructions.

; Annotate the debug info version of the module.
!llvm.module.flags = !{!0, !1}
!0 = !{i32 2, !"Debug Info Version", i32 3}
!1 = !{i32 2, !"Dwarf Version", i32 2}

; Forward-declared the SSR/DMA state types. This will go away at some point,
; when we leave the runtime data structure management entirely to Rust, and use
; inline functions to access them transparently in the JITed IR.
%SsrState = type { [0 x i32], [4 x i32], [0 x i32], [4 x i32], [0 x i32], [4 x i32], [0 x i32], i32, [0 x i16], i16, [0 x i16], i16, [0 x i8], i8, [0 x i8], i8, [0 x i8], i8, [1 x i8] }
%DmaState = type { [0 x i64], i64, [0 x i64], i64, [0 x i32], i32, [0 x i32], i32, [0 x i32], i32, [0 x i32], i32, [0 x i32] }
%cpu = type {
    i8*,             ; Context
    [32 x i32],      ; Registers
    [32 x i64],      ; Float Registers
    i32,             ; PC
    i64,             ; Retired Instructions
    [2 x %SsrState], ; SSRs
    i32,             ; SSR enable
    %DmaState,       ; DMA
    i32*             ; TCDM
}

; Forward declarations.
declare i32 @banshee_load(%cpu* %cpu, i32 %addr, i8 %size)
declare void @banshee_store(%cpu* %cpu, i32 %addr, i32 %value, i8 %size)
declare i32 @banshee_csr_read(%cpu* %cpu, i16 %csr)
declare void @banshee_csr_write(%cpu* %cpu, i16 %csr, i32 %value)
declare void @banshee_abort_escape(%cpu* %cpu, i32 %addr)
declare void @banshee_abort_illegal_inst(%cpu* %cpu, i32 %addr, i32 %raw)
declare void @banshee_abort_illegal_branch(%cpu* %cpu, i32 %addr, i32 %target)
declare void @banshee_trace(%cpu* %cpu, i32 %addr, i32 %raw, [2 x i64] %access_slice, [2 x i64] %data_slice)

declare void @banshee_ssr_write_cfg(%SsrState* writeonly %ssr, i32 %addr, i32 %value)
declare i32 @banshee_ssr_read_cfg(%SsrState* readonly %ssr, i32 %addr)
declare i32 @banshee_ssr_next(%SsrState* %ssr)

declare void @banshee_dma_src(%DmaState* writeonly %dma, i32 %lo, i32 %hi)
declare void @banshee_dma_dst(%DmaState* writeonly %dma, i32 %lo, i32 %hi)
declare i32 @banshee_dma_strt(%DmaState* %dma, i8* %cpu, i32 %size, i32 %flags)
declare i32 @banshee_dma_stat(%DmaState* readonly %dma, i32 %addr)

; declare i32* @banshee_reg_ptr(%Cpu* %cpu, i32 %reg)
