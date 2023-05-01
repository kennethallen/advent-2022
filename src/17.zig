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

const boardWidth: u64 = 7;

const Push = enum { left, right };

const Shape = struct {
  dims: [2]u64,
  shape: u64,

  fn canMoveHoriz(self: @This(), dir: Push, board: [][boardWidth]bool, botLeft: [2]u64) bool {
    if (botLeft[0] == switch (dir) {
      .left => 0,
      .right => boardWidth - self.dims[0],
    }) return false;

    switch (self.shape) {
      1 => {
        const checkCoords: [3][2]u64 = switch (dir) {
          .left => .{
            botLeft,
            .{ botLeft[0] - 1, botLeft[1] + 1 },
            .{ botLeft[0], botLeft[1] + 2 },
          },
          .right => .{
            .{ botLeft[0] + 2, botLeft[1] },
            .{ botLeft[0] + 3, botLeft[1] + 1 },
            .{ botLeft[0] + 2, botLeft[1] + 2 },
          },
        };
        for (checkCoords) |c| {
          if (c[1] < board.len and board[c[1]][c[0]]) return false;
        }
      },

      2 => {
        const checkCoords: [3][2]u64 = switch (dir) {
          .left => .{
            .{ botLeft[0] - 1, botLeft[1] },
            .{ botLeft[0] + 1, botLeft[1] + 1 },
            .{ botLeft[0] + 1, botLeft[1] + 2 },
          },
          .right => .{
            .{ botLeft[0] + 3, botLeft[1] },
            .{ botLeft[0] + 3, botLeft[1] + 1 },
            .{ botLeft[0] + 3, botLeft[1] + 2 },
          },
        };
        for (checkCoords) |c| {
          if (c[1] < board.len and board[c[1]][c[0]]) return false;
        }
      },

      else => {
        const searchX = switch (dir) {
          .left => botLeft[0] - 1,
          .right => botLeft[0] + self.dims[0],
        };
        var searchY = botLeft[1];
        while (searchY < board.len and searchY < botLeft[1] + self.dims[1]) : (searchY += 1) {
          if (board[searchY][searchX]) return false;
        }
      },
    }
    return true;
  }

  fn canFall(self: @This(), board: [][boardWidth]bool, botLeft: [2]u64) bool {
    if (botLeft[1] == 0) return false;

    switch (self.shape) {
      1 => {
        const checkCoords = [_][2]u64{
          .{ botLeft[0], botLeft[1] },
          .{ botLeft[0] + 1, botLeft[1] - 1 },
          .{ botLeft[0] + 2, botLeft[1] },
        };
        for (checkCoords) |c| {
          if (c[1] < board.len and board[c[1]][c[0]]) return false;
        }
      },

      else => {
        const searchY = botLeft[1] - 1;
        if (searchY < board.len) {
          var searchX = botLeft[0];
          while (searchX < botLeft[0] + self.dims[0]) : (searchX += 1) {
            if (board[searchY][searchX]) return false;
          }
        }
      },
    }
    return true;
  }

  fn fill(self: @This(), board: [][boardWidth]bool, botLeft: [2]u64) void {
    switch (self.shape) {
      1 => {
        const fillCoords = [_][2]u64{
          .{ botLeft[0] + 1, botLeft[1] },
          .{ botLeft[0], botLeft[1] + 1 },
          .{ botLeft[0] + 1, botLeft[1] + 1 },
          .{ botLeft[0] + 2, botLeft[1] + 1 },
          .{ botLeft[0] + 1, botLeft[1] + 2 },
        };
        for (fillCoords) |c| {
          if (board[c[1]][c[0]]) unreachable; // debug
          board[c[1]][c[0]] = true;
        }
      },

      2 => {
        const fillCoords = [_][2]u64{
          botLeft,
          .{ botLeft[0] + 1, botLeft[1] },
          .{ botLeft[0] + 2, botLeft[1] },
          .{ botLeft[0] + 2, botLeft[1] + 1 },
          .{ botLeft[0] + 2, botLeft[1] + 2 },
        };
        for (fillCoords) |c| {
          if (board[c[1]][c[0]]) unreachable; // debug
          board[c[1]][c[0]] = true;
        }
      },

      else => {
        for (botLeft[0]..botLeft[0] + self.dims[0]) |x| {
          for (botLeft[1]..botLeft[1] + self.dims[1]) |y| {
            if (board[y][x]) { std.debug.print("{},{}\n", .{x, y}); unreachable; } // debug // TODO remove
            board[y][x] = true;
          }
        }
      },
    }
  }
};

const shapes = [_]Shape{
  // ####
  .{ .shape = 0, .dims = .{ 4, 1 } },

  //  #
  // ###
  //  #
  .{ .shape = 1, .dims = .{ 3, 3 } },

  //   #
  //   #
  // ###
  .{ .shape = 2, .dims = .{ 3, 3 } },

  // #
  // #
  // #
  // #
  .{ .shape = 3, .dims = .{ 1, 4 } },

  // ##
  // ##
  .{ .shape = 4, .dims = .{ 2, 2 } },
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

  var board = std.ArrayListUnmanaged([7]bool){};
  defer board.deinit(alloc);

  std.debug.print("{any}\n", .{pushes.items});//debug
  var pushIdx: u32 = 0;
  for (0..2022) |rock| {
    const shape = shapes[rock % shapes.len];
    var botLeft = [2]u64{ 2, board.items.len + 3 };

    //try printBoard(alloc, board.items, shape, botLeft); //debug
    //std.debug.print("\n", .{}); //debug

    while (true) {
      const push = pushes.items[pushIdx % pushes.items.len];
      pushIdx += 1;

      if (shape.canMoveHoriz(push, board.items, botLeft))
        switch (push) {
          .left => botLeft[0] -= 1,
          .right => botLeft[0] += 1,
        };
      //const dirChar: u8 = switch (push) { .left => '<', .right => '>' };
      //std.debug.print("moved h {c}\n", .{ dirChar }); //debug
      //try printBoard(alloc, board.items, shape, botLeft); //debug
      //std.debug.print("\n", .{}); //debug

      if (!shape.canFall(board.items, botLeft))
        break;
      botLeft[1] -= 1;
      //std.debug.print("moved v\n", .{}); //debug
      //try printBoard(alloc, board.items, shape, botLeft); //debug
      //std.debug.print("\n", .{}); //debug
    }

    const heightNeeded = botLeft[1] + shape.dims[1];
    if (board.items.len < heightNeeded)
      try board.appendNTimes(alloc, .{false} ** boardWidth, heightNeeded - board.items.len);
    shape.fill(board.items, botLeft);
  }

  return .{ board.items.len, 0 };
}

fn printBoard(alloc: Allocator, board: [][boardWidth]bool, shape: Shape, botLeft: [2]u64) !void {
  std.debug.print("{any} {any}\n", .{shape, botLeft});
  const future = try alloc.alloc([boardWidth]bool, @max(board.len, botLeft[1] + shape.dims[1]));
  defer alloc.free(future);
  mem.copy([boardWidth]bool, future, board);
  mem.set([boardWidth]bool, future[board.len..], .{false} ** boardWidth);
  shape.fill(future, botLeft);

  var y: u64 = future.len;
  while (y > 0) {
    y -= 1;
    std.debug.print("|", .{});
    for (future[y], 0..) |new, x| {
      const char: u8 = if (y < board.len and board[y][x]) '#' else if (new) '@' else '.';
      std.debug.print("{c}", .{char});
    }
    std.debug.print("|\n", .{});
  }
}
