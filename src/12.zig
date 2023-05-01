const std = @import("std");
const fmt = std.fmt;
const fs = std.fs;
const heap = std.heap;
const io = std.io;
const math = std.math;
const mem = std.mem;

const a_star = @import("a_star.zig");

const Allocator = mem.Allocator;

const Day12Error = error{
  InvalidCell,
  InvalidGrid,
  NoStart,
  MultipleStart,
  NoEnd,
  MultipleEnd,
  NoPath,
};

pub fn main() ![2]u64 {
  var gpa = heap.GeneralPurposeAllocator(.{}){};
  defer _ = gpa.deinit();
  const alloc = gpa.allocator();

  var grid = std.ArrayListUnmanaged([]u8){};
  defer grid.deinit(alloc);
  defer for (grid.items) |line| alloc.free(line);

  const ends: [2][2]usize = input: {
    const file = try fs.cwd().openFile("input/12.txt", .{});
    defer file.close();
    const reader = file.reader();

    var start: ?[2]usize = null;
    var end: ?[2]usize = null;

    var y: usize = 0;
    while (try reader.readUntilDelimiterOrEofAlloc(alloc, '\n', 1_000)) |*line| {
      errdefer alloc.free(line.*);
      if (y > 0 and line.len != grid.items[0].len)
        return Day12Error.InvalidGrid;

      for (line.*, 0..) |*cell, x| {
        if (cell.* >= 'a' and cell.* <= 'z')
          cell.* -= 'a'
        else if (cell.* == 'S') {
          if (start) |_| return Day12Error.MultipleStart;
          start = .{ x, y };
          cell.* = 'a' - 'a';
        } else if (cell.* == 'E') {
          if (end) |_| return Day12Error.MultipleEnd;
          end = .{ x, y };
          cell.* = 'z' - 'a';
        } else return Day12Error.InvalidCell;
      }

      try grid.append(alloc, line.*);
      y += 1;
    }

    if (start) |s| {
      if (end) |e| {
        break :input .{ s, e };
      } else return Day12Error.NoEnd;
    } else return Day12Error.NoStart;
  };

  const width = grid.items[0].len;
  const height = grid.items.len;

  return .{
    try a_star.aStar(
      [2]usize,
      usize,
      AStarCtx{ .end = ends[1], .grid = grid.items, .width = width, .height = height },
      alloc,
      ends[0],
      pathfindHeur,
      pathfindExplore,
    ),
    try a_star.aStar(
      [2]usize,
      usize,
      DijkstraCtx{ .grid = grid.items, .width = width, .height = height },
      alloc,
      ends[1],
      dijkstraHeur,
      dijkstraExplore,
    ),
  };
}

const AStarCtx = struct {
  end: [2]usize,
  grid: [][]const u8,
  width: usize,
  height: usize,
};
fn pathfindHeur(ctx: AStarCtx, a: [2]usize) ?usize {
  // Taxicab distance
  const d = (if (a[0] > ctx.end[0]) a[0] - ctx.end[0] else ctx.end[0] - a[0]) + (if (a[1] > ctx.end[1]) a[1] - ctx.end[1] else ctx.end[1] - a[1]);
  return if (d == 0) null else d;
}
fn pathfindExplore(ctx: AStarCtx, x: [2]usize, buf: *std.ArrayList(a_star.Explore([2]usize, usize))) !void {
  const heightLimit = 1 + ctx.grid[x[1]][x[0]];

  // Left
  if (x[0] > 0) {
    const l = [2]usize{ x[0] - 1, x[1] };
    if (ctx.grid[l[1]][l[0]] <= heightLimit)
      try buf.append(.{ .pos = l, .edgeCost = 1 });
  }
  // Right
  if (x[0] < ctx.width - 1) {
    const r = [2]usize{ x[0] + 1, x[1] };
    if (ctx.grid[r[1]][r[0]] <= heightLimit)
      try buf.append(.{ .pos = r, .edgeCost = 1 });
  }
  // Up
  if (x[1] > 0) {
    const u = [2]usize{ x[0], x[1] - 1 };
    if (ctx.grid[u[1]][u[0]] <= heightLimit)
      try buf.append(.{ .pos = u, .edgeCost = 1 });
  }
  // Down
  if (x[1] < ctx.height - 1) {
    const d = [2]usize{ x[0], x[1] + 1 };
    if (ctx.grid[d[1]][d[0]] <= heightLimit)
      try buf.append(.{ .pos = d, .edgeCost = 1 });
  }
}

const DijkstraCtx = struct {
  grid: [][]const u8,
  width: usize,
  height: usize,
};
fn dijkstraHeur(ctx: DijkstraCtx, a: [2]usize) ?usize {
  return if (ctx.grid[a[1]][a[0]] == 0) null else 0;
}
fn dijkstraExplore(ctx: DijkstraCtx, x: [2]usize, buf: *std.ArrayList(a_star.Explore([2]usize, usize))) !void {
  const heightMin = ctx.grid[x[1]][x[0]] - 1;

  // Left
  if (x[0] > 0) {
    const l = [2]usize{ x[0] - 1, x[1] };
    if (ctx.grid[l[1]][l[0]] >= heightMin)
      try buf.append(.{ .pos = l, .edgeCost = 1 });
  }
  // Right
  if (x[0] < ctx.width - 1) {
    const r = [2]usize{ x[0] + 1, x[1] };
    if (ctx.grid[r[1]][r[0]] >= heightMin)
      try buf.append(.{ .pos = r, .edgeCost = 1 });
  }
  // Up
  if (x[1] > 0) {
    const u = [2]usize{ x[0], x[1] - 1 };
    if (ctx.grid[u[1]][u[0]] >= heightMin)
      try buf.append(.{ .pos = u, .edgeCost = 1 });
  }
  // Down
  if (x[1] < ctx.height - 1) {
    const d = [2]usize{ x[0], x[1] + 1 };
    if (ctx.grid[d[1]][d[0]] >= heightMin)
      try buf.append(.{ .pos = d, .edgeCost = 1 });
  }
}
