const std = @import("std");
const termutils = @import("termutils.zig");

const Color = termutils.colors.Color;
const Attributes = @import("Attributes.zig");
const Row = @import("Row.zig");
const RenderCommand = @import("RenderCommand.zig");

const Page = @This();

rows: []Row,
content_height: u32,

pub fn init(rows: []Row) Page {
    var content_height: u32 = 0;
    for (rows) |row| content_height += row.get_height();

    return .{
        .rows = rows,
        .content_height = content_height,
    };
}

pub fn deinit(page: *Page, gpa: std.mem.Allocator) void {
    for (page.rows) |*r| {
        r.deinit(gpa);
    }
    gpa.free(page.rows);
    page.* = undefined;
}

pub fn printEmpty(writer: *std.Io.Writer, size: termutils.size.TermSize) !void {
    try writer.writeAll(termutils.clear_screen);
    try writer.writeAll(Color.black.background());

    try writer.splatByteAll(' ', size.col);
    try writer.splatByteAll('\n', size.row - 1);
    try writer.writeAll(termutils.colors.reset);
}

pub fn print(
    page: *Page,
    cmd: RenderCommand,
    attributes: ?*Attributes,
) !void {
    const writer = cmd.writer;
    const size = cmd.size;

    try writer.writeAll(termutils.clear_screen);
    try writer.writeAll(Color.black.background());

    try Row.print_empty(writer, size.col);

    var rest = size.row - 2;

    if (attributes) |attr| {
        if (attr.title) |title| {
            try title.print(writer, size.col);
            rest -= 2;
        }
    }

    try Row.print_empty(writer, size.col);

    rest -= 1;

    for (page.rows) |r| {
        // TODO: Use padding
        try r.print(cmd.writer, size.col - 2);
    }

    rest -= page.content_height - 1;

    try writer.splatByteAll('\n', rest);
    try writer.writeAll(termutils.colors.reset);
}
