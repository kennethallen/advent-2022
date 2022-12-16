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

const Cell = enum { empty, rock, sand };

pub fn main() ![2]u64 {
  var gpa = heap.GeneralPurposeAllocator(.{}) {};
  defer _ = gpa.deinit();
  const alloc = gpa.allocator();

  var walls = std.ArrayListUnmanaged(std.ArrayListUnmanaged([2]usize)) {};
  defer walls.deinit(alloc);
  defer for (walls.items) |*w| w.deinit(alloc);
  {
    const file = try fs.cwd().openFile("input/14.txt", .{});
    defer file.close();
    const reader = file.reader();

    var buf: [500]u8 = undefined;

    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
      var wall = std.ArrayListUnmanaged([2]usize) {};
      errdefer wall.deinit(alloc);

      var j: usize = 1;
      while (line[j] != ',') j += 1;
      var k = j + 1;
      while (k < line.len and line[k] != ' ') k += 1;
      try wall.append(alloc, .{
        try fmt.parseUnsigned(usize, line[0..j], 0),
        try fmt.parseUnsigned(usize, line[j+1..k], 0),
      });

      while (k < line.len) {
        if (!mem.eql(u8, line[k+1..k+4], "-> ")) return Day14Error.BadDelimiter;
        var i = k + 4;
        j = i + 1;
        while (line[j] != ',') j += 1;
        k = j + 1;
        while (k < line.len and line[k] != ' ') k += 1;
        try wall.append(alloc, .{
          try fmt.parseUnsigned(usize, line[i..j], 0),
          try fmt.parseUnsigned(usize, line[j+1..k], 0),
        });
      }

      try walls.append(alloc, wall);
    }
  }

  //for (walls.items) |wall| {
    //std.debug.print("{},{}", .{wall.items[0][0], wall.items[0][1]});
    //for (wall.items[1..]) |c| {
      //std.debug.print(" -> {},{}", .{c[0], c[1]});
    //}
    //std.debug.print("\n", .{});
  //}

  var minX: usize = math.maxInt(usize);
  var maxX: usize = 0;
  var maxY: usize = 0;
  for (walls.items) |wall|
    for (wall.items) |c| {
      if (c[0] < minX) minX = c[0];
      if (c[0] > maxX) maxX = c[0];
      if (c[1] > maxY) maxY = c[1];
    };
  const xOffset = minX - 1;
  const width = maxX - minX + 2;
  const height = maxY + 1;
  std.debug.print("xOffset {} width {} height {}\n", .{xOffset, width, height});

  var grid = try alloc.alloc(Cell, width*height);
  defer alloc.free(grid);
  mem.set(Cell, grid, .empty);

  for (walls.items) |wall| {
    for (wall.items) |*c| c[0] -= xOffset;

    for (wall.items[0..wall.items.len-1]) |c0, i| {
      const c1 = wall.items[i+1];

      if (c0[0] == c1[0]) { // Vertical
        var y = c0[1];
        if (c0[1] < c1[1]) { // Down
          std.debug.print("Down {}x{} {},{} {},{} {},{}\n", .{width, height, c0[0], y, c0[0], c0[1], c1[0], c1[1]});
          while (y < c1[1]) : (y += 1) {
            grid[c0[0] + y*width] = .rock;
          }
        } else { // Up
          std.debug.print("Up {}x{} {},{} {},{} {},{}\n", .{width, height, c0[0], y, c0[0], c0[1], c1[0], c1[1]});
          while (y > c1[1]) : (y -= 1) {
            grid[c0[0] + y*width] = .rock;
          }
        }
      } else if (c0[1] == c1[1]) { // Horizontal
        if (c0[0] < c1[0]) { // Right
          std.debug.print("{}x{} {},{} {},{}\n", .{width, height, c0[0], c0[1], c1[0], c1[1]});
          std.debug.print("Right {}-{}\n", .{c0[1]*width+c0[0], c0[1]*width+c1[0]});
          mem.set(Cell, grid[c0[1]*width..][c0[0]..c1[0]], .rock);
        } else { // Left
          std.debug.print("{}x{} {},{} {},{}\n", .{width, height, c0[0], c0[1], c1[0], c1[1]});
          std.debug.print("Left {}-{}\n", .{c0[1]*width+c1[0]+1, c0[1]*width+c0[0]+1});
          mem.set(Cell, grid[c0[1]*width..][c1[0]+1..c0[0]+1], .rock);
        }
      } else
        return Day14Error.BadLine;
    }

    const cEnd = wall.items[wall.items.len-1];
    grid[cEnd[0] + width*cEnd[1]] = .rock;
  }

  // test
  for (walls.items) |wall| {
    for (wall.items) |c| {
      if (grid[c[0] + width*c[1]] != .rock)
        std.debug.print("No rock {},{}\n", .{c[0],c[1]});
    }
  }
  //{
    //var px: usize = 0;
    //while (px < width) : (px += 1) {
      //var py: usize = 0;
      //while (py < height) : (py += 1) {
        //const shouldBeRock = slow: {
          //for (walls.items) |wall| {
            
          //}
        //};
      //}
    //}
  //}

  var sand: usize = 0;
  pour: while (true) : (sand += 1) {
    var s = [2]usize { 500-xOffset, 0 };
    if (grid[s[0] + s[1]*width] != .empty) return Day14Error.EntranceBlocked;
    while (true) {
      if (grid[s[0] + (s[1]+1)*width] == .empty) {}
      else if (grid[s[0]-1 + (s[1]+1)*width] == .empty) s[0] -= 1
      else if (grid[s[0]+1 + (s[1]+1)*width] == .empty) s[0] += 1
      else {
        grid[s[0] + s[1]*width] = .sand;
        std.debug.print("{},{}\n", .{s[0], s[1]});
        break;
      }
      s[1] += 1;
      if (s[1] >= height-1) break :pour;
    }
  }

  if (true) {
    var cy: usize = 0;
    while (cy < height) : (cy += 1) {
      var cx: usize = 0;
      while (cx < width) : (cx += 1) {
        const cell: u8 = switch (grid[cx + cy*width]) {
          .empty => ' ',
          .sand => 'o',
          .rock => '#',
        };
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
