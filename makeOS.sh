#!/bin/zsh
#
# SPDX-License-Identifier: 0BSD
# SPDX-FileCopyrightText: © 2026 Sebastian Ritter
#

set -e

# same target like in our Package.swift
export TARGET="aarch64-none-none-elf"

# compile our Swift
echo "STEP 1: compile Swift kernel..."
swift build -c release --triple ${TARGET}
# next a hint to get the object files until I implement a SPM compile and SPM command plugin
SWIFT_OBJS=(
"$(find .build -name "KernelImpl.swift.o" | head -n 1)"
"$(find .build -name "RuntimeSupport.swift.o" | head -n 1)"
)

# compile our minimal Assembler
echo "STEP 2: compile Assembler bridge..."
clang -target ${TARGET} -c Sources/Boot/Boot.s -o .build/boot.o
BOOT_OBJS=(
".build/boot.o"
)

# link all together
echo "STEP 3: link all together ..."
clang -target ${TARGET} \
      -T Sources/linker.ld \
      "${BOOT_OBJS[@]}" "${SWIFT_OBJS[@]}" \
      -o .build/kernel.elf \
      -fuse-ld=lld \
      -nostdlib \
      -static

# optional / on error check symbols - for example if LLVM optimize to hard
#echo "=== binary symbols ==="
#nm .build/kernel.elf | grep -E "(kmain|_start|swift)"

# optional / on error disassembly kmain - for example if LLVM optimize to hard
#echo "=== kmain disassembly ==="
#llvm-objdump -d .build/kernel.elf | grep -A 20 "kmain"

echo "STEP 4: start QEMU..."
qemu-system-aarch64 -M virt -cpu cortex-a57 \
    -nographic -serial mon:stdio \
    -kernel .build/kernel.elf
    
#EOF
