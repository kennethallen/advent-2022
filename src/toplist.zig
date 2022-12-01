const std = @import("std");
const math = std.math;
const mem = std.mem;

pub fn Toplist(comptime T: type, comptime size: usize,
  comptime compareFn: fn (lhs: T, rhs: T) math.Order) type {
  return struct {
    const Self = @This();
    items: [size]T,
    
    pub fn insert(self: *Self, x: T) bool {
      var rank = self.items.len;
      for (self.items) |x0, idx| {
        if (compareFn(x, x0) != .gt) {
          rank = idx;
          break;
        }
      }

      if (rank == 0) return false;
      mem.copy(T, self.items[0..rank], self.items[1..rank]);
      self.items[rank - 1] = x;
      return true;
    }
  };
}
