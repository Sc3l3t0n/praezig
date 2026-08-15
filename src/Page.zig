const std = @import("std");
const termutils = @import("termutils.zig");
const title = @import("pageaddons.zig").title;
const page_indicator = @import("pageaddons.zig").page_indicator;

const Presentation = @import("Presentation.zig");
const Color = termutils.colors.Color;
const Row = @import("Row.zig");
const Terminal = @import("Terminal.zig");

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

pub fn printEmpty(term: Terminal) !void {
    try term.clearScreen();
    try term.defaultBg();

    try term.splatByteAll(' ', term.size.col);
    try term.splatByteAll('\n', term.size.row - 1);

    try term.resetColors();
}

pub fn printTooSmall(
    term: Terminal,
) std.Io.Writer.Error!void {
    const rows: []const []const u8 = &.{
        "Screen size",
        " too small ",
    };

    try term.defaultBg();
    try term.clearScreen();

    const term_row_mid = std.math.divCeil(usize, term.size.row, 2) catch unreachable;

    for (0..term_row_mid - 1) |_| {
        try Row.print_empty(term);
    }

    try term.setFg(.red, .bold);

    const term_col_mid = std.math.divFloor(usize, term.size.col, 2) catch unreachable;
    for (rows) |row| {
        const row_mid = std.math.divCeil(usize, row.len, 2) catch unreachable;
        try term.splatByteAll(' ', term_col_mid - row_mid);
        try term.print("{s}\n", .{row});
    }

    for (0..term_row_mid - 1) |_| {
        try Row.print_empty(term);
    }
}

pub fn print(
    page: *Page,
    term: Terminal,
    index: usize,
    max_page: usize,
) Presentation.PrintError!void {
    if (term.size.row < page.minNeededCols(term)) return Presentation.PrintError.TooSmall;

    try term.defaultBg();
    try term.clearScreen();

    try Row.print_empty(term);

    var rest = term.size.row - 2;

    if (term.settings.addons.title) |value| {
        try title.print(term, value);
        rest -= 2;
    }

    try Row.print_empty(term);

    rest -= 1;

    for (page.rows) |r| {
        // TODO: Use padding
        try r.print(term);
    }

    rest -= page.content_height;

    try term.splatByteAll('\n', rest);

    if (term.settings.addons.page_indicator) {
        try page_indicator.print(term, index, max_page);
    } else {
        try term.writeByte('\n');
    }

    try term.resetColors();
}

fn minNeededCols(page: *const Page, term: Terminal) u32 {
    var min_cols = page.content_height // content height
    + 2 // top padding
    + 1; // title padding

    min_cols += if (term.settings.addons.title) |_| 2 else 0; // title if enabled
    min_cols += if (term.settings.addons.page_indicator) 2 else 1; // bottom padding and page indicator if enabled

    return min_cols;
}
