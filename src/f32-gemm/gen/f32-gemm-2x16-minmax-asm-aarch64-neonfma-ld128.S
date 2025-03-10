// Copyright 2025 Google LLC
//
// This source code is licensed under the BSD-style license found in the
// LICENSE file in the root directory of this source tree.

#include "xnnpack/assembly.h"

BEGIN_FUNCTION xnn_f32_gemm_minmax_ukernel_2x16__asm_aarch64_neonfma_ld128_2

      # Free up GP registers.
      stp x19, x20, [sp, -64]
      stp x21, x22, [sp, -48]
      stp x23, x24, [sp, -32]
      stp x25, x26, [sp, -16]

      # Preserve callee saved q8-q15 registers.
      stp d8, d9, [sp, -128]
      stp d10, d11, [sp, -112]
      stp d12, d13, [sp, -96]
      stp d14, d15, [sp, -80]

      # Load params.
      ldr x13, [sp, 8]

      # Load min/max values.
      ld2r {v0.4s, v1.4s}, [x13]
      # Setup and alias a & c pointers.
      add x9, x3, x4
      add x13, x6, x7

      cmp x0, 2
      csel  x9, x3, x9, LO
      csel  x13, x6, x13, LO

outer_loop:
      # Initialize k counter.
      mov x20, x2

      # Initialize accumulators with the biases.
      ldp q11, q13, [x5, 0]
      ldp q15, q17, [x5, 32]
      mov v12.16b, v11.16b
      mov v14.16b, v13.16b
      mov v16.16b, v15.16b
      mov v18.16b, v17.16b
      add x5, x5, 64

      # Are there at least 16 bytes?
      cmp x20, 16
      blt inner_loop_tail
      sub x20, x20, 16

inner_loop:
      ldr q2, [x3], 16
      ldr q3, [x9], 16
      ldp q7, q8, [x5], 32
      ldp q9, q10, [x5], 32
      fmla  v11.4s, v7.4s, v2.s[0]
      fmla  v12.4s, v7.4s, v3.s[0]
      fmla  v13.4s, v8.4s, v2.s[0]
      fmla  v14.4s, v8.4s, v3.s[0]
      fmla  v15.4s, v9.4s, v2.s[0]
      fmla  v16.4s, v9.4s, v3.s[0]
      fmla  v17.4s, v10.4s, v2.s[0]
      fmla  v18.4s, v10.4s, v3.s[0]
      ldp q7, q8, [x5], 32
      ldp q9, q10, [x5], 32
      fmla  v11.4s, v7.4s, v2.s[1]
      fmla  v12.4s, v7.4s, v3.s[1]
      fmla  v13.4s, v8.4s, v2.s[1]
      fmla  v14.4s, v8.4s, v3.s[1]
      fmla  v15.4s, v9.4s, v2.s[1]
      fmla  v16.4s, v9.4s, v3.s[1]
      fmla  v17.4s, v10.4s, v2.s[1]
      fmla  v18.4s, v10.4s, v3.s[1]
      ldp q7, q8, [x5], 32
      ldp q9, q10, [x5], 32
      fmla  v11.4s, v7.4s, v2.s[2]
      fmla  v12.4s, v7.4s, v3.s[2]
      fmla  v13.4s, v8.4s, v2.s[2]
      fmla  v14.4s, v8.4s, v3.s[2]
      fmla  v15.4s, v9.4s, v2.s[2]
      fmla  v16.4s, v9.4s, v3.s[2]
      fmla  v17.4s, v10.4s, v2.s[2]
      fmla  v18.4s, v10.4s, v3.s[2]
      ldp q7, q8, [x5], 32
      ldp q9, q10, [x5], 32
      fmla  v11.4s, v7.4s, v2.s[3]
      fmla  v12.4s, v7.4s, v3.s[3]
      fmla  v13.4s, v8.4s, v2.s[3]
      fmla  v14.4s, v8.4s, v3.s[3]
      fmla  v15.4s, v9.4s, v2.s[3]
      fmla  v16.4s, v9.4s, v3.s[3]
      fmla  v17.4s, v10.4s, v2.s[3]
      fmla  v18.4s, v10.4s, v3.s[3]
      subs x20, x20, 16
      bhs inner_loop

      add x20, x20, 16
      cmp x20, 4
      blt inner_loop_end

