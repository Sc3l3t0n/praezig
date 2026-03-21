const std = @import("std");
const termutils = @import("termutils.zig");

const Color = termutils.colors.Color;
const Attributes = @import("Attributes.zig");
const Row = @import("Row.zig");

const Error = error{
    SizeNotSet,
};

const Page = @This();

index: u32,
rows: std.ArrayList(Row) = .empty,
content_height: u32,
attributes: ?*Attributes = null,
size: ?*const termutils.size.TermSize,

pub fn init(index: u32) Page {
    return Page{
        .index = index,
        .content_height = 0,
        .size = null,
    };
}

pub fn deinit(page: *Page, gpa: std.mem.Allocator) void {
    for (page.rows.items) |*r| {
        r.deinit(gpa);
    }
    page.rows.deinit(gpa);
    page.* = undefined;
}

pub fn addRow(page: *Page, gpa: std.mem.Allocator, toAdd: Row) !void {
    try page.rows.append(gpa, toAdd);
    page.content_height += toAdd.get_height();
}

pub fn printEmpty(size: termutils.size.TermSize, writer: *std.Io.Writer) !void {
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

pub fn print(page: *Page, gpa: std.mem.Allocator, writer: *std.Io.Writer) !void {
    if (page.size == null) {
        return Error.SizeNotSet;
    }

    try writer.print(termutils.clear_screen, .{});
    try writer.print(Color.black.background(), .{});

    try Row.print_empty(writer, page.size.?.col);

    var rest = page.size.?.row - 2;

    if (page.attributes) |*attributes| {
        if (attributes.*.title) |*title| {
            try writer.print("{s}", .{try title.render(gpa, page.size.?.col)});
            rest -= 2;
        }
    }

    try Row.print_empty(writer, page.size.?.col);

    rest -= 1;

    for (page.rows.items) |*r| {
        // TODO: Use padding
        const pStr = try r.render(gpa, page.size.?.col - 2);
        try writer.print("  {s}", .{pStr});
    }

    rest -= page.content_height - 1;

    for (0..rest) |_| {
        try writer.print("\n", .{});
    }
    try writer.print(termutils.colors.reset, .{});
}
