const std = @import("std");

const Title = @import("pageaddons.zig").Title;
const Page = @import("Page.zig");

const Error = error{
    UnknownAttribute,
};

const Attributes = @This();

gpa: std.mem.Allocator,
title: ?Title = null,

pub fn init(gpa: std.mem.Allocator) Attributes {
    return Attributes{
        .gpa = gpa,
    };
}

pub fn deinit(attr: *Attributes) void {
    if (attr.title) |*title| title.deinit();
}

pub fn addAttribute(attr: *Attributes, line: []const u8) !void {
    if (std.mem.startsWith(u8, line, ".title: ")) {
        attr.title = try Title.init(attr.gpa, line[8..]);
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
