const std = @import("std");
const fs = std.fs;
const io = std.io;

const Day03Error = error {
  InvalidRucksack,
  NoMisplacedItem,
  NoBadge,
};

pub fn main() !void {
  var sumPrios0: u64 = 0;
  var sumPrios1: u64 = 0;
  {
    const file = try fs.cwd().openFile("src/03.txt", .{});
    defer file.close();
    const reader = file.reader();

    var bufs: [3][100]u8 = undefined;

    input: while (true) {
      var lines: [bufs.len][]u8 = undefined;
      inline for (lines) |*line, i| {
        line.* = if (i == 0)
          try reader.readUntilDelimiterOrEof(&bufs[i], '\n') orelse break :input
        else
          try reader.readUntilDelimiter(&bufs[i], '\n');
        sumPrios0 += try part0(line.*);
      }
      
      sumPrios1 += try part1(&lines);
    }
  }

  try io.getStdOut().writer().print("03 {} {}\n", .{ sumPrios0, sumPrios1 });
}

fn part0(sack: []const u8) !u8 {
  if (sack.len % 2 != 0)
    return Day03Error.InvalidRucksack;

  const mid = sack.len / 2;
  for (sack[0..mid]) |x|
    for (sack[mid..]) |y|
      if (x == y)
        return itemPrio(x);

  return Day03Error.NoMisplacedItem;
}

fn part1(sacks: [][]const u8) !u8 {
  firstSack: for (sacks[0]) |x| {
    otherSacks: for (sacks[1..]) |sack| {
      for (sack) |y|
        if (x == y)
          continue :otherSacks;
      continue :firstSack;
    }
    return itemPrio(x);
  }

  return Day03Error.NoBadge;
}

fn itemPrio(i: u8) u8 {
  return i - if (i < 'a') @as(u8, 'A' - 27) else @as(u8, 'a' - 1);
}
