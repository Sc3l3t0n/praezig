const std = @import("std");

const esc = "\x1B";
const csi = esc ++ "[";

/// Resets the terminal style to normal.
pub const reset = csi ++ "0m";

pub const reset_foreground = csi ++ "39m";
pub const reset_background = csi ++ "49m";

pub const default_foreground = csi ++ "K";

/// All the weights that can be used in the terminal.
/// All the colors that can be used in the terminal.
pub const Color = enum {
    default,
    black,
    dark_red,
    dark_green,
    dark_yellow,
    dark_blue,
    dark_magenta,
    dark_cyan,
    light_gray,
    dark_gray,
    red,
    green,
    orange,
    blue,
    magenta,
    cyan,
    white,

    pub fn printFg(color: Color, writer: *std.Io.Writer, weight: Weight) !void {
        try writer.writeAll(csi);
        try writer.writeAll(weight.value());
        try writer.writeAll(Foreground.value(color));
    }

    pub fn printBg(color: Color, writer: *std.Io.Writer) !void {
        try writer.writeAll(csi);
        try writer.writeAll(Background.value(color));
    }

    pub const Weight = enum {
        normal,
        bold,

        pub fn value(weight: Weight) []const u8 {
            return switch (weight) {
                .normal => "0;",
                .bold => "1;",
            };
        }
    };

    /// Used to change the foreground color and weight of the terminal.
    pub const Foreground = struct {
        /// Returns the escape sequence to change the foreground color and weight.
        fn value(color: Color) []const u8 {
            return switch (color) {
                .default => "39m",
                .black => "30m",
                .dark_red => "31m",
                .dark_green => "32m",
                .dark_yellow => "33m",
                .dark_blue => "34m",
                .dark_magenta => "35m",
                .dark_cyan => "36m",
                .light_gray => "37m",
                .dark_gray => "90m",
                .red => "91m",
                .green => "92m",
                .orange => "93m",
                .blue => "94m",
                .magenta => "95m",
                .cyan => "96m",
                .white => "97m",
            };
        }
    };

    /// Used to change the background color of the terminal.
    pub const Background = struct {
        /// Returns the escape sequence to change the background color.
        fn value(color: Color) []const u8 {
            return switch (color) {
                .default => "49m",
                .black => "40m",
                .dark_red => "41m",
                .dark_green => "42m",
                .dark_yellow => "43m",
                .dark_blue => "44m",
                .dark_magenta => "45m",
                .dark_cyan => "46m",
                .light_gray => "47m",
                .dark_gray => "100m",
                .red => "101m",
                .green => "102m",
                .orange => "103m",
                .blue => "104m",
                .magenta => "105m",
                .cyan => "106m",
                .white => "107m",
            };
        }
    };
};
