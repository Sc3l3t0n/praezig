const std = @import("std");
const row = @import("row.zig");
const termutils = @import("termutils.zig");
const Color = termutils.colors.Color;

const PageError = error{
    SizeNotSet,
};

pub const Page = struct {
    index: u32,
    rows: std.ArrayList(row.Row),
    content_hight: u32,
    addons: ?[]PageAddon,
    size: ?*const termutils.size.TermSize,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, index: u32) !Self {
        const rows = std.ArrayList(row.Row).init(allocator);
        return Self{
            .index = index,
            .rows = rows,
            .content_hight = 0,
            .addons = null,
            .size = null,
        };
    }

    pub fn deinit(self: *Self) void {
        for (self.rows.items) |r| {
            r.deinit();
        }
        self.rows.deinit();
    }

    pub fn addRow(self: *Self, toAdd: row.Row) !void {
        try self.rows.append(toAdd);
        self.content_hight += toAdd.get_height();
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

        for (0..self.size.?.col) |_| {
            try writer.print(" ", .{});
        }

        for (self.rows.items) |*r| {
            // TODO: Use padding
            const pStr = try r.render(self.size.?.col - 2);
            try writer.print("  {s}", .{pStr});
        }

        const rest = self.size.?.row - self.content_hight - 1;

        for (0..rest) |_| {
            try writer.print("\n", .{});
        }
        try writer.print(termutils.colors.reset, .{});
    }
};

pub const PageAddon = struct {};
