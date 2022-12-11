const std = @import("std");
const fmt = std.fmt;
const fs = std.fs;
const heap = std.heap;
const io = std.io;
const math = std.math;
const mem = std.mem;

const Allocator = std.mem.Allocator;

const Day10Error = error {
  InvalidInstruction,
};

pub fn main() ![2]u64 {
  var sum: i64 = 0;
  {
    const file = try fs.cwd().openFile("input/10.txt", .{});
    defer file.close();
    const reader = file.reader();

    const writer = io.getStdOut().writer();

    var buf: [100]u8 = undefined;
    var x: i64 = 1;
    var cycle: i64 = 0;
    var nextAdd: i64 = 20;

    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |row| {
      var nextX: i64 = x;
      var nextCycle: i64 = cycle;
      if (mem.eql(u8, row, "noop"))
        nextCycle += 1
      else if (row.len >= 6 and mem.eql(u8, row[0..5], "addx ")) {
        nextCycle += 2;
        nextX += try fmt.parseInt(i64, row[5..], 0);
      } else
        return Day10Error.InvalidInstruction;

      while (cycle < nextCycle) {
        const screenPos = @mod(cycle, 40);
        const px = x >= screenPos - 1 and x <= screenPos + 1;
        try writer.writeByte(if (px) '#' else ' ');
        if (screenPos == 39) try writer.writeByte('\n');

        cycle += 1;

        if (cycle >= nextAdd) {
          sum += nextAdd * x;
          nextAdd += 40;
        }
      }
      
      x = nextX;
    }
  }

  return .{ @intCast(u64, sum), 0 };
}
