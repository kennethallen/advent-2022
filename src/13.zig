const std = @import("std");
const fmt = std.fmt;
const fs = std.fs;
const heap = std.heap;
const io = std.io;
const math = std.math;
const mem = std.mem;

const Allocator = mem.Allocator;

const Day13Error = error{
    BadPacket,
    BadDelimiter,
    EqualPair,
};

pub fn main() ![2]u64 {
    var gpa = heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var packets = std.ArrayListUnmanaged(Packet){};
    defer packets.deinit(alloc);
    defer for (packets.items) |*p| p.deinit(alloc);
    {
        const file = try fs.cwd().openFile("input/13.txt", .{});
        defer file.close();
        const reader = file.reader();

        var buf: [500]u8 = undefined;

        while (true) {
            {
                const line = try reader.readUntilDelimiterOrEof(&buf, '\n') orelse break;
                const r = try parsePacket(alloc, line);
                var p = r.@"1";
                errdefer p.deinit(alloc);
                if (r.@"0" != line.len) return Day13Error.BadPacket;
                try packets.append(alloc, p);
            }
            {
                const line = try reader.readUntilDelimiter(&buf, '\n');
                const r = try parsePacket(alloc, line);
                var p = r.@"1";
                errdefer p.deinit(alloc);
                if (r.@"0" != line.len) return Day13Error.BadPacket;
                try packets.append(alloc, p);
            }

            if (!mem.eql(u8, "", try reader.readUntilDelimiterOrEof(&buf, '\n') orelse break))
                return Day13Error.BadDelimiter;
        }
    }

    var sum: u64 = 0;
    {
        var i: usize = 0;
        while (2 * i < packets.items.len) : (i += 1)
            switch (comparePacket(packets.items[2 * i], packets.items[2 * i + 1])) {
                .lt => sum += i + 1,
                .gt => {},
                .eq => return Day13Error.EqualPair,
            };
    }

    var delims: [2]Packet = undefined;
    var delimsCount: usize = 0;
    defer for (delims[0..delimsCount]) |*d| d.deinit(alloc);

    inline for ([_]usize{ 2, 6 }) |n| {
        var lIn = try std.ArrayListUnmanaged(Packet).initCapacity(alloc, 1);
        errdefer lIn.deinit(alloc);
        lIn.appendAssumeCapacity(.{ .int = n });
        var lOut = try std.ArrayListUnmanaged(Packet).initCapacity(alloc, 1);
        lOut.appendAssumeCapacity(.{ .list = lIn });
        delims[delimsCount] = .{ .list = lOut };
        delimsCount += 1;
    }

    var decoderKey: usize = 1;
    var lo: usize = 0;
    for (delims, 0..) |d, i| {
        var hi = packets.items.len - 1;
        swaps: while (lo < hi) {
            while (comparePacket(packets.items[lo], d) == .lt) {
                lo += 1;
                if (lo >= hi) break :swaps;
            }
            while (comparePacket(packets.items[hi], d) == .gt) {
                hi -= 1;
                if (lo >= hi) break :swaps;
            }
            mem.swap(Packet, &packets.items[lo], &packets.items[hi]);
            lo += 1;
            hi -= 1;
        }
        decoderKey *= lo + i + 1;
    }

    return .{ sum, decoderKey };
}

const Packet = union(enum) {
    int: usize,
    list: std.ArrayListUnmanaged(Packet),

    fn deinit(self: *@This(), alloc: Allocator) void {
        switch (self.*) {
            .int => |_| {},
            .list => |*l| {
                for (l.items) |*p| p.deinit(alloc);
                l.deinit(alloc);
            },
        }
    }
};

fn parsePacket(alloc: Allocator, line: []const u8) !struct { usize, Packet } {
    if (line.len >= 2 and line[0] == '[') {
        var cursor: usize = 1;
        var list = std.ArrayListUnmanaged(Packet){};
        errdefer list.deinit(alloc);
        errdefer for (list.items) |*p| p.deinit(alloc);
        if (line[cursor] != ']')
            while (true) {
                var r = try parsePacket(alloc, line[cursor..]);
                {
                    errdefer r.@"1".deinit(alloc);
                    try list.append(alloc, r.@"1");
                }
                cursor += r.@"0";
                switch (line[cursor]) {
                    ']' => break,
                    ',' => cursor += 1,
                    else => return Day13Error.BadPacket,
                }
            };
        return .{ cursor + 1, .{ .list = list } };
    } else if (line.len >= 1 and line[0] >= '0' and line[0] <= '9') {
        var cursor: usize = 1;
        while (cursor < line.len and line[cursor] >= '0' and line[cursor] <= '9')
            cursor += 1;
        return .{ cursor, .{ .int = try fmt.parseUnsigned(usize, line[0..cursor], 0) } };
    } else return Day13Error.BadPacket;
}

fn comparePacket(l: Packet, r: Packet) math.Order {
    switch (l) {
        .int => |li| switch (r) {
            .int => |ri| return math.order(li, ri),
            .list => |_| {
                var ll = [_]Packet{l};
                return comparePacket(.{ .list = .{ .items = &ll, .capacity = ll.len } }, r);
            },
        },
        .list => |ll| switch (r) {
            .int => |_| {
                var rl = [_]Packet{r};
                return comparePacket(l, .{ .list = .{ .items = &rl, .capacity = rl.len } });
            },
            .list => |rl| {
                var i: usize = 0;
                while (true) {
                    if (i == ll.items.len) return if (i == rl.items.len) .eq else .lt;
                    if (i == rl.items.len) return .gt;
                    const cmp = comparePacket(ll.items[i], rl.items[i]);
                    if (cmp != .eq) return cmp;
                    i += 1;
                }
            },
        },
    }
}

fn packetLessThan(_: void, l: Packet, r: Packet) bool {
    return comparePacket(l, r) == .lt;
}
