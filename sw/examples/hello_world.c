#include "stdint.h"
#include "../snRuntime/include/snrt.h"

static void populate(int *ptr, uint32_t size, uint32_t seed) {
    for (uint32_t i = 0; i < size; i++) {
        *ptr = (int)seed * 3;
        ++ptr;
        ++seed;
    }
}

enum {
    REG_STATUS = 0,
    REG_REPEAT = 1,
    REG_BOUNDS = 2,   // + loop index
    REG_STRIDES = 6,  // + loop index
    REG_RPTR = 24,    // + snrt_ssr_dim
    REG_WPTR = 28,    // + snrt_ssr_dim
};

// Configure an SSR data mover for a 1D loop nest.
void issr_loop_1d(enum snrt_ssr_dm dm, size_t b0, size_t i0) {
    --b0;
    write_issr_cfg(REG_BOUNDS + 0, dm, b0);
    size_t a = 0;
    write_issr_cfg(REG_STRIDES + 0, dm, i0 - a);
    a += i0 * b0;
}
void write_issr_cfg(uint32_t reg, uint32_t dm, uint32_t value) {
    register volatile uint32_t t0 asm("t0") = reg << 5 | dm;
    register volatile uint32_t t1 asm("t1") = value;
    // scfgw t1, t0
    asm volatile(
        ".word (0b0000000 << 25) | \
               (      (5) << 20) | \
               (      (6) << 15) | \
               (    0b010 << 12) | \
               (  0b00001 <<  7) | \
               (0b0101011 <<  0)   \n" ::"r"(t0),
        "r"(t1));
}
/// Start a streaming read.
void issr_read(enum snrt_ssr_dm dm, enum snrt_ssr_dim dim,
                   volatile void *ptr) {
    write_issr_cfg(REG_RPTR + dim, dm, (uintptr_t)ptr);
}

void issr_write(enum snrt_ssr_dm dm, enum snrt_ssr_dim dim,
                    volatile void *ptr) {
    write_issr_cfg(REG_WPTR + dim, dm, (uintptr_t)ptr);
}
void issr_repeat(enum snrt_ssr_dm dm, size_t count) {
    write_issr_cfg(REG_REPEAT, dm, count - 1);
}


