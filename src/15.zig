const std = @import("std");
const fmt = std.fmt;
const fs = std.fs;
const heap = std.heap;
const io = std.io;
const math = std.math;
const mem = std.mem;

//const range_set = @import("range_set.zig");

const Allocator = mem.Allocator;

const Day15Error = error{
  BadSensor,
};

const Sensor = struct {
  pos: [2]isize,
  beacon: [2]isize,
  radius: isize,

  fn init(pos: [2]isize, beacon: [2]isize) !@This() {
    return .{
      .pos = pos,
      .beacon = beacon,
      .radius = try math.absInt(pos[0] - beacon[0]) + try math.absInt(pos[1] - beacon[1]),
    };
  }

  fn sees(self: @This(), x: [2]isize) bool {
    const dist = math.absCast(self.pos[0] - x[0]) + math.absCast(self.pos[1] - x[1]);
    return dist <= self.radius;
  }
};

pub fn main() ![2]u64 {
  var gpa = heap.GeneralPurposeAllocator(.{}){};
  defer _ = gpa.deinit();
  const alloc = gpa.allocator();

  var sensors = std.ArrayListUnmanaged(Sensor){};
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

      try sensors.append(alloc, try Sensor.init(.{ sx, sy }, .{ bx, by }));
    }
  }

  //  var minX: isize = math.maxInt(isize);
  //  var maxX: isize = math.minInt(isize);
  //  var minY: isize = math.maxInt(isize);
  //  var maxY: isize = math.minInt(isize);
  //  for (sensors.items) |s| {
  //  const d = try s.dist();
  //  if (minX > s.pos[0]-d) minX = s.pos[0]-d;
  //  if (maxX < s.pos[0]+d) maxX = s.pos[0]+d;
  //  if (minY > s.pos[1]-d) minY = s.pos[1]-d;
  //  if (maxY < s.pos[1]+d) maxY = s.pos[1]+d;
  //  }
  //  const width = maxX - minX + 1;
  //  const height = maxY - minY + 1;

  //  var grid = try alloc.alloc(?bool, width*height);
  //  defer alloc.free(grid);
  //  @memset(grid, null);

  //var blockedCellsLine2M = range_set.RangeSet {};
  var blockedCellsLine2M = std.AutoHashMapUnmanaged(isize, void){};
  defer blockedCellsLine2M.deinit(alloc);
  for (sensors.items) |s| {
    const distTo2M = try math.absInt(s.pos[1] - 2_000_000);

    if (distTo2M <= s.radius) {
      var x = s.pos[0] - (s.radius - distTo2M);
      while (x <= s.pos[0] + (s.radius - distTo2M)) : (x += 1) {
        try blockedCellsLine2M.put(alloc, x, {});
      }
    }
  }
  for (sensors.items) |s| {
    if (s.beacon[1] == 2_000_000)
      _ = blockedCellsLine2M.remove(s.beacon[0]);
  }

  var tree = QuadTree{ .pos = .{ 0, 0 }, .dim = .{ 4_000_001, 4_000_001 }, .inner = .{ .solid = true } };
  defer tree.deinit(alloc);
  for (sensors.items) |s| {
    std.debug.print("{},{}\n", .{ s.pos[0], s.pos[1] });
    _ = try tree.carveOut(alloc, s);
  }
  const derivedBeacon = tree.getSingle().?;
  const tuningFrequency = @intCast(usize, derivedBeacon[0] * 4_000_000 + derivedBeacon[1]);

  return .{ blockedCellsLine2M.count(), tuningFrequency };
}

