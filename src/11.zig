const std = @import("std");
const fmt = std.fmt;
const fs = std.fs;
const heap = std.heap;
const io = std.io;
const math = std.math;
const mem = std.mem;

const toplist = @import("toplist.zig");

const Allocator = std.mem.Allocator;

const Day11Error = error {
  InvalidMonkey,
};

const Operation = enum { add, mul };

const Monkey = struct {
  operation: Operation,
  operand: ?u64,
  divTest: u64,
  trueThrow: usize,
  falseThrow: usize,
  items: std.ArrayListUnmanaged(u64) = .{},
  inspections: u64 = 0,
  
  fn deinit(self: *@This(), alloc: Allocator) void {
    self.items.deinit(alloc);
  }

  fn clone(self: @This(), alloc: Allocator) !@This() {
    var m = self;
    m.items = try self.items.clone(alloc);
    return m;
  }

  fn inspect(self: *@This(), i: u64, divThree: bool, itemMod: u64) struct { u64, usize } {
    self.inspections += 1;
    const arg = self.operand orelse i;
    var j = switch (self.operation) { .add => i + arg, .mul => i * arg };
    if (divThree) j /= 3;
    j %= itemMod;
    return .{ j, if (j % self.divTest == 0) self.trueThrow else self.falseThrow };
  }
};

pub fn main() ![2]u64 {
  var gpa = heap.GeneralPurposeAllocator(.{}) {};
  defer _ = gpa.deinit();
  const alloc = gpa.allocator();

  var monkeys = std.ArrayListUnmanaged(Monkey) {};
  defer monkeys.deinit(alloc);
  defer for (monkeys.items) |*m| m.deinit(alloc);
  {
    const file = try fs.cwd().openFile("input/11.txt", .{});
    defer file.close();
    const reader = file.reader();

    var buf: [100]u8 = undefined;

    while (true) {
      var line = try reader.readUntilDelimiterOrEof(&buf, '\n') orelse break;
      if (!mem.eql(u8, line[0..7], "Monkey ") or !mem.eql(u8, line[line.len-1..], ":"))
        return Day11Error.InvalidMonkey;
      if (try fmt.parseUnsigned(u64, line[7..line.len-1], 0) != monkeys.items.len)
        return Day11Error.InvalidMonkey;

      line = try reader.readUntilDelimiter(&buf, '\n');
      if (!mem.eql(u8, line[0..18], "  Starting items: "))
        return Day11Error.InvalidMonkey;
      {
        var items = std.ArrayListUnmanaged(u64) {};
        errdefer items.deinit(alloc);
        line = line[18..];
        {
          var num = mem.sliceTo(line, ',');
          while (num.len < line.len) {
            try items.append(alloc, try fmt.parseUnsigned(u64, num, 0));
            if (line[num.len+1] != ' ')
              return Day11Error.InvalidMonkey;

            line = line[num.len+2..];
            num = mem.sliceTo(line, ',');
          }
          try items.append(alloc, try fmt.parseUnsigned(u64, num, 0));
        }

        line = try reader.readUntilDelimiter(&buf, '\n');
        if (!mem.eql(u8, line[0..23], "  Operation: new = old ") or line[24] != ' ')
          return Day11Error.InvalidMonkey;
        const op: Operation = switch (line[23]) {
          '+' => .add,
          '*' => .mul,
          else => return Day11Error.InvalidMonkey,
        };
        const operand = if (mem.eql(u8, line[25..], "old"))
          null
        else
          try fmt.parseUnsigned(u64, line[25..], 0);

        line = try reader.readUntilDelimiter(&buf, '\n');
        if (!mem.eql(u8, line[0..21], "  Test: divisible by "))
          return Day11Error.InvalidMonkey;
        const divTest = try fmt.parseUnsigned(u64, line[21..], 0);

        line = try reader.readUntilDelimiter(&buf, '\n');
        if (!mem.eql(u8, line[0..29], "    If true: throw to monkey "))
          return Day11Error.InvalidMonkey;
        const trueThrow = try fmt.parseUnsigned(usize, line[29..], 0);
        if (trueThrow == monkeys.items.len)
          return Day11Error.InvalidMonkey;

        line = try reader.readUntilDelimiter(&buf, '\n');
        if (!mem.eql(u8, line[0..30], "    If false: throw to monkey "))
          return Day11Error.InvalidMonkey;
        const falseThrow = try fmt.parseUnsigned(usize, line[30..], 0);
        if (falseThrow == monkeys.items.len)
          return Day11Error.InvalidMonkey;

        try monkeys.append(alloc, .{
          .items = items,
          .operation = op,
          .operand = operand,
          .divTest = divTest,
          .trueThrow = trueThrow,
          .falseThrow = falseThrow,
        });
      }

      line = try reader.readUntilDelimiterOrEof(&buf, '\n') orelse break;
      if (line.len > 0)
        return Day11Error.InvalidMonkey;
    }
  }

  var itemMod: u64 = 1;
  for (monkeys.items) |m| itemMod *= m.divTest;

  var monkeys1 = try std.ArrayListUnmanaged(Monkey).initCapacity(alloc, monkeys.items.len);
  defer monkeys1.deinit(alloc);
  defer for (monkeys1.items) |*m| m.deinit(alloc);
  for (monkeys.items) |m| monkeys1.appendAssumeCapacity(try m.clone(alloc));

  return .{
    try process(alloc, monkeys.items, itemMod, 20, true),
    try process(alloc, monkeys1.items, itemMod, 10_000, false),
  };
}

fn process(
  alloc: Allocator,
  monkeys: []Monkey,
  itemMod: u64,
  comptime rounds: u64,
  comptime divThree: bool,
) !u64 {
  var round: u64 = 0;
  while (round < rounds) : (round += 1) {
    for (monkeys) |*m| {
      for (m.items.items) |i| {
        const res = m.inspect(i, divThree, itemMod);
        try monkeys[res.@"1"].items.append(alloc, res.@"0");
      }
      m.items.clearRetainingCapacity();
    }
  }

  var top = toplist.Toplist(u64, 2) {};
  for (monkeys) |m| _ = top.insert(m.inspections);
  var product: u64 = 1;
  for (top.asSlice()) |n| product *= n;
  return product;
}
