const esc = "\x1B";
const csi = esc ++ "[";

pub const Style = enum {
    Bold,
    Faint,
    Italic,
    Underline,
    Blinking,
    Reverse,
    Invisible,
    Strikethrough,

    pub fn enable(comptime self: Style) []const u8 {
        return comptime switch (self) {
            Style.Bold => csi ++ "1m",
            Style.Faint => csi ++ "2m",
            Style.Italic => csi ++ "3m",
            Style.Underline => csi ++ "4m",
            Style.Blinking => csi ++ "5m",
            Style.Reverse => csi ++ "7m",
            Style.Invisible => csi ++ "8m",
            Style.Strikethrough => csi ++ "9m",
        };
    }

    pub fn disable(comptime self: Style) []const u8 {
        return comptime switch (self) {
            Style.Bold => csi ++ "22m",
            Style.Faint => csi ++ "22m",
            Style.Italic => csi ++ "23m",
            Style.Underline => csi ++ "24m",
            Style.Blinking => csi ++ "25m",
            Style.Reverse => csi ++ "27m",
            Style.Invisible => csi ++ "28m",
            Style.Strikethrough => csi ++ "29m",
        };
    }
};
