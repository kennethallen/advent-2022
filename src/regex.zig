const std = @import("std");
const mem = std.mem;

const Allocator = mem.Allocator;

const regez = @cImport(@cInclude("regez.h"));
const REGEX_T_ALIGNOF = regez.sizeof_regex_t;
const REGEX_T_SIZEOF = regez.alignof_regex_t;

pub const RegexError = error{ BadPattern, NoMatch };

pub const Match = ?[]const u8;

pub const Pattern = struct {
    regex: *regez.regex_t,

    pub fn init(alloc: Allocator, pattern: [:0]const u8) !@This() {
        var slice = try alloc.alignedAlloc(u8, REGEX_T_ALIGNOF, REGEX_T_SIZEOF);
        errdefer alloc.free(slice);

        var regex = @ptrCast(*regez.regex_t, slice.ptr);

        if (regez.regcomp(regex, pattern, regez.REG_EXTENDED) != 0)
            return RegexError.BadPattern;
        return .{ .regex = regex };
    }

    pub fn deinit(self: *@This(), alloc: Allocator) void {
        regez.regfree(self.regex);
        alloc.free(@alignCast(REGEX_T_ALIGNOF, @ptrCast([*]u8, self.regex))[0..REGEX_T_SIZEOF]);
    }

    pub fn match(self: @This(), alloc: Allocator, data: [:0]const u8, matches: []Match) !void {
        var bounds = try alloc.alloc(regez.regmatch_t, matches.len);
        defer alloc.free(bounds);

        switch (regez.regexec(self.regex, data, bounds.len, bounds.ptr, 0)) {
            0 => {},
            regez.REG_NOMATCH => return RegexError.NoMatch,
            else => unreachable,
        }

        for (bounds, 0..) |bound, i| {
            matches[i] =
                if (bound.rm_so == -1) null else data[@intCast(usize, bound.rm_so)..@intCast(usize, bound.rm_eo)];
        }
    }
};
