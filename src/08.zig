const std = @import("std");
const fs = std.fs;
const heap = std.heap;
const io = std.io;

const Day08Error = error {
  InvalidTree,
  UnevenRows,
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

  var visibility = try alloc.alloc(bool, height * width);
  defer alloc.free(visibility);
  var visCount: u64 = 0;
  for (grid.items) |row, y| {
    var x: u64 = 0;
    var sightline: u8 = 0;
    while (x < width) : (x += 1) {
      const tree = row[x];
      if (tree >= sightline) {
        var vis = &visibility[y*width + x];
        if (!vis.*) {
          vis.* = true;
          visCount += 1;
        }
        sightline = tree + 1;
        if (sightline > 9) break;
      }
    }

    sightline = 0;
    x = width;
    while (x > 0) {
      x -= 1;
      const tree = row[x];
      if (tree >= sightline) {
        var vis = &visibility[y*width + x];
        if (!vis.*) {
          vis.* = true;
          visCount += 1;
        }
        sightline = tree + 1;
        if (sightline > 9) break;
      }
    }
  }

  var x: u64 = 0;
  while (x < width) : (x += 1) {
    var sightline: u8 = 0;
    for (grid.items) |row, y| {
      const tree = row[x];
      if (tree >= sightline) {
        var vis = &visibility[y*width + x];
        if (!vis.*) {
          vis.* = true;
          visCount += 1;
        }
        sightline = tree + 1;
        if (sightline > 9) break;
      }
    }

    sightline = 0;
    var y: u64 = height;
    while (y > 0) {
      y -= 1;
      const tree = grid.items[y][x];
      if (tree >= sightline) {
        var vis = &visibility[y*width + x];
        if (!vis.*) {
          vis.* = true;
          visCount += 1;
        }
        sightline = tree + 1;
        if (sightline > 9) break;
      }
    }
  }

  return .{ visCount, 0 };
}
