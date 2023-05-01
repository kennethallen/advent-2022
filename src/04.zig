const std = @import("std");
const fs = std.fs;
const io = std.io;

const Day04Error = error{
  InvalidAssignmentPair,
};

pub fn main() ![2]u64 {
  var fullContains: u64 = 0;
  var overlaps: u64 = 0;
  {
    const file = try fs.cwd().openFile("input/04.txt", .{});
    defer file.close();
    const reader = file.reader();

    var buf: [100]u8 = undefined;

    while (true) {
      const e0lo = try std.fmt.parseUnsigned(u64, try reader.readUntilDelimiterOrEof(&buf, '-') orelse break, 0);
      const e0hi = try std.fmt.parseUnsigned(u64, try reader.readUntilDelimiter(&buf, ','), 0);
      const e1lo = try std.fmt.parseUnsigned(u64, try reader.readUntilDelimiter(&buf, '-'), 0);
      const e1hi = try std.fmt.parseUnsigned(u64, try reader.readUntilDelimiter(&buf, '\n'), 0);

      if (e0lo > e0hi or e1lo > e1hi)
        return Day04Error.InvalidAssignmentPair;

      if ((e0lo >= e1lo and e0hi <= e1hi) or (e1lo >= e0lo and e1hi <= e0hi))
        fullContains += 1;
      if (e0hi >= e1lo and e1hi >= e0lo)
        overlaps += 1;
    }
  }

  return .{ fullContains, overlaps };
}
