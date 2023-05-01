const std = @import("std");
const fs = std.fs;
const heap = std.heap;
const io = std.io;
const mem = std.mem;

const Allocator = mem.Allocator;

const Day08Error = error{
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
  count: u64 = undefined,

  pub fn init(alloc: Allocator, trees: [][]const u8) !@This() {
    if (trees.len < 2) return Day08Error.TooSmall;
    const width = trees[0].len;
    if (width < 2) return Day08Error.TooSmall;
    for (trees[1..]) |row|
      if (row.len != width) return Day08Error.UnevenRows;
    var vis = try alloc.alloc(bool, width * trees.len);
    mem.set(bool, vis, false);

    return .{ .trees = trees, .vis = vis, .height = trees.len, .width = width };
  }

  pub fn deinit(self: @This(), alloc: Allocator) void {
    alloc.free(self.vis);
  }

  pub fn doCount(self: *@This()) u64 {
    self.count = 4; // Corners

    for (self.trees[1 .. self.height - 1], 0..) |_, y| {
      var x: u64 = 0;
      while (x < self.width) : (x += 1)
        if (self.process(x, y + 1)) break;
      self.sightline = 0;

      x = self.width;
      while (x > 0) {
        x -= 1;
        if (self.process(x, y + 1)) break;
      }
      self.sightline = 0;
    }

    var x: u64 = 1;
    while (x < self.width - 1) : (x += 1) {
      for (self.trees, 0..) |_, y|
        if (self.process(x, y)) break;
      self.sightline = 0;

      var y: u64 = self.height;
      while (y > 0) {
        y -= 1;
        if (self.process(x, y)) break;
      }
      self.sightline = 0;
    }

    return self.count;
  }

  fn process(self: *@This(), x: usize, y: usize) bool {
    const tree = self.trees[y][x];
    if (tree >= self.sightline) {
      var vis = &self.vis[y * self.width + x];
      if (!vis.*) {
        vis.* = true;
        self.count += 1;
      }
      self.sightline = tree + 1;
      return self.sightline > 9;
    }
    return false;
  }

  fn scoreTree(self: @This(), x: usize, y: usize) u64 {
    const tree = self.trees[y][x];
    // Right
    var checkDist: u64 = 0;
    while (checkDist + 1 < self.width - x) {
      checkDist += 1;
      if (self.trees[y][x + checkDist] >= tree) break;
    }
    var prod = checkDist;
    // Left
    checkDist = 0;
    while (checkDist + 1 <= x) {
      checkDist += 1;
      if (self.trees[y][x - checkDist] >= tree) break;
    }
    prod *= checkDist;
    // Down
    checkDist = 0;
    while (checkDist + 1 < self.height - y) {
      checkDist += 1;
      if (self.trees[y + checkDist][x] >= tree) break;
    }
    prod *= checkDist;
    // Up
    checkDist = 0;
    while (checkDist + 1 <= y) {
      checkDist += 1;
      if (self.trees[y - checkDist][x] >= tree) break;
    }
    prod *= checkDist;
    return prod;
  }

  fn maxScore(self: @This()) u64 {
    var max: u64 = 0;
    var x: usize = 0;
    while (x < self.width) : (x += 1) {
      var y: usize = 0;
      while (y < self.height) : (y += 1) {
        const score = self.scoreTree(x, y);
        if (score > max) max = score;
      }
    }
    return max;
  }
};

pub fn main() ![2]u64 {
  var gpa = heap.GeneralPurposeAllocator(.{}){};
  defer _ = gpa.deinit();
  const alloc = gpa.allocator();

  var grid = std.ArrayListUnmanaged([]u8){};
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

  return .{ vis.doCount(), vis.maxScore() };
}
