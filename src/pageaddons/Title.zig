const std = @import("std");
const HorizontalAlignment = @import("../style.zig").HorizontalAlignment;

value: []const u8,
rendered: ?[]const u8 = null,
alignment: HorizontalAlignment,

const Title = @This();

pub fn init(value: []const u8) Title {
    return .{
        .value = value,
        .alignment = HorizontalAlignment.center, // TODO: make this configurable
    };
}

pub fn deinit(title: *Title, gpa: std.mem.Allocator) void {
    gpa.free(title.value);
    if (title.rendered) |rendered| {
        gpa.free(rendered);
    }
    title.* = undefined;
}

pub fn render(
    title: *Title,
    gpa: std.mem.Allocator,
    width: usize,
) ![]const u8 {
    if (title.rendered) |rendered| {
        if (rendered.len == width) return rendered;

        gpa.free(rendered);
        title.rendered = null;
    }

    var rendered = std.ArrayList(u8).empty;
    const padding: usize = switch (title.alignment) {
        .center => (width - title.value.len) / 2,
        .left => 0,
        .right => width - title.value.len,
    };
    try rendered.appendNTimes(gpa, ' ', padding);
    try rendered.appendSlice(gpa, title.value);
    try rendered.append(gpa, '\n');
    try rendered.appendNTimes(gpa, '=', width);

    title.rendered = try rendered.toOwnedSlice(gpa);
    return title.rendered.?;
}
