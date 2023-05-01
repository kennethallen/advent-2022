const std = @import("std");
const fs = std.fs;
const io = std.io;
const math = std.math;

const toplist = @import("toplist.zig");

pub fn main() ![2]u64 {
  var maxElves = toplist.Toplist(u64, 3){};
  {
    const file = try fs.cwd().openFile("input/01.txt", .{});
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
      } else elf = (elf orelse 0) + try std.fmt.parseUnsigned(u64, line, 0);
    }
    if (elf) |e| _ = maxElves.insert(e);
  }

  const maxElf = maxElves.asSlice()[maxElves.count - 1];
  var sumMaxElves: u64 = 0;
  for (maxElves.asSlice()) |elf| sumMaxElves += elf;
  return .{ maxElf, sumMaxElves };
}
