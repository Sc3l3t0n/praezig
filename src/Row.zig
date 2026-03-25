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
    indent: u8 = 1,
};

pub const Error = error{
    TooLong, // TODO: Temporary (handle properly)
};

const Row = @This();

row_type: Type,
content: []const u8,
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
    row.* = undefined;
}

pub fn get_height(row: Row) u8 {
    return switch (row.row_type) {
        .Heading, .SubHeading => row.content_height + 1,
        else => row.content_height,
    };
}

pub fn print_empty(writer: *std.Io.Writer, width: usize) !void {
    try writer.splatByteAll(' ', width);
}

/// Renders row to writer
pub fn print(
    row: Row,
    writer: *std.Io.Writer,
    width: usize,
) !void {
    if (row.content.len >= width) {
        return Error.TooLong; // TODO: Temporary (handle properly)
    }

    try writer.splatByteAll(' ', 2 * row.options.indent);

    const backgroundColor = comptime Color.black.background();

    switch (row.row_type) {
        .Heading => {
            const esc: []const u8 = comptime Color.dark_yellow.foreground(.bold) ++ backgroundColor;

            try writer.writeAll(comptime Style.bold.enable() ++ Style.underline.enable());
            try writer.writeAll(esc);
            try writer.writeAll(row.content);
            try writer.writeAll(comptime Style.bold.disable() ++ Style.underline.disable());
            try writer.writeByte('\n');
        },
        .SubHeading => {
            const esc: []const u8 = comptime Color.blue.foreground(.bold) ++ backgroundColor;

            try writer.writeAll(comptime Style.bold.enable() ++ Style.underline.enable());
            try writer.writeAll(esc);
            try writer.writeAll(row.content);
            try writer.writeAll(comptime Style.bold.disable() ++ Style.underline.disable());
            try writer.writeByte('\n');
        },
        .Text => {
            const esc: []const u8 = comptime Color.white.foreground(.normal) ++ backgroundColor;

            try writer.writeAll(esc);
            try writer.writeAll(row.content);
        },
        .BulletPoint => {
            const esc: []const u8 = comptime Color.green.foreground(.normal) ++ backgroundColor;
            const esc_back: []const u8 = comptime Color.white.foreground(.normal) ++ backgroundColor;

            try writer.writeAll(esc);
            try writer.writeAll(if (@import("builtin").os.tag == .windows) "* " else "▶ ");
            try writer.writeAll(esc_back);
            try writer.writeAll(row.content);
        },
    }

    try writer.writeByte('\n');
}
