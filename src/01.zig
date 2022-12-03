const std = @import("std");
const fs = std.fs;
const io = std.io;
const math = std.math;

const toplist = @import("toplist.zig");

fn orderU64(a: u64, b: u64) math.Order {
  return math.order(a, b);
}

pub fn main() !void {
  var maxElves = toplist.Toplist(u64, 3, orderU64){};
  {
    const file = try fs.cwd().openFile("src/01.txt", .{});
    defer file.close();
    const reader = file.reader();

    var buf: [100]u8 = undefined;

    var elf: ?u64 = null;
    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
      if (line.len == 0) {
        if (elf) |e| {
          _ = maxElves.insert(e);
          elf = null;
        }
      } else
        elf = (elf orelse 0) + try std.fmt.parseUnsigned(u64, line, 0);
    }
    if (elf) |e| _ = maxElves.insert(e);
  }

  const maxElf = maxElves.asSlice()[maxElves.count - 1];
  var sumMaxElves: u64 = 0;
  for (maxElves.asSlice()) |elf| sumMaxElves += elf;
  try std.io.getStdOut().writer().print("01 {} {}\n", .{ maxElf, sumMaxElves });
}
