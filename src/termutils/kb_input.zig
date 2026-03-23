const std = @import("std");
const builtin = @import("builtin");
const windows = std.os.windows;

/// Error codes for the keyboard module.
pub const Error = error{
    NotSupported,
    Unexpected,
};

/// Set the terminal to rawmode/cookmode.
/// Currently only works on Linux!
pub fn setRawMode(io: std.Io, enable: bool) !void {
    switch (builtin.target.os.tag) {
        .linux => try setRawModeLinux(enable),
        .windows => try setRawModeWindows(io, enable),
        else => return Error.NotSupported,
    }
}

fn setRawModeWindows(io: std.Io, enable: bool) !void {
    const ENABLE_ECHO_INPUT: u16 = 0x0004;
    const ENABLE_LINE_INPUT: u16 = 0x0002;
    const stdin = std.Io.File.stdin();

    var get_console_mode = windows.CONSOLE.USER_IO.GET_MODE;
    switch (get_console_mode.operate(io, stdin) catch return Error.Unexpected) {
        .SUCCESS => {},
        else => return Error.Unexpected,
    }

    var mode = get_console_mode.Data;

    if (enable) {
        mode &= ~ENABLE_ECHO_INPUT;
        mode &= ~ENABLE_LINE_INPUT;
    } else {
        mode |= ENABLE_ECHO_INPUT;
        mode |= ENABLE_LINE_INPUT;
    }

    var set_console_mode = windows.CONSOLE.USER_IO.SET_MODE(mode);
    switch (set_console_mode.operate(io, stdin) catch return Error.Unexpected) {
        .SUCCESS => {},
        else => return Error.Unexpected,
    }
}

fn setRawModeLinux(enable: bool) !void {
    const fd = std.Io.File.stdin().handle;
    var current = std.posix.tcgetattr(fd) catch return Error.Unexpected;

    current.lflag.ECHO = !enable;
    current.lflag.ICANON = !enable;

    std.posix.tcsetattr(fd, .NOW, current) catch return Error.Unexpected;
}
