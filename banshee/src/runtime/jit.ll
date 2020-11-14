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

; Forward declarations.
declare void @banshee_ssr_write_cfg(%SsrState* %ssr, i32 %addr, i32 %value)
declare i32 @banshee_ssr_read_cfg(%SsrState* %ssr, i32 %addr)
