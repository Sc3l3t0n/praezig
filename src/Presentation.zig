const std = @import("std");
const mem = std.mem;
const fs = std.fs;

const Io = std.Io;
const Settings = @import("Settings.zig");
const Page = @import("Page.zig");
const Row = @import("Row.zig");
const RenderCommand = @import("RenderCommand.zig");
const TermSize = @import("termutils.zig").size.TermSize;

const Presentation = @This();

pages: []Page,
settings: Settings,

pub fn deinit(presentation: *Presentation, gpa: mem.Allocator) void {
    presentation.settings.deinit(gpa);
    for (presentation.pages) |*page| {
        page.deinit(gpa);
    }
    gpa.free(presentation.pages);
    presentation.* = undefined;
}

// TODO: Use reader for this parsing
pub fn parse(
    gpa: mem.Allocator,
    content: []const u8,
) !Presentation {
    const win_encoded = mem.containsAtLeast(u8, content, 1, "\r\n");
    var iterator = if (win_encoded)
        mem.splitSequence(u8, content, "\r\n")
    else
        mem.splitSequence(u8, content, "\n");

    const settings = try parseSettings(gpa, &iterator);

    var pages = std.ArrayList(Page).empty;
    var rows = std.ArrayList(Row).empty;
    defer rows.deinit(gpa);

    while (iterator.next()) |token| {
        if (token.len == 0) continue;
        if (mem.startsWith(u8, token, "# ")) {
            const slice = token[2..];
            const r = Row.init(
                .Heading,
                try gpa.dupe(u8, slice),
                .{},
            );
            try rows.append(gpa, r);
        } else if (mem.startsWith(u8, token, "## ")) {
            const slice = token[3..];
            const r = Row.init(
                .SubHeading,
                try gpa.dupe(u8, slice),
                .{},
            );
            try rows.append(gpa, r);
        } else if (mem.startsWith(u8, token, "- ")) {
            const slice = token[2..];
            const r = Row.init(
                .BulletPoint,
                try gpa.dupe(u8, slice),
                .{},
            );
            try rows.append(gpa, r);
        } else if (mem.startsWith(u8, token, "---")) {
            const p = Page.init(try rows.toOwnedSlice(gpa));
            try pages.append(gpa, p);
        } else {
            const r = Row.init(
                .Text,
                try gpa.dupe(u8, token),
                .{},
            );
            try rows.append(gpa, r);
        }
    }

    const p = Page.init(try rows.toOwnedSlice(gpa));
    try pages.append(gpa, p);

    return .{ .pages = try pages.toOwnedSlice(gpa), .settings = settings };
}

pub fn fromFile(
    io: Io,
    gpa: mem.Allocator,
    path: []const u8,
) !Presentation {
    const file = if (fs.path.isAbsolute(path))
        try Io.Dir.openFileAbsolute(io, path, .{})
    else
        try Io.Dir.cwd().openFile(io, path, .{});

    defer file.close(io);

    var file_buf: [1024]u8 = undefined;
    var file_reader = file.reader(io, &file_buf);
    const file_content = try file_reader.interface.allocRemaining(
        gpa,
        .limited(1024 * 1024 * 1024),
    );
    defer gpa.free(file_content);

    return try parse(gpa, file_content);
}

fn parseSettings(gpa: mem.Allocator, iterator: *mem.SplitIterator(u8, .sequence)) !Settings {
    const peek = iterator.peek();
    if (peek == null or !mem.startsWith(u8, peek.?, "---")) return .{};

    _ = iterator.next();
    const start_i = iterator.index.?;
    const value = iterator.rest();

    while (iterator.peek()) |token| {
        if (mem.startsWith(u8, token, "---")) break;
        _ = iterator.next();
    }

    const len = iterator.index.? - start_i - iterator.delimiter.len;
    _ = iterator.next();

    return try Settings.parse(gpa, value[0..len], null);
}

pub fn printPage(
    presentation: *Presentation,
    cmd: RenderCommand,
    index: usize,
) !void {
    if (index >= presentation.pages.len) return error.IndexOutOfRange;

    try presentation.pages[index].print(
        cmd,
        presentation.settings,
    );
}

pub fn pageAmount(presentation: Presentation) usize {
    return presentation.pages.len;
}

const testing = std.testing;

test "Parser Headings" {
    const gpa = testing.allocator;
    const content =
        \\# Heading 1
        \\# Heading 2
    ;
    var parsed = try parse(
        gpa,
        content,
    );
    defer parsed.deinit(gpa);

    const rows = parsed.pages[0].rows;
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
    var parsed = try parse(
        gpa,
        content,
    );
    defer parsed.deinit(gpa);

    const rows = parsed.pages[0].rows;

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
    var parsed = try parse(
        gpa,
        content,
    );
    defer parsed.deinit(gpa);
    const rows = parsed.pages[0].rows;

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
    var parsed = try parse(
        gpa,
        content,
    );
    defer parsed.deinit(gpa);
    const rows = parsed.pages[0].rows;

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
    var parsed = try parse(
        gpa,
        content,
    );
    defer parsed.deinit(gpa);
    try testing.expectEqual(3, parsed.pages.len);
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
    var parsed = try parse(gpa, content);
    defer parsed.deinit(gpa);

    try testing.expectEqual(2, parsed.pages.len);
    for (parsed.pages) |p| {
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
    var parsed = try parse(
        gpa,
        content,
    );
    defer parsed.deinit(gpa);
    const rows = parsed.pages[1].rows;
    try testing.expectEqual(1, rows.len);
    try testing.expectEqualStrings("Heading 2", rows[0].content);
}

test "Settings are parsed" {
    const gpa = testing.allocator;
    const content =
        \\---
        \\.title = "Test"
        \\---
        \\# Heading 1
    ;
    var parsed = try parse(gpa, content);
    defer parsed.deinit(gpa);

    try testing.expectEqualStrings(
        "Test",
        parsed.settings.title.?,
    );
    try testing.expectEqualStrings(
        "Heading 1",
        parsed.pages[0].rows[0].content,
    );
}
