const std = @import("std");

const Title = @import("pageaddons.zig").Title;
const Page = @import("Page.zig");

const Error = error{
    UnknownAttribute,
};

const Self = @This();

gpa: std.mem.Allocator,
title: ?Title = null,

pub fn init(gpa: std.mem.Allocator) Self {
    return Self{
        .gpa = gpa,
    };
}

pub fn deinit(self: *Self) void {
    if (self.title) |*title| title.deinit();
}

pub fn addAttribute(self: *Self, line: []const u8) !void {
    if (std.mem.startsWith(u8, line, ".title: ")) {
        self.title = try Title.init(self.gpa, line[8..]);
    } else {
        return Error.UnknownAttribute;
    }
}

test "title is parsed" {
    const t = std.testing;
    var attributes = init(t.allocator);
    try attributes.addAttribute(".title: Hello, World!");
    defer attributes.deinit();
    try t.expectEqualStrings("Hello, World!", attributes.title.?.value.items);
}

test "unknown attribute" {
    const t = std.testing;
    var attributes = init(t.allocator);
    try t.expectError(
        Error.UnknownAttribute,
        attributes.addAttribute(".unknown: value"),
    );
}
