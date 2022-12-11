const std = @import("std");
const fmt = std.fmt;
const fs = std.fs;
const heap = std.heap;
const io = std.io;
const math = std.math;

const Allocator = std.mem.Allocator;

const Day09Error = error {
  InvalidMove,
};

const Dir = enum { l, r, d, u };

const Rope = struct {
  h: [2]i64 = .{ 0, 0 },
  t: [2]i64 = .{ 0, 0 },
  trail: std.AutoHashMapUnmanaged([2]i64, void) = .{},

  pub fn init(alloc: Allocator) !@This() {
    var r = @This() {};
    try r.trail.put(alloc, r.t, {});
    return r;
  }

  pub fn deinit(self: *@This(), alloc: Allocator) void {
    self.trail.deinit(alloc);
  }

  pub fn move(self: *@This(), alloc: Allocator, dir: Dir) !void {
    switch (dir) {
      .l => {
        self.h[0] -= 1;
        if (self.t[0] > self.h[0] + 1) {
          self.t = .{ self.h[0] + 1, self.h[1] };
          try self.trail.put(alloc, self.t, {});
        }
      },
      .r => {
        self.h[0] += 1;
        if (self.t[0] < self.h[0] - 1) {
          self.t = .{ self.h[0] - 1, self.h[1] };
          try self.trail.put(alloc, self.t, {});
        }
      },
      .d => {
        self.h[1] -= 1;
        if (self.t[1] > self.h[1] + 1) {
          self.t = .{ self.h[0], self.h[1] + 1 };
          try self.trail.put(alloc, self.t, {});
        }
      },
      .u => {
        self.h[1] += 1;
        if (self.t[1] < self.h[1] - 1) {
          self.t = .{ self.h[0], self.h[1] - 1 };
          try self.trail.put(alloc, self.t, {});
        }
      },
    }
  }
};

pub fn main() ![2]u64 {
  var gpa = heap.GeneralPurposeAllocator(.{}) {};
  defer _ = gpa.deinit();
  const alloc = gpa.allocator();

  var rope = try Rope.init(alloc);
  defer rope.deinit(alloc);
  {
    const file = try fs.cwd().openFile("input/09.txt", .{});
    defer file.close();
    const reader = file.reader();

    var buf: [100]u8 = undefined;

    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |row| {
      if (row.len < 3 or row[1] != ' ')
        return Day09Error.InvalidMove;
      const dir: Dir = switch (row[0]) {
        'L' => .l,
        'R' => .r,
        'D' => .d,
        'U' => .u,
        else => return Day09Error.InvalidMove,
      };
      var mag = try fmt.parseUnsigned(u64, row[2..], 0);
      while (mag > 0) : (mag -= 1)
        try rope.move(alloc, dir);
    }
  }

  return .{ rope.trail.count(), 0 };
}
