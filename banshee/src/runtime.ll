; ModuleID = 'runtime.3a1fbbbh-cgu.0'
source_filename = "runtime.3a1fbbbh-cgu.0"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

%SsrState = type { [0 x i32], [4 x i32], [0 x i32], [4 x i32], [0 x i32], [4 x i32], [0 x i32], i32, [0 x i16], i16, [0 x i16], i16, [0 x i8], i8, [0 x i8], i8, [0 x i8], i8, [1 x i8] }
%DmaState = type { [0 x i64], i64, [0 x i64], i64, [0 x i32], i32, [1 x i32] }
%"unwind::libunwind::_Unwind_Exception" = type { [0 x i64], i64, [0 x i64], void (i32, %"unwind::libunwind::_Unwind_Exception"*)*, [0 x i64], [6 x i64], [0 x i64] }
%"unwind::libunwind::_Unwind_Context" = type { [0 x i8] }

; Function Attrs: nofree norecurse nounwind nonlazybind writeonly
define void @banshee_ssr_write_cfg(%SsrState* nocapture align 4 dereferenceable(60) %ssr, i32 %addr, i32 %value) unnamed_addr #0 {
start:
  %0 = lshr i32 %addr, 3
  %addr1 = zext i32 %0 to i64
  switch i64 %addr1, label %bb1 [
    i64 0, label %bb10
    i64 1, label %bb11
  ]

bb1:                                              ; preds = %start
  %addr.off = add i32 %addr, -16
  %1 = icmp ult i32 %addr.off, 32
  br i1 %1, label %bb12, label %bb3

bb3:                                              ; preds = %bb1
  %addr.off5 = add i32 %addr, -48
  %2 = icmp ult i32 %addr.off5, 32
  br i1 %2, label %bb14, label %bb5

bb5:                                              ; preds = %bb3
  %3 = and i32 %addr, -32
  switch i32 %3, label %bb18 [
    i32 192, label %bb16
    i32 224, label %bb17
  ]

bb10:                                             ; preds = %start
  %4 = getelementptr inbounds %SsrState, %SsrState* %ssr, i64 0, i32 7
  %5 = and i32 %value, 268435455
  store i32 %5, i32* %4, align 4
  %6 = getelementptr inbounds %SsrState, %SsrState* %ssr, i64 0, i32 17
  %value.lobit = lshr i32 %value, 31
  %7 = trunc i32 %value.lobit to i8
  store i8 %7, i8* %6, align 2
  %8 = getelementptr inbounds %SsrState, %SsrState* %ssr, i64 0, i32 13
  %_20 = lshr i32 %value, 30
  %9 = trunc i32 %_20 to i8
  %10 = and i8 %9, 1
  store i8 %10, i8* %8, align 4
  %_24 = lshr i32 %value, 28
  %11 = getelementptr inbounds %SsrState, %SsrState* %ssr, i64 0, i32 15
  %12 = trunc i32 %_24 to i8
  %13 = and i8 %12, 3
  store i8 %13, i8* %11, align 1
  br label %bb18

bb11:                                             ; preds = %start
  %14 = getelementptr inbounds %SsrState, %SsrState* %ssr, i64 0, i32 9
  %15 = trunc i32 %value to i16
  store i16 %15, i16* %14, align 4
  br label %bb18

bb12:                                             ; preds = %bb1
  %_31 = add nsw i64 %addr1, -2
  %16 = getelementptr inbounds %SsrState, %SsrState* %ssr, i64 0, i32 3, i64 %_31
  store i32 %value, i32* %16, align 4
  br label %bb18

bb14:                                             ; preds = %bb3
  %_37 = add nsw i64 %addr1, -6
  %17 = getelementptr inbounds %SsrState, %SsrState* %ssr, i64 0, i32 5, i64 %_37
  store i32 %value, i32* %17, align 4
  br label %bb18

