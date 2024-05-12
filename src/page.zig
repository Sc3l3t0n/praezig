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

    pub fn addRow(self: *Self, toAdd: row.Row) !void {
        try self.rows.append(toAdd);
    }
};

pub const PageAddon = struct {};
