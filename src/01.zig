const std = @import("std");
const fs = std.fs;
const io = std.io;
const math = std.math;

const toplist = @import("toplist.zig");

fn order_u64(a: u64, b: u64) math.Order {
  return math.order(a, b);
}

pub fn main() !void {
  var max_elves = toplist.Toplist(u64, 3, order_u64){};
  {
    const file = try fs.cwd().openFile("src/01.txt", .{});
    defer file.close();
    const reader = file.reader();

    var buf: [100]u8 = undefined;

    var elf: ?u64 = null;
    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
      if (line.len == 0) {
        if (elf) |e| {
          _ = max_elves.insert(e);
          elf = null;
        }
      } else
        elf = (elf orelse 0) + try std.fmt.parseUnsigned(u64, line, 0);
    }
    if (elf) |e| _ = max_elves.insert(e);
  }

  const max_elf = max_elves.asSlice()[max_elves.count - 1];
  var sum_max_elves: u64 = 0;
  for (max_elves.asSlice()) |elf| sum_max_elves += elf;
  try std.io.getStdOut().writer().print("01 {} {}\n", .{ max_elf, sum_max_elves });
}
