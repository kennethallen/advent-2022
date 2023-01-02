const std = @import("std");
const fmt = std.fmt;
const fs = std.fs;
const heap = std.heap;
const io = std.io;
const math = std.math;
const mem = std.mem;

const Allocator = mem.Allocator;

const Day16Error = error {
  BadLine,
  DuplicateLabel,
  UnknownLabel,
  NoStartLabel,
};

const Valve = struct {
  tunnels: std.ArrayListUnmanaged(u64),
  flow: u64,

  fn deinit(self: *@This(), alloc: Allocator) void {
    self.tunnels.deinit(alloc);
  }
};

const Scenario = struct {
  pos: u64,
  time: u64 = 0,
  pressureReleased: u64 = 0,
  toOpen: []u64,

  fn search(self: *@This(), valves: []Valve, dists: []u64) u64 {
    //std.debug.print("{} {} {} {any}\n", .{ self.pos, self.time, self.pressureReleased, self.toOpen });
    var max = self.pressureReleased;
    for (self.toOpen) |_, i| {
      const dest = self.toOpen[i];
      const dist = dists[self.pos + valves.len*dest];
      const valveOpenTime = self.time + dist + 1;
      if (valveOpenTime < 30) {
        mem.swap(u64, &self.toOpen[0], &self.toOpen[i]);
        defer mem.swap(u64, &self.toOpen[0], &self.toOpen[i]);
        max = @max(max, (Scenario {
          .pos = dest,
          .time = valveOpenTime,
          .pressureReleased = self.pressureReleased + (30-valveOpenTime)*valves[dest].flow,
          .toOpen = self.toOpen[1..],
        }).search(valves, dists));
      }
    }
    //std.debug.print("Leaving {} time {} with max {}\n", .{ self.pos, self.time, max });
    return max;
  }
};

pub fn main() ![2]u64 {
  var gpa = heap.GeneralPurposeAllocator(.{}) {};
  defer _ = gpa.deinit();
  const alloc = gpa.allocator();

  var valves = std.ArrayListUnmanaged(Valve) {};
  defer valves.deinit(alloc);
  defer for (valves.items) |*v| v.deinit(alloc);
  var startLabel: u64 = undefined;
  {
    var buf: [100]u8 = undefined;
    
    var labels = std.StringHashMapUnmanaged(u64) {};
    defer labels.deinit(alloc);
    defer {
      var keys = labels.keyIterator();
      while (keys.next()) |key| alloc.free(key.*);
    }

    {
      const file = try fs.cwd().openFile("input/16.txt", .{});
      defer file.close();
      const reader = file.reader();
      var idx: u64 = 0;
      while (try reader.readUntilDelimiterOrEof(&buf, ' ')) |_| {
        {
          const label = try reader.readUntilDelimiterAlloc(alloc, ' ', 100);
          errdefer alloc.free(label);
          const res = try labels.getOrPut(alloc, label);
          if (res.found_existing) return Day16Error.DuplicateLabel;
          res.value_ptr.* = idx;

          idx += 1;
        }

        _ = try reader.readUntilDelimiter(&buf, '\n');
      }
    }

    startLabel = labels.get("AA") orelse return Day16Error.NoStartLabel;

    const file = try fs.cwd().openFile("input/16.txt", .{});
    defer file.close();
    const reader = file.reader();
    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
      if (!mem.eql(u8, line[0..6], "Valve ")) return Day16Error.BadLine;
      var labelEnd: usize = 6;
      while (true) {
        if (labelEnd >= line.len) return Day16Error.BadLine;
        if (line[labelEnd] == ' ') break;
        labelEnd += 1;
      }
      const flowStart = labelEnd+15;
      if (!mem.eql(u8, line[labelEnd..flowStart], " has flow rate=")) return Day16Error.BadLine;
      var flowEnd = flowStart;
      while (true) {
        if (flowEnd >= line.len) return Day16Error.BadLine;
        if (line[flowEnd] == ';') break;
        flowEnd += 1;
      }
      const flow = try fmt.parseUnsigned(u8, line[flowStart..flowEnd], 0);
      var tunnelStart = if (mem.eql(u8, line[flowEnd..flowEnd+25], "; tunnels lead to valves "))
          flowEnd+25
        else if (mem.eql(u8, line[flowEnd..flowEnd+24], "; tunnel leads to valve "))
          flowEnd+24
        else return Day16Error.BadLine;
      var tunnels = std.ArrayListUnmanaged(u64) {};
      errdefer tunnels.deinit(alloc);
      tunnels: while (true) {
        var tunnelEnd = tunnelStart;
        while (true) {
          if (tunnelEnd >= line.len) {
            try tunnels.append(alloc,
              labels.get(line[tunnelStart..tunnelEnd]) orelse return Day16Error.UnknownLabel);
            break :tunnels;
          }
          if (line[tunnelEnd] == ',') {
            try tunnels.append(alloc,
              labels.get(line[tunnelStart..tunnelEnd]) orelse return Day16Error.UnknownLabel);
            break;
          }
          tunnelEnd += 1;
        }
        if (tunnelEnd+1 >= line.len or line[tunnelEnd+1] != ' ')
          return Day16Error.BadLine;
        tunnelStart = tunnelEnd+2;
      }
      try valves.append(alloc, .{ .flow = flow, .tunnels = tunnels });
    }
  }

  const dists = try buildDists(alloc, valves.items);
  defer alloc.free(dists);

  var toOpen = std.ArrayListUnmanaged(u64) {};
  defer toOpen.deinit(alloc);
  for (valves.items) |v, i|
    if (v.flow > 0)
      try toOpen.append(alloc, i);

  var scenario = Scenario { .pos = startLabel, .toOpen = toOpen.items };
  const maxPressure = scenario.search(valves.items, dists);

  return .{ maxPressure, 0 };
}

fn buildDists(alloc: Allocator, valves: []Valve) ![]u64 {
  var dists = try alloc.alloc(u64, valves.len * valves.len);
  errdefer alloc.free(dists);
  //mem.set(u64, dists, 1_000_000);
  
  var visited = try alloc.alloc(bool, valves.len);
  defer alloc.free(visited);

  var toVisit = std.PriorityQueue([2]u64, void, priorityCompare).init(alloc, {});
  defer toVisit.deinit();
  
  for (valves) |_, origin| {
    mem.set(bool, visited, false);
    try toVisit.add(.{ 0, origin });

    while (toVisit.removeOrNull()) |node| {
      if (visited[node[1]]) continue;
      visited[node[1]] = true;
      dists[origin + node[1]*valves.len] = node[0];
      for (valves[node[1]].tunnels.items) |next|
        if (!visited[next])
          try toVisit.add(.{ node[0]+1, next });
    }
  
    //for (visited) |v| if (!v) @panic("Location not visited");
  }

  //for (dists) |d| if (d == 1_000_000) @panic("Distance not set");
  return dists;
}

fn priorityCompare(_: void, a: [2]u64, b: [2]u64) math.Order {
  return math.order(a[0], b[0]);
}
