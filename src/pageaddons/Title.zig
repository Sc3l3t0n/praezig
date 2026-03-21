const std = @import("std");
const HorizontalAlignment = @import("../style.zig").HorizontalAlignment;

value: std.ArrayList(u8) = .empty,
rendered: ?std.ArrayList(u8) = null,
alignment: HorizontalAlignment,
allocator: std.mem.Allocator,

const Self = @This();

pub fn init(allocator: std.mem.Allocator, value: []const u8) !Self {
    var contentArray = try std.ArrayList(u8).initCapacity(allocator, value.len);
    contentArray.appendSliceAssumeCapacity(value);
    return Self{
        .value = contentArray,
        .alignment = HorizontalAlignment.center, // TODO: make this configurable
        .allocator = allocator,
    };
}

pub fn deinit(self: *Self) void {
    self.value.deinit(self.allocator);
    if (self.rendered) |*rendered| {
        rendered.deinit(self.allocator);
    }
}

pub fn render(
    self: *Self,
    width: usize,
) ![]const u8 {
    if (self.rendered) |r| {
        return r.items;
    }

    var rendered = std.ArrayList(u8).empty;
    const padding: usize = switch (self.alignment) {
        .center => (width - self.value.items.len) / 2,
        .left => 0,
        .right => width - self.value.items.len,
    };
    try rendered.appendNTimes(self.allocator, ' ', padding);
    try rendered.appendSlice(self.allocator, self.value.items);
    try rendered.append(self.allocator, '\n');
    try rendered.appendNTimes(self.allocator, '=', width);
    self.rendered = rendered;

    return rendered.items;
}
