const std = @import("std");
const termutils = @import("termutils.zig");
const title = @import("pageaddons.zig").title;
const page_indicator = @import("pageaddons.zig").page_indicator;

const Color = termutils.colors.Color;
const Settings = @import("Settings.zig");
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

pub fn printEmpty(
    writer: *std.Io.Writer,
    size: termutils.size.TermSize,
    settings: Settings,
) !void {
    try writer.writeAll(termutils.clear_screen);
    try settings.colors.background.printBg(writer);

    try writer.splatByteAll(' ', size.col);
    try writer.splatByteAll('\n', size.row - 1);
    try writer.writeAll(termutils.colors.reset);
}

pub fn print(
    page: *Page,
    index: usize,
    max_page: usize,
    cmd: RenderCommand,
    settings: Settings,
) !void {
    const writer = cmd.writer;
    const size = cmd.size;

    try writer.writeAll(termutils.clear_screen);
    try settings.colors.background.printBg(writer);

    try Row.print_empty(writer, size.col);

    var rest = size.row - 2;

    if (settings.addons.title) |value| {
        try title.print(value, writer, size.col, settings);
        rest -= 2;
    }

    try Row.print_empty(writer, size.col);

    rest -= 1;

    for (page.rows) |r| {
        // TODO: Use padding
        try r.print(cmd.writer, size.col, settings);
    }

    rest -= page.content_height;

    try writer.splatByteAll('\n', rest);

    if (settings.addons.page_indicator) {
        try page_indicator.print(index, max_page, writer, size.col, settings);
    } else {
        try writer.writeByte('\n');
    }

    try writer.writeAll(termutils.colors.reset);
}
