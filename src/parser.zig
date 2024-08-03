const std = @import("std");
const row = @import("row.zig");
const page = @import("page.zig");
const fs = std.fs;

const mem = std.mem;
const Attributes = @import("attributes.zig").Attributes;

pub const Parsed = struct {
    pages: std.ArrayList(page.Page),
    attributes: ?Attributes,
};

pub const Parser = struct {
    pub fn parse(
        allocator: std.mem.Allocator,
        content: []const u8,
    ) !Parsed {
        const win_encoded = std.mem.containsAtLeast(u8, content, 1, "\r\n");
        var iterator = if (win_encoded)
            mem.splitSequence(u8, content, "\r\n")
        else
            mem.splitSequence(u8, content, "\n");

        var pages = std.ArrayList(page.Page).init(allocator);
        var index: u32 = 0;

        const attributes = try parseAttributes(allocator, &iterator);

        try pages.append(try page.Page.init(allocator, index));

        while (iterator.next()) |token| {
            if (token.len == 0) continue;
            if (mem.startsWith(u8, token, "# ")) {
                const slice = token[2..];
                const r = try row.Row.init(
                    allocator,
                    .Heading,
                    slice,
                    .{},
                );
                try pages.items[index].addRow(r);
            } else if (mem.startsWith(u8, token, "## ")) {
                const slice = token[3..];
                const r = try row.Row.init(
                    allocator,
                    .SubHeading,
                    slice,
                    .{},
                );
                try pages.items[index].addRow(r);
            } else if (mem.startsWith(u8, token, "- ")) {
                const slice = token[2..];
                const r = try row.Row.init(
                    allocator,
                    .BulletPoint,
                    slice,
                    .{},
                );
                try pages.items[index].addRow(r);
            } else if (mem.startsWith(u8, token, "---")) {
                index += 1;
                try pages.append(try page.Page.init(allocator, index));
            } else {
                const r = try row.Row.init(
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
        allocator: std.mem.Allocator,
        path: []const u8,
    ) !Parsed {
        const file = try fs.openFileAbsolute(path, .{});
        defer file.close();

        var array = std.ArrayList(u8).init(allocator);
        defer array.deinit();

        try file.reader().readAllArrayList(&array, 50000);

        return try parse(allocator, array.items);
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
};

const testing = std.testing;

test "Parser Headings" {
    const allocator = std.heap.page_allocator;
    const content =
        \\# Heading 1
        \\# Heading 2
    ;
    const pages = (try Parser.parse(
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
    const pages = (try Parser.parse(
        allocator,
        content,
    )).pages;

    const rows = pages.items[0].rows.items;

    try testing.expectEqual(2, rows.len);
    try testing.expectEqualStrings("SubHeading 1", rows[0].content.items);
    try testing.expectEqual(.SubHeading, rows[0].rowType);
    try testing.expectEqualStrings("SubHeading 2", rows[1].content.items);
    try testing.expectEqual(.SubHeading, rows[1].rowType);
}

test "Parser BulletPoints" {
    const allocator = std.heap.page_allocator;
    const content =
        \\- BulletPoint 1
        \\- BulletPoint 2
    ;
    const pages = (try Parser.parse(
        allocator,
        content,
    )).pages;
    const rows = pages.items[0].rows.items;

    try testing.expectEqual(2, rows.len);
    try testing.expectEqualStrings("BulletPoint 1", rows[0].content.items);
    try testing.expectEqual(.BulletPoint, rows[0].rowType);
    try testing.expectEqualStrings("BulletPoint 2", rows[1].content.items);
    try testing.expectEqual(.BulletPoint, rows[1].rowType);
}

test "Parser Text" {
    const allocator = std.heap.page_allocator;
    const content =
        \\Text 1
        \\Text 2
    ;
    const pages = (try Parser.parse(
        allocator,
        content,
    )).pages;
    const rows = pages.items[0].rows.items;

    try testing.expectEqual(2, rows.len);
    try testing.expectEqualStrings("Text 1", rows[0].content.items);
    try testing.expectEqual(.Text, rows[0].rowType);
    try testing.expectEqualStrings("Text 2", rows[1].content.items);
    try testing.expectEqual(.Text, rows[1].rowType);
}

test "Parser Page" {
    const allocator = std.heap.page_allocator;
    const content =
        \\# Heading 1
        \\---
        \\---
    ;
    const pages = (try Parser.parse(
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
    const pages = (try Parser.parse(allocator, content)).pages;

    try testing.expectEqual(2, pages.items.len);
    for (pages.items) |p| {
        const rows = p.rows.items;

        try testing.expectEqual(4, rows.len);
        try testing.expectEqual(.Heading, rows[0].rowType);
        try testing.expectEqual(.SubHeading, rows[1].rowType);
        try testing.expectEqual(.BulletPoint, rows[2].rowType);
        try testing.expectEqual(.Text, rows[3].rowType);
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
    const pages = (try Parser.parse(
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
    const parsed = try Parser.parse(allocator, content);
    try testing.expectEqualStrings(
        "Test",
        parsed.attributes.?.title.?.items,
    );
    try testing.expectEqualStrings(
        "Heading 1",
        parsed.pages.items[0].rows.items[0].content.items,
    );
}
