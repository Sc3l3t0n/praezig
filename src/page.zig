const std = @import("std");
const row = @import("row.zig");
const termutils = @import("termutils.zig");

const Color = termutils.colors.Color;
const Attributes = @import("attributes.zig").Attributes;
const Row = row.Row;

const PageError = error{
    SizeNotSet,
};

pub const Page = struct {
    index: u32,
    rows: std.ArrayList(Row),
    content_height: u32,
    attributes: ?*Attributes = null,
    size: ?*const termutils.size.TermSize,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, index: u32) !Self {
        const rows = std.ArrayList(Row).init(allocator);
        return Self{
            .index = index,
            .rows = rows,
            .content_height = 0,
            .size = null,
        };
    }

    pub fn deinit(self: *Self) void {
        for (self.rows.items) |r| {
            r.deinit();
        }
        self.rows.deinit();
    }

    pub fn addRow(self: *Self, toAdd: Row) !void {
        try self.rows.append(toAdd);
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
            return PageError.SizeNotSet;
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
};
