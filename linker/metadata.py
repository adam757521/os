import sys
import struct

from elftools.elf.elffile import ELFFile


def boundries_of_section(section):
    return (section["sh_addr"], section["sh_size"])

def main():
    if len(sys.argv) != 3:
        print("Error: no arg or out")
        exit()
    
    arg = sys.argv[1]

    with open(arg, 'rb') as f:
        elf = ELFFile(f)

        symbols = elf.get_section_by_name(".symtab")
        if not symbols:
            pass

        stack_top = None;
        for sym in symbols.iter_symbols():
            if sym.name == "_kernel_stack_top":
                stack_top = sym['st_value']

        if not stack_top:
            pass

        code = elf.get_section_by_name(".text")
        data = elf.get_section_by_name(".data")
        bss = elf.get_section_by_name(".bss")
        code_s = boundries_of_section(code)
        data_s = boundries_of_section(data)
        bss_s = boundries_of_section(bss)

    with open(sys.argv[2], 'wb') as out:
        # TODO: is this used
        s = struct.pack("<IIIIIII", code_s[0], code_s[1], data_s[0], data_s[1], bss_s[0], bss_s[1], stack_top)
        out.write(s)


if __name__ == "__main__":
    main()

