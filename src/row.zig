const std = @import("std");
const Color = @import("termutils.zig").colors.Color;
const Style = @import("termutils.zig").style.Style;

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
    indent: u8 = 0,
};

pub const RowErrors = error{
    TooLong, // TODO: Temporary (handle properly)
};

pub const Row = struct {
    allocator: std.mem.Allocator,

    row_type: RowType,
    content: std.ArrayList(u8),
    rendered_content: ?std.ArrayList(u8),
    content_height: u8,
    options: RowOptions,

    const Self = @This();

    pub fn init(
        allocator: std.mem.Allocator,
        row_type: RowType,
        content: []const u8,
        options: RowOptions,
    ) !Self {
        var contentArray = std.ArrayList(u8).init(allocator);
        try contentArray.appendSlice(content);

        // TODO: Determin content height based on content.

        return Self{
            .allocator = allocator,
            .row_type = row_type,
            .content = contentArray,
            .rendered_content = null,
            .content_height = 1,
            .options = options,
        };
    }

    pub fn deinit(self: Self) void {
        self.content.deinit();
        if (self.rendered_content) |rendered_content| {
            rendered_content.deinit();
        }
    }

    pub fn get_height(self: Self) u8 {
        return switch (self.row_type) {
            .Heading, .SubHeading => self.content_height + 1,
            else => self.content_height,
        };
    }

    // Returns the rendered content as []u8
    // The rendered content is stored in the struct for future use.
    pub fn render(
        self: *Self,
        width: usize,
    ) ![]u8 {
        if (self.rendered_content) |rendered_content| {
            return rendered_content.items;
        }

        if (self.content.items.len >= width) {
            return RowErrors.TooLong; // TODO: Temporary (handle properly)
        }
        self.rendered_content = std.ArrayList(u8).init(self.allocator);
        const buffer = &self.rendered_content.?;
        try buffer.appendNTimes(' ', 4 * self.options.indent);

        const backgroundColor = comptime Color.black.background();

        switch (self.row_type) {
            .Heading => {
                const esc: []const u8 = comptime Color.dark_yellow.foreground(.bold) ++ backgroundColor;

                try buffer.appendSlice(comptime Style.bold.enable() ++ Style.underline.enable());
                try buffer.appendSlice(esc);
                try buffer.appendSlice(self.content.items);
                try buffer.appendSlice(comptime Style.bold.disable() ++ Style.underline.disable());
                try buffer.append('\n');
            },
            .SubHeading => {
                const esc: []const u8 = comptime Color.blue.foreground(.bold) ++ backgroundColor;

                try buffer.appendSlice(comptime Style.bold.enable() ++ Style.underline.enable());
                try buffer.appendSlice(esc);
                try buffer.appendSlice(self.content.items);
                try buffer.appendSlice(comptime Style.bold.disable() ++ Style.underline.disable());
                try buffer.append('\n');
            },
            .Text => {
                const esc: []const u8 = comptime Color.white.foreground(.normal) ++ backgroundColor;

                try buffer.appendSlice(esc);
                try buffer.appendSlice(self.content.items);
            },
            .BulletPoint => {
                const esc: []const u8 = comptime Color.green.foreground(.normal) ++ backgroundColor;
                const esc_back: []const u8 = comptime Color.white.foreground(.normal) ++ backgroundColor;

                try buffer.appendSlice(esc);
                try buffer.appendSlice(if (@import("builtin").os.tag == .windows) "* " else "▶ ");
                try buffer.appendSlice(esc_back);
                try buffer.appendSlice(self.content.items);
            },
        }

        try buffer.append('\n');
        return buffer.items;
    }
};
