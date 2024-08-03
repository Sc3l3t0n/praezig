const std = @import("std");
const Color = @import("termutils.zig").colors.Color;

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

    // Returns the rendered content as []u8
    // The rendered content is stored in the struct for future use.
    pub fn render(
        self: *Self,
        width: usize,
    ) ![]u8 {
        if (self.renderedContent) |renderedContent| {
            return renderedContent.items;
        }

        if (self.content.items.len >= width) {
            return RowErrors.TooLong; // TODO: Temporary (handle properly)
        }
        self.renderedContent = std.ArrayList(u8).init(self.allocator);
        const buffer = &self.renderedContent.?;
        try buffer.appendNTimes(' ', 4 * self.options.indent);

        const backgroundColor = comptime Color.Black.background();

        switch (self.rowType) {
            .Heading => {
                const esc: []const u8 = comptime Color.DarkYellow.foreground(.Bold) ++ backgroundColor;

                try buffer.appendSlice(esc);
                try buffer.appendSlice(self.content.items);
            },
            .SubHeading => {
                const esc: []const u8 = comptime Color.Blue.foreground(.Bold) ++ backgroundColor;

                try buffer.appendSlice(esc);
                try buffer.appendSlice(self.content.items);
            },
            .Text => {
                const esc: []const u8 = comptime Color.White.foreground(.Normal) ++ backgroundColor;

                try buffer.appendSlice(esc);
                try buffer.appendSlice(self.content.items);
            },
            .BulletPoint => {
                const esc: []const u8 = comptime Color.Green.foreground(.Normal) ++ backgroundColor;
                const esc_back: []const u8 = comptime Color.White.foreground(.Normal) ++ backgroundColor;

                try buffer.appendSlice(esc);
                try buffer.appendSlice("▶ ");
                try buffer.appendSlice(esc_back);
                try buffer.appendSlice(self.content.items);
            },
        }

        try buffer.append('\n');
        return buffer.items;
    }
};
