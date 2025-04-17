ENTRY(_kmain)

SECTIONS {
    /DISCARD/ : {
        *(.eh_frame)
        *(.eh_frame_hdr)
        *(.comment)
        *(.note.GNU-stack)
    }

    . = 0x100000;
    .text :
    {
        KEEP(*(.text.kmain))
        *(.text*)
    }

    .data :
    {
        _data_start = .;
        *(.data)
        *(.data.*)
        _data_end = .;
    }

    .bss :
    {
        _bss_start = .;
        *(.bss)
        *(COMMON)

        . = ALIGN(16);
        _kernel_stack_bottom = .;
        . = . + 0x1000;
        _kernel_stack_top = .;

        _bss_end = .;
    }
}
