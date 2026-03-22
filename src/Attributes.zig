const std = @import("std");
const zon = std.zon;

const Title = @import("pageaddons.zig").Title;
const Page = @import("Page.zig");

const ZonStruct = struct {
    title: ?[]const u8,
};

const Attributes = @This();

title: ?Title = null,

pub const empty: Attributes = .{};

pub fn parse(gpa: std.mem.Allocator, slice: []const u8, diag: ?*zon.parse.Diagnostics) !Attributes {
    var list = try std.ArrayList(u8).initCapacity(gpa, slice.len + 3);

    if (!std.mem.startsWith(u8, slice, ".{")) list.appendSliceAssumeCapacity(".{");
    list.appendSliceAssumeCapacity(slice);
    if (!std.mem.endsWith(u8, slice, "}")) list.appendAssumeCapacity('}');

    const object = try list.toOwnedSliceSentinel(gpa, 0);
    defer gpa.free(object);

    const zon_struct = try zon.parse.fromSliceAlloc(ZonStruct, gpa, object, diag, .{});

    return .{
        .title = if (zon_struct.title) |t| .init(t) else null,
    };
}

pub fn deinit(attr: *Attributes, gpa: std.mem.Allocator) void {
    if (attr.title) |*title| title.deinit(gpa);
    attr.* = undefined;
}

test "parse works without object identifiert (.{})" {
    const t = std.testing;
    const gpa = t.allocator;

    const input =
        \\.title = "Hello"
    ;

    var attributes = try parse(gpa, input, null);
    defer attributes.deinit(gpa);

    try t.expectEqualStrings(attributes.title.?.value, "Hello");
}

test "parse works with object identifiert (.{})" {
    const t = std.testing;
    const gpa = t.allocator;

    const input =
        \\.{
        \\.title = "Hello"
        \\}
    ;

    var attributes = try parse(gpa, input, null);
    defer attributes.deinit(gpa);

    try t.expectEqualStrings(attributes.title.?.value, "Hello");
}
