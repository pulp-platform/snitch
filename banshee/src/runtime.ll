; ModuleID = 'runtime.3a1fbbbh-cgu.0'
source_filename = "runtime.3a1fbbbh-cgu.0"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

%"core::fmt::Formatter" = type { [0 x i64], { i64, i64 }, [0 x i64], { i64, i64 }, [0 x i64], { {}*, [3 x i64]* }, [0 x i32], i32, [0 x i32], i32, [0 x i8], i8, [7 x i8] }
%SsrState = type { [0 x i32], [4 x i32], [0 x i32], [4 x i32], [0 x i32], [4 x i32], [0 x i32], i32, [0 x i16], i16, [0 x i16], i16, [0 x i8], i8, [0 x i8], i8, [0 x i8], i8, [1 x i8] }
%DmaState = type { [0 x i64], i64, [0 x i64], i64, [0 x i32], i32, [0 x i32], i32, [0 x i32], i32, [0 x i32], i32, [0 x i32] }
%"core::fmt::Arguments" = type { [0 x i64], { [0 x { [0 x i8]*, i64 }]*, i64 }, [0 x i64], { i64*, i64 }, [0 x i64], { [0 x { i8*, i8* }]*, i64 }, [0 x i64] }
%"core::panic::Location" = type { [0 x i64], { [0 x i8]*, i64 }, [0 x i32], i32, [0 x i32], i32, [0 x i32] }
%"unwind::libunwind::_Unwind_Exception" = type { [0 x i64], i64, [0 x i64], void (i32, %"unwind::libunwind::_Unwind_Exception"*)*, [0 x i64], [6 x i64], [0 x i64] }
%"unwind::libunwind::_Unwind_Context" = type { [0 x i8] }

@alloc36 = private unnamed_addr constant <{ [4 x i8] }> zeroinitializer, align 4
@alloc87 = private unnamed_addr constant <{ [45 x i8] }> <{ [45 x i8] c"assertion failed: `(left == right)`\0A  left: `" }>, align 1
@alloc88 = private unnamed_addr constant <{ [12 x i8] }> <{ [12 x i8] c"`,\0A right: `" }>, align 1
@alloc89 = private unnamed_addr constant <{ [3 x i8] }> <{ [3 x i8] c"`: " }>, align 1
@alloc90 = private unnamed_addr constant <{ i8*, [8 x i8], i8*, [8 x i8], i8*, [8 x i8] }> <{ i8* getelementptr inbounds (<{ [45 x i8] }>, <{ [45 x i8] }>* @alloc87, i32 0, i32 0, i32 0), [8 x i8] c"-\00\00\00\00\00\00\00", i8* getelementptr inbounds (<{ [12 x i8] }>, <{ [12 x i8] }>* @alloc88, i32 0, i32 0, i32 0), [8 x i8] c"\0C\00\00\00\00\00\00\00", i8* getelementptr inbounds (<{ [3 x i8] }>, <{ [3 x i8] }>* @alloc89, i32 0, i32 0, i32 0), [8 x i8] c"\03\00\00\00\00\00\00\00" }>, align 8
@alloc47 = private unnamed_addr constant <{ [50 x i8] }> <{ [50 x i8] c"DMA transfer size must be a multiple of 4B for now" }>, align 1
@alloc48 = private unnamed_addr constant <{ i8*, [8 x i8] }> <{ i8* getelementptr inbounds (<{ [50 x i8] }>, <{ [50 x i8] }>* @alloc47, i32 0, i32 0, i32 0), [8 x i8] c"2\00\00\00\00\00\00\00" }>, align 8
@alloc99 = private unnamed_addr constant <{ [0 x i8] }> zeroinitializer, align 8
@alloc126 = private unnamed_addr constant <{ [14 x i8] }> <{ [14 x i8] c"src/runtime.rs" }>, align 1
@alloc123 = private unnamed_addr constant <{ i8*, [16 x i8] }> <{ i8* getelementptr inbounds (<{ [14 x i8] }>, <{ [14 x i8] }>* @alloc126, i32 0, i32 0, i32 0), [16 x i8] c"\0E\00\00\00\00\00\00\00\9C\00\00\00\05\00\00\00" }>, align 8
@alloc82 = private unnamed_addr constant <{ [8 x i8] }> zeroinitializer, align 8
@alloc71 = private unnamed_addr constant <{ [45 x i8] }> <{ [45 x i8] c"DMA src transfer block must be 4-byte-aligned" }>, align 1
@alloc72 = private unnamed_addr constant <{ i8*, [8 x i8] }> <{ i8* getelementptr inbounds (<{ [45 x i8] }>, <{ [45 x i8] }>* @alloc71, i32 0, i32 0, i32 0), [8 x i8] c"-\00\00\00\00\00\00\00" }>, align 8
@alloc125 = private unnamed_addr constant <{ i8*, [16 x i8] }> <{ i8* getelementptr inbounds (<{ [14 x i8] }>, <{ [14 x i8] }>* @alloc126, i32 0, i32 0, i32 0), [16 x i8] c"\0E\00\00\00\00\00\00\00\A8\00\00\00\09\00\00\00" }>, align 8
@alloc94 = private unnamed_addr constant <{ [45 x i8] }> <{ [45 x i8] c"DMA dst transfer block must be 4-byte-aligned" }>, align 1
@alloc95 = private unnamed_addr constant <{ i8*, [8 x i8] }> <{ i8* getelementptr inbounds (<{ [45 x i8] }>, <{ [45 x i8] }>* @alloc94, i32 0, i32 0, i32 0), [8 x i8] c"-\00\00\00\00\00\00\00" }>, align 8
@alloc127 = private unnamed_addr constant <{ i8*, [16 x i8] }> <{ i8* getelementptr inbounds (<{ [14 x i8] }>, <{ [14 x i8] }>* @alloc126, i32 0, i32 0, i32 0), [16 x i8] c"\0E\00\00\00\00\00\00\00\A9\00\00\00\09\00\00\00" }>, align 8

; <&T as core::fmt::Debug>::fmt
; Function Attrs: nounwind nonlazybind
define internal zeroext i1 @"_ZN42_$LT$$RF$T$u20$as$u20$core..fmt..Debug$GT$3fmt17h239ce14a0c38695eE"(i32** noalias nocapture readonly align 8 dereferenceable(8) %self, %"core::fmt::Formatter"* align 8 dereferenceable(64) %f) unnamed_addr #0 {
start:
  %_4 = load i32*, i32** %self, align 8, !nonnull !2
; call core::fmt::Formatter::debug_lower_hex
  %_3.i = tail call zeroext i1 @_ZN4core3fmt9Formatter15debug_lower_hex17h0f758bf74de7e467E(%"core::fmt::Formatter"* noalias nonnull readonly align 8 dereferenceable(64) %f) #5, !noalias !3
  br i1 %_3.i, label %bb3.i, label %bb2.i

