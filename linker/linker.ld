ENTRY(_kmain)

SECTIONS {
    . = 0x100000;
    .text :
    {
        *(.text)
        *(.text.*)
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
        _bss_end = .;
    }
}
