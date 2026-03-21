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

const Row = @This();

gpa: std.mem.Allocator,

row_type: Type,
content: std.ArrayList(u8),
rendered_content: ?std.ArrayList(u8),
content_height: u8,
options: Options,


pub fn init(
    gpa: std.mem.Allocator,
    row_type: Type,
    content: []const u8,
    options: Options,
) !Row {
    var contentArray = try std.ArrayList(u8).initCapacity(gpa, content.len);
    contentArray.appendSliceAssumeCapacity(content);

    // TODO: Determin content height based on content.

    return Row{
        .gpa = gpa,
        .row_type = row_type,
        .content = contentArray,
        .rendered_content = null,
        .content_height = 1,
        .options = options,
    };
}

pub fn deinit(row: *Row) void {
    row.content.deinit(row.gpa);
    if (row.rendered_content) |*rendered_content| {
        rendered_content.deinit(row.gpa);
    }
}

pub fn get_height(row: Row) u8 {
    return switch (row.row_type) {
        .Heading, .SubHeading => row.content_height + 1,
        else => row.content_height,
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
    row: *Row,
    width: usize,
) ![]u8 {
    if (row.rendered_content) |rendered_content| {
        return rendered_content.items;
    }

    if (row.content.items.len >= width) {
        return Error.TooLong; // TODO: Temporary (handle properly)
    }
    row.rendered_content = std.ArrayList(u8).empty;
    const buffer = &row.rendered_content.?;
    try buffer.appendNTimes(row.gpa, ' ', 4 * row.options.indent);

    const backgroundColor = comptime Color.black.background();

    switch (row.row_type) {
        .Heading => {
            const esc: []const u8 = comptime Color.dark_yellow.foreground(.bold) ++ backgroundColor;

            try buffer.appendSlice(row.gpa, comptime Style.bold.enable() ++ Style.underline.enable());
            try buffer.appendSlice(row.gpa, esc);
            try buffer.appendSlice(row.gpa, row.content.items);
            try buffer.appendSlice(row.gpa, comptime Style.bold.disable() ++ Style.underline.disable());
            try buffer.append(row.gpa, '\n');
        },
        .SubHeading => {
            const esc: []const u8 = comptime Color.blue.foreground(.bold) ++ backgroundColor;

            try buffer.appendSlice(row.gpa, comptime Style.bold.enable() ++ Style.underline.enable());
            try buffer.appendSlice(row.gpa, esc);
            try buffer.appendSlice(row.gpa, row.content.items);
            try buffer.appendSlice(row.gpa, comptime Style.bold.disable() ++ Style.underline.disable());
            try buffer.append(row.gpa, '\n');
        },
        .Text => {
            const esc: []const u8 = comptime Color.white.foreground(.normal) ++ backgroundColor;

            try buffer.appendSlice(row.gpa, esc);
            try buffer.appendSlice(row.gpa, row.content.items);
        },
        .BulletPoint => {
            const esc: []const u8 = comptime Color.green.foreground(.normal) ++ backgroundColor;
            const esc_back: []const u8 = comptime Color.white.foreground(.normal) ++ backgroundColor;

            try buffer.appendSlice(row.gpa, esc);
            try buffer.appendSlice(row.gpa, if (@import("builtin").os.tag == .windows) "* " else "▶ ");
            try buffer.appendSlice(row.gpa, esc_back);
            try buffer.appendSlice(row.gpa, row.content.items);
        },
    }

    try buffer.append(row.gpa, '\n');
    return buffer.items;
}
