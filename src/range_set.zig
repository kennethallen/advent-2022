const std = @import("std");
const mem = std.mem;

const Allocator = mem.Allocator;

const RangeSet = struct {
    ranges: std.ArrayListUnmanaged([2]isize) = .{},

    fn deinit(self: *@This(), alloc: Allocator) void {
        self.ranges.deinit(alloc);
    }

    fn card(self: @This()) usize {
        var c: usize = 0;
        for (self.ranges.items) |r| {
            c += @intCast(usize, r[1] - r[0]);
        }
        return c;
    }

    fn add(self: *@This(), alloc: Allocator, a0: isize, a1: isize) !void {
        if (a1 <= a0) return;
        const l = self.find(a0, 0);
        const r = self.find(a1 - 1, l.idx);
        if (l.found) {
            if (r.found)
                try self.ranges.replaceRange(alloc, l.idx, 1 + r.idx - l.idx, &.{.{ self.ranges.items[l.idx][0], self.ranges.items[r.idx][1] }})
            else
                try self.ranges.replaceRange(alloc, l.idx, r.idx - l.idx, &.{.{ self.ranges.items[l.idx][0], a1 }});
        } else {
            if (r.found)
                try self.ranges.replaceRange(alloc, l.idx, 1 + r.idx - l.idx, &.{.{ a0, self.ranges.items[r.idx][1] }})
            else
                try self.ranges.replaceRange(alloc, l.idx, r.idx - l.idx, &.{.{ a0, a1 }});
        }
    }

    const FindResult = struct { found: bool, idx: usize };
    fn find(self: @This(), n: isize, min: usize) FindResult {
        var lo = min;
        var hi: usize = self.ranges.items.len;
        while (lo < hi) {
            const mid = lo + (hi - lo) / 2;
            const range = self.ranges.items[mid];
            if (n < range[0])
                hi = mid
            else if (n >= range[1])
                lo = mid + 1
            else
                return .{ .found = true, .idx = mid };
        }
        return .{ .found = false, .idx = lo };
    }
};

const testing = std.testing;
test "RangeSet" {
    const alloc = testing.allocator;
    var rs = RangeSet{};
    defer rs.deinit(alloc);

    try testing.expectEqual(rs.card(), 0);
    try rs.add(alloc, 10, 20);
    try testing.expectEqual(rs.card(), 10);
    try rs.add(alloc, 30, 40);
    try rs.add(alloc, 50, 60);
    try testing.expectEqual(rs.card(), 30);
    try rs.add(alloc, 5, 60);
}