bb2.i:                                            ; preds = %start
; call core::fmt::Formatter::debug_upper_hex
  %_7.i = tail call zeroext i1 @_ZN4core3fmt9Formatter15debug_upper_hex17hcb8ddb31a324fd72E(%"core::fmt::Formatter"* noalias nonnull readonly align 8 dereferenceable(64) %f) #5
  br i1 %_7.i, label %bb7.i, label %bb6.i

bb3.i:                                            ; preds = %start
; call core::fmt::num::<impl core::fmt::LowerHex for u32>::fmt
  %0 = tail call zeroext i1 @"_ZN4core3fmt3num53_$LT$impl$u20$core..fmt..LowerHex$u20$for$u20$u32$GT$3fmt17hfce767795847c2acE"(i32* noalias nonnull readonly align 4 dereferenceable(4) %_4, %"core::fmt::Formatter"* nonnull align 8 dereferenceable(64) %f) #5
  br label %"_ZN4core3fmt3num50_$LT$impl$u20$core..fmt..Debug$u20$for$u20$u32$GT$3fmt17h6238c6625c3bbc68E.exit"

bb6.i:                                            ; preds = %bb2.i
; call core::fmt::num::imp::<impl core::fmt::Display for u32>::fmt
  %1 = tail call zeroext i1 @"_ZN4core3fmt3num3imp52_$LT$impl$u20$core..fmt..Display$u20$for$u20$u32$GT$3fmt17h43c98606ce80fde1E"(i32* noalias nonnull readonly align 4 dereferenceable(4) %_4, %"core::fmt::Formatter"* nonnull align 8 dereferenceable(64) %f) #5
  br label %"_ZN4core3fmt3num50_$LT$impl$u20$core..fmt..Debug$u20$for$u20$u32$GT$3fmt17h6238c6625c3bbc68E.exit"

bb7.i:                                            ; preds = %bb2.i
; call core::fmt::num::<impl core::fmt::UpperHex for u32>::fmt
  %2 = tail call zeroext i1 @"_ZN4core3fmt3num53_$LT$impl$u20$core..fmt..UpperHex$u20$for$u20$u32$GT$3fmt17hc2f65734cb045febE"(i32* noalias nonnull readonly align 4 dereferenceable(4) %_4, %"core::fmt::Formatter"* nonnull align 8 dereferenceable(64) %f) #5
  br label %"_ZN4core3fmt3num50_$LT$impl$u20$core..fmt..Debug$u20$for$u20$u32$GT$3fmt17h6238c6625c3bbc68E.exit"

"_ZN4core3fmt3num50_$LT$impl$u20$core..fmt..Debug$u20$for$u20$u32$GT$3fmt17h6238c6625c3bbc68E.exit": ; preds = %bb3.i, %bb6.i, %bb7.i
  %.0.in.i = phi i1 [ %0, %bb3.i ], [ %2, %bb7.i ], [ %1, %bb6.i ]
  ret i1 %.0.in.i
}

; <&T as core::fmt::Debug>::fmt
; Function Attrs: nounwind nonlazybind
define internal zeroext i1 @"_ZN42_$LT$$RF$T$u20$as$u20$core..fmt..Debug$GT$3fmt17hc117f9fdf259cc83E"(i64** noalias nocapture readonly align 8 dereferenceable(8) %self, %"core::fmt::Formatter"* align 8 dereferenceable(64) %f) unnamed_addr #0 {
start:
  %_4 = load i64*, i64** %self, align 8, !nonnull !2
; call core::fmt::Formatter::debug_lower_hex
  %_3.i = tail call zeroext i1 @_ZN4core3fmt9Formatter15debug_lower_hex17h0f758bf74de7e467E(%"core::fmt::Formatter"* noalias nonnull readonly align 8 dereferenceable(64) %f) #5, !noalias !6
  br i1 %_3.i, label %bb3.i, label %bb2.i

bb2.i:                                            ; preds = %start
; call core::fmt::Formatter::debug_upper_hex
  %_7.i = tail call zeroext i1 @_ZN4core3fmt9Formatter15debug_upper_hex17hcb8ddb31a324fd72E(%"core::fmt::Formatter"* noalias nonnull readonly align 8 dereferenceable(64) %f) #5
  br i1 %_7.i, label %bb7.i, label %bb6.i

bb3.i:                                            ; preds = %start
; call core::fmt::num::<impl core::fmt::LowerHex for u64>::fmt
  %0 = tail call zeroext i1 @"_ZN4core3fmt3num53_$LT$impl$u20$core..fmt..LowerHex$u20$for$u20$u64$GT$3fmt17h8377eae1154d58afE"(i64* noalias nonnull readonly align 8 dereferenceable(8) %_4, %"core::fmt::Formatter"* nonnull align 8 dereferenceable(64) %f) #5
  br label %"_ZN4core3fmt3num50_$LT$impl$u20$core..fmt..Debug$u20$for$u20$u64$GT$3fmt17h3b33b895b17bfaadE.exit"

bb6.i:                                            ; preds = %bb2.i
; call core::fmt::num::imp::<impl core::fmt::Display for u64>::fmt
  %1 = tail call zeroext i1 @"_ZN4core3fmt3num3imp52_$LT$impl$u20$core..fmt..Display$u20$for$u20$u64$GT$3fmt17hf7050dcb5cce3380E"(i64* noalias nonnull readonly align 8 dereferenceable(8) %_4, %"core::fmt::Formatter"* nonnull align 8 dereferenceable(64) %f) #5
  br label %"_ZN4core3fmt3num50_$LT$impl$u20$core..fmt..Debug$u20$for$u20$u64$GT$3fmt17h3b33b895b17bfaadE.exit"

bb7.i:                                            ; preds = %bb2.i
; call core::fmt::num::<impl core::fmt::UpperHex for u64>::fmt
  %2 = tail call zeroext i1 @"_ZN4core3fmt3num53_$LT$impl$u20$core..fmt..UpperHex$u20$for$u20$u64$GT$3fmt17ha39b2ba18f51b7c9E"(i64* noalias nonnull readonly align 8 dereferenceable(8) %_4, %"core::fmt::Formatter"* nonnull align 8 dereferenceable(64) %f) #5
  br label %"_ZN4core3fmt3num50_$LT$impl$u20$core..fmt..Debug$u20$for$u20$u64$GT$3fmt17h3b33b895b17bfaadE.exit"

"_ZN4core3fmt3num50_$LT$impl$u20$core..fmt..Debug$u20$for$u20$u64$GT$3fmt17h3b33b895b17bfaadE.exit": ; preds = %bb3.i, %bb6.i, %bb7.i
  %.0.in.i = phi i1 [ %0, %bb3.i ], [ %2, %bb7.i ], [ %1, %bb6.i ]
  ret i1 %.0.in.i
}

