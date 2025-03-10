#!/usr/bin/env python3
# Copyright 2024 Google LLC
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

import os
import sys

from gemm_compiler import avx512vnni_template
from gemm_compiler import generate
from gemm_compiler import neondot_template
from gemm_compiler import neonmlal_aarch32_template

"""Generates qd8-f32-qc8w assembly gemm microkernels."""


output_base = 'src/qd8-f32-qc8w-gemm/gen/'


def generate_qd8_f32_qc8w_gemm_microkernels():
  if '/bazel-out/' in os.getcwd():
    os.chdir(os.environ['BUILD_WORKING_DIRECTORY'])

  for nr in range(16, 33, 16):
    for mr in range(1, 12):
      generate.generate_gemm_microkernel(
          M=mr,
          N=nr,
          isa=avx512vnni_template.Avx512Vnni(),
          output_file=os.path.join(
              output_base,
              f'qd8-f32-qc8w-gemm-{mr}x{nr}-minmax-asm-amd64-avx512vnni.S',
          ),
      )

  # not enough SIMD registers to go above 5x64
  for mr in range(1, 6):
    generate.generate_gemm_microkernel(
        M=mr,
        N=64,
        isa=avx512vnni_template.Avx512Vnni(),
        output_file=os.path.join(
            output_base,
            f'qd8-f32-qc8w-gemm-{mr}x64-minmax-asm-amd64-avx512vnni.S',
        ),
    )

  for unroll in {1, 2, 4}:
    decrement = 32 * unroll
    for nr in range(8, 17, 8):
      for mr in range(1, 5):
        generate.generate_gemm_microkernel(
            M=mr,
            N=nr,
            isa=neondot_template.NeonDot(unroll),
            output_file=os.path.join(
                output_base,
                f'qd8-f32-qc8w-gemm-{mr}x{nr}-minmax-asm-aarch64-neondot-ld{decrement}.S',
            ),
        )

  nr = 8
  unroll = 2
  decrement = 32 * unroll
  for mr in range(1, 5):
    generate.generate_gemm_microkernel(
        M=mr,
        N=nr,
        isa=neonmlal_aarch32_template.NeonMlal(unroll),
        output_file=os.path.join(
            output_base,
            f'qd8-f32-qc8w-gemm-{mr}x{nr}-minmax-asm-aarch32-neonmlal-ld{decrement}.S',
        ),
    )
