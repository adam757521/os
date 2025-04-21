const exec_parsing = @import("exec_parsing.zig");

export fn parse_elf_32() i8 {
    return exec_parsing.t();
}