bb16:                                             ; preds = %bb5
  %18 = getelementptr inbounds %SsrState, %SsrState* %ssr, i64 0, i32 7
  store i32 %value, i32* %18, align 4
  %19 = getelementptr inbounds %SsrState, %SsrState* %ssr, i64 0, i32 17
  store i8 0, i8* %19, align 2
  %20 = getelementptr inbounds %SsrState, %SsrState* %ssr, i64 0, i32 13
  store i8 0, i8* %20, align 4
  %21 = getelementptr inbounds %SsrState, %SsrState* %ssr, i64 0, i32 15
  %22 = trunc i32 %0 to i8
  %23 = add i8 %22, -24
  store i8 %23, i8* %21, align 1
  br label %bb18

bb17:                                             ; preds = %bb5
  %24 = getelementptr inbounds %SsrState, %SsrState* %ssr, i64 0, i32 7
  store i32 %value, i32* %24, align 4
  %25 = getelementptr inbounds %SsrState, %SsrState* %ssr, i64 0, i32 17
  store i8 0, i8* %25, align 2
  %26 = getelementptr inbounds %SsrState, %SsrState* %ssr, i64 0, i32 13
  store i8 1, i8* %26, align 4
  %27 = getelementptr inbounds %SsrState, %SsrState* %ssr, i64 0, i32 15
  %28 = trunc i32 %0 to i8
  %29 = add i8 %28, -28
  store i8 %29, i8* %27, align 1
  br label %bb18

bb18:                                             ; preds = %bb5, %bb10, %bb11, %bb17, %bb16, %bb14, %bb12
  ret void
}

; Function Attrs: norecurse nounwind nonlazybind readonly
define i32 @banshee_ssr_read_cfg(%SsrState* nocapture readonly align 4 dereferenceable(60) %ssr, i32 %addr) unnamed_addr #1 {
start:
  %0 = lshr i32 %addr, 3
  %addr1 = zext i32 %0 to i64
  switch i64 %addr1, label %bb1 [
    i64 0, label %bb6
    i64 1, label %bb7
  ]

bb1:                                              ; preds = %start
  %addr.off = add i32 %addr, -16
  %1 = icmp ult i32 %addr.off, 32
  br i1 %1, label %bb8, label %bb3

bb3:                                              ; preds = %bb1
  %addr.off3 = add i32 %addr, -48
  %2 = icmp ult i32 %addr.off3, 32
  br i1 %2, label %bb10, label %bb12

bb6:                                              ; preds = %start
  %3 = getelementptr inbounds %SsrState, %SsrState* %ssr, i64 0, i32 7
  %_12 = load i32, i32* %3, align 4
  %4 = getelementptr inbounds %SsrState, %SsrState* %ssr, i64 0, i32 17
  %5 = load i8, i8* %4, align 2, !range !2
  %6 = zext i8 %5 to i32
  %_13 = shl nuw i32 %6, 31
  %_11 = or i32 %_13, %_12
  %7 = getelementptr inbounds %SsrState, %SsrState* %ssr, i64 0, i32 13
  %8 = load i8, i8* %7, align 4, !range !2
  %9 = zext i8 %8 to i32
  %_16 = shl nuw nsw i32 %9, 30
  %_10 = or i32 %_11, %_16
  %10 = getelementptr inbounds %SsrState, %SsrState* %ssr, i64 0, i32 15
  %_21 = load i8, i8* %10, align 1
  %_20 = zext i8 %_21 to i32
  %_19 = shl i32 %_20, 28
  %11 = or i32 %_10, %_19
  br label %bb12

bb7:                                              ; preds = %start
  %12 = getelementptr inbounds %SsrState, %SsrState* %ssr, i64 0, i32 9
  %_22 = load i16, i16* %12, align 4
  %13 = zext i16 %_22 to i32
  br label %bb12

bb8:                                              ; preds = %bb1
  %_26 = add nsw i64 %addr1, -2
  %14 = getelementptr inbounds %SsrState, %SsrState* %ssr, i64 0, i32 3, i64 %_26
  %15 = load i32, i32* %14, align 4
  br label %bb12

