const std = @import("std");
const mem = std.mem;
const fs = std.fs;

const Io = std.Io;
const Attributes = @import("Attributes.zig");
const Page = @import("Page.zig");
const Row = @import("Row.zig");

pub const Parsed = struct {
    pages: std.ArrayList(Page),
    attributes: ?Attributes,

    pub fn deinit(parsed: *Parsed, gpa: mem.Allocator) void {
        if (parsed.attributes) |*a| a.deinit(gpa);
        for (parsed.pages.items) |*page| {
            page.deinit(gpa);
        }
        parsed.pages.deinit(gpa);
        parsed.* = undefined;
    }
};

// TODO: Use reader for this parsing
pub fn parse(
    gpa: mem.Allocator,
    content: []const u8,
) !Parsed {
    const win_encoded = mem.containsAtLeast(u8, content, 1, "\r\n");
    var iterator = if (win_encoded)
        mem.splitSequence(u8, content, "\r\n")
    else
        mem.splitSequence(u8, content, "\n");

    var pages = std.ArrayList(Page).empty;
    var index: u32 = 0;

    const attributes = try parseAttributes(gpa, &iterator);

    try pages.append(gpa, Page.init(index));

    while (iterator.next()) |token| {
        if (token.len == 0) continue;
        if (mem.startsWith(u8, token, "# ")) {
            const slice = token[2..];
            const r = Row.init(
                .Heading,
                try gpa.dupe(u8, slice),
                .{},
            );
            try pages.items[index].addRow(gpa, r);
        } else if (mem.startsWith(u8, token, "## ")) {
            const slice = token[3..];
            const r = Row.init(
                .SubHeading,
                try gpa.dupe(u8, slice),
                .{},
            );
            try pages.items[index].addRow(gpa, r);
        } else if (mem.startsWith(u8, token, "- ")) {
            const slice = token[2..];
            const r = Row.init(
                .BulletPoint,
                try gpa.dupe(u8, slice),
                .{},
            );
            try pages.items[index].addRow(gpa, r);
        } else if (mem.startsWith(u8, token, "---")) {
            index += 1;
            try pages.append(gpa, Page.init(index));
        } else {
            const r = Row.init(
                .Text,
                try gpa.dupe(u8, token),
                .{},
            );
            try pages.items[index].addRow(gpa, r);
        }
    }
    return .{ .pages = pages, .attributes = attributes };
}

pub fn fromFile(
    io: Io,
    gpa: mem.Allocator,
    path: []const u8,
) !Parsed {
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

fn parseAttributes(gpa: mem.Allocator, iterator: *mem.SplitIterator(u8, .sequence)) !?Attributes {
    const peek = iterator.peek();
    if (peek == null or !mem.startsWith(u8, peek.?, "---")) return null;

    _ = iterator.next();
    const start_i = iterator.index.?;
    const value = iterator.rest();

    while (iterator.peek()) |token| {
        if (mem.startsWith(u8, token, "---")) break;
        _ = iterator.next();
    }

    const len = iterator.index.? - start_i - iterator.delimiter.len;
    _ = iterator.next();

    return try Attributes.parse(gpa, value[0..len], null);
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

    const rows = parsed.pages.items[0].rows.items;
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

    const rows = parsed.pages.items[0].rows.items;

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
    const rows = parsed.pages.items[0].rows.items;

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
    const rows = parsed.pages.items[0].rows.items;

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
    try testing.expectEqual(3, parsed.pages.items.len);
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

    try testing.expectEqual(2, parsed.pages.items.len);
    for (parsed.pages.items) |p| {
        const rows = p.rows.items;

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
    const rows = parsed.pages.items[1].rows.items;
    try testing.expectEqual(1, rows.len);
    try testing.expectEqualStrings("Heading 2", rows[0].content);
}

test "Attributes are parsed" {
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
        parsed.attributes.?.title.?.value,
    );
    try testing.expectEqualStrings(
        "Heading 1",
        parsed.pages.items[0].rows.items[0].content,
    );
}
