const esc = "\x1B";
const csi = esc ++ "[";

/// Escape sequence to clear the screen.
pub const clearScreen = csi ++ "2J";

/// Escape sequence to switch to the alternate screen.
pub const alternateScreen = csi ++ "?1049h";
/// Escape sequence to switch back to the main screen.
pub const mainScreen = csi ++ "?1049l";

/// Escape sequence to remove the cursor.
pub const cursorHide = csi ++ "?25l";
/// Escape sequence to show the cursor.
pub const cursorShow = csi ++ "?25h";

/// Backspace character.
pub const backspace = "\x08";

/// Modify the style (colors and weight) of the terminal.
pub const colors = @import("termutils/colors.zig");
/// Get the size of the terminal.
pub const size = @import("termutils/size.zig");
/// Manage Keyboard input.
pub const kb_input = @import("termutils/kb_input.zig");