int main()
{ 
  uint32_t A[16] = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16};
  uint32_t B[16] = {16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1};

  size_t core_id = snrt_cluster_compute_core_idx();
  size_t core_num = snrt_cluster_compute_core_num();

  if (core_id % core_num == 0)
  {
  register volatile int t0 asm ("t0");
  register volatile int t1 asm ("t1");
  register volatile int t2 asm ("t2");
  issr_loop_1d(SNRT_SSR_DM0, 16, 4);
  issr_loop_1d(SNRT_SSR_DM1, 16, 4);
  //issr_loop_1d(SNRT_SSR_DM2, 16, 8);
  issr_read(SNRT_SSR_DM0, SNRT_SSR_1D, A);
  issr_read(SNRT_SSR_DM1, SNRT_SSR_1D, B);
  //issr_write(SNRT_SSR_DM2, SNRT_SSR_1D, t2);
  /* robustness test 1 */
  /*
  asm volatile ("csrsi 0x7C2, 1");
  asm volatile ("csrci 0x7C2, 1");
  asm volatile ("csrsi 0x7C0, 1");
  asm volatile ("csrci 0x7C0, 1");
  /* robusteness test 2*/
  /*
  asm volatile ("csrsi 0x7C0, 1");
  asm volatile ("csrci 0x7C0, 1");
  asm volatile ("csrsi 0x7C2, 1");
  asm volatile ("csrci 0x7C2, 1");
  /* robustness test 3*/
  /*
  asm volatile("csrsi 0x7C2, 1");
  asm volatile("csrsi 0x7C0, 1");*/
  /* robustness test 4*/
  /*asm volatile("csrsi 0x7C0, 1");
  asm volatile("csrsi 0x7C2, 1");*/
 
  asm volatile ("csrsi 0x7C2, 1");
  for(uint32_t i=0; i<16; i++)
  {
      __asm__ volatile (
                        "add t2, t0, t1\n"
            
                        :"=r"(t2)
                        :"r"(t1),"r"(t0)
                        );
    
   }
   __asm__ volatile ("csrci 0x7C2, 1");
    }
  return 0;
  
  /* ISSR write test */
  /*
  register volatile int t0 asm ("t0");
  register volatile int t1 asm ("t1");
  register volatile int t2 asm ("t2");
  issr_loop_1d(SNRT_SSR_DM0, 16, 16);
  issr_loop_1d(SNRT_SSR_DM1, 16, 16);
  issr_loop_1d(SNRT_SSR_DM2, 16, 16);
  issr_read(SNRT_SSR_DM0, SNRT_SSR_1D, A);
  issr_read(SNRT_SSR_DM1, SNRT_SSR_1D, B);
  issr_write(SNRT_SSR_DM2, SNRT_SSR_1D, t2);
  asm volatile ("csrsi 0x7C2, 1");

  for(uint32_t i=0; i<16; i++)
    {
      __asm__ volatile (
                        "add t2, t0, t1\n"
            
                        :"=r"(t2)
                        :"r"(t1),"r"(t0)
                        );
    
       }                  

  __asm__ volatile ("csrci 0x7C2, 1");
  return 0;
  */
  /* ISSR write test ends */
  /* ISSR read test */
  /*
  register volatile int t0 asm ("t0");
  register volatile int t1 asm ("t1");
  issr_loop_1d(SNRT_SSR_DM0, 16, 8);
  issr_loop_1d(SNRT_SSR_DM1, 16, 8);
  issr_read(SNRT_SSR_DM0, SNRT_SSR_1D, A);
  issr_read(SNRT_SSR_DM1, SNRT_SSR_1D, B);
  asm volatile ("csrsi 0x7C2, 1");

  register volatile int t2 asm ("t2");

  for(uint32_t i=0; i<16; i++)
    {
      __asm__ volatile (
                        "add t2, t0, t1\n"
            
                        :"=r"(t2)
                        :"r"(t1),"r"(t0)
                        );
       }                  

  __asm__ volatile ("csrci 0x7C2, 1");
  return 0;
  */
  /* ISSR read test end */
   
  /*
  __asm__ volatile(
                   ".word 0x00400793\n\t" // li a5, 4
                   ".word 0x0047878b\n\t" // p.lb a5, 4(a5!)
                   );
  
  __asm__ volatile(
                   ".word 0x123457b7\n\t" //          	lui	a5,0x12345
                   ".word 0x08030737\n\t" //          	lui	a4,0x8030
                   ".word 0x01000693\n\t" //          	li	a3,16
                   ".word 0x01900613\n\t" //          	li	a2,25
                   ".word 0x67878793\n\t" //          	addi	a5,a5,1656 # 12345678 <__l1_end+0x12245678>
                   ".word 0x00570713\n\t" //          	addi	a4,a4,5 # 8030005 <__l1_end+0x7f30005>
                   ".word 0x00b00593\n\t" //          	li	a1,11
                   ".word 0xff500513\n\t" //          	li	a0,-11
                   ".word 0x42c687b3\n\t" //          	p.mac	a5,a3,a2
                   ".word 0x42c697b3\n\t" //          	p.msu	a5,a3,a2
                   ".word 0xc8e787d7\n\t" //          	pv.shuffle2.h	a5,a5,a4
                   ".word 0xc8e797d7\n\t" //          	pv.shuffle2.b	a5,a5,a4
                   ".word 0xa0b787d7\n\t" //          	pv.sdotup.h	a5,a5,a1
                   ".word 0xa0b7c7d7\n\t" //          	pv.sdotup.sc.h	a5,a5,a1
                   ".word 0xa8b717d7\n\t" //          	pv.sdotusp.b	a5,a4,a1
                   ".word 0xa8b757d7\n\t" //          	pv.sdotusp.sc.b	a5,a4,a1
                   ".word 0xb8a707d7\n\t" //          	pv.sdotsp.h	a5,a4,a0
                   ".word 0xb8a747d7\n\t" //          	pv.sdotsp.sc.h	a5,a4,a0
                   );
  
  __asm__ volatile(
                   ".word 0x123457b7\n\t" //          	lui	a5,0x12345
                   ".word 0xf1111737\n\t" //          	lui	a4,0xf1111
                   ".word 0x67878793\n\t" //          	addi	a5,a5,1656 # 12345678 <__l1_end+0x12245678>
                   ".word	0x11170713\n\t" //          	addi	a4,a4,273 # f1111111 <pulp__FC+0xf1111112>
                   ".word 	0xb007e7d7\n\t" //          	pv.insert.h	a5,a5,0
                   ".word	0xb207f7d7\n\t" //          	pv.insert.b	a5,a5,1
                   ".word	0xa217e7d7\n\t" //          	pv.sdotup.sci.h	a5,a5,3
                   ".word 0xabf7e7d7\n\t" //          	pv.sdotusp.sci.h	a5,a5,-1
                   ".word 0xbbf767d7\n\t" //          	pv.sdotsp.sci.h	a5,a4,-1
                   );
                   
  __asm__ volatile(
                   ".word	0x111117b7\n\t" //          	lui	a5,0x11111
                   ".word 0x22222737\n\t" //          	lui	a4,0x22222
                   ".word	0x333336b7\n\t" //          	lui	a3,0x33333
                   ".word	0x12345637\n\t" //          	lui	a2,0x12345
                   ".word	0x000105b7\n\t" //          	lui	a1,0x10
                   ".word	0x00000513\n\t" //          	li	a0,0
                   ".word	0x11178793\n\t" //          	addi	a5,a5,273 # 11111111 <__l1_end+0x11011111>
                   ".word	0x22270713\n\t" //          	addi	a4,a4,546 # 22222222 <__l1_end+0x22122222>
                   ".word	0x33368693\n\t" //          	addi	a3,a3,819 # 33333333 <__l1_end+0x33233333>
                   ".word	0x67860613\n\t" //          	addi	a2,a2,1656 # 12345678 <__l1_end+0x12245678>
                   ".word	0x00158593\n\t" //          	addi	a1,a1,1 # 10001 <__stack_start+0x10001>
                   ".word	0x00e79557\n\t" //          	pv.add.b	a0,a5,a4
                   ".word	0x08f55557\n\t" //          	pv.sub.sc.b	a0,a0,a5
                   ".word	0x10d79557\n\t" //          	pv.avg.b	a0,a5,a3
                   ".word	0x20d79557\n\t" //          	pv.min.b	a0,a5,a3
                   ".word 0x30e7d557\n\t" //          	pv.max.sc.b	a0,a5,a4
                   ".word 	0x68b61557\n\t" //          	pv.and.b	a0,a2,a1
                   ".word	0x58b55557\n\t" //          	pv.or.sc.b	a0,a0,a1
                   );
  
  __asm__ volatile(
                   ".word 0x123457b7\n\t" //          	lui	a5,0x12345
                  ".word 0xf2345737\n\t" //          	lui	a4,0xf2345
                   ".word	0x100f16b7\n\t" //          	lui	a3,0x100f1
                   ".word 0x67878793\n\t" //          	addi	a5,a5,1656 # 12345678 <__l1_end+0x12245678>
                   ".word 0x67870713\n\t" //          	addi	a4,a4,1656 # f2345678 <pulp__FC+0xf2345679>
                   ".word	0x00f68693\n\t" //          	addi	a3,a3,15 # 100f100f <__l1_end+0xfff100f>
                   ".word	0x1a57e7d7\n\t" //          	pv.avgu.sci.h	a5,a5,11
                   ".word	0x125767d7\n\t" //          	pv.avg.sci.h	a5,a4,11
                   ".word	0x225767d7\n\t" //          	pv.min.sci.h	a5,a4,11
                   ".word	0x2a57e7d7\n\t" //          	pv.minu.sci.h	a5,a5,11
                   ".word 0x325767d7\n\t" //          	pv.max.sci.h	a5,a4,11
                   ".word	0x3a57e7d7\n\t" //          	pv.maxu.sci.h	a5,a5,11
                   ".word	0x4027e7d7\n\t" //          	pv.srl.sci.h	a5,a5,4
                   ".word 0x482767d7\n\t" //          	pv.sra.sci.h	a5,a4,4
                   ".word 0x5027e7d7\n\t" //          	pv.sll.sci.h	a5,a5,4
                   ".word 	0x7a07e7d7\n\t" //          	pv.extract.h	a5,a5,1
                   ".word 0x8246e7d7\n\t" //          	pv.dotup.sci.h	a5,a3,9
                   ".word 0x8bb6e7d7\n\t" //          	pv.dotusp.sci.h	a5,a3,-9
                   );
  
  __asm__ volatile(
                   ".word	0x123457b7\n\t" //          	lui	a5,0x12345
                   ".word 0xf2345737\n\t" //          	lui	a4,0xf2345
                   ".word	0x67878793\n\t" //          	addi	a5,a5,1656 # 12345678 <__l1_end+0x12245678>
                   ".word 0x67870713\n\t" //          	addi	a4,a4,1656 # f2345678 <pulp__FC+0xf2345679>
                   ".word	0x1a57e7d7\n\t" //          	pv.avgu.sci.h	a5,a5,11
                   ".word 0x125767d7\n\t" //          	pv.avg.sci.h	a5,a4,11
                   ".word	0x225767d7\n\t" //          	pv.min.sci.h	a5,a4,11
                   ".word	0x2a57e7d7\n\t" //          	pv.minu.sci.h	a5,a5,11
                   ".word 0x325767d7\n\t" //          	pv.max.sci.h	a5,a4,11
                   ".word	0x3a57e7d7\n\t" //          	pv.maxu.sci.h	a5,a5,11
                   ".word	0x4027e7d7\n\t" //          	pv.srl.sci.h	a5,a5,0
                   ".word 0x482767d7\n\t" //          	pv.sra.sci.h	a5,a4,0
                   ".word	0x5027e7d7\n\t" //          	pv.sll.sci.h	a5,a5,0
                   );
  
  __asm__ volatile(
                   
                   ".word 0x123457b7\n\t"//          	lui	a5,0x12345
                   ".word 0x00000713\n\t" //          	li	a4,0
                   ".word	0xfff00693\n\t" //          	li	a3,-1
                   ".word 0x67878793\n\t" //          	addi	a5,a5,1656 # 12345678 <__l1_end+0x12245678>
                   ".word 0x70068757\n\t" //          	pv.abs.h	a4,a3
                   ".word	0x08a7e757\n\t" //          	pv.sub.sci.h	a4,a5,20
                   ".word	0x6a476757\n\t" //          	pv.and.sci.h	a4,a4,9
                   ".word 0x5a576757\n\t" //          	pv.or.sci.h	a4,a4,11
                   ".word 0x62776757\n\t" //          	pv.xor.sci.h	a4,a4,15
                   );
  
                   
  __asm__ volatile(
                   ".word 0x00500793\n\t"
                   ".word 0x00100713\n\t"
                   ".word 0x14e7d7b3\n\t"
                   ".word 0x000057b7\n\t"
                   ".word 0x67878793\n\t"
                   ".word 0x0257e7d7\n\t"
                   ".word 0x700787d7\n\t"
                   );
  
  __asm__ volatile(
                   ".word 0x00000793\n\t"//          	li	a5,0
                   ".word 0x00000713\n\t" //          	li	a4,0
                   ".word 0x00000693\n\t"//          	li	a3,0
                   ".word 0x00000613\n\t"//          	li	a2,0
                   ".word	0x00100713\n\t"//         	li	a4,1
                   ".word	0xff800693  \n\t"//        	li	a3,-8
                   ".word	0x040706b3 \n\t"//         	p.abs	a3,a4
                   ".word 0x04068633  \n\t"//        	p.abs	a2,a3
                   ".word	0x1006c5b3\n\t" //          	p.exths	a1,a3
                   ".word	0x00002637\n\t" //          	lui	a2,0x2
                   ".word	0xfff60613\n\t" //          	addi	a2,a2,-1 # 1fff <__stack_start+0x1fff>
                   ".word	0x10065533 \n\t" //         	p.exthz	a0,a2
                   ".word	0x0016ac63\n\t"//          	p.bneimm	a3,1,80000124 <bf>
                   ".word	0xf8000793\n\t"//          	li	a5,-128
                   ".word	0x04f6d733\n\t" //          	p.minu	a4,a3,a5
                   ".word	0x04e7c733   \n\t"//       	p.min	a4,a5,a4
                   ".word	0x04f777b3\n\t" //          	p.maxu	a5,a4,a5
                   ".word	0x04e667b3\n\t"//          	p.max	a5,a2,a4

                   //80000124 <bf>:
                   ".word 0x00000013\n\t" //          	nop
                   ".word	0x00000513\n\t" //          	li	a0,0
                   ".word	0x00008067\n\t" //           
                   );
  
  
  __asm__ volatile
    (
     ".word 0x00000793\n\t"         // 	li	a5,0
     ".word 0x00000713\n\t" //          	li	a4,0
     ".word 0x00000693\n\t" //          	li	a3,0
     ".word 0x00100793\n\t" //          	li	a5,1
     ".word 0xff800713\n\t" //          	li	a4,-8
     ".word 0x040787b3\n\t" //        	p.abs	a5,a5
     ".word 0x04070733\n\t" //         	p.abs	a4,a4
     ".word 0x100746b3\n\t" //          	p.exths	a3,a4
     ".word 0x000026b7\n\t" //          	lui	a3,0x2
     ".word 0xfff68693\n\t" //          	addi	a3,a3,-1 # 1fff <__stack_start+0x1fff>
     ".word 0x1006d633\n\t" //          	p.exthz	a2,a3
     ".word 0xf8000793\n\t" //          	li	a5,-128
     ".word	0x04f6d733\n\t" //          	p.minu	a4,a3,a5
     ".word	0x04e7c733\n\t" //          	p.min	a4,a5,a4
     ".word 0x04f777b3\n\t" //          	p.maxu	a5,a4,a5
     ".word	0x04e667b3\n\t" //          	p.max	a5,a2,a4
     );
  */
}
