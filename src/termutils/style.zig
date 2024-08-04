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

    pub fn enable(comptime self: Style) []const u8 {
        return comptime switch (self) {
            .bold => csi ++ "1m",
            .faint => csi ++ "2m",
            .italic => csi ++ "3m",
            .underline => csi ++ "4m",
            .blinking => csi ++ "5m",
            .inverse => csi ++ "7m",
            .invisible => csi ++ "8m",
            .strikethrough => csi ++ "9m",
        };
    }

    pub fn disable(comptime self: Style) []const u8 {
        return comptime switch (self) {
            .bold => csi ++ "22m",
            .faint => csi ++ "22m",
            .italic => csi ++ "23m",
            .underline => csi ++ "24m",
            .blinking => csi ++ "25m",
            .inverse => csi ++ "27m",
            .invisible => csi ++ "28m",
            .strikethrough => csi ++ "29m",
        };
    }
};