; Function Attrs: nofree norecurse nounwind nonlazybind writeonly
define void @banshee_ssr_write_cfg(%SsrState* nocapture align 4 dereferenceable(60) %ssr, i32 %addr, i32 %value) unnamed_addr #1 {
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
define i32 @banshee_ssr_read_cfg(%SsrState* nocapture readonly align 4 dereferenceable(60) %ssr, i32 %addr) unnamed_addr #2 {
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
  %5 = load i8, i8* %4, align 2, !range !9
  %6 = zext i8 %5 to i32
  %_13 = shl nuw i32 %6, 31
  %_11 = or i32 %_13, %_12
  %7 = getelementptr inbounds %SsrState, %SsrState* %ssr, i64 0, i32 13
  %8 = load i8, i8* %7, align 4, !range !9
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
define i32 @banshee_ssr_next(%SsrState* nocapture align 4 dereferenceable(60) %ssr) unnamed_addr #0 personality i32 (i32, i32, i64, %"unwind::libunwind::_Unwind_Exception"*, %"unwind::libunwind::_Unwind_Context"*)* @rust_eh_personality {
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
define void @banshee_dma_src(%DmaState* nocapture align 8 dereferenceable(32) %dma, i32 %lo, i32 %hi) unnamed_addr #1 {
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
define void @banshee_dma_dst(%DmaState* nocapture align 8 dereferenceable(32) %dma, i32 %lo, i32 %hi) unnamed_addr #1 {
start:
  %_5 = zext i32 %hi to i64
  %_4 = shl nuw i64 %_5, 32
  %_7 = zext i32 %lo to i64
  %0 = getelementptr inbounds %DmaState, %DmaState* %dma, i64 0, i32 3
  %1 = or i64 %_4, %_7
  store i64 %1, i64* %0, align 8
  ret void
}

; Function Attrs: nounwind nonlazybind
define i32 @banshee_dma_strt(%DmaState* nocapture align 8 dereferenceable(32) %dma, i8* %cpu, i32 %size, i32 %flags) unnamed_addr #0 personality i32 (i32, i32, i64, %"unwind::libunwind::_Unwind_Exception"*, %"unwind::libunwind::_Unwind_Context"*)* @rust_eh_personality {
start:
  %_157 = alloca %"core::fmt::Arguments", align 8
  %_155 = alloca i64*, align 8
  %_153 = alloca i64*, align 8
  %_150 = alloca [3 x { i8*, i8* }], align 8
  %_143 = alloca %"core::fmt::Arguments", align 8
  %_132 = alloca i64, align 8
  %_111 = alloca %"core::fmt::Arguments", align 8
  %_109 = alloca i64*, align 8
  %_107 = alloca i64*, align 8
  %_104 = alloca [3 x { i8*, i8* }], align 8
  %_97 = alloca %"core::fmt::Arguments", align 8
  %_86 = alloca i64, align 8
  %_32 = alloca %"core::fmt::Arguments", align 8
  %_30 = alloca i32*, align 8
  %_28 = alloca i32*, align 8
  %_25 = alloca [3 x { i8*, i8* }], align 8
  %_18 = alloca %"core::fmt::Arguments", align 8
  %_7 = alloca i32, align 4
  %0 = getelementptr inbounds %DmaState, %DmaState* %dma, i64 0, i32 11
  %id = load i32, i32* %0, align 4
  %1 = add i32 %id, 1
  store i32 %1, i32* %0, align 4
  %2 = bitcast i32* %_7 to i8*
  call void @llvm.lifetime.start.p0i8(i64 4, i8* nonnull %2)
  %3 = and i32 %size, 3
  store i32 %3, i32* %_7, align 4
  %_13 = icmp eq i32 %3, 0
  br i1 %_13, label %bb1, label %bb2

bb1:                                              ; preds = %start
  call void @llvm.lifetime.end.p0i8(i64 4, i8* nonnull %2)
  %_54 = and i32 %flags, 2
  %enable_2d = icmp eq i32 %_54, 0
  %4 = getelementptr inbounds %DmaState, %DmaState* %dma, i64 0, i32 9
  %5 = load i32, i32* %4, align 8
  %narrow = select i1 %enable_2d, i32 1, i32 %5
  %steps.0 = zext i32 %narrow to i64
  %6 = icmp eq i32 %narrow, 0
  br i1 %6, label %bb14, label %bb16.lr.ph

bb16.lr.ph:                                       ; preds = %bb1
  %num_beats = lshr i32 %size, 2
  %7 = getelementptr inbounds %DmaState, %DmaState* %dma, i64 0, i32 0, i64 0
  %8 = getelementptr inbounds %DmaState, %DmaState* %dma, i64 0, i32 5
  %9 = getelementptr inbounds %DmaState, %DmaState* %dma, i64 0, i32 3
  %10 = getelementptr inbounds %DmaState, %DmaState* %dma, i64 0, i32 7
  %11 = bitcast i64* %_86 to i8*
  %12 = bitcast i64* %_132 to i8*
  %_178 = zext i32 %num_beats to i64
  %13 = icmp eq i32 %num_beats, 0
  br i1 %13, label %bb16.preheader, label %bb16.us

bb16.preheader:                                   ; preds = %bb16.lr.ph
  %_73.pre = load i64, i64* %7, align 8
  %_77.pre = load i32, i32* %8, align 8
  %_79.pre = load i64, i64* %9, align 8
  %_83.pre = load i32, i32* %10, align 4
  %_76 = zext i32 %_77.pre to i64
  %_82 = zext i32 %_83.pre to i64
  br label %bb16

bb16.us:                                          ; preds = %bb16.lr.ph, %bb32.bb12.loopexit_crit_edge.us
  %iter.sroa.0.065.us = phi i64 [ %14, %bb32.bb12.loopexit_crit_edge.us ], [ 0, %bb16.lr.ph ]
  %14 = add nuw nsw i64 %iter.sroa.0.065.us, 1
  %_73.us = load i64, i64* %7, align 8
  %_77.us = load i32, i32* %8, align 8
  %_76.us = zext i32 %_77.us to i64
  %_74.us = mul i64 %iter.sroa.0.065.us, %_76.us
  %src.us = add i64 %_74.us, %_73.us
  %_79.us = load i64, i64* %9, align 8
  %_83.us = load i32, i32* %10, align 4
  %_82.us = zext i32 %_83.us to i64
  %_80.us = mul i64 %iter.sroa.0.065.us, %_82.us
  %dst.us = add i64 %_80.us, %_79.us
  call void @llvm.lifetime.start.p0i8(i64 8, i8* nonnull %11)
  %15 = and i64 %src.us, 3
  store i64 %15, i64* %_86, align 8
  %_92.us = icmp eq i64 %15, 0
  br i1 %_92.us, label %bb17.us, label %bb18

