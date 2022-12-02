const std = @import("std");
const fs = std.fs;
const io = std.io;
const math = std.math;

const toplist = @import("toplist.zig");

fn order_u32(a: u32, b: u32) math.Order {
  return math.order(a, b);
}

pub fn main() !void {
  var max_elves = toplist.Toplist(u32, 3, order_u32) { .items = [_]u32{0} ** 3 };
  {
    const file = try fs.cwd().openFile("src/01.txt", .{});
    defer file.close();
    const reader = file.reader();

    var buf: [100]u8 = undefined;

    var elf: ?u32 = null;
    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
      if (line.len == 0) {
        if (elf) |e| {
          _ = max_elves.insert(e);
          elf = null;
        }
      } else {
        elf = (elf orelse 0) + try std.fmt.parseUnsigned(u32, line, 0);
      }
    }
    if (elf) |e| { _ = max_elves.insert(e); }
  }

  const max_elf = max_elves.items[max_elves.items.len - 1];
  var sum_max_elves: u32 = 0;
  for (max_elves.items) |elf| {
    sum_max_elves += elf;
  }
  try std.io.getStdOut().writer().print("01 {} {}\n", .{ max_elf, sum_max_elves });
}
