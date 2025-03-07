// Copyright 2025 Google LLC
//
// This source code is licensed under the BSD-style license found in the
// LICENSE file in the root directory of this source tree.

#include "xnnpack/assembly.h"

BEGIN_FUNCTION xnn_qd8_f32_qc8w_gemm_minmax_ukernel_1x16c4__asm_aarch64_neondot_ld128_2

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
      ldr x24, [sp, 16]
      # Round kc up to channels.
      add x2, x2, #3
      and x2, x2, #0xFFFFFFFFFFFFFFFC


outer_loop:
      # Initialize k counter.
      mov x20, x2
      # Initialize accumulators with k_sum * input zero point.
      ldr q10, [x24]
      ldp  q2, q3, [x5, 0]
      ldp  q4, q5, [x5, 32]
      mul v12.4s, v2.4s, v10.s[0]
      mul v13.4s, v3.4s, v10.s[0]
      mul v14.4s, v4.4s, v10.s[0]
      mul v15.4s, v5.4s, v10.s[0]
      add x5, x5, 64

      # Are there at least 16 bytes?
      cmp x20, 16
      blt inner_loop_tail
      sub x20, x20, 16

inner_loop:
      ldr q2, [x3], 16
      ldp q6, q7, [x5], 32
      ldp q8, q9, [x5], 32
      sdot  v12.4s, v6.16b, v2.4b[0]
      sdot  v13.4s, v7.16b, v2.4b[0]
      sdot  v14.4s, v8.16b, v2.4b[0]
      sdot  v15.4s, v9.16b, v2.4b[0]
      ldp q6, q7, [x5], 32
      ldp q8, q9, [x5], 32
      sdot  v12.4s, v6.16b, v2.4b[1]
      sdot  v13.4s, v7.16b, v2.4b[1]
      sdot  v14.4s, v8.16b, v2.4b[1]
      sdot  v15.4s, v9.16b, v2.4b[1]
      ldp q6, q7, [x5], 32
      ldp q8, q9, [x5], 32
      sdot  v12.4s, v6.16b, v2.4b[2]
      sdot  v13.4s, v7.16b, v2.4b[2]
      sdot  v14.4s, v8.16b, v2.4b[2]
      sdot  v15.4s, v9.16b, v2.4b[2]
      ldp q6, q7, [x5], 32
      ldp q8, q9, [x5], 32
      sdot  v12.4s, v6.16b, v2.4b[3]
      sdot  v13.4s, v7.16b, v2.4b[3]
      sdot  v14.4s, v8.16b, v2.4b[3]
      sdot  v15.4s, v9.16b, v2.4b[3]
      subs x20, x20, 16
      bhs inner_loop

      add x20, x20, 16
      cmp x20, 4
      blt inner_loop_end

inner_loop_tail:
      ldr s2, [x3], 4
      ldp q6, q7, [x5], 32
      ldp q8, q9, [x5], 32
      sdot  v12.4s, v6.16b, v2.4b[0]
      sdot  v13.4s, v7.16b, v2.4b[0]
      sdot  v14.4s, v8.16b, v2.4b[0]
      sdot  v15.4s, v9.16b, v2.4b[0]
      subs x20, x20, 4
      bne inner_loop_tail

inner_loop_end:

      # Convert from int32 to float.
      scvtf v12.4s, v12.4s
      scvtf v13.4s, v13.4s
      scvtf v14.4s, v14.4s
      scvtf v15.4s, v15.4s
      # Multiply by input scale.
      fmul v12.4s, v12.4s, v10.s[1]
      fmul v13.4s, v13.4s, v10.s[1]
      fmul v14.4s, v14.4s, v10.s[1]
      fmul v15.4s, v15.4s, v10.s[1]
      # Load weights scale.
      ldp q2, q3, [x5, 0]
      ldp q4, q5, [x5, 32]
      add x5, x5, 64
      # Load biases.
      ldp q6, q7, [x5, 0]
      ldp q8, q9, [x5, 32]
      add x5, x5, 64
      # Multiply by weight's scale.
      fmul v12.4s, v12.4s, v2.4s
      fmul v13.4s, v13.4s, v3.4s
      fmul v14.4s, v14.4s, v4.4s
      fmul v15.4s, v15.4s, v5.4s
      # Add bias.
      fadd v12.4s, v12.4s, v6.4s
      fadd v13.4s, v13.4s, v7.4s
      fadd v14.4s, v14.4s, v8.4s
      fadd v15.4s, v15.4s, v9.4s
      # Min/max clamping.
      fmin  v12.4s, v1.4s, v12.4s
      fmin  v13.4s, v1.4s, v13.4s
      fmin  v14.4s, v1.4s, v14.4s
      fmin  v15.4s, v1.4s, v15.4s
      fmax  v12.4s, v0.4s, v12.4s
      fmax  v13.4s, v0.4s, v13.4s
      fmax  v14.4s, v0.4s, v14.4s
      fmax  v15.4s, v0.4s, v15.4s

      # Check whether full or partial store.
      cmp x1, 16
      b.lo tail_8
      stp  q12, q13, [x6], 32
      stp  q14, q15, [x6], 32
      sub x3, x3, x2

      sub x1, x1, 16
      b.ne outer_loop
      b return

tail_8:
      tbz w1, 3, tail_4
      stp  q12, q13, [x6], 32
      mov  v12.16b, v14.16b
      mov  v13.16b, v15.16b


tail_4:
      tbz w1, 2, tail_2
      str  q12, [x6], 16
      mov  v12.16b, v13.16b


tail_2:
      tbz w1, 1, tail_1
      str  d12, [x6], 8
      dup d12, v12.d[1]


tail_1:
      tbz w1, 0, return
      str  s12, [x6]

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
END_FUNCTION xnn_qd8_f32_qc8w_gemm_minmax_ukernel_1x16c4__asm_aarch64_neondot_ld128_2