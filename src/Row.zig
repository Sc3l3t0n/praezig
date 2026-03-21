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

row_type: Type,
content: []const u8,
rendered_content: ?[]const u8 = null,
content_height: u8,
options: Options,

pub fn init(
    row_type: Type,
    content: []const u8,
    options: Options,
) Row {
    // TODO: Determin content height based on content.
    return Row{
        .row_type = row_type,
        .content = content,
        .content_height = 1,
        .options = options,
    };
}

pub fn deinit(row: *Row, gpa: std.mem.Allocator) void {
    gpa.free(row.content);
    if (row.rendered_content) |rendered_content| {
        gpa.free(rendered_content);
    }
    row.* = undefined;
}

pub fn get_height(row: Row) u8 {
    return switch (row.row_type) {
        .Heading, .SubHeading => row.content_height + 1,
        else => row.content_height,
    };
}

pub fn print_empty(writer: *std.Io.Writer, width: usize) !void {
    for (0..width) |_| {
        try writer.print(" ", .{});
    }
}

// Returns the rendered content as []u8
// The rendered content is stored in the struct for future use.
pub fn render(
    row: *Row,
    gpa: std.mem.Allocator,
    width: usize,
) ![]const u8 {
    if (row.rendered_content) |rendered_content| {
        return rendered_content;
    }

    if (row.content.len >= width) {
        return Error.TooLong; // TODO: Temporary (handle properly)
    }

    var buffer = std.ArrayList(u8).empty;
    try buffer.appendNTimes(gpa, ' ', 4 * row.options.indent);

    const backgroundColor = comptime Color.black.background();

    switch (row.row_type) {
        .Heading => {
            const esc: []const u8 = comptime Color.dark_yellow.foreground(.bold) ++ backgroundColor;

            try buffer.appendSlice(gpa, comptime Style.bold.enable() ++ Style.underline.enable());
            try buffer.appendSlice(gpa, esc);
            try buffer.appendSlice(gpa, row.content);
            try buffer.appendSlice(gpa, comptime Style.bold.disable() ++ Style.underline.disable());
            try buffer.append(gpa, '\n');
        },
        .SubHeading => {
            const esc: []const u8 = comptime Color.blue.foreground(.bold) ++ backgroundColor;

            try buffer.appendSlice(gpa, comptime Style.bold.enable() ++ Style.underline.enable());
            try buffer.appendSlice(gpa, esc);
            try buffer.appendSlice(gpa, row.content);
            try buffer.appendSlice(gpa, comptime Style.bold.disable() ++ Style.underline.disable());
            try buffer.append(gpa, '\n');
        },
        .Text => {
            const esc: []const u8 = comptime Color.white.foreground(.normal) ++ backgroundColor;

            try buffer.appendSlice(gpa, esc);
            try buffer.appendSlice(gpa, row.content);
        },
        .BulletPoint => {
            const esc: []const u8 = comptime Color.green.foreground(.normal) ++ backgroundColor;
            const esc_back: []const u8 = comptime Color.white.foreground(.normal) ++ backgroundColor;

            try buffer.appendSlice(gpa, esc);
            try buffer.appendSlice(gpa, if (@import("builtin").os.tag == .windows) "* " else "▶ ");
            try buffer.appendSlice(gpa, esc_back);
            try buffer.appendSlice(gpa, row.content);
        },
    }

    try buffer.append(gpa, '\n');

    row.rendered_content = try buffer.toOwnedSlice(gpa);
    return row.rendered_content.?;
}
