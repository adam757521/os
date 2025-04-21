var BPB = packed struct { _: [3]u8 };

pub export fn t() !i8 {
    const a = 5;
    const b = 6;
    const c = a + b;
    return c;
}
