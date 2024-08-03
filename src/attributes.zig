const std = @import("std");

const AttributeError = error{
    UnknownAttribute,
};

pub const Attributes = struct {
    allocator: std.mem.Allocator,

    title: ?std.ArrayList(u8) = null,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        return Self{
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Self) void {
        if (self.title) |title| {
            title.deinit();
        }
    }

    pub fn addAttribute(self: *Self, line: []const u8) !void {
        if (std.mem.startsWith(u8, line, ".title: ")) {
            self.title = std.ArrayList(u8).init(self.allocator);
            try self.title.?.appendSlice(line[8..]);
        } else {
            return AttributeError.UnknownAttribute;
        }
    }
};

const t = @import("std").testing;

test "title is parsed" {
    var attributes = Attributes.init(t.allocator);
    try attributes.addAttribute(".title: Hello, World!");
    defer attributes.deinit();
    try t.expectEqualStrings("Hello, World!", attributes.title.?.items);
}

test "unknown attribute" {
    var attributes = Attributes.init(t.allocator);
    try t.expectError(
        AttributeError.UnknownAttribute,
        attributes.addAttribute(".unknown: value"),
    );
}
