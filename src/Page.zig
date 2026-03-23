const std = @import("std");
const termutils = @import("termutils.zig");

const Color = termutils.colors.Color;
const Attributes = @import("Attributes.zig");
const Row = @import("Row.zig");

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
    try writer.print(termutils.clear_screen, .{});
    try writer.print(Color.black.background(), .{});

    for (0..size.col) |_| {
        try writer.print(" ", .{});
    }
    const rest = size.row - 1;
    for (0..rest) |_| {
        try writer.print("\n", .{});
    }
    try writer.print(termutils.colors.reset, .{});
}

pub fn print(
    page: *Page,
    gpa: std.mem.Allocator,
    writer: *std.Io.Writer,
    size: *const termutils.size.TermSize,
    attributes: ?*Attributes,
) !void {
    try writer.print(termutils.clear_screen, .{});
    try writer.print(Color.black.background(), .{});

    try Row.print_empty(writer, size.col);

    var rest = size.row - 2;

    if (attributes) |*attr| {
        if (attr.*.title) |*title| {
            try writer.print("{s}", .{try title.render(gpa, size.col)});
            rest -= 2;
        }
    }

    try Row.print_empty(writer, size.col);

    rest -= 1;

    for (page.rows) |*r| {
        // TODO: Use padding
        const pStr = try r.render(gpa, size.col - 2);
        try writer.print("  {s}", .{pStr});
    }

    rest -= page.content_height - 1;

    for (0..rest) |_| {
        try writer.print("\n", .{});
    }
    try writer.print(termutils.colors.reset, .{});
}
