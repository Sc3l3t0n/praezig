const std = @import("std");
const HorizontalAlignment = @import("../style.zig").HorizontalAlignment;

value: std.ArrayList(u8) = .empty,
rendered: ?std.ArrayList(u8) = null,
alignment: HorizontalAlignment,
gpa: std.mem.Allocator,

const Title = @This();

pub fn init(gpa: std.mem.Allocator, value: []const u8) !Title {
    var contentArray = try std.ArrayList(u8).initCapacity(gpa, value.len);
    contentArray.appendSliceAssumeCapacity(value);
    return Title{
        .value = contentArray,
        .alignment = HorizontalAlignment.center, // TODO: make this configurable
        .gpa = gpa,
    };
}

pub fn deinit(title: *Title) void {
    title.value.deinit(title.gpa);
    if (title.rendered) |*rendered| {
        rendered.deinit(title.gpa);
    }
}

pub fn render(
    title: *Title,
    width: usize,
) ![]const u8 {
    if (title.rendered) |r| {
        return r.items;
    }

    var rendered = std.ArrayList(u8).empty;
    const padding: usize = switch (title.alignment) {
        .center => (width - title.value.items.len) / 2,
        .left => 0,
        .right => width - title.value.items.len,
    };
    try rendered.appendNTimes(title.gpa, ' ', padding);
    try rendered.appendSlice(title.gpa, title.value.items);
    try rendered.append(title.gpa, '\n');
    try rendered.appendNTimes(title.gpa, '=', width);
    title.rendered = rendered;

    return rendered.items;
}
