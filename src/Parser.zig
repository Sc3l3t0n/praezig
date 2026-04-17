const std = @import("std");
const mem = std.mem;
const fs = std.fs;

const Io = std.Io;
const Allocator = std.mem.Allocator;
const Page = @import("Page.zig");
const Row = @import("Row.zig");
const Settings = @import("Settings.zig");
const Writer = Io.Writer;

const Presentation = @import("Presentation.zig");

const Error = union(enum) {
    settings: std.zon.parse.Diagnostics,

    pub fn deinit(err: *Error, gpa: Allocator) void {
        switch (err.*) {
            inline else => |*e| e.deinit(gpa),
        }
    }

    pub fn format(err: *const Error, writer: *Writer) Writer.Error!void {
        try switch (err.*) {
            inline else => |e| e.format(writer),
        };
    }
};

const Parser = @This();

gpa: Allocator,
pages: std.ArrayList(Page) = .empty,
cur_rows: std.ArrayList(Row) = .empty,
settings: ?Settings = null,

err: ?Error = null,

pub fn init(gpa: Allocator) Parser {
    return .{ .gpa = gpa };
}

pub fn deinit(parser: *Parser) void {
    if (parser.err) |*err| err.deinit(parser.gpa);

    for (parser.pages.items) |*page| {
        page.deinit(parser.gpa);
    }
    parser.pages.deinit(parser.gpa);

    for (parser.cur_rows.items) |*row| {
        row.deinit(parser.gpa);
    }
    parser.cur_rows.deinit(parser.gpa);
}

pub fn result(parser: *Parser) !Presentation {
    if (parser.err) |_| return error.ErrorOccured;

    return .{
        .pages = try parser.pages.toOwnedSlice(parser.gpa),
        .settings = parser.settings orelse .{},
    };
}

pub fn run(
    parser: *Parser,
    content: []const u8,
) !void {
    const gpa = parser.gpa;

    const win_encoded = mem.containsAtLeast(u8, content, 1, "\r\n");
    var iterator = if (win_encoded)
        mem.splitSequence(u8, content, "\r\n")
    else
        mem.splitSequence(u8, content, "\n");

    try parser.parseSettings(&iterator);

    while (iterator.next()) |token| {
        if (token.len == 0) continue;
        if (mem.startsWith(u8, token, "# ")) {
            const slice = token[2..];
            const r = Row.init(
                .Heading,
                try gpa.dupe(u8, slice),
                .{},
            );
            try parser.appendRow(r);
        } else if (mem.startsWith(u8, token, "## ")) {
            const slice = token[3..];
            const r = Row.init(
                .SubHeading,
                try gpa.dupe(u8, slice),
                .{},
            );
            try parser.appendRow(r);
        } else if (mem.startsWith(u8, token, "- ")) {
            const slice = token[2..];
            const r = Row.init(
                .BulletPoint,
                try gpa.dupe(u8, slice),
                .{},
            );
            try parser.appendRow(r);
        } else if (mem.startsWith(u8, token, "---")) {
            try parser.finishPage();
        } else {
            const r = Row.init(
                .Text,
                try gpa.dupe(u8, token),
                .{},
            );
            try parser.appendRow(r);
        }
    }

    try parser.finishPage();
}

pub fn runFromFile(
    parser: *Parser,
    io: Io,
    path: []const u8,
) !void {
    const file = if (std.fs.path.isAbsolute(path))
        try Io.Dir.openFileAbsolute(io, path, .{})
    else
        try Io.Dir.cwd().openFile(io, path, .{});

    defer file.close(io);

    var file_buf: [1024]u8 = undefined;
    var file_reader = file.reader(io, &file_buf);
    const file_content = try file_reader.interface.allocRemaining(
        parser.gpa,
        .limited(1024 * 1024 * 1024),
    );
    defer parser.gpa.free(file_content);

    return try run(parser, file_content);
}

fn appendRow(parser: *Parser, row: Row) !void {
    try parser.cur_rows.append(parser.gpa, row);
}

fn finishPage(parser: *Parser) !void {
    const p = Page.init(try parser.cur_rows.toOwnedSlice(parser.gpa));
    try parser.pages.append(parser.gpa, p);
}

fn parseSettings(
    parser: *Parser,
    iterator: *mem.SplitIterator(u8, .sequence),
) !void {
    const peek = iterator.peek();
    if (peek == null or !mem.startsWith(u8, peek.?, "---")) return;

    _ = iterator.next();
    const start_i = iterator.index.?;
    const value = iterator.rest();

    while (iterator.peek()) |token| {
        if (mem.startsWith(u8, token, "---")) break;
        _ = iterator.next();
    }

    const len = iterator.index.? - start_i - iterator.delimiter.len;
    _ = iterator.next();

    var diag: std.zon.parse.Diagnostics = .{};

    if (Settings.parse(parser.gpa, value[0..len], &diag)) |settings| {
        diag.deinit(parser.gpa);
        parser.settings = settings;
    } else |err| {
        parser.err = .{ .settings = diag };
        return err;
    }
}

const testing = std.testing;