bb17.us:                                          ; preds = %bb16.us
  call void @llvm.lifetime.end.p0i8(i64 8, i8* nonnull %11)
  call void @llvm.lifetime.start.p0i8(i64 8, i8* nonnull %12)
  %16 = and i64 %dst.us, 3
  store i64 %16, i64* %_132, align 8
  %_138.us = icmp eq i64 %16, 0
  br i1 %_138.us, label %bb24.us, label %bb25

bb24.us:                                          ; preds = %bb17.us
  call void @llvm.lifetime.end.p0i8(i64 8, i8* nonnull %12)
  br label %bb36.us

bb36.us:                                          ; preds = %bb36.us, %bb24.us
  %iter1.sroa.0.064.us = phi i64 [ 0, %bb24.us ], [ %17, %bb36.us ]
  %17 = add nuw nsw i64 %iter1.sroa.0.064.us, 1
  %_194.us = shl i64 %iter1.sroa.0.064.us, 2
  %_192.us = add i64 %_194.us, %src.us
  %_191.us = trunc i64 %_192.us to i32
  %tmp.us = tail call i32 @banshee_load(i8* %cpu, i32 %_191.us, i8 zeroext 2)
  %_199.us = add i64 %_194.us, %dst.us
  %_198.us = trunc i64 %_199.us to i32
  tail call void @banshee_store(i8* %cpu, i32 %_198.us, i32 %tmp.us, i8 zeroext 2)
  %exitcond = icmp eq i64 %17, %_178
  br i1 %exitcond, label %bb32.bb12.loopexit_crit_edge.us, label %bb36.us

bb32.bb12.loopexit_crit_edge.us:                  ; preds = %bb36.us
  %exitcond69 = icmp eq i64 %14, %steps.0
  br i1 %exitcond69, label %bb14, label %bb16.us

bb2:                                              ; preds = %start
  %18 = bitcast %"core::fmt::Arguments"* %_18 to i8*
  call void @llvm.lifetime.start.p0i8(i64 48, i8* nonnull %18)
  %19 = bitcast [3 x { i8*, i8* }]* %_25 to i8*
  call void @llvm.lifetime.start.p0i8(i64 48, i8* nonnull %19)
  %20 = bitcast i32** %_28 to i8*
  call void @llvm.lifetime.start.p0i8(i64 8, i8* nonnull %20)
  store i32* %_7, i32** %_28, align 8
  %21 = bitcast i32** %_30 to i8*
  call void @llvm.lifetime.start.p0i8(i64 8, i8* nonnull %21)
  store i32* bitcast (<{ [4 x i8] }>* @alloc36 to i32*), i32** %_30, align 8
  %22 = bitcast %"core::fmt::Arguments"* %_32 to i8*
  call void @llvm.lifetime.start.p0i8(i64 48, i8* nonnull %22)
  %23 = bitcast %"core::fmt::Arguments"* %_32 to [0 x { [0 x i8]*, i64 }]**
  store [0 x { [0 x i8]*, i64 }]* bitcast (<{ i8*, [8 x i8] }>* @alloc48 to [0 x { [0 x i8]*, i64 }]*), [0 x { [0 x i8]*, i64 }]** %23, align 8, !alias.scope !10, !noalias !13
  %24 = getelementptr inbounds %"core::fmt::Arguments", %"core::fmt::Arguments"* %_32, i64 0, i32 1, i32 1
  store i64 1, i64* %24, align 8, !alias.scope !10, !noalias !13
  %25 = getelementptr inbounds %"core::fmt::Arguments", %"core::fmt::Arguments"* %_32, i64 0, i32 3, i32 0
  store i64* null, i64** %25, align 8, !alias.scope !10, !noalias !13
  %26 = getelementptr inbounds %"core::fmt::Arguments", %"core::fmt::Arguments"* %_32, i64 0, i32 5, i32 0
  store [0 x { i8*, i8* }]* bitcast (<{ [0 x i8] }>* @alloc99 to [0 x { i8*, i8* }]*), [0 x { i8*, i8* }]** %26, align 8, !alias.scope !10, !noalias !13
  %27 = getelementptr inbounds %"core::fmt::Arguments", %"core::fmt::Arguments"* %_32, i64 0, i32 5, i32 1
  store i64 0, i64* %27, align 8, !alias.scope !10, !noalias !13
  %28 = bitcast [3 x { i8*, i8* }]* %_25 to i32***
  store i32** %_28, i32*** %28, align 8
  %29 = getelementptr inbounds [3 x { i8*, i8* }], [3 x { i8*, i8* }]* %_25, i64 0, i64 0, i32 1
  store i8* bitcast (i1 (i32**, %"core::fmt::Formatter"*)* @"_ZN42_$LT$$RF$T$u20$as$u20$core..fmt..Debug$GT$3fmt17h239ce14a0c38695eE" to i8*), i8** %29, align 8
  %30 = getelementptr inbounds [3 x { i8*, i8* }], [3 x { i8*, i8* }]* %_25, i64 0, i64 1, i32 0
  %31 = bitcast i8** %30 to i32***
  store i32** %_30, i32*** %31, align 8
  %32 = getelementptr inbounds [3 x { i8*, i8* }], [3 x { i8*, i8* }]* %_25, i64 0, i64 1, i32 1
  store i8* bitcast (i1 (i32**, %"core::fmt::Formatter"*)* @"_ZN42_$LT$$RF$T$u20$as$u20$core..fmt..Debug$GT$3fmt17h239ce14a0c38695eE" to i8*), i8** %32, align 8
  %33 = getelementptr inbounds [3 x { i8*, i8* }], [3 x { i8*, i8* }]* %_25, i64 0, i64 2, i32 0
  %34 = bitcast i8** %33 to %"core::fmt::Arguments"**
  store %"core::fmt::Arguments"* %_32, %"core::fmt::Arguments"** %34, align 8
  %35 = getelementptr inbounds [3 x { i8*, i8* }], [3 x { i8*, i8* }]* %_25, i64 0, i64 2, i32 1
  store i8* bitcast (i1 (%"core::fmt::Arguments"*, %"core::fmt::Formatter"*)* @"_ZN59_$LT$core..fmt..Arguments$u20$as$u20$core..fmt..Display$GT$3fmt17h19cd578fd598a921E" to i8*), i8** %35, align 8
  %36 = bitcast %"core::fmt::Arguments"* %_18 to [0 x { [0 x i8]*, i64 }]**
  store [0 x { [0 x i8]*, i64 }]* bitcast (<{ i8*, [8 x i8], i8*, [8 x i8], i8*, [8 x i8] }>* @alloc90 to [0 x { [0 x i8]*, i64 }]*), [0 x { [0 x i8]*, i64 }]** %36, align 8, !alias.scope !16, !noalias !19
  %37 = getelementptr inbounds %"core::fmt::Arguments", %"core::fmt::Arguments"* %_18, i64 0, i32 1, i32 1
  store i64 3, i64* %37, align 8, !alias.scope !16, !noalias !19
  %38 = getelementptr inbounds %"core::fmt::Arguments", %"core::fmt::Arguments"* %_18, i64 0, i32 3, i32 0
  store i64* null, i64** %38, align 8, !alias.scope !16, !noalias !19
  %39 = getelementptr inbounds %"core::fmt::Arguments", %"core::fmt::Arguments"* %_18, i64 0, i32 5, i32 0
  %40 = bitcast [0 x { i8*, i8* }]** %39 to [3 x { i8*, i8* }]**
  store [3 x { i8*, i8* }]* %_25, [3 x { i8*, i8* }]** %40, align 8, !alias.scope !16, !noalias !19
  %41 = getelementptr inbounds %"core::fmt::Arguments", %"core::fmt::Arguments"* %_18, i64 0, i32 5, i32 1
  store i64 3, i64* %41, align 8, !alias.scope !16, !noalias !19
