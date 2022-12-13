const std = @import("std");
const fmt = std.fmt;
const fs = std.fs;
const heap = std.heap;
const io = std.io;
const math = std.math;
const mem = std.mem;

const Allocator = mem.Allocator;

const Day12Error = error {
  InvalidCell,
  InvalidGrid,
  NoStart,
  MultipleStart,
  NoEnd,
  MultipleEnd,
  NoPath,
};

pub fn main() ![2]u64 {
  var gpa = heap.GeneralPurposeAllocator(.{}) {};
  defer _ = gpa.deinit();
  const alloc = gpa.allocator();

  var grid = std.ArrayListUnmanaged([]u8) {};
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
      
      for (line.*) |*cell, x| {
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
        } else
          return Day12Error.InvalidCell;
      }

      try grid.append(alloc, line.*);
      y += 1;
    }

    if (start) |s| {
      if (end) |e| {
        break :input .{ s, e };
      } else
        return Day12Error.NoEnd;
    } else
      return Day12Error.NoStart;
  };

  return .{
    try aStar(alloc, ends[0], ends[1], grid.items),
    try dijkstra(alloc, ends[1], grid.items),
  };
}

fn heur(a: [2]usize, b: [2]usize) usize {
  // Taxicab distance
  return (if (a[0] > b[0]) a[0] - b[0] else b[0] - a[0])
    + (if (a[1] > b[1]) a[1] - b[1] else b[1] - a[1]);
}

const AStarNode = struct {
  coord: [2]usize,
  knownCost: usize,
  estTotalCost: usize,

  fn priorityCompare(_: void, a: @This(), b: @This()) math.Order {
    return math.order(a.estTotalCost, b.estTotalCost);
  }
};

fn aStar(
  alloc: Allocator,
  start: [2]usize,
  end: [2]usize,
  heights: [][]const u8,
) !usize {
  const width = heights[0].len;
  const height = heights.len;

  var toVisit = std.PriorityQueue(AStarNode, void, AStarNode.priorityCompare).init(alloc, {});
  defer toVisit.deinit();
  // Init with start
  try toVisit.add(.{ .coord = start, .knownCost = 0, .estTotalCost = heur(start, end) });

  var visited = try alloc.alloc(bool, width*height);
  defer alloc.free(visited);
  mem.set(bool, visited, false);

  while (toVisit.removeOrNull()) |n| {
    {
      var nodeVisited = &visited[n.coord[0] + n.coord[1]*width];
      if (nodeVisited.*) continue;
      nodeVisited.* = true;
    }

    if (mem.eql(usize, &n.coord, &end)) return n.knownCost;

    const heightLimit = 1 + heights[n.coord[1]][n.coord[0]];

    // Left
    if (n.coord[0] > 0) {
      const l: [2]usize = .{ n.coord[0]-1, n.coord[1] };
      if (heights[l[1]][l[0]] <= heightLimit and !visited[l[0] + l[1]*width])
        try toVisit.add(.{ .coord = l, .knownCost = n.knownCost+1, .estTotalCost = n.knownCost+1+heur(l, end) });
    }
    // Right
    if (n.coord[0] < width-1) {
      const r: [2]usize = .{ n.coord[0]+1, n.coord[1] };
      if (heights[r[1]][r[0]] <= heightLimit and !visited[r[0] + r[1]*width])
        try toVisit.add(.{ .coord = r, .knownCost = n.knownCost+1, .estTotalCost = n.knownCost+1+heur(r, end) });
    }
    // Down
    if (n.coord[1] > 0) {
      const u: [2]usize = .{ n.coord[0], n.coord[1]-1 };
      if (heights[u[1]][u[0]] <= heightLimit and !visited[u[0] + u[1]*width])
        try toVisit.add(.{ .coord = u, .knownCost = n.knownCost+1, .estTotalCost = n.knownCost+1+heur(u, end) });
    }
    // Right
    if (n.coord[1] < height-1) {
      const d: [2]usize = .{ n.coord[0], n.coord[1]+1 };
      if (heights[d[1]][d[0]] <= heightLimit and !visited[d[0] + d[1]*width])
        try toVisit.add(.{ .coord = d, .knownCost = n.knownCost+1, .estTotalCost = n.knownCost+1+heur(d, end) });
    }
  }
  return Day12Error.NoPath;
}

const DijkstraNode = struct {
  coord: [2]usize,
  knownCost: usize,

  fn priorityCompare(_: void, a: @This(), b: @This()) math.Order {
    return math.order(a.knownCost, b.knownCost);
  }
};

fn dijkstra(
  alloc: Allocator,
  start: [2]usize,
  heights: [][]const u8,
) !usize {
  const width = heights[0].len;
  const height = heights.len;

  var toVisit = std.PriorityQueue(DijkstraNode, void, DijkstraNode.priorityCompare).init(alloc, {});
  defer toVisit.deinit();
  // Init with start
  try toVisit.add(.{ .coord = start, .knownCost = 0 });

  var visited = try alloc.alloc(bool, width*height);
  defer alloc.free(visited);
  mem.set(bool, visited, false);

  while (toVisit.removeOrNull()) |n| {
    {
      var nodeVisited = &visited[n.coord[0] + n.coord[1]*width];
      if (nodeVisited.*) continue;
      nodeVisited.* = true;
    }

    const cellHeight = heights[n.coord[1]][n.coord[0]];
    if (cellHeight == 0) return n.knownCost;
    const heightMin = cellHeight - 1;

    // Left
    if (n.coord[0] > 0) {
      const l: [2]usize = .{ n.coord[0]-1, n.coord[1] };
      if (heights[l[1]][l[0]] >= heightMin and !visited[l[0] + l[1]*width])
        try toVisit.add(.{ .coord = l, .knownCost = n.knownCost+1 });
    }
    // Right
    if (n.coord[0] < width-1) {
      const r: [2]usize = .{ n.coord[0]+1, n.coord[1] };
      if (heights[r[1]][r[0]] >= heightMin and !visited[r[0] + r[1]*width])
        try toVisit.add(.{ .coord = r, .knownCost = n.knownCost+1 });
    }
    // Down
    if (n.coord[1] > 0) {
      const u: [2]usize = .{ n.coord[0], n.coord[1]-1 };
      if (heights[u[1]][u[0]] >= heightMin and !visited[u[0] + u[1]*width])
        try toVisit.add(.{ .coord = u, .knownCost = n.knownCost+1 });
    }
    // Right
    if (n.coord[1] < height-1) {
      const d: [2]usize = .{ n.coord[0], n.coord[1]+1 };
      if (heights[d[1]][d[0]] >= heightMin and !visited[d[0] + d[1]*width])
        try toVisit.add(.{ .coord = d, .knownCost = n.knownCost+1 });
    }
  }
  return Day12Error.NoPath;
}
