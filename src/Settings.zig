const std = @import("std");
const zon = std.zon;
const color = @import("termutils.zig").colors;
const HorizontalAlignment = @import("alignments.zig").Horizontal;

const Color = color.Color;

const Settings = @This();

pub const Colors = struct {
    background: Color = .black,
    text: TextColors = .{},
    decorations: DecorationColors = .{},
};

pub const TextColors = struct {
    title: Color = .white,
    page_indicator: Color = .white,
    heading: Color = .dark_yellow,
    sub_heading: Color = .blue,
    normal_text: Color = .white,
    bullet_point: Color = .white,
};

pub const DecorationColors = struct {
    title: Color = .white,
    page_indicator: Color = .white,
    bullet_point: Color = .green,
};

pub const Alignments = struct {
    horizontal: HorizontalAlignments = .{},
};

pub const HorizontalAlignments = struct {
    title: HorizontalAlignment = .center,
    page_indicator: HorizontalAlignment = .center,
};

pub const Addons = struct {
    title: ?[]const u8 = null,
    page_indicator: bool = true,
};

addons: Addons = .{},
colors: Colors = .{},
alignments: Alignments = .{},

pub fn parse(gpa: std.mem.Allocator, slice: []const u8, diag: ?*zon.parse.Diagnostics) !Settings {
    var list = try std.ArrayList(u8).initCapacity(gpa, slice.len + 3);

    if (!std.mem.startsWith(u8, slice, ".{")) list.appendSliceAssumeCapacity(".{");
    list.appendSliceAssumeCapacity(slice);
    if (!std.mem.endsWith(u8, slice, "}")) list.appendAssumeCapacity('}');

    const object = try list.toOwnedSliceSentinel(gpa, 0);
    defer gpa.free(object);

    return try zon.parse.fromSliceAlloc(Settings, gpa, object, diag, .{});
}

pub fn deinit(settings: *Settings, gpa: std.mem.Allocator) void {
    if (settings.addons.title) |title| gpa.free(title);
    settings.* = undefined;
}

test "parse works without object identifiert (.{})" {
    const t = std.testing;
    const gpa = t.allocator;

    const input =
        \\.addons = .{
        \\  .title = "Hello",
        \\},
    ;

    var attributes = try parse(gpa, input, null);
    defer attributes.deinit(gpa);

    try t.expectEqualStrings(attributes.addons.title.?, "Hello");
}

test "parse works with object identifiert (.{})" {
    const t = std.testing;
    const gpa = t.allocator;

    const input =
        \\.{
        \\  .addons = .{
        \\    .title = "Hello",
        \\  },
        \\}
    ;

    var attributes = try parse(gpa, input, null);
    defer attributes.deinit(gpa);

    try t.expectEqualStrings(attributes.addons.title.?, "Hello");
}

test "parse works for colors" {
    const t = std.testing;
    const gpa = t.allocator;

    const input =
        \\.{
        \\  .colors = .{
        \\    .decorations = .{
        \\      .bullet_point = .blue,
        \\    },
        \\    .text = .{
        \\      .title = .green,
        \\    },
        \\  },
        \\}
    ;

    var attributes = try parse(gpa, input, null);
    defer attributes.deinit(gpa);

    try t.expectEqualDeep(Settings{ .colors = .{
        .decorations = .{ .bullet_point = .blue },
        .text = .{ .title = .green },
    } }, attributes);
}
