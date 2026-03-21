const std = @import("std");

const Title = @import("pageaddons.zig").Title;
const Page = @import("Page.zig");

const Error = error{
    UnknownAttribute,
};

const Attributes = @This();

title: ?Title = null,

pub const empty: Attributes = .{};

pub fn deinit(attr: *Attributes, gpa: std.mem.Allocator) void {
    if (attr.title) |*title| title.deinit(gpa);
    attr.* = undefined;
}

pub fn addAttribute(attr: *Attributes, gpa: std.mem.Allocator, line: []const u8) !void {
    if (std.mem.startsWith(u8, line, ".title: ")) {
        attr.title = Title.init(try gpa.dupe(u8, line[8..]));
    } else {
        return Error.UnknownAttribute;
    }
}

test "title is parsed" {
    const t = std.testing;
    var attributes = empty;
    try attributes.addAttribute(t.allocator, ".title: Hello, World!");
    defer attributes.deinit(t.allocator);
    try t.expectEqualStrings("Hello, World!", attributes.title.?.value);
}

test "unknown attribute" {
    const t = std.testing;
    var attributes = empty;
    try t.expectError(
        Error.UnknownAttribute,
        attributes.addAttribute(t.allocator, ".unknown: value"),
    );
}
