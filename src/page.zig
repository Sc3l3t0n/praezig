const std = @import("std");
const row = @import("row.zig");

pub const Page = struct {
    index: u32,
    rows: std.ArrayList(row.Row),
    addons: ?[]PageAddon,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, index: u32) !Self {
        const rows = std.ArrayList(row.Row).init(allocator);
        return Self{
            .index = index,
            .rows = rows,
            .addons = null,
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
        try writer.print("Page: {}\n", .{self.index});
        for (self.rows.items) |*r| {
            const pStr = try r.render();
            try writer.print("{s}\n", .{pStr.*});
        }
    }
};

pub const PageAddon = struct {};
