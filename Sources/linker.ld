/*
 * SPDX-License-Identifier: 0BSD
 * SPDX-FileCopyrightText: © 2026 Sebastian Ritter
 */
 
/* the entry point is called "_start" */
ENTRY(_start)

SECTIONS {
    . = 0x40300000; /* Device Tree Blob not overlap 0x40000000 + 3MB */
    .text : {
      /* KEEP = do not optimize; and do first the boot than all other code */
      KEEP(*(.text.boot)) *(.text .text.*)
    }
    
    /* our constants */
    .rodata : {
      *(.rodata .rodata.*)
    }
    
    /* our global initialized variables */
    .data : {
      *(.data .data.*)
    }
    
    /* our uninitalizied variables and stack */
    .bss : {
      /* the align is important on ARM and on 16-bytes */
        . = ALIGN(16);
        __bss_start = .;
        *(.bss .bss.*)
        . = ALIGN(16);
        __bss_end = .;
    }

    /* Stack separat, nach BSS */
    . = ALIGN(16);

    /* the bottom of stack with 64KB size */
    stack_bottom = .;
    . += 0x10000;   /* 64KB Stack */

      /* the top of the stack */
    stack_top = .;
    
}
