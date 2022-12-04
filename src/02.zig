const std = @import("std");
const fs = std.fs;
const io = std.io;

const Day02Error = error {
  InvalidStrategy,
};

pub fn main() ![2]u64 {
  var score0: u64 = 0;
  var score1: u64 = 0;
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

      var opp = line[0] - 'A';           // 0/1/2 for R/P/S
      var me = line[2] - 'X';            // 0/1/2 for R/P/S (part 1) or lose/draw/win (part 2)

      score0 += 1 + me                   // 1/2/3 for my R/P/S
        + 3 * ((4 + me - opp) % 3);      // 0/3/6 for lose/draw/win
      score1 += 1 + ((opp + me + 2) % 3) // 1/2/3 for my R/P/S
        + 3 * me;                        // 0/3/6 for lose/draw/win
    }
  }

  return .{ score0, score1 };
}
