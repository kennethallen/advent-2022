const std = @import("std");
const fmt = std.fmt;
const fs = std.fs;
const heap = std.heap;
const io = std.io;
const math = std.math;
const mem = std.mem;

const Allocator = mem.Allocator;

const Day17Error = error{
    BadPush,
    UnknownSymbol,
};

const boardWidth: u3 = 7;

const Push = enum { left, right };

const Shape = enum {
    // ####
    flat,

    //  #
    // ###
    //  #
    plus,

    //   #
    //   #
    // ###
    backL,

    // #
    // #
    // #
    // #
    tall,

    // ##
    // ##
    square,

    fn dims(self: Shape) [2]u64 {
        return switch (self) {
            .flat => .{ 4, 1 },
            .plus, .backL => .{ 3, 3 },
            .tall => .{ 1, 4 },
            .square => .{ 2, 2 },
        };
    }

    fn includes(self: Shape, pos: [2]u64) bool {
        return switch (self) {
            .flat, .tall, .square => pos[0] < self.dims()[0] and pos[1] < self.dims()[1],
            .plus => switch (pos[0]) {
                0, 2 => pos[1] == 1,
                1 => pos[1] <= 2,
                else => false,
            },
            .backL => switch (pos[0]) {
                0, 1 => pos[1] == 0,
                2 => pos[1] <= 2,
                else => false,
            },
        };
    }
};

const Row = u7;

const Board = struct {
    rows: std.ArrayListUnmanaged(Row) = .{},
    bottomOffset: u64 = 0,
    height: u64 = 0,

    fn deinit(self: *@This(), alloc: Allocator) void {
        self.rows.deinit(alloc);
    }

    fn debugPrint(self: @This(), shape: Shape, shapePos: [2]u64) void {
        std.debug.print("{any} {any}\n", .{ shape, shapePos });

        var y: u64 = @max(self.height, shapePos[1] + shape.dims()[1]);
        while (y > self.bottomOffset) {
            y -= 1;

            const row: Row = if (y - self.bottomOffset < self.rows.items.len) self.rows.items[y - self.bottomOffset] else 0;

            std.debug.print("|", .{});
            for (0..boardWidth) |x| {
                const char: u8 =
                    if (row & (@intCast(Row, 0b1) << @intCast(u3, x)) != 0) '#' else if (x >= shapePos[0] and y >= shapePos[1] and shape.includes(.{ x - shapePos[0], y - shapePos[1] })) '@' else '.';
                std.debug.print("{c}", .{char});
            }
            std.debug.print("|\n", .{});
        }
        std.debug.print("{any} rows, {any} omitted and {any} materialized\n", .{ self.height, self.bottomOffset, self.rows.items.len });
    }

    fn ensureRowCount(self: *@This(), alloc: Allocator, reqHeight: u64) !void {
        if (reqHeight > self.rows.items.len)
            try self.rows.appendNTimes(alloc, 0, reqHeight - self.rows.items.len);
    }

    fn fill(self: *@This(), alloc: Allocator, shape: Shape, shapePos: [2]u64) !void {
        const y = shapePos[1] - self.bottomOffset;
        const shapeHeight = shape.dims()[1];
        try self.ensureRowCount(alloc, y + shapeHeight);

        self.height = @max(self.height, shapePos[1] + shapeHeight);

        const xShift = @intCast(u3, shapePos[0]);
        switch (shape) {
            .flat => {
                self.rows.items[y] |= @intCast(Row, 0b1111) << xShift;
            },
            .plus => {
                const midMask = @intCast(Row, 0b010) << xShift;
                self.rows.items[y] |= midMask;
                self.rows.items[y + 1] |= @intCast(Row, 0b111) << xShift;
                self.rows.items[y + 2] |= midMask;
            },
            .backL => {
                self.rows.items[y] |= @intCast(Row, 0b111) << xShift;
                const stemMask = @intCast(Row, 0b100) << xShift;
                for (self.rows.items[y + 1 .. y + 3]) |*row| row.* |= stemMask;
            },
            .tall => {
                const mask = @intCast(Row, 0b1) << xShift;
                for (self.rows.items[y .. y + 4]) |*row| row.* |= mask;
            },
            .square => {
                const mask = @intCast(Row, 0b11) << xShift;
                for (self.rows.items[y .. y + 2]) |*row| row.* |= mask;
            },
        }

        var rowIdx: u64 = y + shapeHeight;
        while (rowIdx > y) {
            rowIdx -= 1;
            if (self.rows.items[rowIdx] == 0b1111111) {
                //self.debugPrint(shape, shapePos);
                //std.debug.print("{any} rows, {any} omitted and {any} materialized\n", .{ self.height, self.bottomOffset, self.rows.items.len });//debug

                self.bottomOffset += rowIdx + 1;
                try self.rows.replaceRange(alloc, 0, rowIdx + 1, &.{});

                //std.debug.print("{any} rows, {any} omitted and {any} materialized\n", .{ self.height, self.bottomOffset, self.rows.items.len });//debug
                break;
            }
        }
    }

    fn overlaps(self: *@This(), alloc: Allocator, shape: Shape, shapePos: [2]u64) !bool {
        const y = shapePos[1] - self.bottomOffset;
        try self.ensureRowCount(alloc, y + shape.dims()[1]);

        const xShift = @intCast(u3, shapePos[0]);
        switch (shape) {
            .flat => {
                return self.rows.items[y] & (@intCast(Row, 0b1111) << xShift) != 0;
            },
            .plus => {
                const midMask = @intCast(Row, 0b010) << xShift;
                return self.rows.items[y] & midMask != 0 or self.rows.items[y + 1] & (@intCast(Row, 0b111) << xShift) != 0 or self.rows.items[y + 2] & midMask != 0;
            },
            .backL => {
                const stemMask = @intCast(Row, 0b100) << xShift;
                return self.rows.items[y] & (@intCast(Row, 0b111) << xShift) != 0 or self.rows.items[y + 1] & stemMask != 0 or self.rows.items[y + 2] & stemMask != 0;
            },
            .tall => {
                const mask = @intCast(Row, 0b1) << xShift;
                return self.rows.items[y] & mask != 0 or self.rows.items[y + 1] & mask != 0 or self.rows.items[y + 2] & mask != 0 or self.rows.items[y + 3] & mask != 0;
            },
            .square => {
                const mask = @intCast(Row, 0b11) << xShift;
                return self.rows.items[y] & mask != 0 or self.rows.items[y + 1] & mask != 0;
            },
        }
    }

    fn canMoveHoriz(self: *@This(), alloc: Allocator, dir: Push, shape: Shape, shapePos: [2]u64) !bool {
        return shapePos[0] != switch (dir) {
            .left => 0,
            .right => boardWidth - shape.dims()[0],
        } and !try self.overlaps(alloc, shape, .{
            switch (dir) {
                .left => shapePos[0] - 1,
                .right => shapePos[0] + 1,
            },
            shapePos[1],
        });
    }

    fn canFall(self: *@This(), alloc: Allocator, shape: Shape, shapePos: [2]u64) !bool {
        return shapePos[1] > self.bottomOffset and !try self.overlaps(alloc, shape, .{ shapePos[0], shapePos[1] - 1 });
    }
};

