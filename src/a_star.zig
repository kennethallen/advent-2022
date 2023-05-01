const std = @import("std");
const math = std.math;
const mem = std.mem;

const Allocator = mem.Allocator;

const Error = error{
  NoPath,
  OutOfMemory,
};

fn Node(comptime Pos: type, comptime Cost: type) type {
  return struct {
    pos: Pos,
    knownCost: Cost,
    estTotalCost: ?Cost,

    fn priorityCompare(_: void, a: @This(), b: @This()) math.Order {
      if (a.estTotalCost) |aCost| {
        return if (b.estTotalCost) |bCost| math.order(aCost, bCost) else return .gt;
      } else return if (b.estTotalCost) |_| .lt else .eq;
    }
  };
}

pub fn Explore(comptime Pos: type, comptime Cost: type) type {
  return struct {
    pos: Pos,
    edgeCost: Cost,
  };
}

pub fn aStar(
  comptime Pos: type,
  comptime Cost: type,
  ctx: anytype,
  alloc: Allocator,
  start: Pos,
  comptime heur: fn (ctx: @TypeOf(ctx), x: Pos) ?Cost,
  comptime explore: fn (
    ctx: @TypeOf(ctx),
    x: Pos,
    buf: *std.ArrayList(Explore(Pos, Cost)),
  ) Error!void,
) !Cost {
  var toVisit = std.PriorityQueue(Node(Pos, Cost), void, Node(Pos, Cost).priorityCompare).init(alloc, {});
  defer toVisit.deinit();
  // Init with start
  try toVisit.add(.{ .pos = start, .knownCost = 0, .estTotalCost = heur(ctx, start) });

  var visited = std.AutoHashMapUnmanaged(Pos, void){};
  defer visited.deinit(alloc);

  var exploreBuf = std.ArrayList(Explore(Pos, Cost)).init(alloc);
  defer exploreBuf.deinit();

  while (toVisit.removeOrNull()) |n| {
    if ((try visited.getOrPut(alloc, n.pos)).found_existing) continue;

    if (n.estTotalCost == null) return n.knownCost;

    try explore(ctx, n.pos, &exploreBuf);
    for (exploreBuf.items) |neighbor|
      if (!visited.contains(neighbor.pos)) {
        const knownCost = n.knownCost + neighbor.edgeCost;
        const toEnd = if (heur(ctx, neighbor.pos)) |c| knownCost + c else null;
        try toVisit.add(.{ .pos = neighbor.pos, .knownCost = knownCost, .estTotalCost = toEnd });
      };
    exploreBuf.clearRetainingCapacity();
  }
  return Error.NoPath;
}
