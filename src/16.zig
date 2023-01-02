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
  timeRemaining: u64,
  pressureReleased: u64,
  flow: u64,
  open: []bool,

  fn init(alloc: Allocator, valveCount: usize, startPos: u64) !@This() {
    var open = try alloc.alloc(bool, valveCount);
    mem.set(bool, open, false);
    return .{
      .pos = startPos,
      .timeRemaining = 30,
      .pressureReleased = 0,
      .flow = 0,
      .open = open,
    };
  }

  fn search(self: *@This(), valves: []const Valve) u64 {
    //std.debug.print("{} {} {} {} {}\n", .{ self.pos, self.timeRemaining, self.pressureReleased, self.flow, self.open.len });
    if (self.timeRemaining == 0) return self.pressureReleased;

    var max: u64 = math.minInt(u64);
    if (!self.open[self.pos] and valves[self.pos].flow > 0) {
      self.open[self.pos] = true;
      defer self.open[self.pos] = false;
      max = @max(max, (Scenario {
        .pos = self.pos,
        .timeRemaining = self.timeRemaining - 1,
        .pressureReleased = self.pressureReleased + self.flow,
        .flow = self.flow + valves[self.pos].flow,
        .open = self.open,
      }).search(valves));
    }
    for (valves[self.pos].tunnels.items) |newPos| {
      max = @max(max, (Scenario {
        .pos = newPos,
        .timeRemaining = self.timeRemaining - 1,
        .pressureReleased = self.pressureReleased + self.flow,
        .flow = self.flow,
        .open = self.open,
      }).search(valves));
    }
    return max;
  }

  fn deinit(self: *@This(), alloc: Allocator) void {
    alloc.free(self.open);
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

  var scenario = try Scenario.init(alloc, valves.items.len, startLabel);
  defer scenario.deinit(alloc);
  const maxPressure = scenario.search(valves.items);

  return .{ maxPressure, 0 };
}
