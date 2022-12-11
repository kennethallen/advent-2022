const std = @import("std");
const fs = std.fs;
const heap = std.heap;
const io = std.io;

const Allocator = std.mem.Allocator;

const Day08Error = error {
  InvalidTree,
  UnevenRows,
  TooSmall,
};

const VisTracker = struct {
  trees: [][]const u8,
  vis: []bool,
  height: usize,
  width: usize,
  sightline: u8 = 0,
  count: u64 = 0,

  pub fn init(alloc: Allocator, trees: [][]const u8) !@This() {
    if (trees.len < 2) return Day08Error.TooSmall;
    const width = trees[0].len;
    if (width < 2) return Day08Error.TooSmall;
    for (trees[1..]) |row|
      if (row.len != width) return Day08Error.UnevenRows;

    return .{
      .trees = trees,
      .vis = try alloc.alloc(bool, width * trees.len),
      .height = trees.len,
      .width = width,
    };
  }

  pub fn deinit(self: @This(), alloc: Allocator) void {
    alloc.free(self.vis);
  }

  pub fn doCount(self: *@This()) void {
    for (self.trees) |row, y| {
      var x: u64 = 0;
      while (x < self.width) : (x += 1)
        if (self.process(x, y, row[x])) break;
      self.sightline = 0;

      x = self.width;
      while (x > 0) {
        x -= 1;
        if (self.process(x, y, row[x])) break;
      }
      self.sightline = 0;
    }

    var x: u64 = 0;
    while (x < self.width) : (x += 1) {
      for (self.trees) |row, y|
        if (self.process(x, y, row[x])) break;
      self.sightline = 0;

      var y: u64 = self.height;
      while (y > 0) {
        y -= 1;
        if (self.process(x, y, self.trees[y][x])) break;
      }
      self.sightline = 0;
    }
  }

  fn process(self: *@This(), x: usize, y: usize, tree: u8) bool {
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

  var vis = try VisTracker.init(alloc, grid.items);
  defer vis.deinit(alloc);

  vis.doCount();

  return .{ vis.count, 0 };
}
