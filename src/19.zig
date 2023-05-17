const std = @import("std");
const fmt = std.fmt;
const fs = std.fs;
const heap = std.heap;
const io = std.io;
const math = std.math;
const mem = std.mem;

const regex = @import("regex.zig");

const Allocator = mem.Allocator;

const Day19Error = error{InvalidBlueprint};

const Resource = enum { ore, clay, obsidian, geode };
const resources = @typeInfo(Resource).Enum.fields;

const ResourceCount = std.EnumArray(Resource, u64);
const BotCosts = std.EnumArray(Resource, ResourceCount);
const Blueprint = struct {
    id: u64,
    botCosts: BotCosts,
};

pub fn main() ![2]u64 {
    var gpa = heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var blueprints = std.ArrayListUnmanaged(Blueprint){};
    defer blueprints.deinit(alloc);
    {
        const file = try fs.cwd().openFile("input/19.txt", .{});
        defer file.close();
        const reader = file.reader();

        var re = try regex.Pattern.init(alloc, "^Blueprint ([[:digit:]]*): Each ore robot costs ([[:digit:]]*) ore\\. Each clay robot costs ([[:digit:]]*) ore\\. Each obsidian robot costs ([[:digit:]]*) ore and ([[:digit:]]*) clay\\. Each geode robot costs ([[:digit:]]*) ore and ([[:digit:]]*) obsidian\\.$");
        defer re.deinit(alloc);

        var buf: [500]u8 = undefined;

        while (try reader.readUntilDelimiterOrEof(buf[0 .. buf.len - 1], '\n')) |*line| {
            buf[line.len] = 0;
            var matches: [8]regex.Match = undefined;
            try re.match(alloc, buf[0..line.len :0], &matches);

            var counts: [7]u64 = undefined;
            for (matches[1..], 0..) |match, i|
                counts[i] = try fmt.parseUnsigned(u64, match orelse return Day19Error.InvalidBlueprint, 0);

            try blueprints.append(alloc, .{ .id = counts[0], .botCosts = BotCosts.init(.{
                .ore = ResourceCount.initDefault(0, .{ .ore = counts[1] }),
                .clay = ResourceCount.initDefault(0, .{ .ore = counts[2] }),
                .obsidian = ResourceCount.initDefault(0, .{ .ore = counts[3], .clay = counts[4] }),
                .geode = ResourceCount.initDefault(0, .{ .ore = counts[5], .obsidian = counts[6] }),
            }) });
        } else {}
    }

    return .{ 0, 0 };
}
