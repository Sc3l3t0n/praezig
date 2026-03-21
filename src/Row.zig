const std = @import("std");
const style = @import("style.zig");

const Color = @import("termutils.zig").colors.Color;
const Style = @import("termutils.zig").style.Style;

pub const Type = enum {
    Heading,
    SubHeading,
    Text,
    BulletPoint,
    // TODO: SubBulletPoint,
    // TODO: NumberedPoint,
};

pub const Options = struct {
    verticalAlignment: style.VerticalAlignment = .center,
    horizontalAlignment: style.HorizontalAlignment = .left,
    indent: u8 = 0,
};

pub const Error = error{
    TooLong, // TODO: Temporary (handle properly)
};

allocator: std.mem.Allocator,

row_type: Type,
content: std.ArrayList(u8),
rendered_content: ?std.ArrayList(u8),
content_height: u8,
options: Options,

const Self = @This();

pub fn init(
    allocator: std.mem.Allocator,
    row_type: Type,
    content: []const u8,
    options: Options,
) !Self {
    var contentArray = try std.ArrayList(u8).initCapacity(allocator, content.len);
    contentArray.appendSliceAssumeCapacity(content);

    // TODO: Determin content height based on content.

    return Self{
        .allocator = allocator,
        .row_type = row_type,
        .content = contentArray,
        .rendered_content = null,
        .content_height = 1,
        .options = options,
    };
}

pub fn deinit(self: *Self) void {
    self.content.deinit(self.allocator);
    if (self.rendered_content) |*rendered_content| {
        rendered_content.deinit(self.allocator);
    }
}

pub fn get_height(self: Self) u8 {
    return switch (self.row_type) {
        .Heading, .SubHeading => self.content_height + 1,
        else => self.content_height,
    };
}

pub fn print_empty(writer: anytype, width: usize) !void {
    for (0..width) |_| {
        try writer.print(" ", .{});
    }
}

// Returns the rendered content as []u8
// The rendered content is stored in the struct for future use.
pub fn render(
    self: *Self,
    width: usize,
) ![]u8 {
    if (self.rendered_content) |rendered_content| {
        return rendered_content.items;
    }

    if (self.content.items.len >= width) {
        return Error.TooLong; // TODO: Temporary (handle properly)
    }
    self.rendered_content = std.ArrayList(u8).empty;
    const buffer = &self.rendered_content.?;
    try buffer.appendNTimes(self.allocator, ' ', 4 * self.options.indent);

    const backgroundColor = comptime Color.black.background();

    switch (self.row_type) {
        .Heading => {
            const esc: []const u8 = comptime Color.dark_yellow.foreground(.bold) ++ backgroundColor;

            try buffer.appendSlice(self.allocator, comptime Style.bold.enable() ++ Style.underline.enable());
            try buffer.appendSlice(self.allocator, esc);
            try buffer.appendSlice(self.allocator, self.content.items);
            try buffer.appendSlice(self.allocator, comptime Style.bold.disable() ++ Style.underline.disable());
            try buffer.append(self.allocator, '\n');
        },
        .SubHeading => {
            const esc: []const u8 = comptime Color.blue.foreground(.bold) ++ backgroundColor;

            try buffer.appendSlice(self.allocator, comptime Style.bold.enable() ++ Style.underline.enable());
            try buffer.appendSlice(self.allocator, esc);
            try buffer.appendSlice(self.allocator, self.content.items);
            try buffer.appendSlice(self.allocator, comptime Style.bold.disable() ++ Style.underline.disable());
            try buffer.append(self.allocator, '\n');
        },
        .Text => {
            const esc: []const u8 = comptime Color.white.foreground(.normal) ++ backgroundColor;

            try buffer.appendSlice(self.allocator, esc);
            try buffer.appendSlice(self.allocator, self.content.items);
        },
        .BulletPoint => {
            const esc: []const u8 = comptime Color.green.foreground(.normal) ++ backgroundColor;
            const esc_back: []const u8 = comptime Color.white.foreground(.normal) ++ backgroundColor;

            try buffer.appendSlice(self.allocator, esc);
            try buffer.appendSlice(self.allocator, if (@import("builtin").os.tag == .windows) "* " else "▶ ");
            try buffer.appendSlice(self.allocator, esc_back);
            try buffer.appendSlice(self.allocator, self.content.items);
        },
    }

    try buffer.append(self.allocator, '\n');
    return buffer.items;
}
