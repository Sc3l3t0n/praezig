// NOTE: Maybe get them from termutils
const esc = "\x1B";
const csi = esc ++ "[";

pub const reset = csi ++ "0m";

pub const Weight = enum {
    Normal,
    Bold,
};

pub const Color = enum {
    Default,
    Black,
    DarkRed,
    DarkGreen,
    DarkYellow,
    DarkBlue,
    DarkMagenta,
    DarkCyan,
    LightGray,
    DarkGray,
    Red,
    Green,
    Orange,
    Blue,
    Magenta,
    Cyan,
    White,
};

pub const Foreground = struct {
    const Default = "39m";
    const Black = "30m";
    const DarkRed = "31m";
    const DarkGreen = "32m";
    const DarkYellow = "33m";
    const DarkBlue = "34m";
    const DarkMagenta = "35m";
    const DarkCyan = "36m";
    const LightGray = "37m";
    const DarkGray = "90m";
    const Red = "91m";
    const Green = "92m";
    const Orange = "93m";
    const Blue = "94m";
    const Magenta = "95m";
    const Cyan = "96m";
    const White = "97m";

    pub fn get(comptime color: Color, comptime weight: Weight) []const u8 {
        const sWeight = switch (weight) {
            .Normal => "0;",
            .Bold => "1;",
        };

        const sColor = switch (color) {
            .Default => Default,
            .Black => Black,
            .DarkRed => DarkRed,
            .DarkGreen => DarkGreen,
            .DarkYellow => DarkYellow,
            .DarkBlue => DarkBlue,
            .DarkMagenta => DarkMagenta,
            .DarkCyan => DarkCyan,
            .LightGray => LightGray,
            .DarkGray => DarkGray,
            .Red => Red,
            .Green => Green,
            .Orange => Orange,
            .Blue => Blue,
            .Magenta => Magenta,
            .Cyan => Cyan,
            .White => White,
        };

        return csi ++ sWeight ++ sColor;
    }
};

pub const Background = struct {
    const Default = "49m";
    const Black = "40m";
    const DarkRed = "41m";
    const DarkGreen = "42m";
    const DarkYellow = "43m";
    const DarkBlue = "44m";
    const DarkMagenta = "45m";
    const DarkCyan = "46m";
    const LightGray = "47m";
    const DarkGray = "100m";
    const Red = "101m";
    const Green = "101m";
    const Orange = "103m";
    const Blue = "104m";
    const Magenta = "105m";
    const Cyan = "106m";
    const White = "107m";

    pub fn get(comptime color: Color) []const u8 {
        const sColor = switch (color) {
            .Default => Default,
            .Black => Black,
            .DarkRed => DarkRed,
            .DarkGreen => DarkGreen,
            .DarkYellow => DarkYellow,
            .DarkBlue => DarkBlue,
            .DarkMagenta => DarkMagenta,
            .DarkCyan => DarkCyan,
            .LightGray => LightGray,
            .DarkGray => DarkGray,
            .Red => Red,
            .Green => Green,
            .Orange => Orange,
            .Blue => Blue,
            .Magenta => Magenta,
            .Cyan => Cyan,
            .White => White,
        };

        return csi ++ sColor;
    }
};
