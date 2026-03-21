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
};

// TODO: Use reader for this parsing
pub fn parse(
    allocator: mem.Allocator,
    content: []const u8,
) !Parsed {
    const win_encoded = mem.containsAtLeast(u8, content, 1, "\r\n");
    var iterator = if (win_encoded)
        mem.splitSequence(u8, content, "\r\n")
    else
        mem.splitSequence(u8, content, "\n");

    var pages = std.ArrayList(Page).empty;
    var index: u32 = 0;

    const attributes = try parseAttributes(allocator, &iterator);

    try pages.append(allocator, try Page.init(allocator, index));

    while (iterator.next()) |token| {
        if (token.len == 0) continue;
        if (mem.startsWith(u8, token, "# ")) {
            const slice = token[2..];
            const r = try Row.init(
                allocator,
                .Heading,
                slice,
                .{},
            );
            try pages.items[index].addRow(r);
        } else if (mem.startsWith(u8, token, "## ")) {
            const slice = token[3..];
            const r = try Row.init(
                allocator,
                .SubHeading,
                slice,
                .{},
            );
            try pages.items[index].addRow(r);
        } else if (mem.startsWith(u8, token, "- ")) {
            const slice = token[2..];
            const r = try Row.init(
                allocator,
                .BulletPoint,
                slice,
                .{},
            );
            try pages.items[index].addRow(r);
        } else if (mem.startsWith(u8, token, "---")) {
            index += 1;
            try pages.append(allocator, try Page.init(allocator, index));
        } else {
            const r = try Row.init(
                allocator,
                .Text,
                token,
                .{},
            );
            try pages.items[index].addRow(r);
        }
    }
    return .{ .pages = pages, .attributes = attributes };
}

pub fn fromFile(
    io: Io,
    allocator: mem.Allocator,
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
        allocator,
        .limited(1024 * 1024 * 1024),
    );
    defer allocator.free(file_content);

    return try parse(allocator, file_content);
}

fn parseAttributes(allocator: mem.Allocator, iterator: *mem.SplitIterator(u8, .sequence)) !?Attributes {
    var attributes = Attributes.init(allocator);
    if (iterator.peek()) |iToken| {
        if (!mem.startsWith(u8, iToken, "---")) return null;
        _ = iterator.next();
        while (iterator.next()) |token| {
            if (mem.startsWith(u8, token, "---")) {
                return attributes;
            } else {
                try attributes.addAttribute(token);
            }
        }
    }
    return null;
}

const testing = std.testing;

test "Parser Headings" {
    const allocator = std.heap.page_allocator;
    const content =
        \\# Heading 1
        \\# Heading 2
    ;
    const pages = (try parse(
        allocator,
        content,
    )).pages;

    const rows = pages.items[0].rows.items;
    try testing.expectEqual(2, rows.len);

    try testing.expectEqualStrings("Heading 1", rows[0].content.items);
    try testing.expectEqualStrings("Heading 2", rows[1].content.items);
}

test "Parser SubHeadings" {
    const allocator = std.heap.page_allocator;
    const content =
        \\## SubHeading 1
        \\## SubHeading 2
    ;
    const pages = (try parse(
        allocator,
        content,
    )).pages;

    const rows = pages.items[0].rows.items;

    try testing.expectEqual(2, rows.len);
    try testing.expectEqualStrings("SubHeading 1", rows[0].content.items);
    try testing.expectEqual(.SubHeading, rows[0].row_type);
    try testing.expectEqualStrings("SubHeading 2", rows[1].content.items);
    try testing.expectEqual(.SubHeading, rows[1].row_type);
}

test "Parser BulletPoints" {
    const allocator = std.heap.page_allocator;
    const content =
        \\- BulletPoint 1
        \\- BulletPoint 2
    ;
    const pages = (try parse(
        allocator,
        content,
    )).pages;
    const rows = pages.items[0].rows.items;

    try testing.expectEqual(2, rows.len);
    try testing.expectEqualStrings("BulletPoint 1", rows[0].content.items);
    try testing.expectEqual(.BulletPoint, rows[0].row_type);
    try testing.expectEqualStrings("BulletPoint 2", rows[1].content.items);
    try testing.expectEqual(.BulletPoint, rows[1].row_type);
}

test "Parser Text" {
    const allocator = std.heap.page_allocator;
    const content =
        \\Text 1
        \\Text 2
    ;
    const pages = (try parse(
        allocator,
        content,
    )).pages;
    const rows = pages.items[0].rows.items;

    try testing.expectEqual(2, rows.len);
    try testing.expectEqualStrings("Text 1", rows[0].content.items);
    try testing.expectEqual(.Text, rows[0].row_type);
    try testing.expectEqualStrings("Text 2", rows[1].content.items);
    try testing.expectEqual(.Text, rows[1].row_type);
}

test "Parser Page" {
    const allocator = std.heap.page_allocator;
    const content =
        \\# Heading 1
        \\---
        \\---
    ;
    const pages = (try parse(
        allocator,
        content,
    )).pages;
    try testing.expectEqual(3, pages.items.len);
}

test "Parse Mixed" {
    const allocator = std.heap.page_allocator;
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
    const pages = (try parse(allocator, content)).pages;

    try testing.expectEqual(2, pages.items.len);
    for (pages.items) |p| {
        const rows = p.rows.items;

        try testing.expectEqual(4, rows.len);
        try testing.expectEqual(.Heading, rows[0].row_type);
        try testing.expectEqual(.SubHeading, rows[1].row_type);
        try testing.expectEqual(.BulletPoint, rows[2].row_type);
        try testing.expectEqual(.Text, rows[3].row_type);
    }
}

test "Skip Empty Line before Heading" {
    const allocator = std.heap.page_allocator;
    const content =
        \\# Heading 1
        \\---
        \\
        \\# Heading 2
    ;
    const pages = (try parse(
        allocator,
        content,
    )).pages;
    const rows = pages.items[1].rows.items;
    try testing.expectEqual(1, rows.len);
    try testing.expectEqualStrings("Heading 2", rows[0].content.items);
}

test "Attributes are parsed" {
    const allocator = std.heap.page_allocator;
    const content =
        \\---
        \\.title: Test
        \\---
        \\# Heading 1
    ;
    const parsed = try parse(allocator, content);
    try testing.expectEqualStrings(
        "Test",
        parsed.attributes.?.title.?.value.items,
    );
    try testing.expectEqualStrings(
        "Heading 1",
        parsed.pages.items[0].rows.items[0].content.items,
    );
}