; call std::panicking::begin_panic_fmt
  call void @_ZN3std9panicking15begin_panic_fmt17h905a6d44880d49efE(%"core::fmt::Arguments"* noalias nonnull readonly align 8 dereferenceable(48) %_18, %"core::panic::Location"* noalias readonly align 8 dereferenceable(24) bitcast (<{ i8*, [16 x i8] }>* @alloc123 to %"core::panic::Location"*))
  unreachable

bb14:                                             ; preds = %bb32.bb12.loopexit_crit_edge.us, %bb24, %bb1
  ret i32 %id

bb16:                                             ; preds = %bb24, %bb16.preheader
  %iter.sroa.0.065 = phi i64 [ %42, %bb24 ], [ 0, %bb16.preheader ]
  %42 = add nuw nsw i64 %iter.sroa.0.065, 1
  %_74 = mul i64 %iter.sroa.0.065, %_76
  %src = add i64 %_74, %_73.pre
  call void @llvm.lifetime.start.p0i8(i64 8, i8* nonnull %11)
  %43 = and i64 %src, 3
  store i64 %43, i64* %_86, align 8
  %_92 = icmp eq i64 %43, 0
  br i1 %_92, label %bb17, label %bb18

bb17:                                             ; preds = %bb16
  %_80 = mul i64 %iter.sroa.0.065, %_82
  %dst = add i64 %_80, %_79.pre
  call void @llvm.lifetime.end.p0i8(i64 8, i8* nonnull %11)
  call void @llvm.lifetime.start.p0i8(i64 8, i8* nonnull %12)
  %44 = and i64 %dst, 3
  store i64 %44, i64* %_132, align 8
  %_138 = icmp eq i64 %44, 0
  br i1 %_138, label %bb24, label %bb25

bb18:                                             ; preds = %bb16.us, %bb16
  %45 = bitcast %"core::fmt::Arguments"* %_97 to i8*
  call void @llvm.lifetime.start.p0i8(i64 48, i8* nonnull %45)
  %46 = bitcast [3 x { i8*, i8* }]* %_104 to i8*
  call void @llvm.lifetime.start.p0i8(i64 48, i8* nonnull %46)
  %47 = bitcast i64** %_107 to i8*
  call void @llvm.lifetime.start.p0i8(i64 8, i8* nonnull %47)
  store i64* %_86, i64** %_107, align 8
  %48 = bitcast i64** %_109 to i8*
  call void @llvm.lifetime.start.p0i8(i64 8, i8* nonnull %48)
  store i64* bitcast (<{ [8 x i8] }>* @alloc82 to i64*), i64** %_109, align 8
  %49 = bitcast %"core::fmt::Arguments"* %_111 to i8*
  call void @llvm.lifetime.start.p0i8(i64 48, i8* nonnull %49)
  %50 = bitcast %"core::fmt::Arguments"* %_111 to [0 x { [0 x i8]*, i64 }]**
  store [0 x { [0 x i8]*, i64 }]* bitcast (<{ i8*, [8 x i8] }>* @alloc72 to [0 x { [0 x i8]*, i64 }]*), [0 x { [0 x i8]*, i64 }]** %50, align 8, !alias.scope !22, !noalias !25
  %51 = getelementptr inbounds %"core::fmt::Arguments", %"core::fmt::Arguments"* %_111, i64 0, i32 1, i32 1
  store i64 1, i64* %51, align 8, !alias.scope !22, !noalias !25
  %52 = getelementptr inbounds %"core::fmt::Arguments", %"core::fmt::Arguments"* %_111, i64 0, i32 3, i32 0
  store i64* null, i64** %52, align 8, !alias.scope !22, !noalias !25
  %53 = getelementptr inbounds %"core::fmt::Arguments", %"core::fmt::Arguments"* %_111, i64 0, i32 5, i32 0
  store [0 x { i8*, i8* }]* bitcast (<{ [0 x i8] }>* @alloc99 to [0 x { i8*, i8* }]*), [0 x { i8*, i8* }]** %53, align 8, !alias.scope !22, !noalias !25
  %54 = getelementptr inbounds %"core::fmt::Arguments", %"core::fmt::Arguments"* %_111, i64 0, i32 5, i32 1
  store i64 0, i64* %54, align 8, !alias.scope !22, !noalias !25
  %55 = bitcast [3 x { i8*, i8* }]* %_104 to i64***
  store i64** %_107, i64*** %55, align 8
  %56 = getelementptr inbounds [3 x { i8*, i8* }], [3 x { i8*, i8* }]* %_104, i64 0, i64 0, i32 1
  store i8* bitcast (i1 (i64**, %"core::fmt::Formatter"*)* @"_ZN42_$LT$$RF$T$u20$as$u20$core..fmt..Debug$GT$3fmt17hc117f9fdf259cc83E" to i8*), i8** %56, align 8
  %57 = getelementptr inbounds [3 x { i8*, i8* }], [3 x { i8*, i8* }]* %_104, i64 0, i64 1, i32 0
  %58 = bitcast i8** %57 to i64***
  store i64** %_109, i64*** %58, align 8
  %59 = getelementptr inbounds [3 x { i8*, i8* }], [3 x { i8*, i8* }]* %_104, i64 0, i64 1, i32 1
  store i8* bitcast (i1 (i64**, %"core::fmt::Formatter"*)* @"_ZN42_$LT$$RF$T$u20$as$u20$core..fmt..Debug$GT$3fmt17hc117f9fdf259cc83E" to i8*), i8** %59, align 8
  %60 = getelementptr inbounds [3 x { i8*, i8* }], [3 x { i8*, i8* }]* %_104, i64 0, i64 2, i32 0
  %61 = bitcast i8** %60 to %"core::fmt::Arguments"**
  store %"core::fmt::Arguments"* %_111, %"core::fmt::Arguments"** %61, align 8
  %62 = getelementptr inbounds [3 x { i8*, i8* }], [3 x { i8*, i8* }]* %_104, i64 0, i64 2, i32 1
  store i8* bitcast (i1 (%"core::fmt::Arguments"*, %"core::fmt::Formatter"*)* @"_ZN59_$LT$core..fmt..Arguments$u20$as$u20$core..fmt..Display$GT$3fmt17h19cd578fd598a921E" to i8*), i8** %62, align 8
  %63 = bitcast %"core::fmt::Arguments"* %_97 to [0 x { [0 x i8]*, i64 }]**
  store [0 x { [0 x i8]*, i64 }]* bitcast (<{ i8*, [8 x i8], i8*, [8 x i8], i8*, [8 x i8] }>* @alloc90 to [0 x { [0 x i8]*, i64 }]*), [0 x { [0 x i8]*, i64 }]** %63, align 8, !alias.scope !28, !noalias !31
  %64 = getelementptr inbounds %"core::fmt::Arguments", %"core::fmt::Arguments"* %_97, i64 0, i32 1, i32 1
  store i64 3, i64* %64, align 8, !alias.scope !28, !noalias !31
  %65 = getelementptr inbounds %"core::fmt::Arguments", %"core::fmt::Arguments"* %_97, i64 0, i32 3, i32 0
  store i64* null, i64** %65, align 8, !alias.scope !28, !noalias !31
  %66 = getelementptr inbounds %"core::fmt::Arguments", %"core::fmt::Arguments"* %_97, i64 0, i32 5, i32 0
  %67 = bitcast [0 x { i8*, i8* }]** %66 to [3 x { i8*, i8* }]**
  store [3 x { i8*, i8* }]* %_104, [3 x { i8*, i8* }]** %67, align 8, !alias.scope !28, !noalias !31
  %68 = getelementptr inbounds %"core::fmt::Arguments", %"core::fmt::Arguments"* %_97, i64 0, i32 5, i32 1
  store i64 3, i64* %68, align 8, !alias.scope !28, !noalias !31
