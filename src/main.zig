const std = @import("std");
const fmt = std.fmt;
const heap = std.heap;
const process = std.process;

const ArgError = error {
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
    _ = switch (try fmt.parseUnsigned(usize, arg, 0)) {
       1 => try @import("01.zig").main(),
       2 => try @import("02.zig").main(),
       3 => try @import("03.zig").main(),
//       4 => try @import("04.zig").main(),
//       5 => try @import("05.zig").main(),
//       6 => try @import("06.zig").main(),
//       7 => try @import("07.zig").main(),
//       8 => try @import("08.zig").main(),
//       9 => try @import("09.zig").main(),
//      10 => try @import("10.zig").main(),
//      11 => try @import("11.zig").main(),
//      12 => try @import("12.zig").main(),
//      13 => try @import("13.zig").main(),
//      14 => try @import("14.zig").main(),
//      15 => try @import("15.zig").main(),
//      16 => try @import("16.zig").main(),
//      17 => try @import("17.zig").main(),
//      18 => try @import("18.zig").main(),
//      19 => try @import("19.zig").main(),
//      20 => try @import("20.zig").main(),
//      21 => try @import("21.zig").main(),
//      22 => try @import("22.zig").main(),
//      23 => try @import("23.zig").main(),
//      24 => try @import("24.zig").main(),
//      25 => try @import("25.zig").main(),
      else => return ArgError.DayNotFound,
    };
  }
}
