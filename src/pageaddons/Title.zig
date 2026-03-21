const std = @import("std");
const HorizontalAlignment = @import("../style.zig").HorizontalAlignment;

value: std.ArrayList(u8) = .empty,
rendered: ?std.ArrayList(u8) = null,
alignment: HorizontalAlignment,
gpa: std.mem.Allocator,

const Self = @This();

pub fn init(gpa: std.mem.Allocator, value: []const u8) !Self {
    var contentArray = try std.ArrayList(u8).initCapacity(gpa, value.len);
    contentArray.appendSliceAssumeCapacity(value);
    return Self{
        .value = contentArray,
        .alignment = HorizontalAlignment.center, // TODO: make this configurable
        .gpa = gpa,
    };
}

pub fn deinit(self: *Self) void {
    self.value.deinit(self.gpa);
    if (self.rendered) |*rendered| {
        rendered.deinit(self.gpa);
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
    try rendered.appendNTimes(self.gpa, ' ', padding);
    try rendered.appendSlice(self.gpa, self.value.items);
    try rendered.append(self.gpa, '\n');
    try rendered.appendNTimes(self.gpa, '=', width);
    self.rendered = rendered;

    return rendered.items;
}
