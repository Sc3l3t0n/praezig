const esc = "\x1B";
const csi = esc ++ "[";

pub const newPage = csi ++ "2J";


pub const colors = @import("termutils/colors.zig");
pub const size = @import("termutils/size.zig");
