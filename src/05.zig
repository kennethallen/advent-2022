const std = @import("std");
const fs = std.fs;
const heap = std.heap;
const io = std.io;
const mem = std.mem;

const Day05Error = error {
  InvalidStacks,
  InvalidMoves,
};

const Stack = std.ArrayList(u8);
const Stacks = std.ArrayList(Stack);

pub fn main() ![2]u64 {
  var gpa = heap.GeneralPurposeAllocator(.{}){};
  defer _ = gpa.deinit();
  const alloc = gpa.allocator();

  var stacks: Stacks = undefined;
  defer stacks.deinit();
  defer for (stacks.items) |stack| stack.deinit();
  var stacks1: Stacks = undefined;
  defer stacks1.deinit();
  defer for (stacks1.items) |stack| stack.deinit();
  {
    const file = try fs.cwd().openFile("input/05.txt", .{});
    defer file.close();
    const reader = file.reader();

    {
      var buf: [100]u8 = undefined;

      var line = try reader.readUntilDelimiter(&buf, '\n');
      if ((line.len + 1) % 4 != 0)
        return Day05Error.InvalidStacks;
      const cols = (line.len + 1) / 4;
      stacks = try Stacks.initCapacity(alloc, cols);
      {
        var i: usize = 0;
        while (i < cols) : (i += 1)
          stacks.appendAssumeCapacity(Stack.init(alloc));
      }

      while (true) {
        for (stacks.items) |*stack, i| {
          const li = i * 4;
          if (li + 3 < line.len and line[li + 3] != ' ')
            return Day05Error.InvalidStacks;

          if (line[li] == '[' and line[li + 2] == ']') {
            try stack.append(line[li + 1]);
          } else if (mem.eql(u8, line[li..li+3], "   ")) {
            if (stack.items.len > 0)
              return Day05Error.InvalidStacks;
          } else {
            return Day05Error.InvalidStacks;
          }
        }

        line = try reader.readUntilDelimiter(&buf, '\n');
        if (mem.eql(u8, line[0..3], " 1 ")) break;
      }
      _ = try reader.readUntilDelimiter(&buf, '\n');
    }

    for (stacks.items) |stack| mem.reverse(u8, stack.items);

    stacks1 = try Stacks.initCapacity(alloc, stacks.items.len);
    for (stacks.items) |*stack|
      stacks1.appendAssumeCapacity(try stack.clone());

    {
      var buf: [100]u8 = undefined;
      while (true) {
        if (!mem.eql(u8, "move", try reader.readUntilDelimiterOrEof(&buf, ' ') orelse break))
          return Day05Error.InvalidMoves;
        var n = try std.fmt.parseUnsigned(u64, try reader.readUntilDelimiter(&buf, ' '), 0);
        if (!mem.eql(u8, "from", try reader.readUntilDelimiter(&buf, ' ')))
          return Day05Error.InvalidMoves;
        const from = try std.fmt.parseUnsigned(u64, try reader.readUntilDelimiter(&buf, ' '), 0);
        if (!mem.eql(u8, "to", try reader.readUntilDelimiter(&buf, ' ')))
          return Day05Error.InvalidMoves;
        const to = try std.fmt.parseUnsigned(u64, try reader.readUntilDelimiter(&buf, '\n'), 0);

        {
          const fromS = &stacks1.items[from - 1];
          const toS = &stacks1.items[to - 1];
          const fromBreak = fromS.items.len - n;
          try toS.appendSlice(fromS.items[fromBreak..]);
          fromS.shrinkRetainingCapacity(fromBreak);
        }

        {
          const fromS = &stacks.items[from - 1];
          const toS = &stacks.items[to - 1];
          while (n > 0) : (n -= 1) try toS.append(fromS.pop());
        }
      }
    }
  }

  {
    const writer = io.getStdOut().writer();
    for (stacks.items) |stack|
      try writer.writeByte(stack.items[stack.items.len - 1]);
    try writer.writeByte('\n');
  }
  {
    const writer = io.getStdOut().writer();
    for (stacks1.items) |stack|
      try writer.writeByte(stack.items[stack.items.len - 1]);
    try writer.writeByte('\n');
  }
  return .{ 0, 0 };
}
