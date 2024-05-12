const std = @import("std");
const row = @import("row.zig");
const termsize = @import("termsize.zig");
const termutils = @import("termutils.zig");

const PageError = error{
    SizeNotSet,
};

pub const Page = struct {
    index: u32,
    rows: std.ArrayList(row.Row),
    addons: ?[]PageAddon,
    size: ?termsize.TermSize,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, index: u32) !Self {
        const rows = std.ArrayList(row.Row).init(allocator);
        return Self{
            .index = index,
            .rows = rows,
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
    }

    pub fn print(self: *Self, writer: anytype) !void {
        if (self.size == null) {
            return PageError.SizeNotSet;
        }

        try writer.print(termutils.newPage, .{});
        try writer.print(termutils.colors.Background.get(.Black), .{});

        for (0..self.size.?.col) |_| {
            try writer.print(" ", .{});
        }

        for (self.rows.items) |*r| {
            // TODO: Use padding
            const pStr = try r.render(self.size.?.col - 2);
            try writer.print("  {s}", .{pStr.*});
        }

        const rest = self.size.?.row - self.rows.items.len - 1;

        for (0..rest) |_| {
            try writer.print("\n", .{});
        }
        try writer.print(termutils.colors.reset, .{});
    }
};

pub const PageAddon = struct {};
