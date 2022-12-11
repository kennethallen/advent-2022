const std = @import("std");
const fs = std.fs;
const heap = std.heap;
const io = std.io;

const Allocator = std.mem.Allocator;

const Day08Error = error {
  InvalidTree,
  UnevenRows,
};

const VisTracker = struct {
  vis: []bool,
  count: u64 = 0,
  width: usize,
  sightline: u8 = 0,

  pub fn init(alloc: Allocator, width: usize, height: usize) !@This() {
    return .{
      .vis = try alloc.alloc(bool, width * height),
      .width = width,
    };
  }

  pub fn deinit(self: @This(), alloc: Allocator) void {
    alloc.free(self.vis);
  }

  pub fn process(self: *@This(), x: usize, y: usize, tree: u8) bool {
    if (tree >= self.sightline) {
      var vis = &self.vis[y*self.width + x];
      if (!vis.*) {
        vis.* = true;
        self.count += 1;
      }
      self.sightline = tree + 1;
      return self.sightline > 9;
    }
    return false;
  }

  pub fn reset(self: *@This()) void {
    self.sightline = 0;
  }
};

pub fn main() ![2]u64 {
  var gpa = heap.GeneralPurposeAllocator(.{}) {};
  defer _ = gpa.deinit();
  const alloc = gpa.allocator();

  var grid = std.ArrayListUnmanaged([]u8) {};
  defer grid.deinit(alloc);
  defer for (grid.items) |row| alloc.free(row);
  {
    const file = try fs.cwd().openFile("input/08.txt", .{});
    defer file.close();
    const reader = file.reader();

    while (try reader.readUntilDelimiterOrEofAlloc(alloc, '\n', 100)) |row| {
      errdefer alloc.free(row);
      for (row) |*tree| {
        if (tree.* < '0' or tree.* > '9')
          return Day08Error.InvalidTree;
        tree.* -= '0';
      }
      try grid.append(alloc, row);
    }
  }

  const height = grid.items.len;
  const width = grid.items[0].len;
  for (grid.items[1..]) |row|
    if (row.len != width) return Day08Error.UnevenRows;

  var vis = try VisTracker.init(alloc, width, height);
  defer vis.deinit(alloc);
  for (grid.items) |row, y| {
    var x: u64 = 0;
    while (x < width) : (x += 1)
      if (vis.process(x, y, row[x])) break;
    vis.reset();

    x = width;
    while (x > 0) {
      x -= 1;
      if (vis.process(x, y, row[x])) break;
    }
    vis.reset();
  }

  var x: u64 = 0;
  while (x < width) : (x += 1) {
    for (grid.items) |row, y|
      if (vis.process(x, y, row[x])) break;
    vis.reset();

    var y: u64 = height;
    while (y > 0) {
      y -= 1;
      if (vis.process(x, y, grid.items[y][x])) break;
    }
    vis.reset();
  }

  return .{ vis.count, 0 };
}
