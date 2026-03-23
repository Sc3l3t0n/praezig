// Credit to https://github.com/Siphonay
const std = @import("std");
const builtin = @import("builtin");

pub const TermSizeError = error{
    Unexpected,
    Unsupported,
    NotATty,
};

/// The terminal size in columns and rows.
pub const TermSize = struct {
    col: usize,
    row: usize,
};

/// Get the size of the terminal.
/// Is supported on Linux, macOS, and Windows.
pub fn getTerminalSize(io: std.Io) TermSizeError!TermSize {
    const stdout = std.Io.File.stdout();

    return switch (builtin.target.os.tag) {
        .windows => windows: {
            var get_console_info = std.os.windows.CONSOLE.USER_IO.GET_SCREEN_BUFFER_INFO;

            const result = get_console_info.operate(io, stdout) catch break :windows TermSizeError.Unexpected;
            switch (result) {
                .SUCCESS => {},
                else => break :windows TermSizeError.Unexpected,
            }

            break :windows TermSize{ // These are stored in a signed type (windows.SHORT) but will never be negative
                .col = @intCast(get_console_info.Data.dwWindowSize.X),
                .row = @intCast(get_console_info.Data.dwWindowSize.Y - 1), // assume prompt is 1 line high
            };
        },
        else => |os_tag| other_os: {
            const ioctl_interface = switch (os_tag) {
                .linux => std.os.linux,
                else => std.c,
            };

            if (!@hasDecl(ioctl_interface, "T")) {
                break :other_os TermSizeError.Unsupported;
            }

            var winsize: std.posix.winsize = undefined;

            switch (std.posix.errno(ioctl_interface.ioctl(stdout.handle, ioctl_interface.T.IOCGWINSZ, @intFromPtr(&winsize)))) {
                .SUCCESS => break :other_os TermSize{
                    .col = winsize.col,
                    .row = winsize.row - 1, // assume prompt is 1 line high
                },
                else => break :other_os TermSizeError.Unexpected,
            }
        },
    } catch |err| {
        if (!(stdout.isTty(io) catch false)) {
            return TermSizeError.NotATty;
        } else return err;
    };
}
