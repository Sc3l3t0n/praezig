const std = @import("std");

const Title = @import("pageaddons.zig").Title;
const Page = @import("page.zig").Page;

const AttributeError = error{
    UnknownAttribute,
};

pub const Attributes = struct {
    allocator: std.mem.Allocator,

    title: ?Title = null,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        return Self{
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Self) void {
        if (self.title) |*title| title.deinit();
    }

    pub fn addAttribute(self: *Self, line: []const u8) !void {
        if (std.mem.startsWith(u8, line, ".title: ")) {
            self.title = try Title.init(self.allocator, line[8..]);
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
    try t.expectEqualStrings("Hello, World!", attributes.title.?.value.items);
}

test "unknown attribute" {
    var attributes = Attributes.init(t.allocator);
    try t.expectError(
        AttributeError.UnknownAttribute,
        attributes.addAttribute(".unknown: value"),
    );
}
