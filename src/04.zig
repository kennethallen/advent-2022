const std = @import("std");
const fs = std.fs;
const io = std.io;

const Day03Error = error {
  InvalidRucksack,
  NoMisplacedItem,
  NoBadge,
};

pub fn main() !void {
  var fullContains: u64 = 0;
  {
    const file = try fs.cwd().openFile("src/04.txt", .{});
    defer file.close();
    const reader = file.reader();

    var buf: [100]u8 = undefined;

    while (true) {
      const e0lo = try std.fmt.parseUnsigned(u64,
        try reader.readUntilDelimiterOrEof(&buf, '-') orelse break, 0);
      const e0hi = try std.fmt.parseUnsigned(u64,
        try reader.readUntilDelimiter(&buf, ','), 0);
      const e1lo = try std.fmt.parseUnsigned(u64,
        try reader.readUntilDelimiter(&buf, '-'), 0);
      const e1hi = try std.fmt.parseUnsigned(u64,
        try reader.readUntilDelimiter(&buf, '\n'), 0);

      if ((e0lo >= e1lo and e0hi <= e1hi) or (e1lo >= e0lo and e1hi <= e0hi))
        fullContains += 1;
    }
  }

  try io.getStdOut().writer().print("04 {} {}\n", .{ fullContains, 0 });
}