const std = @import("std");
const fmt = std.fmt;
const fs = std.fs;
const heap = std.heap;
const io = std.io;
const math = std.math;
const mem = std.mem;

const Allocator = mem.Allocator;

const Day09Error = error{
    InvalidMove,
};

const Dir = enum { l, r, d, u };

fn Rope(comptime n: usize) type {
    return struct {
        knots: [n][2]i64 = [_][2]i64{[2]i64{ 0, 0 }} ** n,
        trail: std.AutoHashMapUnmanaged([2]i64, void) = .{},

        pub fn init(alloc: Allocator) !@This() {
            var r = @This(){};
            try r.trail.put(alloc, r.knots[n - 1], {});
            return r;
        }

        pub fn deinit(self: *@This(), alloc: Allocator) void {
            self.trail.deinit(alloc);
        }

        pub fn move(self: *@This(), alloc: Allocator, dir: Dir) !void {
            switch (dir) {
                .r => self.knots[0][0] += 1,
                .l => self.knots[0][0] -= 1,
                .u => self.knots[0][1] += 1,
                .d => self.knots[0][1] -= 1,
            }
            inline for (self.knots[1..], 0..) |*t, i| {
                const h = self.knots[i];
                if (t[0] < h[0] - 1) t.* = .{ h[0] - 1, clampDist(h[1], t[1]) } else if (t[0] > h[0] + 1) t.* = .{ h[0] + 1, clampDist(h[1], t[1]) } else if (t[1] < h[1] - 1) t.* = .{ clampDist(h[0], t[0]), h[1] - 1 } else if (t[1] > h[1] + 1) t.* = .{ clampDist(h[0], t[0]), h[1] + 1 };

                if (i == n - 2)
                    try self.trail.put(alloc, t.*, {});
            }
        }
    };
}

fn clampDist(h: i64, t: i64) i64 {
    return switch (math.order(h, t)) {
        .eq => t,
        .lt => t - 1,
        .gt => t + 1,
    };
}

pub fn main() ![2]u64 {
    var gpa = heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var rope0 = try Rope(2).init(alloc);
    defer rope0.deinit(alloc);
    var rope1 = try Rope(10).init(alloc);
    defer rope1.deinit(alloc);
    {
        const file = try fs.cwd().openFile("input/09.txt", .{});
        defer file.close();
        const reader = file.reader();

        var buf: [100]u8 = undefined;

        while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |row| {
            if (row.len < 3 or row[1] != ' ')
                return Day09Error.InvalidMove;
            const dir: Dir = switch (row[0]) {
                'L' => .l,
                'R' => .r,
                'D' => .d,
                'U' => .u,
                else => return Day09Error.InvalidMove,
            };
            var mag = try fmt.parseUnsigned(u64, row[2..], 0);
            while (mag > 0) : (mag -= 1) {
                try rope0.move(alloc, dir);
                try rope1.move(alloc, dir);
            }
        }
    }

    return .{ rope0.trail.count(), rope1.trail.count() };
}