test "Parser Headings" {
    const gpa = testing.allocator;
    const content =
        \\# Heading 1
        \\# Heading 2
    ;
    var parser = init(gpa);
    defer parser.deinit();
    try parser.run(content);

    var res = try parser.result();
    defer res.deinit(gpa);

    const rows = res.pages[0].rows;
    try testing.expectEqual(2, rows.len);

    try testing.expectEqualStrings("Heading 1", rows[0].content);
    try testing.expectEqualStrings("Heading 2", rows[1].content);
}

test "Parser SubHeadings" {
    const gpa = testing.allocator;
    const content =
        \\## SubHeading 1
        \\## SubHeading 2
    ;
    var parser = init(gpa);
    defer parser.deinit();
    try parser.run(content);

    var res = try parser.result();
    defer res.deinit(gpa);

    const rows = res.pages[0].rows;

    try testing.expectEqual(2, rows.len);
    try testing.expectEqualStrings("SubHeading 1", rows[0].content);
    try testing.expectEqual(.SubHeading, rows[0].row_type);
    try testing.expectEqualStrings("SubHeading 2", rows[1].content);
    try testing.expectEqual(.SubHeading, rows[1].row_type);
}

test "Parser BulletPoints" {
    const gpa = testing.allocator;
    const content =
        \\- BulletPoint 1
        \\- BulletPoint 2
    ;
    var parser = init(gpa);
    defer parser.deinit();
    try parser.run(content);

    var res = try parser.result();
    defer res.deinit(gpa);

    const rows = res.pages[0].rows;

    try testing.expectEqual(2, rows.len);
    try testing.expectEqualStrings("BulletPoint 1", rows[0].content);
    try testing.expectEqual(.BulletPoint, rows[0].row_type);
    try testing.expectEqualStrings("BulletPoint 2", rows[1].content);
    try testing.expectEqual(.BulletPoint, rows[1].row_type);
}

test "Parser Text" {
    const gpa = testing.allocator;
    const content =
        \\Text 1
        \\Text 2
    ;
    var parser = init(gpa);
    defer parser.deinit();
    try parser.run(content);

    var res = try parser.result();
    defer res.deinit(gpa);

    const rows = res.pages[0].rows;

    try testing.expectEqual(2, rows.len);
    try testing.expectEqualStrings("Text 1", rows[0].content);
    try testing.expectEqual(.Text, rows[0].row_type);
    try testing.expectEqualStrings("Text 2", rows[1].content);
    try testing.expectEqual(.Text, rows[1].row_type);
}

test "Parser Page" {
    const gpa = testing.allocator;
    const content =
        \\# Heading 1
        \\---
        \\---
    ;
    var parser = init(gpa);
    defer parser.deinit();
    try parser.run(content);

    var res = try parser.result();
    defer res.deinit(gpa);

    try testing.expectEqual(3, res.pages.len);
}

test "Parse Mixed" {
    const gpa = testing.allocator;
    const content =
        \\# Heading 1
        \\## SubHeading 1
        \\- BulletPoint 1
        \\Text 1
        \\---
        \\# Heading 2
        \\## SubHeading 2
        \\- BulletPoint 2
        \\Text 2
    ;
    var parser = init(gpa);
    defer parser.deinit();
    try parser.run(content);

    var res = try parser.result();
    defer res.deinit(gpa);

    try testing.expectEqual(2, res.pages.len);
    for (res.pages) |p| {
        const rows = p.rows;

        try testing.expectEqual(4, rows.len);
        try testing.expectEqual(.Heading, rows[0].row_type);
        try testing.expectEqual(.SubHeading, rows[1].row_type);
        try testing.expectEqual(.BulletPoint, rows[2].row_type);
        try testing.expectEqual(.Text, rows[3].row_type);
    }
}

test "Skip Empty Line before Heading" {
    const gpa = testing.allocator;
    const content =
        \\# Heading 1
        \\---
        \\
        \\# Heading 2
    ;
    var parser = init(gpa);
    defer parser.deinit();
    try parser.run(content);

    var res = try parser.result();
    defer res.deinit(gpa);

    const rows = res.pages[1].rows;

    try testing.expectEqual(1, rows.len);
    try testing.expectEqualStrings("Heading 2", rows[0].content);
}

test "Settings are parsed" {
    const gpa = testing.allocator;
    const content =
        \\---
        \\.addons = .{
        \\  .title = "Test",
        \\},
        \\---
        \\# Heading 1
    ;
    var parser = init(gpa);
    defer parser.deinit();
    try parser.run(content);

    var res = try parser.result();
    defer res.deinit(gpa);

    try testing.expectEqualStrings(
        "Test",
        res.settings.addons.title.?,
    );
    try testing.expectEqualStrings(
        "Heading 1",
        res.pages[0].rows[0].content,
    );
}

test "Settings parse error handled" {
    const gpa = testing.allocator;
    const content =
        \\---
        \\.ad = .{
        \\  .title = "Test",
        \\},
        \\---
        \\# Heading 1
    ;
    var parser = init(gpa);
    defer parser.deinit();

    try testing.expectError(error.ParseZon, parser.run(content));

    try testing.expectEqual(
        std.meta.Tag(Error).settings,
        std.meta.activeTag(parser.err.?),
    );
}
