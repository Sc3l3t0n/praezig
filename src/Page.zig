const std = @import("std");
const termutils = @import("termutils.zig");

const Color = termutils.colors.Color;
const Attributes = @import("Attributes.zig");
const Row = @import("Row.zig");

const Error = error{
    SizeNotSet,
};

const Page = @This();

gpa: std.mem.Allocator,
index: u32,
rows: std.ArrayList(Row) = .empty,
content_height: u32,
attributes: ?*Attributes = null,
size: ?*const termutils.size.TermSize,

pub fn init(gpa: std.mem.Allocator, index: u32) !Page {
    return Page{
        .gpa = gpa,
        .index = index,
        .content_height = 0,
        .size = null,
    };
}

pub fn deinit(page: *Page) void {
    for (page.rows.items) |*r| {
        r.deinit();
    }
    page.rows.deinit(page.gpa);
}

pub fn addRow(page: *Page, toAdd: Row) !void {
    try page.rows.append(page.gpa, toAdd);
    page.content_height += toAdd.get_height();
}

pub fn printEmpty(size: termutils.size.TermSize, writer: anytype) !void {
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

pub fn print(page: *Page, writer: anytype) !void {
    if (page.size == null) {
        return Error.SizeNotSet;
    }

    try writer.print(termutils.clear_screen, .{});
    try writer.print(Color.black.background(), .{});

    try Row.print_empty(writer, page.size.?.col);

    var rest = page.size.?.row - 2;

    if (page.attributes) |*attributes| {
        if (attributes.*.title) |*title| {
            try writer.print("{s}", .{try title.render(page.size.?.col)});
            rest -= 2;
        }
    }

    try Row.print_empty(writer, page.size.?.col);

    rest -= 1;

    for (page.rows.items) |*r| {
        // TODO: Use padding
        const pStr = try r.render(page.size.?.col - 2);
        try writer.print("  {s}", .{pStr});
    }

    rest -= page.content_height - 1;

    for (0..rest) |_| {
        try writer.print("\n", .{});
    }
    try writer.print(termutils.colors.reset, .{});
}
