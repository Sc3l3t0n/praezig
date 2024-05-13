const std = @import("std");
const colors = @import("termutils.zig").colors;

pub const RowType = enum {
    Heading,
    SubHeading,
    Text,
    BulletPoint,
    // TODO: SubBulletPoint,
    // TODO: NumberedPoint,
};

pub const VerticalAlignment = enum {
    Left,
    Center,
    Right,
};

pub const HorizontalAlignment = enum {
    Top,
    Center,
    Bottom,
};

pub const RowOptions = struct {
    verticalAlignment: VerticalAlignment = .Left,
    horizontalAlignment: HorizontalAlignment = .Center,
    height: u8 = 1,
    indent: u8 = 0,
};

pub const RowErrors = error{
    TooLong, // TODO: Temporary (handle properly)
};

pub const Row = struct {
    allocator: std.mem.Allocator,

    rowType: RowType,
    content: std.ArrayList(u8),
    renderedContent: ?std.ArrayList(u8),
    contentHeight: u8,
    options: RowOptions,

    const Self = @This();

    pub fn init(
        allocator: std.mem.Allocator,
        rowType: RowType,
        content: []const u8,
        options: RowOptions,
    ) !Self {
        // TODO: Use fromOwnedSlice
        var contentArray = std.ArrayList(u8).init(allocator);
        try contentArray.appendSlice(content);

        // TODO: Determin content height based on content.

        return Self{
            .allocator = allocator,
            .rowType = rowType,
            .content = contentArray,
            .renderedContent = null,
            .contentHeight = 1,
            .options = options,
        };
    }

    pub fn deinit(self: Self) void {
        self.content.deinit();
        if (self.renderedContent) |renderedContent| {
            renderedContent.deinit();
        }
    }

    // Returns the rendered content as *ArrayList(u8).
    // The rendered content is stored in the struct for future use.
    // 'deinit' is called by the row
    pub fn render(
        self: *Self,
        width: usize,
    ) !*[]u8 {
        if (self.renderedContent) |*renderedContent| {
            return &renderedContent.items;
        }

        if (self.content.items.len >= width) {
            return RowErrors.TooLong; // TODO: Temporary (handle properly)
        }
        self.renderedContent = std.ArrayList(u8).init(self.allocator);
        const buffer = &self.renderedContent.?;
        try buffer.appendNTimes(' ', 4 * self.options.indent);

        const backgroundColor = colors.Background.get(.Black);
        var widthWithEscapeCodes = width + 2;

        switch (self.rowType) {
            .Heading => {
                try buffer.appendSlice(colors.Foreground.get(.DarkYellow, .Bold));
                try buffer.appendSlice(backgroundColor);
                widthWithEscapeCodes += 2 * backgroundColor.len;
                try buffer.appendSlice(self.content.items);
            },
            .SubHeading => {
                try buffer.appendSlice(colors.Foreground.get(.Blue, .Bold));
                try buffer.appendSlice(backgroundColor);
                widthWithEscapeCodes += 2 * backgroundColor.len;
                try buffer.appendSlice(self.content.items);
            },
            .Text => {
                try buffer.appendSlice(colors.Foreground.get(.White, .Normal));
                try buffer.appendSlice(backgroundColor);
                widthWithEscapeCodes += 2 * backgroundColor.len;
                try buffer.appendSlice(self.content.items);
            },
            .BulletPoint => {
                try buffer.appendSlice(colors.Foreground.get(.Green, .Normal));
                try buffer.appendSlice(backgroundColor);
                widthWithEscapeCodes += 2 * backgroundColor.len;
                try buffer.appendSlice("▶ ");
                try buffer.appendSlice(colors.Foreground.get(.White, .Normal));
                try buffer.appendSlice(backgroundColor);
                widthWithEscapeCodes += backgroundColor.len;
                try buffer.appendSlice(self.content.items);
            },
        }

        try buffer.appendNTimes(' ', widthWithEscapeCodes -| buffer.items.len);
        try buffer.append('\n');
        return &buffer.items;
    }
};