bb10:                                             ; preds = %bb3
  %_31 = add nsw i64 %addr1, -6
  %16 = getelementptr inbounds %SsrState, %SsrState* %ssr, i64 0, i32 5, i64 %_31
  %17 = load i32, i32* %16, align 4
  br label %bb12

bb12:                                             ; preds = %bb3, %bb6, %bb7, %bb10, %bb8
  %.0 = phi i32 [ %15, %bb8 ], [ %17, %bb10 ], [ %13, %bb7 ], [ %11, %bb6 ], [ 0, %bb3 ]
  ret i32 %.0
}

; Function Attrs: nounwind nonlazybind
define i32 @banshee_ssr_next(%SsrState* nocapture align 4 dereferenceable(60) %ssr) unnamed_addr #2 personality i32 (i32, i32, i64, %"unwind::libunwind::_Unwind_Exception"*, %"unwind::libunwind::_Unwind_Context"*)* @rust_eh_personality {
start:
  %0 = getelementptr inbounds %SsrState, %SsrState* %ssr, i64 0, i32 7
  %ptr = load i32, i32* %0, align 4
  %1 = getelementptr inbounds %SsrState, %SsrState* %ssr, i64 0, i32 9
  %_3 = load i16, i16* %1, align 4
  %2 = getelementptr inbounds %SsrState, %SsrState* %ssr, i64 0, i32 11
  %_4 = load i16, i16* %2, align 2
  %_2 = icmp eq i16 %_3, %_4
  br i1 %_2, label %bb2, label %bb1

bb1:                                              ; preds = %start
  %3 = add i16 %_3, 1
  store i16 %3, i16* %1, align 4
  br label %bb19

bb2:                                              ; preds = %start
  store i16 0, i16* %1, align 4
  %4 = getelementptr inbounds %SsrState, %SsrState* %ssr, i64 0, i32 17
  store i8 1, i8* %4, align 2
  %5 = getelementptr inbounds %SsrState, %SsrState* %ssr, i64 0, i32 15
  %_9 = load i8, i8* %5, align 1
  %_8 = zext i8 %_9 to i64
  br label %bb2.i

bb2.i:                                            ; preds = %bb2, %bb15
  %iter.sroa.0.037 = phi i64 [ 0, %bb2 ], [ %spec.select, %bb15 ]
  %6 = icmp ult i64 %iter.sroa.0.037, %_8
  %7 = getelementptr inbounds %SsrState, %SsrState* %ssr, i64 0, i32 5, i64 %iter.sroa.0.037
  %_19 = load i32, i32* %7, align 4
  %8 = getelementptr inbounds %SsrState, %SsrState* %ssr, i64 0, i32 0, i64 %iter.sroa.0.037
  %_25 = load i32, i32* %8, align 4
  %9 = getelementptr inbounds %SsrState, %SsrState* %ssr, i64 0, i32 3, i64 %iter.sroa.0.037
  %_30 = load i32, i32* %9, align 4
  %_24 = icmp eq i32 %_25, %_30
  br i1 %_24, label %bb15, label %bb14

bb10:                                             ; preds = %bb15, %bb14
  %_44 = load i32, i32* %0, align 4
  %10 = add i32 %_44, %_19
  store i32 %10, i32* %0, align 4
  br label %bb19

bb14:                                             ; preds = %bb2.i
  %11 = add i32 %_25, 1
  store i32 %11, i32* %8, align 4
  store i8 0, i8* %4, align 2
  br label %bb10

bb15:                                             ; preds = %bb2.i
  %not. = xor i1 %6, true
  %12 = zext i1 %6 to i64
  %spec.select = add nuw i64 %iter.sroa.0.037, %12
  store i32 0, i32* %8, align 4
  %13 = icmp ugt i64 %spec.select, %_8
  %.0.i.i = or i1 %13, %not.
  br i1 %.0.i.i, label %bb10, label %bb2.i

bb19:                                             ; preds = %bb1, %bb10
  ret i32 %ptr
}

