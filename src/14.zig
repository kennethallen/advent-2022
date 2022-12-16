const std = @import("std");
const fmt = std.fmt;
const fs = std.fs;
const heap = std.heap;
const io = std.io;
const math = std.math;
const mem = std.mem;

const Allocator = mem.Allocator;

const Day14Error = error {
  BadLine,
  BadDelimiter,
  EntranceBlocked,
};

pub fn main() ![2]u64 {
  var gpa = heap.GeneralPurposeAllocator(.{}) {};
  defer _ = gpa.deinit();
  const alloc = gpa.allocator();

  var fill = std.AutoHashMapUnmanaged([2]usize, bool) {};
  defer fill.deinit(alloc);
  {
    const file = try fs.cwd().openFile("input/14.txt", .{});
    defer file.close();
    const reader = file.reader();

    var buf: [500]u8 = undefined;

    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
      var j: usize = 1;
      while (line[j] != ',') j += 1;
      var p0 = [2]usize { try fmt.parseUnsigned(usize, line[0..j], 0), undefined };
      var i: usize = j + 1;
      while (i < line.len and line[i] != ' ') i += 1;
      p0[1] = try fmt.parseUnsigned(usize, line[j+1..i], 0);

      try fill.put(alloc, p0, true);

      while (i < line.len) {
        if (!mem.eql(u8, line[i+1..i+4], "-> ")) return Day14Error.BadDelimiter;
        i += 4;
        j = i + 1;
        while (line[j] != ',') j += 1;
        var p1 = [2]usize { try fmt.parseUnsigned(usize, line[i..j], 0), undefined };
        i = j + 1;
        while (i < line.len and line[i] != ' ') i += 1;
        p1[1] = try fmt.parseUnsigned(usize, line[j+1..i], 0);
        
        if (p0[0] == p1[0]) {
          var y = p0[1];
          if (p0[1] < p1[1])
            while (y <= p1[1]) : (y += 1)
              try fill.put(alloc, .{ p0[0], y }, true)
          else
            while (y >= p1[1]) : (y -= 1)
              try fill.put(alloc, .{ p0[0], y }, true);
        } else if (p0[1] == p1[1]) {
          var x = p0[0];
          if (p0[0] < p1[0])
            while (x <= p1[0]) : (x += 1)
              try fill.put(alloc, .{ x, p0[1] }, true)
          else
            while (x >= p1[0]) : (x -= 1)
              try fill.put(alloc, .{ x, p0[1] }, true);
        } else
          return Day14Error.BadLine;
        p0 = p1;
      }
    }
  }

  var floor: usize = 0;
  {
    var rocks = fill.keyIterator();
    while (rocks.next()) |rock| {
      if (rock[1] > floor) floor = rock[1];
    }
  }

  var sand: usize = 0;
  pour: while (true) : (sand += 1) {
    var x = [2]usize { 500, 0 };
    if (fill.contains(x)) return Day14Error.EntranceBlocked;
    while (true) {
      if (!fill.contains(.{ x[0], x[1]+1 })) {}
      else if (!fill.contains(.{ x[0]-1, x[1]+1 })) x[0] -= 1
      else if (!fill.contains(.{ x[0]+1, x[1]+1 })) x[0] += 1
      else {
        try fill.put(alloc, x, false);
        std.debug.print("{},{}\n", .{x[0], x[1]});
        break;
      }
      x[1] += 1;
      if (x[1] >= floor + 10) break :pour;
    }
  }

  {
    var maxX: usize = 0;
    var minX: usize = 1000000;
    {
      var cells = fill.keyIterator();
      while (cells.next()) |c| {
        if (c[0] < minX) minX = c[0];
        if (c[0] > maxX) maxX = c[0];
      }
    }

    var cy: usize = 0;
    while (cy <= floor) : (cy += 1) {
      var cx: usize = minX;
      while (cx <= maxX) : (cx += 1) {
        const cell: u8 = if (fill.get(.{cx,cy})) |rock| (if (rock) '#' else 'o') else ' ';
        std.debug.print("{c}", .{cell});
      }
      std.debug.print("\n", .{});
    }
    var i: usize = minX;
    while (i <= maxX) : (i += 1) std.debug.print("-", .{});
    std.debug.print("\n", .{});
  }

  return .{ sand, 0 };
}
