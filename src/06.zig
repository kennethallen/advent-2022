const std = @import("std");
const fs = std.fs;
const io = std.io;
const mem = std.mem;

const Day06Error = error {
  InvalidSignal,
};

pub fn main() ![2]u64 {
  return .{ try findMarker(4), try findMarker(14) };
}

fn findMarker(comptime window: usize) !u64 {
  const file = try fs.cwd().openFile("input/06.txt", .{});
  defer file.close();
  const reader = file.reader();

  var buf: [window]u8 = undefined;
  var toAdvance: usize = window;
  var total = toAdvance;

  while (true) {
    if (try reader.read(buf[buf.len - toAdvance..]) < toAdvance)
      return Day06Error.InvalidSignal;
    if (buf[buf.len - 1] == '\n')
      return Day06Error.InvalidSignal;
  
    toAdvance = check(&buf, buf.len - toAdvance);
    if (toAdvance == 0) break;

    mem.copy(u8, buf[0..], buf[toAdvance..]);
    total += toAdvance;
  }

  return @intCast(u64, total);
}

fn check(buf: []u8, split: usize) usize {
  const lastNew = @max(split, 1);
  var toAdvance: usize = 0;

  var n = buf.len - 1;
  while (n >= lastNew and n > toAdvance) : (n -= 1) {
    var m = n;
    while (m > toAdvance) : (m -= 1) {
      if (buf[n] == buf[m - 1]) {
        toAdvance = m;
        break;
      }
    }
  }

  return toAdvance;
}
