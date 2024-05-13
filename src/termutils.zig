const esc = "\x1B";
const csi = esc ++ "[";

pub const newPage = csi ++ "2J";

pub const alternateScreen = csi ++ "?1049h";
pub const mainScreen = csi ++ "?1049l";

pub const colors = @import("termutils/colors.zig");
pub const size = @import("termutils/size.zig");
