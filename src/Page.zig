const std = @import("std");
const termutils = @import("termutils.zig");

const Color = termutils.colors.Color;
const Attributes = @import("Attributes.zig");
const Row = @import("Row.zig");

const Error = error{
    SizeNotSet,
};

const Self = @This();

allocator: std.mem.Allocator,
index: u32,
rows: std.ArrayList(Row) = .empty,
content_height: u32,
attributes: ?*Attributes = null,
size: ?*const termutils.size.TermSize,

pub fn init(allocator: std.mem.Allocator, index: u32) !Self {
    return Self{
        .allocator = allocator,
        .index = index,
        .content_height = 0,
        .size = null,
    };
}

pub fn deinit(self: *Self) void {
    for (self.rows.items) |*r| {
        r.deinit();
    }
    self.rows.deinit(self.allocator);
}

pub fn addRow(self: *Self, toAdd: Row) !void {
    try self.rows.append(self.allocator, toAdd);
    self.content_height += toAdd.get_height();
}

pub fn printEmpty(size: termutils.size.TermSize, writer: anytype) !void {
    try writer.print(termutils.clear_screen, .{});
    try writer.print(Color.black.background(), .{});

    for (0..size.col) |_| {
        try writer.print(" ", .{});
    }
    const rest = size.row - 1;
    for (0..rest) |_| {
        try writer.print("\n", .{});
    }
    try writer.print(termutils.colors.reset, .{});
}

pub fn print(self: *Self, writer: anytype) !void {
    if (self.size == null) {
        return Error.SizeNotSet;
    }

    try writer.print(termutils.clear_screen, .{});
    try writer.print(Color.black.background(), .{});

    try Row.print_empty(writer, self.size.?.col);

    var rest = self.size.?.row - 2;

    if (self.attributes) |*attributes| {
        if (attributes.*.title) |*title| {
            try writer.print("{s}", .{try title.render(self.size.?.col)});
            rest -= 2;
        }
    }

    try Row.print_empty(writer, self.size.?.col);

    rest -= 1;

    for (self.rows.items) |*r| {
        // TODO: Use padding
        const pStr = try r.render(self.size.?.col - 2);
        try writer.print("  {s}", .{pStr});
    }

    rest -= self.content_height - 1;

    for (0..rest) |_| {
        try writer.print("\n", .{});
    }
    try writer.print(termutils.colors.reset, .{});
}
