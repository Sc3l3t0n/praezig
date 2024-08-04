const esc = "\x1B";
const csi = esc ++ "[";

/// Resets the terminal style to normal.
pub const reset = csi ++ "0m";

pub const reset_foreground = csi ++ "39m";
pub const reset_background = csi ++ "49m";

pub const default_foreground = csi ++ "K";

/// All the weights that can be used in the terminal.
pub const Weight = enum {
    normal,
    bold,
};

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

    pub fn foreground(comptime color: Color, comptime weight: Weight) []const u8 {
        return comptime Foreground.get(color, weight);
    }

    pub fn background(comptime color: Color) []const u8 {
        return comptime Background.get(color);
    }
};

/// Used to change the foreground color and weight of the terminal.
const Foreground = struct {
    /// Returns the escape sequence to change the foreground color and weight.
    fn get(comptime color: Color, comptime weight: Weight) []const u8 {
        const sWeight = comptime switch (weight) {
            .normal => "0;",
            .bold => "1;",
        };

        const sColor = comptime switch (color) {
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

        comptime return csi ++ sWeight ++ sColor;
    }
};

/// Used to change the background color of the terminal.
const Background = struct {
    /// Returns the escape sequence to change the background color.
    fn get(comptime color: Color) []const u8 {
        const sColor = comptime switch (color) {
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

        comptime return csi ++ sColor;
    }
};
