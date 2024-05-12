const std = @import("std");
const row = @import("row.zig");
const page = @import("page.zig");

const mem = std.mem;

pub const Parser = struct {
    pub fn parse(
        allocator: std.mem.Allocator,
        content: []const u8,
    ) !std.ArrayList(page.Page) {
        var tokenIterator = mem.tokenize(u8, content, "\n");
        var pages = std.ArrayList(page.Page).init(allocator);
        var index: u32 = 0;

        try pages.append(try page.Page.init(allocator, index));

        // NOTE: Do i need to free the memory of the tokens?
        while (tokenIterator.next()) |token| {
            if (mem.startsWith(u8, token, "# ")) {
                const slice = mem.trimLeft(u8, token, "# ");
                const r = try row.Row.init(allocator, .Heading, slice, .{});
                try pages.items[index].addRow(r);
            } else if (mem.startsWith(u8, token, "## ")) {
                const slice = mem.trimLeft(u8, token, "## ");
                const r = try row.Row.init(allocator, .SubHeading, slice, .{});
                try pages.items[index].addRow(r);
            } else if (mem.startsWith(u8, token, "- ")) {
                const slice = mem.trimLeft(u8, token, "- ");
                const r = try row.Row.init(allocator, .BulletPoint, slice, .{});
                try pages.items[index].addRow(r);
            } else if (mem.startsWith(u8, token, "---")) {
                index += 1;
                try pages.append(try page.Page.init(allocator, index));
            } else {
                const r = try row.Row.init(allocator, .Text, token, .{});
                try pages.items[index].addRow(r);
            }
        }
        return pages;
    }
};

const testing = std.testing;

test "Parser Headings" {
    const allocator = std.heap.page_allocator;
    const content =
        \\# Heading 1
        \\# Heading 2
    ;
    const pages = try Parser.parse(allocator, content);

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
    const pages = try Parser.parse(allocator, content);

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
    const pages = try Parser.parse(allocator, content);
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
    const pages = try Parser.parse(allocator, content);
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
        \\---
        \\---
    ;
    const pages = try Parser.parse(allocator, content);
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
    const pages = try Parser.parse(allocator, content);

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
