const std = @import("std");
const fs = std.fs;
const io = std.io;
const mem = std.mem;

const Day06Error = error {
  InvalidSignal,
};

pub fn main() ![2]u64 {
  var count: u64 = 4;
  {
    const file = try fs.cwd().openFile("input/06.txt", .{});
    defer file.close();
    const reader = file.reader();

    var buf: [4]u8 = undefined;

    if ((try reader.read(&buf)) < 4) {
      return Day06Error.InvalidSignal;
    }

    while (true) {
      if (buf[3] == '\n') {
        return Day06Error.InvalidSignal;
      }
    
      if (check(&buf)) {
        break;
      }

      mem.copy(u8, buf[0..], buf[1..]);
      buf[3] = try reader.readByte();
      count += 1;
    }
  }

  return .{ count, 0 };
}

pub fn check(buf: []u8) bool {
  for (buf) |a, i| {
    for (buf[(i+1)..]) |b| {
      if (a == b) {
        return false;
      }
    }
  }
  return true;
}