inner_loop_tail:
      ldr s2, [x3], 4
      ldr s3, [x9], 4
      ldp q7, q8, [x5], 32
      ldp q9, q10, [x5], 32
      fmla  v11.4s, v7.4s, v2.s[0]
      fmla  v12.4s, v7.4s, v3.s[0]
      fmla  v13.4s, v8.4s, v2.s[0]
      fmla  v14.4s, v8.4s, v3.s[0]
      fmla  v15.4s, v9.4s, v2.s[0]
      fmla  v16.4s, v9.4s, v3.s[0]
      fmla  v17.4s, v10.4s, v2.s[0]
      fmla  v18.4s, v10.4s, v3.s[0]
      subs x20, x20, 4
      bne inner_loop_tail

inner_loop_end:
      # Min/max clamping.
      fmin  v11.4s, v1.4s, v11.4s
      fmin  v12.4s, v1.4s, v12.4s
      fmin  v13.4s, v1.4s, v13.4s
      fmin  v14.4s, v1.4s, v14.4s
      fmin  v15.4s, v1.4s, v15.4s
      fmin  v16.4s, v1.4s, v16.4s
      fmin  v17.4s, v1.4s, v17.4s
      fmin  v18.4s, v1.4s, v18.4s
      fmax  v11.4s, v0.4s, v11.4s
      fmax  v12.4s, v0.4s, v12.4s
      fmax  v13.4s, v0.4s, v13.4s
      fmax  v14.4s, v0.4s, v14.4s
      fmax  v15.4s, v0.4s, v15.4s
      fmax  v16.4s, v0.4s, v16.4s
      fmax  v17.4s, v0.4s, v17.4s
      fmax  v18.4s, v0.4s, v18.4s

      # Check whether full or partial store.
      cmp x1, 16
      b.lo tail_8
      stp  q11, q13, [x6], 32
      stp  q15, q17, [x6], 32
      stp  q12, q14, [x13], 32
      stp  q16, q18, [x13], 32
      sub x3, x3, x2
      sub x9, x9, x2

      sub x1, x1, 16
      b.ne outer_loop
      b return

tail_8:
      tbz w1, 3, tail_4
      stp  q11, q13, [x6], 32
      stp  q12, q14, [x13], 32
      mov  v11.16b, v15.16b
      mov  v13.16b, v17.16b
      mov  v12.16b, v16.16b
      mov  v14.16b, v18.16b


tail_4:
      tbz w1, 2, tail_2
      str  q11, [x6], 16
      str  q12, [x13], 16
      mov  v11.16b, v13.16b
      mov  v12.16b, v14.16b


tail_2:
      tbz w1, 1, tail_1
      str  d11, [x6], 8
      str  d12, [x13], 8
      dup d11, v11.d[1]
      dup d12, v12.d[1]


tail_1:
      tbz w1, 0, return
      str  s11, [x6]
      str  s12, [x13]

return:
      # Restore the callee saved GP registers.
      ldp x19, x20, [sp, -64]
      ldp x21, x22, [sp, -48]
      ldp x23, x24, [sp, -32]
      ldp x25, x26, [sp, -16]

      # Restore callee saved q8-q15 registers.
      ldp d8, d9, [sp, -128]
      ldp d10, d11, [sp, -112]
      ldp d12, d13, [sp, -96]
      ldp d14, d15, [sp, -80]
      ret
END_FUNCTION xnn_f32_gemm_minmax_ukernel_2x16__asm_aarch64_neonfma_ld128_2