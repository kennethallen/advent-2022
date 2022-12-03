const std = @import("std");
const math = std.math;
const mem = std.mem;

pub fn Toplist(comptime T: type, comptime size: usize,
  comptime compareFn: fn (lhs: T, rhs: T) math.Order) type {
    _ = compareFn;
  return struct {
    const Self = @This();
    items: [size]T = undefined,
    count: usize = 0,
    
    fn position(self: *Self, x: T) usize {
      for (self.asSlice()) |x0, i|
        if (x <= x0)
          return i;
      return self.count;
    }

    pub fn insert(self: *Self, x: T) bool {
      const rank = self.position(x);
      if (self.count < self.items.len) {
        mem.copyBackwards(T, self.items[rank+1..], self.items[rank..self.count]);
        self.items[rank] = x;
        self.count += 1;
        return true;
      } else if (rank == 0) {
        return false;
      } else {
        mem.copy(T, &self.items, self.items[1..rank]);
        self.items[rank - 1] = x;
        return true;
      }
    }

    pub fn asSlice(self: *Self) []T {
      return self.items[0..self.count];
    }
  };
}
