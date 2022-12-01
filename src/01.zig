const std = @import("std");
const fs = std.fs;
const io = std.io;
const math = std.math;

const toplist = @import("toplist.zig");

const alloc = std.heap.page_allocator;

fn order_u32(a: u32, b: u32) math.Order {
  return math.order(a, b);
}

pub fn main() !void {
  const file = try fs.cwd().openFile("src/01.txt", .{});
  defer file.close();
  const reader = file.reader();

  var line = std.ArrayList(u8).init(alloc);
  defer line.deinit();

  var max_elves = toplist.Toplist(u32, 3, order_u32) { .items = [_]u32{0} ** 3 };
  {
    var elf: u32 = 0;
    while (true) {
      reader.readUntilDelimiterArrayList(&line, '\n', 1_000_000)
        catch |err| switch (err) {
          error.EndOfStream => break,
          else => unreachable,
        };
      
      if (std.fmt.parseUnsigned(u32, line.items, 0)) |n| {
        elf += n;
      } else |_| {
        _ = max_elves.insert(elf);
        elf = 0;
      }
    }
    _ = max_elves.insert(elf);
  }

  const max_elf = max_elves.items[max_elves.items.len - 1];
  var sum_max_elves: u32 = 0;
  for (max_elves.items) |elf| {
    sum_max_elves += elf;
  }
  try std.io.getStdOut().writer().print("01 {} {}\n", .{ max_elf, sum_max_elves });
}