; call std::panicking::begin_panic_fmt
  call void @_ZN3std9panicking15begin_panic_fmt17h905a6d44880d49efE(%"core::fmt::Arguments"* noalias nonnull readonly align 8 dereferenceable(48) %_97, %"core::panic::Location"* noalias readonly align 8 dereferenceable(24) bitcast (<{ i8*, [16 x i8] }>* @alloc125 to %"core::panic::Location"*))
  unreachable

bb24:                                             ; preds = %bb17
  call void @llvm.lifetime.end.p0i8(i64 8, i8* nonnull %12)
  %exitcond70 = icmp eq i64 %42, %steps.0
  br i1 %exitcond70, label %bb14, label %bb16

bb25:                                             ; preds = %bb17.us, %bb17
  %69 = bitcast %"core::fmt::Arguments"* %_143 to i8*
  call void @llvm.lifetime.start.p0i8(i64 48, i8* nonnull %69)
  %70 = bitcast [3 x { i8*, i8* }]* %_150 to i8*
  call void @llvm.lifetime.start.p0i8(i64 48, i8* nonnull %70)
  %71 = bitcast i64** %_153 to i8*
  call void @llvm.lifetime.start.p0i8(i64 8, i8* nonnull %71)
  store i64* %_132, i64** %_153, align 8
  %72 = bitcast i64** %_155 to i8*
  call void @llvm.lifetime.start.p0i8(i64 8, i8* nonnull %72)
  store i64* bitcast (<{ [8 x i8] }>* @alloc82 to i64*), i64** %_155, align 8
  %73 = bitcast %"core::fmt::Arguments"* %_157 to i8*
  call void @llvm.lifetime.start.p0i8(i64 48, i8* nonnull %73)
  %74 = bitcast %"core::fmt::Arguments"* %_157 to [0 x { [0 x i8]*, i64 }]**
  store [0 x { [0 x i8]*, i64 }]* bitcast (<{ i8*, [8 x i8] }>* @alloc95 to [0 x { [0 x i8]*, i64 }]*), [0 x { [0 x i8]*, i64 }]** %74, align 8, !alias.scope !34, !noalias !37
  %75 = getelementptr inbounds %"core::fmt::Arguments", %"core::fmt::Arguments"* %_157, i64 0, i32 1, i32 1
  store i64 1, i64* %75, align 8, !alias.scope !34, !noalias !37
  %76 = getelementptr inbounds %"core::fmt::Arguments", %"core::fmt::Arguments"* %_157, i64 0, i32 3, i32 0
  store i64* null, i64** %76, align 8, !alias.scope !34, !noalias !37
  %77 = getelementptr inbounds %"core::fmt::Arguments", %"core::fmt::Arguments"* %_157, i64 0, i32 5, i32 0
  store [0 x { i8*, i8* }]* bitcast (<{ [0 x i8] }>* @alloc99 to [0 x { i8*, i8* }]*), [0 x { i8*, i8* }]** %77, align 8, !alias.scope !34, !noalias !37
  %78 = getelementptr inbounds %"core::fmt::Arguments", %"core::fmt::Arguments"* %_157, i64 0, i32 5, i32 1
  store i64 0, i64* %78, align 8, !alias.scope !34, !noalias !37
  %79 = bitcast [3 x { i8*, i8* }]* %_150 to i64***
  store i64** %_153, i64*** %79, align 8
  %80 = getelementptr inbounds [3 x { i8*, i8* }], [3 x { i8*, i8* }]* %_150, i64 0, i64 0, i32 1
  store i8* bitcast (i1 (i64**, %"core::fmt::Formatter"*)* @"_ZN42_$LT$$RF$T$u20$as$u20$core..fmt..Debug$GT$3fmt17hc117f9fdf259cc83E" to i8*), i8** %80, align 8
  %81 = getelementptr inbounds [3 x { i8*, i8* }], [3 x { i8*, i8* }]* %_150, i64 0, i64 1, i32 0
  %82 = bitcast i8** %81 to i64***
  store i64** %_155, i64*** %82, align 8
  %83 = getelementptr inbounds [3 x { i8*, i8* }], [3 x { i8*, i8* }]* %_150, i64 0, i64 1, i32 1
  store i8* bitcast (i1 (i64**, %"core::fmt::Formatter"*)* @"_ZN42_$LT$$RF$T$u20$as$u20$core..fmt..Debug$GT$3fmt17hc117f9fdf259cc83E" to i8*), i8** %83, align 8
  %84 = getelementptr inbounds [3 x { i8*, i8* }], [3 x { i8*, i8* }]* %_150, i64 0, i64 2, i32 0
  %85 = bitcast i8** %84 to %"core::fmt::Arguments"**
  store %"core::fmt::Arguments"* %_157, %"core::fmt::Arguments"** %85, align 8
  %86 = getelementptr inbounds [3 x { i8*, i8* }], [3 x { i8*, i8* }]* %_150, i64 0, i64 2, i32 1
  store i8* bitcast (i1 (%"core::fmt::Arguments"*, %"core::fmt::Formatter"*)* @"_ZN59_$LT$core..fmt..Arguments$u20$as$u20$core..fmt..Display$GT$3fmt17h19cd578fd598a921E" to i8*), i8** %86, align 8
  %87 = bitcast %"core::fmt::Arguments"* %_143 to [0 x { [0 x i8]*, i64 }]**
  store [0 x { [0 x i8]*, i64 }]* bitcast (<{ i8*, [8 x i8], i8*, [8 x i8], i8*, [8 x i8] }>* @alloc90 to [0 x { [0 x i8]*, i64 }]*), [0 x { [0 x i8]*, i64 }]** %87, align 8, !alias.scope !40, !noalias !43
  %88 = getelementptr inbounds %"core::fmt::Arguments", %"core::fmt::Arguments"* %_143, i64 0, i32 1, i32 1
  store i64 3, i64* %88, align 8, !alias.scope !40, !noalias !43
  %89 = getelementptr inbounds %"core::fmt::Arguments", %"core::fmt::Arguments"* %_143, i64 0, i32 3, i32 0
  store i64* null, i64** %89, align 8, !alias.scope !40, !noalias !43
  %90 = getelementptr inbounds %"core::fmt::Arguments", %"core::fmt::Arguments"* %_143, i64 0, i32 5, i32 0
  %91 = bitcast [0 x { i8*, i8* }]** %90 to [3 x { i8*, i8* }]**
  store [3 x { i8*, i8* }]* %_150, [3 x { i8*, i8* }]** %91, align 8, !alias.scope !40, !noalias !43
  %92 = getelementptr inbounds %"core::fmt::Arguments", %"core::fmt::Arguments"* %_143, i64 0, i32 5, i32 1
  store i64 3, i64* %92, align 8, !alias.scope !40, !noalias !43
