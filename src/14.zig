const std = @import("std");
const fmt = std.fmt;
const fs = std.fs;
const heap = std.heap;
const io = std.io;
const math = std.math;
const mem = std.mem;

const Allocator = mem.Allocator;

const Day14Error = error{
    BadLine,
    BadDelimiter,
    NeverHitFloor,
};

const Cell = enum { empty, rock, sand };

pub fn main() ![2]u64 {
    var gpa = heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var walls = std.ArrayListUnmanaged(std.ArrayListUnmanaged([2]usize)){};
    defer walls.deinit(alloc);
    defer for (walls.items) |*w| w.deinit(alloc);
    {
        const file = try fs.cwd().openFile("input/14.txt", .{});
        defer file.close();
        const reader = file.reader();

        var buf: [500]u8 = undefined;

        while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
            var wall = std.ArrayListUnmanaged([2]usize){};
            errdefer wall.deinit(alloc);

            var j: usize = 1;
            while (line[j] != ',') j += 1;
            var k = j + 1;
            while (k < line.len and line[k] != ' ') k += 1;
            try wall.append(alloc, .{
                try fmt.parseUnsigned(usize, line[0..j], 0),
                try fmt.parseUnsigned(usize, line[j + 1 .. k], 0),
            });

            while (k < line.len) {
                if (!mem.eql(u8, line[k + 1 .. k + 4], "-> ")) return Day14Error.BadDelimiter;
                var i = k + 4;
                j = i + 1;
                while (line[j] != ',') j += 1;
                k = j + 1;
                while (k < line.len and line[k] != ' ') k += 1;
                try wall.append(alloc, .{
                    try fmt.parseUnsigned(usize, line[i..j], 0),
                    try fmt.parseUnsigned(usize, line[j + 1 .. k], 0),
                });
            }

            try walls.append(alloc, wall);
        }
    }

    var minX: usize = math.maxInt(usize);
    var maxX: usize = 0;
    var maxY: usize = 0;
    for (walls.items) |wall|
        for (wall.items) |c| {
            if (c[0] < minX) minX = c[0];
            if (c[0] > maxX) maxX = c[0];
            if (c[1] > maxY) maxY = c[1];
        };
    const height = maxY + 2;
    const width = 2 * height - 1;
    const xOffset = 500 - height + 1;

    var grid = try alloc.alloc(Cell, width * height);
    defer alloc.free(grid);
    @memset(grid, .empty);

    for (walls.items) |wall| {
        for (wall.items) |*c| c[0] -= xOffset;

        for (wall.items[0 .. wall.items.len - 1], 0..) |c0, i| {
            const c1 = wall.items[i + 1];

            if (c0[0] == c1[0]) { // Vertical
                var y = c0[1];
                if (c0[1] < c1[1]) { // Down
                    while (y < c1[1]) : (y += 1) {
                        grid[c0[0] + y * width] = .rock;
                    }
                } else { // Up
                    while (y > c1[1]) : (y -= 1) {
                        grid[c0[0] + y * width] = .rock;
                    }
                }
            } else if (c0[1] == c1[1]) { // Horizontal
                if (c0[0] < c1[0]) // Right
                    @memset(grid[c0[1] * width ..][c0[0]..c1[0]], .rock)
                else // Left
                    @memset(grid[c0[1] * width ..][c1[0] + 1 .. c0[0] + 1], .rock);
            } else return Day14Error.BadLine;
        }

        const cEnd = wall.items[wall.items.len - 1];
        grid[cEnd[0] + width * cEnd[1]] = .rock;
    }

    var sand: usize = 0;
    var sandBeforeFloor: ?usize = null;
    while (true) : (sand += 1) {
        var s = [2]usize{ 500 - xOffset, 0 };
        if (grid[s[0] + s[1] * width] != .empty) break;
        while (true) : (s[1] += 1) {
            if (sandBeforeFloor == null and s[1] >= maxY) sandBeforeFloor = sand;
            if (s[1] + 1 >= height) break;
            const below = s[0] + (s[1] + 1) * width;
            if (grid[below] == .empty) {} else if (grid[below - 1] == .empty) s[0] -= 1 else if (grid[below + 1] == .empty) s[0] += 1 else break;
        }
        grid[s[0] + s[1] * width] = .sand;
    }

    return .{ sandBeforeFloor orelse return Day14Error.NeverHitFloor, sand };
}

fn printField(grid: []Cell, width: usize, height: usize) void {
    var cy: usize = 0;
    while (cy < height) : (cy += 1) {
        var cx: usize = 0;
        while (cx < width) : (cx += 1) {
            const cell: u8 = switch (grid[cx + cy * width]) {
                .empty => ' ',
                .sand => 'o',
                .rock => '#',
            };
            std.debug.print("{c}", .{cell});
        }
        std.debug.print("\n", .{});
    }
}
