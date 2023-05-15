const std = @import("std");
const fmt = std.fmt;
const io = std.io;
const heap = std.heap;
const process = std.process;

const ArgError = error{
    DayNotFound,
};

pub fn main() !void {
    var gpa = heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var args = try process.argsWithAllocator(alloc);
    defer args.deinit();

    _ = args.next();
    while (args.next()) |arg| {
        const n = try fmt.parseUnsigned(usize, arg, 0);
        const s = try switch (n) {
            1 => @import("01.zig").main(),
            2 => @import("02.zig").main(),
            3 => @import("03.zig").main(),
            4 => @import("04.zig").main(),
            5 => @import("05.zig").main(),
            6 => @import("06.zig").main(),
            7 => @import("07.zig").main(),
            8 => @import("08.zig").main(),
            9 => @import("09.zig").main(),
            10 => @import("10.zig").main(),
            11 => @import("11.zig").main(),
            12 => @import("12.zig").main(),
            13 => @import("13.zig").main(),
            14 => @import("14.zig").main(),
            15 => @import("15.zig").main(),
            16 => @import("16.zig").main(),
            17 => @import("17.zig").main(),
            //    18 => @import("18.zig").main(),
            //    19 => @import("19.zig").main(),
            //    20 => @import("20.zig").main(),
            //    21 => @import("21.zig").main(),
            //    22 => @import("22.zig").main(),
            //    23 => @import("23.zig").main(),
            //    24 => @import("24.zig").main(),
            //    25 => @import("25.zig").main(),
            else => return ArgError.DayNotFound,
        };
        try io.getStdOut().writer().print("{:0>2} {} {}\n", .{ n, s[0], s[1] });
    }
}
