pub const background = c.Color{ .r = 0x14, .g = 0x14, .b = 0x14, .a = 0xff };
pub const foreground = c.Color{ .r = 0xdc, .g = 0xdc, .b = 0xdc, .a = 0xff };

test {
    std.testing.refAllDecls(@This());
}

const c = @import("c.zig");
const std = @import("std");