; Function Attrs: nofree norecurse nounwind nonlazybind writeonly
define void @banshee_dma_src(%DmaState* nocapture align 8 dereferenceable(24) %dma, i32 %lo, i32 %hi) unnamed_addr #0 {
start:
  %_5 = zext i32 %hi to i64
  %_4 = shl nuw i64 %_5, 32
  %_7 = zext i32 %lo to i64
  %0 = getelementptr inbounds %DmaState, %DmaState* %dma, i64 0, i32 0, i64 0
  %1 = or i64 %_4, %_7
  store i64 %1, i64* %0, align 8
  ret void
}

; Function Attrs: nofree norecurse nounwind nonlazybind writeonly
define void @banshee_dma_dst(%DmaState* nocapture align 8 dereferenceable(24) %dma, i32 %lo, i32 %hi) unnamed_addr #0 {
start:
  %_5 = zext i32 %hi to i64
  %_4 = shl nuw i64 %_5, 32
  %_7 = zext i32 %lo to i64
  %0 = getelementptr inbounds %DmaState, %DmaState* %dma, i64 0, i32 3
  %1 = or i64 %_4, %_7
  store i64 %1, i64* %0, align 8
  ret void
}

; Function Attrs: nofree norecurse nounwind nonlazybind
define i32 @banshee_dma_strt(%DmaState* nocapture align 8 dereferenceable(24) %dma, i32 %_size, i32 %_flags) unnamed_addr #3 {
start:
  %0 = getelementptr inbounds %DmaState, %DmaState* %dma, i64 0, i32 5
  %id = load i32, i32* %0, align 8
  %1 = add i32 %id, 1
  store i32 %1, i32* %0, align 8
  ret i32 %id
}

; Function Attrs: norecurse nounwind nonlazybind readonly
define i32 @banshee_dma_stat(%DmaState* noalias nocapture readonly align 8 dereferenceable(24) %dma, i32 %addr) unnamed_addr #1 {
start:
  %_3 = and i32 %addr, 3
  switch i32 %_3, label %bb11 [
    i32 0, label %bb2
    i32 1, label %bb3
    i32 2, label %bb5
    i32 3, label %bb5
  ]

bb11:                                             ; preds = %start
  unreachable

bb2:                                              ; preds = %start
  %0 = getelementptr inbounds %DmaState, %DmaState* %dma, i64 0, i32 5
  %1 = load i32, i32* %0, align 8
  br label %bb5

bb3:                                              ; preds = %start
  %2 = getelementptr inbounds %DmaState, %DmaState* %dma, i64 0, i32 5
  %_5 = load i32, i32* %2, align 8
  %3 = add i32 %_5, 1
  br label %bb5

bb5:                                              ; preds = %start, %start, %bb2, %bb3
  %.0 = phi i32 [ %3, %bb3 ], [ %1, %bb2 ], [ 0, %start ], [ 0, %start ]
  ret i32 %.0
}

; Function Attrs: nounwind nonlazybind
declare i32 @rust_eh_personality(i32, i32, i64, %"unwind::libunwind::_Unwind_Exception"*, %"unwind::libunwind::_Unwind_Context"*) unnamed_addr #2

attributes #0 = { nofree norecurse nounwind nonlazybind writeonly "probe-stack"="__rust_probestack" "target-cpu"="x86-64" }
attributes #1 = { norecurse nounwind nonlazybind readonly "probe-stack"="__rust_probestack" "target-cpu"="x86-64" }
attributes #2 = { nounwind nonlazybind "probe-stack"="__rust_probestack" "target-cpu"="x86-64" }
attributes #3 = { nofree norecurse nounwind nonlazybind "probe-stack"="__rust_probestack" "target-cpu"="x86-64" }

!llvm.module.flags = !{!0, !1}

!0 = !{i32 7, !"PIC Level", i32 2}
!1 = !{i32 2, !"RtLibUseGOT", i32 1}
!2 = !{i8 0, i8 2}
