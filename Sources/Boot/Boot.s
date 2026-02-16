// SPDX-License-Identifier: 0BSD
// SPDX-FileCopyrightText: © 2026 Sebastian Ritter

.section .text.boot
.global _start // our entry point declaration, like linker.ld script it also called
.global arm_hvc_call
.global halt // export this label for Raspberry Pi 4 shutdown emulation

// now let us define what behind the entry point declaration is
_start:
    // 0. All other than Core 0 need to sleep (Single-Core)
    mrs x0, mpidr_el1
    and x0, x0, #0xFF        // extract Core ID
    cbz x0, core0_init       // if Core 0 jump to init system on Core 0 - all other cores fallthrough
    
core_sleep:
    wfe                      // let Core Wait-For-Event
    b core_sleep

core0_init:
    // 1. FPU on
    mov x0, #3 << 20
    msr cpacr_el1, x0
    isb

    // 2. init UART0 (Mini UART für RPi4)
    // Raspberry Pi 4 verwendet GPIO-basierte UART
    // Base-Adresse für Peripherals auf RPi4: 0xFE000000
    
    mov x0, #0xFE000000      // BCM2711 Peripheral Base
    add x0, x0, #0x215000    // AUX base (Mini UART)
    
    // Enable Mini UART
    mov w1, #1
    str w1, [x0, #4]         // AUX_ENABLES = 1
    
    mov w1, #0
    str w1, [x0, #0x40]      // AUX_MU_CNTL_REG = 0 (disable)
    
    mov w1, #3
    str w1, [x0, #0x44]      // AUX_MU_LCR_REG = 3 (8-bit mode)
    
    mov w1, #0
    str w1, [x0, #0x48]      // AUX_MU_MCR_REG = 0
    
    mov w1, #0
    str w1, [x0, #0x4C]      // AUX_MU_IER_REG = 0 (disable interrupts)
    
    mov w1, #0xC6
    str w1, [x0, #0x50]      // AUX_MU_IIR_REG = 0xC6 (clear FIFOs)
    
    mov w1, #270             // Baudrate 115200 with 250MHz
    str w1, [x0, #0x68]      // AUX_MU_BAUD_REG
    
    mov w1, #3
    str w1, [x0, #0x40]      // AUX_MU_CNTL_REG = 3 (enable TX/RX)

    // GPIO setup for UART (GPIO14=TXD, GPIO15=RXD)
    mov x2, #0xFE000000
    add x2, x2, #0x200000    // GPIO base

    ldr w1, [x2, #4]         // GPFSEL1
    bic w1, w1, #0x3F << 12  // clear bits 12-17 (GPIO14-15)
    orr w1, w1, #0x2 << 12   // GPIO14 = ALT5
    orr w1, w1, #0x2 << 15   // GPIO15 = ALT5
    str w1, [x2, #4]

    // deaktivate pull-up/down
    mov w1, #0
    str w1, [x2, #0xE4]      // GPIO_PUP_PDN_CNTRL_REG0

    // Test-Ausgabe "Boot"
    mov x0, #0xFE000000
    add x0, x0, #0x215000
.Lwait_boot:
    ldr w2, [x0, #0x54]      // AUX_MU_LSR_REG
    and w2, w2, #0x20        // TX ready?
    cbz w2, .Lwait_boot
    
    // write Boot from Assembler to see this parts run correctly - debuging is for loosers
    mov w1, #66
    str w1, [x0, #0x40]
    mov w1, #111
    str w1, [x0, #0x40]
    mov w1, #111
    str w1, [x0, #0x40]
    mov w1, #116            
    str w1, [x0, #0x40]


    // 3. Setup Stack
    ldr x0, =stack_top
    mov sp, x0

    // 4. jump to Swift world
    bl kmain

// let the exception level 2 (EL2) work for us.
// Note: In result of our rule is minimal Assembler, we only call with the first parameter. In Swift we use the type safety to let no unexpected values is set to first parameter.
arm_hvc_call:
    hvc #0
    ret

// for Raspberry Pi 4 this is like a system stop
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
    .skip 0x10000  // 64 KB more than qemu before
stack_top:

