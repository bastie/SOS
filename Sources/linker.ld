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
    .rodata : ALIGN(16) {
        __rodata_start = .;
        *(.rodata .rodata.*)

        . = ALIGN(8);
        __start_swift_metadata = .;
        
        /* List, see Swift.def from LLVM project */
        /* since Swift 5 the ABI is stabil. */
        KEEP(*(.swift5_typeref))
        KEEP(*(.swift5_fieldmd))
        KEEP(*(.swift5_reflstr))
        KEEP(*(.swift5_types))
        KEEP(*(.swift5_assocty))
        KEEP(*(.swift5_proto))
        KEEP(*(.swift5_protos))
        KEEP(*(.swift5_capture))
        KEEP(*(.swift5_builtin))
        KEEP(*(.swift5_mpenum))
        KEEP(*(.swift5_acfuncs))
        KEEP(*(.swift5_replace))
        
        __stop_swift_metadata = .;

        /* Debug & Error Handling */
        . = ALIGN(8);
        KEEP(*(.swift_ast))
        
        __rodata_end = .;
    }
    
    /* With Swift 6: maybe 'throw' or some crashes are fatal */
    .gcc_except_table : ALIGN(8) {
        *(.gcc_except_table .gcc_except_table.*)
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
