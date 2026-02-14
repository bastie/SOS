// SPDX-License-Identifier: 0BSD
// SPDX-FileCopyrightText: © 2026 Sebastian Ritter

.section .text.boot
.global _start // our entry point declaration, like linker.ld script it also called
.global arm_hvc_call

// now let us define what behind the entry point declaration is
_start:
    // 1. FPU on
    mov x0, #3 << 20
    msr cpacr_el1, x0
    isb

    // 2. init UART0 (PL011)
    mov x0, #0x09000000     // UART Base
    mov w1, #0x0
    str w1, [x0, #0x30]     // CR = 0 (Disable)
    mov w1, #0x70
    str w1, [x0, #0x2c]     // LCRH = 8-bit, FIFO enable
    mov w1, #0x301
    str w1, [x0, #0x30]     // CR = Enable UART, TX, RX

    // write Boot from Assembler to see this parts run correctly - debuging is for loosers
    mov w1, #66
    str w1, [x0]
    mov w1, #111
    str w1, [x0]
    mov w1, #111
    str w1, [x0]
    mov w1, #116            
    str w1, [x0]

    // 3. setup Stack
    // On ARM processors, the stack grows downwards (towards lower addresses). Therefore, the stack pointer is initially set to stack_top.
    ldr x0, =stack_top
    mov sp, x0

    // 4. jump to Swift world
    bl kmain

// let the exception level 2 (EL2) work for us.
// Note: In result of our rule is minimal Assembler, we only call with the first parameter. In Swift we use the type safety to let no unexpected values is set to first parameter.
arm_hvc_call:
    hvc #0
    ret

halt:
    wfi
    b halt

// --- EXCEPTION VECTORS ---
.balign 2048
vectors:
    .rept 16
    .balign 128
    b halt      // on error come to me (halt-label)
    .endr

// --- STACK ---
.section .bss
.balign 16
stack_bottom:
    .skip 0x4000  // 16 reserve KB memory
stack_top:

