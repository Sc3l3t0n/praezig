const std = @import("std");

const esc = "\x1B";
const csi = esc ++ "[";

pub const Style = enum {
    bold,
    faint,
    italic,
    underline,
    blinking,
    inverse,
    invisible,
    strikethrough,

    pub fn printEnable(style: Style, writer: *std.Io.Writer) !void {
        try writer.writeAll(csi);
        try writer.writeAll(style.enable());
    }

    pub fn printEnableAll(styles: []const Style, writer: *std.Io.Writer) !void {
        for (styles) |style| try style.printEnable(writer);
    }

    pub fn printDisable(style: Style, writer: *std.Io.Writer) !void {
        try writer.writeAll(csi);
        try writer.writeAll(style.disable());
    }

    pub fn printDisableAll(styles: []const Style, writer: *std.Io.Writer) !void {
        for (styles) |style| try style.printDisable(writer);
    }

    pub fn enable(style: Style) []const u8 {
        return switch (style) {
            .bold => "1m",
            .faint => "2m",
            .italic => "3m",
            .underline => "4m",
            .blinking => "5m",
            .inverse => "7m",
            .invisible => "8m",
            .strikethrough => "9m",
        };
    }

    pub fn disable(style: Style) []const u8 {
        return switch (style) {
            .bold => "22m",
            .faint => "22m",
            .italic => "23m",
            .underline => "24m",
            .blinking => "25m",
            .inverse => "27m",
            .invisible => "28m",
            .strikethrough => "29m",
        };
    }
};
