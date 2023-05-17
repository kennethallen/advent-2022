const std = @import("std");
const fmt = std.fmt;
const fs = std.fs;
const heap = std.heap;
const io = std.io;
const math = std.math;
const mem = std.mem;

const Allocator = mem.Allocator;

const Day18Error = error{};

const Grid = struct {
    bitset: std.DynamicBitSetUnmanaged,
    dims: [3]u64,
    surfaceArea: u64 = 0,

    fn deinit(self: *@This(), alloc: Allocator) void {
        self.bitset.deinit(alloc);
    }

    fn init(dims: [3]u64, alloc: Allocator) !@This() {
        return .{
            .bitset = try std.DynamicBitSetUnmanaged.initEmpty(alloc, dims[0] * dims[1] * dims[2]),
            .dims = dims,
        };
    }

    fn add(self: *@This(), cube: [3]u64) void {
        self.bitset.set(self.index(cube));

        for (0..3) |dim| {
            if (cube[dim] > 0) {
                var neighbor: [3]u64 = undefined;
                //@memcpy(neighbor, cube);
                for (cube, 0..) |coord, i| neighbor[i] = coord;
                neighbor[dim] -= 1;

                if (self.get(neighbor))
                    self.surfaceArea -= 1
                else
                    self.surfaceArea += 1;
            } else self.surfaceArea += 1;

            if (cube[dim] + 1 < self.dims[dim]) {
                var neighbor: [3]u64 = undefined;
                //@memcpy(neighbor, cube);
                for (cube, 0..) |coord, i| neighbor[i] = coord;
                neighbor[dim] += 1;

                if (self.get(neighbor))
                    self.surfaceArea -= 1
                else
                    self.surfaceArea += 1;
            } else self.surfaceArea += 1;
        }
    }

    fn index(self: @This(), coords: [3]u64) u64 {
        for (coords, 0..) |coord, i| std.debug.assert(coord < self.dims[i]);
        return (coords[0] * self.dims[1] + coords[1]) * self.dims[2] + coords[2];
    }

    fn get(self: @This(), coords: [3]u64) bool {
        return self.bitset.isSet(self.index(coords));
    }

    fn externalArea(self: @This(), alloc: Allocator) !u64 {
        var area: u64 = 0;
        
        var toVisit = std.ArrayListUnmanaged([3]u64){};
        defer toVisit.deinit(alloc);

        // x
        for (0..self.dims[1]) |y| for (0..self.dims[2]) |z| {
            if (self.get(.{0, y, z}))
                area += 1
            else
                try toVisit.append(alloc, .{0, y, z});

            if (self.get(.{self.dims[0]-1, y, z}))
                area += 1
            else
                try toVisit.append(alloc, .{self.dims[0]-1, y, z});
        };
        // y
        for (0..self.dims[0]) |x| for (0..self.dims[2]) |z| {
            if (self.get(.{x, 0, z}))
                area += 1
            else
                try toVisit.append(alloc, .{x, 0, z});
 
            if (self.get(.{x, self.dims[1]-1, z}))
                area += 1
            else
                try toVisit.append(alloc, .{x, self.dims[1]-1, z});
        };
        // z
        for (0..self.dims[0]) |x| for (0..self.dims[1]) |y| {
            if (self.get(.{x, y, 0}))
                area += 1
            else
                try toVisit.append(alloc, .{x, y, 0});

            if (self.get(.{x, y, self.dims[2]-1}))
                area += 1
            else
                try toVisit.append(alloc, .{x, y, self.dims[2]-1});
        };

        var visited = try std.DynamicBitSetUnmanaged.initEmpty(alloc, self.bitset.bit_length);
        defer visited.deinit(alloc);
        while (toVisit.popOrNull()) |coord| {
            if (visited.isSet(self.index(coord))) continue;
            visited.set(self.index(coord));

            // x
            if (coord[0] > 0) {
                const neighbor = .{coord[0]-1, coord[1], coord[2]};
                if (self.get(neighbor))
                    area += 1
                else if (!visited.isSet(self.index(neighbor)))
                    try toVisit.append(alloc, neighbor);
            }
            if (coord[0]+1 < self.dims[0]) {
                const neighbor = .{coord[0]+1, coord[1], coord[2]};
                if (self.get(neighbor))
                    area += 1
                else if (!visited.isSet(self.index(neighbor)))
                    try toVisit.append(alloc, neighbor);
            }

            // y
            if (coord[1] > 0) {
                const neighbor = .{coord[0], coord[1]-1, coord[2]};
                if (self.get(neighbor))
                    area += 1
                else if (!visited.isSet(self.index(neighbor)))
                    try toVisit.append(alloc, neighbor);
            }
            if (coord[1]+1 < self.dims[1]) {
                const neighbor = .{coord[0], coord[1]+1, coord[2]};
                if (self.get(neighbor))
                    area += 1
                else if (!visited.isSet(self.index(neighbor)))
                    try toVisit.append(alloc, neighbor);
            }

            // z
            if (coord[2] > 0) {
                const neighbor = .{coord[0], coord[1], coord[2]-1};
                if (self.get(neighbor))
                    area += 1
                else if (!visited.isSet(self.index(neighbor)))
                    try toVisit.append(alloc, neighbor);
            }
            if (coord[2]+1 < self.dims[2]) {
                const neighbor = .{coord[0], coord[1], coord[2]+1};
                if (self.get(neighbor))
                    area += 1
                else if (!visited.isSet(self.index(neighbor)))
                    try toVisit.append(alloc, neighbor);
            }
        }

        return area;
    }
};

pub fn main() ![2]u64 {
    var gpa = heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var cubes = std.ArrayListUnmanaged([3]u64){};
    defer cubes.deinit(alloc);
    var mins = [_]u64{math.maxInt(u64)} ** 3;
    var maxes = [_]u64{math.minInt(u64)} ** 3;
    {
        const file = try fs.cwd().openFile("input/18.txt", .{});
        defer file.close();
        const reader = file.reader();

        var buf: [100]u8 = undefined;

        while (true) {
            var cube: [3]u64 = undefined;
            {
                const tok = try reader.readUntilDelimiterOrEof(&buf, ',') orelse break;
                cube[0] = try std.fmt.parseUnsigned(u64, tok, 0);
            }

            {
                const tok = try reader.readUntilDelimiter(&buf, ',');
                cube[1] = try std.fmt.parseUnsigned(u64, tok, 0);
            }

            {
                const tok = try reader.readUntilDelimiter(&buf, '\n');
                cube[2] = try std.fmt.parseUnsigned(u64, tok, 0);
            }

            for (cube, 0..) |val, i| {
                mins[i] = @min(mins[i], val);
                maxes[i] = @max(maxes[i], val);
            }
            try cubes.append(alloc, cube);
        }
    }
    std.debug.assert(cubes.items.len > 0);

    var dims: [3]u64 = undefined;
    for (mins, 0..) |min, i| dims[i] = maxes[i] + 1 - min;

    var grid = try Grid.init(dims, alloc);
    defer grid.deinit(alloc);

    for (cubes.items) |cube| {
        var transformed: [3]u64 = undefined;
        for (cube, 0..) |coord, i| transformed[i] = coord - mins[i];
        grid.add(transformed);
    }

    return .{ grid.surfaceArea, try grid.externalArea(alloc) };
}
