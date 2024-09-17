const std = @import("std");
const HorizontalAlignment = @import("../style.zig").HorizontalAlignment;

value: std.ArrayList(u8),
rendered: ?std.ArrayList(u8) = null,
alignment: HorizontalAlignment,
allocator: std.mem.Allocator,

const Self = @This();

pub fn init(allocator: std.mem.Allocator, value: []const u8) !Self {
    var contentArray = std.ArrayList(u8).init(allocator);
    try contentArray.appendSlice(value);
    return Self{
        .value = contentArray,
        .alignment = HorizontalAlignment.center, // TODO: make this configurable
        .allocator = allocator,
    };
}

pub fn deinit(self: *Self) void {
    self.value.deinit();
    if (self.rendered) |rendered| {
        rendered.deinit();
    }
}

pub fn render(
    self: *Self,
    width: usize,
) ![]const u8 {
    if (self.rendered) |r| {
        return r.items;
    }

    var rendered = std.ArrayList(u8).init(self.allocator);
    const padding: usize = switch (self.alignment) {
        .center => (width - self.value.items.len) / 2,
        .left => 0,
        .right => width - self.value.items.len,
    };
    try rendered.appendNTimes(' ', padding);
    try rendered.appendSlice(self.value.items);
    try rendered.append('\n');
    try rendered.appendNTimes('=', width);
    self.rendered = rendered;

    return rendered.items;
}
