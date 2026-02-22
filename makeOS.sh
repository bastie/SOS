#!/bin/zsh
#
# SPDX-License-Identifier: 0BSD
# SPDX-FileCopyrightText: © 2026 Sebastian Ritter
#

set -e

# same target like in our Package.swift
export TARGET="aarch64-none-none-elf"
BUILD_DIR=".build"
SWIFT_BUILD_DIR="${BUILD_DIR}/${TARGET}/release"

# compile our Swift
echo "STEP 1: compile Swift kernel..."
swift build -c release --triple ${TARGET}
SWIFT_OBJS=($(find "${SWIFT_BUILD_DIR}" -name "*.swift.o"))

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
      -o "${BUILD_DIR}/kernel.elf" \
      -fuse-ld=lld \
      -nostdlib \
      -static

# optional / on error check symbols - for example if LLVM optimize to hard
#echo "=== binary symbols ==="
#nm "${BUILD_DIR}/kernel.elf" | grep -E "(kmain|_start|swift)"

# optional / on error disassembly kmain - for example if LLVM optimize to hard
#echo "=== kmain disassembly ==="
#llvm-objdump -d "${BUILD_DIR}/kernel.elf" | grep -A 20 "kmain"

# create a flat kernel.bin
echo "STEP 4: get flat kernel.bin"
llvm-objcopy -O binary "${BUILD_DIR}/kernel.elf" "${BUILD_DIR}/kernel.bin"

# with kernel.bin (not kernel.elf) qemu generate a Device Tree Blob and send it to our kernel
echo "STEP 5: start QEMU..."
qemu-system-aarch64 -M virt -cpu cortex-a57 \
    -nographic -serial mon:stdio \
    -kernel "${BUILD_DIR}/kernel.bin"

# optional create Xcode documentation
echo "STEP 6: create documentation ..."
cp Package.swift "${BUILD_DIR}/"
sed -i '' '/^\/\*START/d; /^END\*\//d' Package.swift
swift package plugin generate-documentation --transform-for-static-hosting --emit-digest --target SOS
cp "${BUILD_DIR}/Package.swift" .

#optional import generated documentation in XCode - remove existing import before
#open .build/plugins/Swift-DocC/outputs/SOS.doccarchive
echo \*\*\* NOTE: import documentation with copy and execute next line \*\*\*
echo open "${BUILD_DIR}/plugins/Swift-DocC/outputs/SOS.doccarchive"

#EOF
