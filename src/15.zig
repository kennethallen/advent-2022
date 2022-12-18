const std = @import("std");
const fmt = std.fmt;
const fs = std.fs;
const heap = std.heap;
const io = std.io;
const math = std.math;
const mem = std.mem;

//const range_set = @import("range_set.zig");

const Allocator = mem.Allocator;

const Day15Error = error {
  BadSensor,
};

const Sensor = struct {
  pos: [2]isize,
  beacon: [2]isize,

  fn dist(self: @This()) !isize {
    return try math.absInt(self.pos[0]-self.beacon[0]) + try math.absInt(self.pos[1]-self.beacon[1]);
  }
};

pub fn main() ![2]u64 {
  var gpa = heap.GeneralPurposeAllocator(.{}) {};
  defer _ = gpa.deinit();
  const alloc = gpa.allocator();

  var sensors = std.ArrayListUnmanaged(Sensor) {};
  defer sensors.deinit(alloc);
  {
    const file = try fs.cwd().openFile("input/15.txt", .{});
    defer file.close();
    const reader = file.reader();

    var buf: [100]u8 = undefined;

    while (true) {
      if (!mem.eql(u8, "Sensor at x", try reader.readUntilDelimiterOrEof(&buf, '=') orelse break))
        return Day15Error.BadSensor;
      const sx = try fmt.parseInt(isize, try reader.readUntilDelimiter(&buf, ','), 0);
      if (!mem.eql(u8, " y", try reader.readUntilDelimiter(&buf, '=')))
        return Day15Error.BadSensor;
      const sy = try fmt.parseInt(isize, try reader.readUntilDelimiter(&buf, ':'), 0);
      if (!mem.eql(u8, " closest beacon is at x", try reader.readUntilDelimiter(&buf, '=')))
        return Day15Error.BadSensor;
      const bx = try fmt.parseInt(isize, try reader.readUntilDelimiter(&buf, ','), 0);
      if (!mem.eql(u8, " y", try reader.readUntilDelimiter(&buf, '=')))
        return Day15Error.BadSensor;
      const by = try fmt.parseInt(isize, try reader.readUntilDelimiter(&buf, '\n'), 0);

      try sensors.append(alloc, .{ .pos = .{ sx, sy }, .beacon = .{ bx, by } });
    }
  }

//  var minX: isize = math.maxInt(isize);
//  var maxX: isize = math.minInt(isize);
//  var minY: isize = math.maxInt(isize);
//  var maxY: isize = math.minInt(isize);
//  for (sensors.items) |s| {
//    const d = try s.dist();
//    if (minX > s.pos[0]-d) minX = s.pos[0]-d;
//    if (maxX < s.pos[0]+d) maxX = s.pos[0]+d;
//    if (minY > s.pos[1]-d) minY = s.pos[1]-d;
//    if (maxY < s.pos[1]+d) maxY = s.pos[1]+d;
//  }
//  const width = maxX - minX + 1;
//  const height = maxY - minY + 1;

//  var grid = try alloc.alloc(?bool, width*height);
//  defer alloc.free(grid);
//  mem.set(?bool, grid, null);

  //var blockedCellsLine2M = range_set.RangeSet {};
  var blockedCellsLine2M = std.AutoHashMapUnmanaged(isize, void) {};
  defer blockedCellsLine2M.deinit(alloc);
  for (sensors.items) |s| {
    const radius = try s.dist();
    const distTo2M = try math.absInt(s.pos[1]-2_000_000);
      
    if (distTo2M <= radius) {
      var x = s.pos[0]-(radius-distTo2M);
      while (x <= s.pos[0]+(radius-distTo2M)) : (x += 1) {
        try blockedCellsLine2M.put(alloc, x, {});
      }
    }
  }
  for (sensors.items) |s| {
    if (s.beacon[1] == 2_000_000)
      _ = blockedCellsLine2M.remove(s.beacon[0]);
  }

  return .{ blockedCellsLine2M.count(), 0 };
}
