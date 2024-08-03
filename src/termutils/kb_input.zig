const std = @import("std");
const builtin = @import("builtin");

/// Error codes for the keyboard module.
pub const KBError = error{
    NotSupported,
    Unexpected,
};

/// Set the terminal to rawmode/cookmode.
/// Currently only works on Linux!
pub fn setRawMode(enable: bool) !void {
    switch (builtin.os.tag) {
        .linux => try setRawModeLinux(enable),
        .windows => try setRawModeWindows(enable),
        else => return KBError.NotSupported,
    }
}

extern "kernel32" fn GetConsoleMode(hConsoleHandle: *anyopaque, lpMode: usize) c_int;
extern "kernel32" fn SetConsoleMode(hConsoleHandle: *anyopaque, lpMode: usize) c_int;
extern "kernel32" fn GetStdHandle(nStdHandle: *anyopaque) *anyopaque;

fn setRawModeWindows(enable: bool) !void {
    const ENABLE_ECHO_INPUT: u16 = 0x0004;
    const ENABLE_LINE_INPUT: u16 = 0x0002;

    var mode: u32 = 0;

    const fd = std.io.getStdIn().handle;
    const err = GetConsoleMode(GetStdHandle(fd), @intFromPtr(&mode));
    if (err != 0) {
        return KBError.Unexpected;
    }

    if (enable) {
        mode &= ~ENABLE_ECHO_INPUT;
        mode &= ~ENABLE_LINE_INPUT;
    } else {
        mode |= ENABLE_ECHO_INPUT;
        mode |= ENABLE_LINE_INPUT;
    }

    const err_set = SetConsoleMode(fd, @intFromPtr(&mode));
    if (err_set != 0) {
        return KBError.Unexpected;
    }
}

fn setRawModeLinux(enable: bool) !void {
    const termios = std.posix.termios;
    const TCGETS = std.posix.T.CGETS;
    const TCSETS = std.posix.T.CSETS;

    var current: termios = undefined;

    const fd = std.io.getStdIn().handle;
    const errGet = std.os.linux.ioctl(fd, TCGETS, @intFromPtr(&current));
    switch (std.posix.errno(errGet)) {
        .SUCCESS => {},
        else => return KBError.Unexpected,
    }

    if (enable) {
        current.lflag.ECHO = false;
        current.lflag.ICANON = false;
    } else {
        current.lflag.ECHO = true;
        current.lflag.ICANON = true;
    }

    const errSet = std.os.linux.ioctl(fd, TCSETS, @intFromPtr(&current));
    switch (std.posix.errno(errSet)) {
        .SUCCESS => {},
        else => return KBError.Unexpected,
    }
}
