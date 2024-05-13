const esc = "\x1B";
const csi = esc ++ "[";

pub const newPage = csi ++ "2J";

pub const alternateScreen = csi ++ "?1049h";
pub const mainScreen = csi ++ "?1049l";

pub const cursorHide = csi ++ "?25l";
pub const cursorShow = csi ++ "?25h";

pub const backspace = "\x08";

pub const colors = @import("termutils/colors.zig");
pub const size = @import("termutils/size.zig");
pub const kb_input = @import("termutils/kb_input.zig");
