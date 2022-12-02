const std = @import("std");
const fs = std.fs;
const io = std.io;
const math = std.math;

const Day02Error = error {
  InvalidStrategy,
};

pub fn main() !void {
  var score: u32 = 0;
  {
    const file = try fs.cwd().openFile("src/02.txt", .{});
    defer file.close();
    const reader = file.reader();

    var buf: [4]u8 = undefined;

    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
      if (line.len != 3
        or line[0] < 'A' or line[0] > 'C'
        or line[1] != ' '
        or line[2] < 'X' or line[2] > 'Z')
        return Day02Error.InvalidStrategy;

      var opp = line[0] - 'A';
      var me = line[2] - 'X';
      score += 1 + me;
      score += switch ((me + 3 - opp) % 3) {
        0 => 3, // draw
        1 => 6, // victory
        2 => 0, // defeat
        else => unreachable,
      };
    }
  }

  try std.io.getStdOut().writer().print("02 {}\n", .{ score });
}