; call std::panicking::begin_panic_fmt
  call void @_ZN3std9panicking15begin_panic_fmt17h905a6d44880d49efE(%"core::fmt::Arguments"* noalias nonnull readonly align 8 dereferenceable(48) %_143, %"core::panic::Location"* noalias readonly align 8 dereferenceable(24) bitcast (<{ i8*, [16 x i8] }>* @alloc127 to %"core::panic::Location"*))
  unreachable
}

; Function Attrs: norecurse nounwind nonlazybind readonly
define i32 @banshee_dma_stat(%DmaState* noalias nocapture readonly align 8 dereferenceable(32) %dma, i32 %addr) unnamed_addr #2 {
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
  %0 = getelementptr inbounds %DmaState, %DmaState* %dma, i64 0, i32 11
  %1 = load i32, i32* %0, align 4
  br label %bb5

bb3:                                              ; preds = %start
  %2 = getelementptr inbounds %DmaState, %DmaState* %dma, i64 0, i32 11
  %_5 = load i32, i32* %2, align 4
  %3 = add i32 %_5, 1
  br label %bb5

bb5:                                              ; preds = %start, %start, %bb2, %bb3
  %.0 = phi i32 [ %3, %bb3 ], [ %1, %bb2 ], [ 0, %start ], [ 0, %start ]
  ret i32 %.0
}

; Function Attrs: argmemonly nounwind willreturn
declare void @llvm.lifetime.start.p0i8(i64 immarg, i8* nocapture) #3

; Function Attrs: argmemonly nounwind willreturn
declare void @llvm.lifetime.end.p0i8(i64 immarg, i8* nocapture) #3

; core::fmt::Formatter::debug_lower_hex
; Function Attrs: nounwind nonlazybind
declare zeroext i1 @_ZN4core3fmt9Formatter15debug_lower_hex17h0f758bf74de7e467E(%"core::fmt::Formatter"* noalias readonly align 8 dereferenceable(64)) unnamed_addr #0

; core::fmt::num::<impl core::fmt::LowerHex for u32>::fmt
; Function Attrs: nounwind nonlazybind
declare zeroext i1 @"_ZN4core3fmt3num53_$LT$impl$u20$core..fmt..LowerHex$u20$for$u20$u32$GT$3fmt17hfce767795847c2acE"(i32* noalias readonly align 4 dereferenceable(4), %"core::fmt::Formatter"* align 8 dereferenceable(64)) unnamed_addr #0

; core::fmt::Formatter::debug_upper_hex
; Function Attrs: nounwind nonlazybind
declare zeroext i1 @_ZN4core3fmt9Formatter15debug_upper_hex17hcb8ddb31a324fd72E(%"core::fmt::Formatter"* noalias readonly align 8 dereferenceable(64)) unnamed_addr #0

; core::fmt::num::<impl core::fmt::UpperHex for u32>::fmt
; Function Attrs: nounwind nonlazybind
declare zeroext i1 @"_ZN4core3fmt3num53_$LT$impl$u20$core..fmt..UpperHex$u20$for$u20$u32$GT$3fmt17hc2f65734cb045febE"(i32* noalias readonly align 4 dereferenceable(4), %"core::fmt::Formatter"* align 8 dereferenceable(64)) unnamed_addr #0

; core::fmt::num::imp::<impl core::fmt::Display for u32>::fmt
; Function Attrs: nounwind nonlazybind
declare zeroext i1 @"_ZN4core3fmt3num3imp52_$LT$impl$u20$core..fmt..Display$u20$for$u20$u32$GT$3fmt17h43c98606ce80fde1E"(i32* noalias readonly align 4 dereferenceable(4), %"core::fmt::Formatter"* align 8 dereferenceable(64)) unnamed_addr #0

; core::fmt::num::<impl core::fmt::LowerHex for u64>::fmt
; Function Attrs: nounwind nonlazybind
declare zeroext i1 @"_ZN4core3fmt3num53_$LT$impl$u20$core..fmt..LowerHex$u20$for$u20$u64$GT$3fmt17h8377eae1154d58afE"(i64* noalias readonly align 8 dereferenceable(8), %"core::fmt::Formatter"* align 8 dereferenceable(64)) unnamed_addr #0

; core::fmt::num::<impl core::fmt::UpperHex for u64>::fmt
; Function Attrs: nounwind nonlazybind
declare zeroext i1 @"_ZN4core3fmt3num53_$LT$impl$u20$core..fmt..UpperHex$u20$for$u20$u64$GT$3fmt17ha39b2ba18f51b7c9E"(i64* noalias readonly align 8 dereferenceable(8), %"core::fmt::Formatter"* align 8 dereferenceable(64)) unnamed_addr #0

; core::fmt::num::imp::<impl core::fmt::Display for u64>::fmt
; Function Attrs: nounwind nonlazybind
declare zeroext i1 @"_ZN4core3fmt3num3imp52_$LT$impl$u20$core..fmt..Display$u20$for$u20$u64$GT$3fmt17hf7050dcb5cce3380E"(i64* noalias readonly align 8 dereferenceable(8), %"core::fmt::Formatter"* align 8 dereferenceable(64)) unnamed_addr #0

