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
    // TODO: Make this work on other platforms
    if (builtin.os.tag != .linux) {
        return KBError.NotSupported;
    }
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