pub fn main() ![2]u64 {
    var gpa = heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var pushes = std.ArrayListUnmanaged(Push){};
    defer pushes.deinit(alloc);
    {
        const file = try fs.cwd().openFile("input/17.txt", .{});
        defer file.close();
        const reader = file.reader();

        while (reader.readByte()) |byte| {
            switch (byte) {
                '\n' => break,
                '<' => try pushes.append(alloc, .left),
                '>' => try pushes.append(alloc, .right),
                else => return Day17Error.BadPush,
            }
        } else |_| {}
    }

    var board = Board{};
    defer board.deinit(alloc);

    var pushIdx: u32 = 0;
    //for (0..1_000_000_000_000) |rock| {
    for (0..2022) |rock| {
        const shape = @intToEnum(Shape, rock % @typeInfo(Shape).Enum.fields.len);
        var shapePos = [2]u64{ 2, board.height + 3 };

        //board.debugPrint(shape, shapePos); //debug
        //std.debug.print("\n", .{}); //debug

        while (true) {
            const push = pushes.items[pushIdx % pushes.items.len];
            pushIdx += 1;

            //std.debug.print("{}\n", .{ push }); //debug
            if (try board.canMoveHoriz(alloc, push, shape, shapePos))
                switch (push) {
                    .left => shapePos[0] -= 1,
                    .right => shapePos[0] += 1,
                };
            //board.debugPrint(shape, shapePos); //debug
            //std.debug.print("\n", .{}); //debug

            if (!try board.canFall(alloc, shape, shapePos))
                break;
            shapePos[1] -= 1;
            //board.debugPrint(shape, shapePos); //debug
            //std.debug.print("\n", .{}); //debug
        }
        //std.debug.print("dropped\n", .{}); //debug

        try board.fill(alloc, shape, shapePos);
        if (rock % 1_000_000 == 0)
            std.debug.print("{any}\n", .{rock}); //debug
    }

    return .{ board.height, 0 };
}