const QuadTree = struct {
  dim: [2]isize,
  pos: [2]isize,
  inner: Contents,

  fn deinit(self: *@This(), alloc: Allocator) void {
    switch (self.inner) {
      .children => |c| {
        for (c) |*child| child.deinit(alloc);
        alloc.free(c);
      },
      else => {},
    }
  }

  // Returns true if this node is solidly in, false if this node is solidly out, or null if it is mixed.
  // This enables merging by the parent.
  fn carveOut(self: *@This(), alloc: Allocator, sensor: Sensor) !?bool {
    switch (self.inner) {
      .solid => |x| if (!x) return false, // Already empty
      else => {},
    }

    var cornerIn = false;
    var cornerOut = false;
    const corners = [_][2]isize{
      self.pos,
      .{ self.pos[0] + self.dim[0] - 1, self.pos[1] },
      .{ self.pos[0], self.pos[1] + self.dim[1] - 1 },
      .{ self.pos[0] + self.dim[0] - 1, self.pos[1] + self.dim[1] - 1 },
    };
    for (corners) |corner| {
      if (sensor.sees(corner)) cornerIn = true else cornerOut = true;
    }
    if (!cornerOut) { // Fully carved out
      self.deinit(alloc);
      self.inner = .{ .solid = false };
      return false;
    } else if (!cornerIn) { // Not affected
      return switch (self.inner) {
        .solid => |x| x,
        .children => null,
      };
    }

    switch (self.inner) {
      .children => |children| {
        var allFalse = true;
        var allTrue = true;
        for (children) |*child| {
          if (try child.carveOut(alloc, sensor)) |solid| {
            if (solid) allFalse = false else allTrue = false;
          } else {
            allTrue = false;
            allFalse = false;
          }
        }
        if (allFalse) { // Merge into solid false
          alloc.free(children);
          self.inner = .{ .solid = false };
          return false;
        } else if (allTrue) { // Merge into solid true
          alloc.free(children);
          self.inner = .{ .solid = true };
          return true;
        }
        return null;
      },
      .solid => |solid| {
        const halfDim = [2]isize{ @divFloor(self.dim[0], 2), @divFloor(self.dim[1], 2) };
        var children: []QuadTree = undefined;
        if (halfDim[0] == 1) { // Vertical stack of two
          children = try alloc.alloc(QuadTree, 2);
          children[0] = .{ .pos = self.pos, .dim = halfDim, .inner = .{ .solid = solid } };
          children[1] = .{ .pos = .{ self.pos[0], self.pos[1] + halfDim[1] }, .dim = .{ halfDim[0], self.dim[1] - halfDim[1] }, .inner = .{ .solid = solid } };
        } else if (halfDim[1] == 1) { // Horizontal line of two
          children = try alloc.alloc(QuadTree, 2);
          children[0] = .{ .pos = self.pos, .dim = halfDim, .inner = .{ .solid = solid } };
          children[1] = .{ .pos = .{ self.pos[0] + halfDim[0], self.pos[1] }, .dim = .{ self.dim[0] - halfDim[0], halfDim[1] }, .inner = .{ .solid = solid } };
        } else {
          children = try alloc.alloc(QuadTree, 4);
          children[0] = .{ .pos = self.pos, .dim = halfDim, .inner = .{ .solid = solid } };
          children[1] = .{ .pos = .{ self.pos[0] + halfDim[0], self.pos[1] }, .dim = .{ self.dim[0] - halfDim[0], halfDim[1] }, .inner = .{ .solid = solid } };
          children[2] = .{ .pos = .{ self.pos[0], self.pos[1] + halfDim[1] }, .dim = .{ halfDim[0], self.dim[1] - halfDim[1] }, .inner = .{ .solid = solid } };
          children[3] = .{ .pos = .{ self.pos[0] + halfDim[0], self.pos[1] + halfDim[1] }, .dim = .{ self.dim[0] - halfDim[0], self.dim[1] - halfDim[1] }, .inner = .{ .solid = solid } };
        }
        self.inner = .{ .children = children };
        // We know from corners test that we will not be merging into a solid block
        for (children) |*child| _ = try child.carveOut(alloc, sensor);
        return null;
      },
    }
  }

  fn getSingle(self: @This()) ?[2]isize {
    switch (self.inner) {
      .solid => |s| return if (s and self.dim[0] == 1 and self.dim[1] == 1) self.pos else null,
      .children => |c| {
        for (c) |child| {
          if (child.getSingle()) |x| return x;
        }
        return null;
      },
    }
  }
};

const Contents = union(enum) {
  solid: bool,
  children: []QuadTree,
};
