const std = @import("std");
const fmt = std.fmt;
const fs = std.fs;
const heap = std.heap;
const io = std.io;
const math = std.math;
const mem = std.mem;

const Allocator = mem.Allocator;

const Day07Error = error{
  InvalidCommand,
  ExpectedDirFoundFile,
  ExpectedFileFoundDir,
  FileSizeChanged,
};

const Dir = struct {
  children: std.StringHashMapUnmanaged(Inode) = .{},

  pub fn deinit(self: *@This(), alloc: Allocator) void {
    var entries = self.children.iterator();
    while (entries.next()) |entry| {
      alloc.free(entry.key_ptr.*);
      switch (entry.value_ptr.*) {
        .dir => |*d| d.deinit(alloc),
        else => {},
      }
    }
    self.children.deinit(alloc);
  }

  fn sumSmall(self: @This()) [2]u64 {
    var mySize: u64 = 0;
    var smallChildrenSum: u64 = 0;

    var vals = self.children.valueIterator();
    while (vals.next()) |val| switch (val.*) {
      .dir => |d| {
        const res = d.sumSmall();
        mySize += res[0];
        smallChildrenSum += res[1];
      },
      .file => |f| mySize += f,
    };

    if (mySize <= 100_000)
      smallChildrenSum += mySize;

    return .{ mySize, smallChildrenSum };
  }

  fn minDir(self: @This(), limit: u64) [2]u64 {
    var mySize: u64 = 0;
    var candidate: u64 = math.maxInt(u64);

    var vals = self.children.valueIterator();
    while (vals.next()) |val| switch (val.*) {
      .dir => |d| {
        const res = d.minDir(limit);
        mySize += res[0];
        if (res[1] < candidate)
          candidate = res[1];
      },
      .file => |f| mySize += f,
    };

    if (mySize >= limit and mySize < candidate)
      candidate = mySize;

    return .{ mySize, candidate };
  }

  pub fn lsDir(self: *@This(), alloc: Allocator, ownedDir: []u8) !*Dir {
    errdefer alloc.free(ownedDir);
    var dirEntry = try self.children.getOrPut(alloc, ownedDir);
    if (dirEntry.found_existing) {
      switch (dirEntry.value_ptr.*) {
        .file => return Day07Error.ExpectedDirFoundFile,
        .dir => |*d| {
          alloc.free(ownedDir);
          return d;
        },
      }
    } else {
      dirEntry.value_ptr.* = .{ .dir = .{} };
      switch (dirEntry.value_ptr.*) {
        .file => unreachable,
        .dir => |*d| return d,
      }
    }
  }

  pub fn lsFile(self: *@This(), alloc: Allocator, ownedName: []u8, size: u64) !void {
    errdefer alloc.free(ownedName);
    var fileEntry = try self.children.getOrPut(alloc, ownedName);
    if (fileEntry.found_existing) {
      switch (fileEntry.value_ptr.*) {
        .dir => return Day07Error.ExpectedFileFoundDir,
        .file => |f| {
          if (f != size)
            return Day07Error.FileSizeChanged;
          alloc.free(ownedName);
        },
      }
    } else {
      fileEntry.value_ptr.* = .{ .file = size };
    }
  }
};

const Inode = union(enum) {
  file: u64,
  dir: Dir,
};

pub const Fs = struct {
  stack: std.ArrayListUnmanaged(*Dir) = .{},

  pub fn init(alloc: Allocator) !@This() {
    var rootDir = try alloc.create(Dir);
    errdefer alloc.destroy(rootDir);
    rootDir.* = .{};
    var self: @This() = .{};
    try self.stack.append(alloc, rootDir);
    return self;
  }

  pub fn deinit(self: *@This(), alloc: Allocator) void {
    self.stack.items[0].deinit(alloc);
    alloc.destroy(self.stack.items[0]);
    self.stack.deinit(alloc);
  }

  pub fn cdRoot(self: *@This()) void {
    self.stack.shrinkRetainingCapacity(1);
  }

  pub fn cdParent(self: *@This()) void {
    self.stack.shrinkRetainingCapacity(@max(1, self.stack.items.len - 1));
  }

  pub fn cwd(self: @This()) *Dir {
    return self.stack.items[self.stack.items.len - 1];
  }

  pub fn root(self: @This()) *Dir {
    return self.stack.items[0];
  }

  pub fn cd(self: *@This(), alloc: Allocator, ownedDir: []u8) !void {
    const dir = try self.cwd().lsDir(alloc, ownedDir);
    try self.stack.append(alloc, dir);
  }
};

pub fn main() ![2]u64 {
  var gpa = heap.GeneralPurposeAllocator(.{}){};
  defer _ = gpa.deinit();
  const alloc = gpa.allocator();

  var myFs = try Fs.init(alloc);
  defer myFs.deinit(alloc);

  scan: {
    const file = try fs.cwd().openFile("input/07.txt", .{});
    defer file.close();
    const reader = file.reader();

    var buf: [100]u8 = undefined;

    if (!mem.eql(u8, "$", try reader.readUntilDelimiterOrEof(&buf, ' ') orelse break :scan))
      return Day07Error.InvalidCommand;

    while (true) {
      switch (try reader.readAll(buf[0..3])) {
        0 => break,
        3 => {},
        else => return Day07Error.InvalidCommand,
      }

      if (mem.eql(u8, buf[0..3], "cd ")) {
        const dir = try reader.readUntilDelimiterAlloc(alloc, '\n', 100);
        if (mem.eql(u8, "/", dir)) {
          myFs.cdRoot();
          alloc.free(dir);
        } else if (mem.eql(u8, "..", dir)) {
          myFs.cdParent();
          alloc.free(dir);
        } else {
          try myFs.cd(alloc, dir);
        }

        if (!mem.eql(u8, "$", try reader.readUntilDelimiterOrEof(&buf, ' ') orelse break))
          return Day07Error.InvalidCommand;
      } else if (mem.eql(u8, buf[0..3], "ls\n")) {
        while (true) {
          const tok0 = try reader.readUntilDelimiterOrEof(&buf, ' ') orelse break :scan;
          if (mem.eql(u8, tok0, "$"))
            break;

          const name = try reader.readUntilDelimiterAlloc(alloc, '\n', 100);
          if (mem.eql(u8, tok0, "dir")) {
            _ = try myFs.cwd().lsDir(alloc, name);
          } else {
            const size = try fmt.parseUnsigned(u64, tok0, 0);
            try myFs.cwd().lsFile(alloc, name, size);
          }
        }
      } else return Day07Error.InvalidCommand;
    }
  }

  const sumSmall = myFs.root().sumSmall();
  const freeSpace = 70_000_000 - sumSmall[0];
  return .{ sumSmall[1], myFs.root().minDir(30_000_000 - freeSpace)[1] };
}
