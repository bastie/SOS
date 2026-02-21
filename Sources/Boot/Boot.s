// SPDX-License-Identifier: 0BSD
// SPDX-FileCopyrightText: © 2026 Sebastian Ritter

.section .text.boot
.global _start // our entry point declaration, like linker.ld script it also called
.global arm_hvc_call
.global wait_for_interrupt

// now let us define what behind the entry point declaration is
_start:
    // 0. All other than Core 0 need to sleep (Single-Core)
    mrs x1, mpidr_el1
    and x1, x1, #0xFF        // extract Core ID in register 1
    cbz x1, core0_init       // if Core 0 jump to init system on Core 0 - all other cores fallthrough and sleep
    
core_sleep:
    wfe                      // let Core Wait-For-Event
    b core_sleep

core0_init:
    mov x24, x0             // store adress of flat Device Tree blob in callee-saved register 24 - if 42 is the answer, maybe 24 is the question

    // register exception vector
    ldr x0, =vectors
    msr vbar_el1, x0
    isb
    
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
    mov w1, #66  // B
    str w1, [x0]
    mov w1, #111 // o
    str w1, [x0]
    mov w1, #111 // o
    str w1, [x0]
    mov w1, #116 // t
    str w1, [x0]

    // 3. setup Stack
    // On ARM processors, the stack grows downwards (towards lower addresses). Therefore, the stack pointer is initially set to stack_top.
    ldr x0, =stack_top
    mov sp, x0

    // 4. jump to Swift world from AArch64 (Note: RISC-V fills Core number in x0 and DTB in x1)
    mov x0, x24
    mov x1, xzr // remove trash from parameter x1 for Swift kernel
    mov x2, xzr // remove trash from parameter x2 for Swift kernel
    mov x3, xzr // remove trash from parameter x3 for Swift kernel
    bl kmain

// let the exception level 2 (EL2) work for us.
// Note: In result of our rule is minimal Assembler, we only call with the first parameter. In Swift we use the type safety to let no unexpected values is set to first parameter.
arm_hvc_call:
    hvc #0
    ret

wait_for_interrupt:
    wfi // wfi - wait for interrupt
    b wait_for_interrupt // You wake up? Go to wait for interrupt

// --- EXCEPTION VECTORS ---
.balign 2048
vectors:
    .rept 16
    .balign 128
    b wait_for_interrupt      // on error come to me (wait_for_interrupt-label)
    .endr