; Function Attrs: nounwind nonlazybind
declare i32 @rust_eh_personality(i32, i32, i64, %"unwind::libunwind::_Unwind_Exception"*, %"unwind::libunwind::_Unwind_Context"*) unnamed_addr #0

; <core::fmt::Arguments as core::fmt::Display>::fmt
; Function Attrs: nounwind nonlazybind
declare zeroext i1 @"_ZN59_$LT$core..fmt..Arguments$u20$as$u20$core..fmt..Display$GT$3fmt17h19cd578fd598a921E"(%"core::fmt::Arguments"* noalias readonly align 8 dereferenceable(48), %"core::fmt::Formatter"* align 8 dereferenceable(64)) unnamed_addr #0

; std::panicking::begin_panic_fmt
; Function Attrs: cold noinline noreturn nounwind nonlazybind
declare void @_ZN3std9panicking15begin_panic_fmt17h905a6d44880d49efE(%"core::fmt::Arguments"* noalias readonly align 8 dereferenceable(48), %"core::panic::Location"* noalias readonly align 8 dereferenceable(24)) unnamed_addr #4

; Function Attrs: nounwind nonlazybind
declare i32 @banshee_load(i8*, i32, i8 zeroext) unnamed_addr #0

; Function Attrs: nounwind nonlazybind
declare void @banshee_store(i8*, i32, i32, i8 zeroext) unnamed_addr #0

attributes #0 = { nounwind nonlazybind "probe-stack"="__rust_probestack" "target-cpu"="x86-64" }
attributes #1 = { nofree norecurse nounwind nonlazybind writeonly "probe-stack"="__rust_probestack" "target-cpu"="x86-64" }
attributes #2 = { norecurse nounwind nonlazybind readonly "probe-stack"="__rust_probestack" "target-cpu"="x86-64" }
attributes #3 = { argmemonly nounwind willreturn }
attributes #4 = { cold noinline noreturn nounwind nonlazybind "probe-stack"="__rust_probestack" "target-cpu"="x86-64" }
attributes #5 = { nounwind }

!llvm.module.flags = !{!0, !1}

!0 = !{i32 7, !"PIC Level", i32 2}
!1 = !{i32 2, !"RtLibUseGOT", i32 1}
!2 = !{}
!3 = !{!4}
!4 = distinct !{!4, !5, !"_ZN4core3fmt3num50_$LT$impl$u20$core..fmt..Debug$u20$for$u20$u32$GT$3fmt17h6238c6625c3bbc68E: %self"}
!5 = distinct !{!5, !"_ZN4core3fmt3num50_$LT$impl$u20$core..fmt..Debug$u20$for$u20$u32$GT$3fmt17h6238c6625c3bbc68E"}
!6 = !{!7}
!7 = distinct !{!7, !8, !"_ZN4core3fmt3num50_$LT$impl$u20$core..fmt..Debug$u20$for$u20$u64$GT$3fmt17h3b33b895b17bfaadE: %self"}
!8 = distinct !{!8, !"_ZN4core3fmt3num50_$LT$impl$u20$core..fmt..Debug$u20$for$u20$u64$GT$3fmt17h3b33b895b17bfaadE"}
!9 = !{i8 0, i8 2}
!10 = !{!11}
!11 = distinct !{!11, !12, !"_ZN4core3fmt9Arguments6new_v117hb9f6139eb96b49ddE: argument 0"}
!12 = distinct !{!12, !"_ZN4core3fmt9Arguments6new_v117hb9f6139eb96b49ddE"}
!13 = !{!14, !15}
!14 = distinct !{!14, !12, !"_ZN4core3fmt9Arguments6new_v117hb9f6139eb96b49ddE: %pieces.0"}
!15 = distinct !{!15, !12, !"_ZN4core3fmt9Arguments6new_v117hb9f6139eb96b49ddE: %args.0"}
!16 = !{!17}
!17 = distinct !{!17, !18, !"_ZN4core3fmt9Arguments6new_v117hb9f6139eb96b49ddE: argument 0"}
!18 = distinct !{!18, !"_ZN4core3fmt9Arguments6new_v117hb9f6139eb96b49ddE"}
!19 = !{!20, !21}
!20 = distinct !{!20, !18, !"_ZN4core3fmt9Arguments6new_v117hb9f6139eb96b49ddE: %pieces.0"}
!21 = distinct !{!21, !18, !"_ZN4core3fmt9Arguments6new_v117hb9f6139eb96b49ddE: %args.0"}
!22 = !{!23}
!23 = distinct !{!23, !24, !"_ZN4core3fmt9Arguments6new_v117hb9f6139eb96b49ddE: argument 0"}
!24 = distinct !{!24, !"_ZN4core3fmt9Arguments6new_v117hb9f6139eb96b49ddE"}
!25 = !{!26, !27}
!26 = distinct !{!26, !24, !"_ZN4core3fmt9Arguments6new_v117hb9f6139eb96b49ddE: %pieces.0"}
!27 = distinct !{!27, !24, !"_ZN4core3fmt9Arguments6new_v117hb9f6139eb96b49ddE: %args.0"}
!28 = !{!29}
!29 = distinct !{!29, !30, !"_ZN4core3fmt9Arguments6new_v117hb9f6139eb96b49ddE: argument 0"}
!30 = distinct !{!30, !"_ZN4core3fmt9Arguments6new_v117hb9f6139eb96b49ddE"}
!31 = !{!32, !33}
!32 = distinct !{!32, !30, !"_ZN4core3fmt9Arguments6new_v117hb9f6139eb96b49ddE: %pieces.0"}
!33 = distinct !{!33, !30, !"_ZN4core3fmt9Arguments6new_v117hb9f6139eb96b49ddE: %args.0"}
!34 = !{!35}
!35 = distinct !{!35, !36, !"_ZN4core3fmt9Arguments6new_v117hb9f6139eb96b49ddE: argument 0"}
!36 = distinct !{!36, !"_ZN4core3fmt9Arguments6new_v117hb9f6139eb96b49ddE"}
!37 = !{!38, !39}
!38 = distinct !{!38, !36, !"_ZN4core3fmt9Arguments6new_v117hb9f6139eb96b49ddE: %pieces.0"}
!39 = distinct !{!39, !36, !"_ZN4core3fmt9Arguments6new_v117hb9f6139eb96b49ddE: %args.0"}
!40 = !{!41}
!41 = distinct !{!41, !42, !"_ZN4core3fmt9Arguments6new_v117hb9f6139eb96b49ddE: argument 0"}
!42 = distinct !{!42, !"_ZN4core3fmt9Arguments6new_v117hb9f6139eb96b49ddE"}
!43 = !{!44, !45}
!44 = distinct !{!44, !42, !"_ZN4core3fmt9Arguments6new_v117hb9f6139eb96b49ddE: %pieces.0"}
!45 = distinct !{!45, !42, !"_ZN4core3fmt9Arguments6new_v117hb9f6139eb96b49ddE: %args.0"}
