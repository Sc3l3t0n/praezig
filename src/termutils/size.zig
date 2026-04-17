//! The terminal size in columns and rows.
//! This is handled as a singleton, and is updated on resize.
//! After getTermSize() is called,
const std = @import("std");
const builtin = @import("builtin");
const events = @import("../events.zig");

pub const Error = error{
    Unexpected,
    Unsupported,
    NotATty,
};

pub const TermSize = struct {
    col: usize = 0,
    row: usize = 0,
};

const EventWithIo = struct {
    io: std.Io,
    inner: std.Io.Event = .unset,

    pub fn init(io: std.Io) EventWithIo {
        return .{ .io = io };
    }

    pub fn set(event: *EventWithIo) void {
        event.inner.set(event.io);
    }

    pub fn waitAndReset(event: *EventWithIo) !void {
        try event.inner.wait(event.io);
        event.inner.reset();
    }
};

var resize_event: ?EventWithIo = null;

pub fn watch(io: std.Io) error{Canceled}!void {
    if (builtin.os.tag == .windows) return;
    innerWatch(io) catch |err| {
        if (err == error.Canceled) return error.Canceled;
        events.put(io, .{ .error_occured = err }) catch {};
    };
}

fn innerWatch(io: std.Io) !void {
    resize_event = .init(io);
    try installSigwinchHandler();

    while (true) {
        try resize_event.?.waitAndReset();

        const size = try getTerminalSize(io);
        try events.put(io, .{ .window_resize = size });
    }
}

fn installSigwinchHandler() !void {
    const act = std.posix.Sigaction{
        .handler = .{ .handler = &handleSigwinch },
        .mask = std.posix.sigemptyset(),
        .flags = 0,
    };
    std.posix.sigaction(std.posix.SIG.WINCH, &act, null);
}

fn handleSigwinch(_: std.posix.SIG) callconv(.c) void {
    if (resize_event) |*re| re.set();
}

/// Get the size of the terminal.
/// Is supported on Linux, macOS, and Windows.
/// Credit to https://github.com/Siphonay
pub fn getTerminalSize(io: std.Io) Error!TermSize {
    const stdout = std.Io.File.stdout();

    return switch (builtin.target.os.tag) {
        .windows => windows: {
            var get_console_info = std.os.windows.CONSOLE.USER_IO.GET_SCREEN_BUFFER_INFO;

            const result = get_console_info.operate(io, stdout) catch break :windows Error.Unexpected;
            switch (result) {
                .SUCCESS => {},
                else => break :windows Error.Unexpected,
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
                break :other_os Error.Unsupported;
            }

            var winsize: std.posix.winsize = undefined;

            switch (std.posix.errno(ioctl_interface.ioctl(stdout.handle, ioctl_interface.T.IOCGWINSZ, @intFromPtr(&winsize)))) {
                .SUCCESS => break :other_os TermSize{
                    .col = winsize.col,
                    .row = winsize.row - 1, // assume prompt is 1 line high
                },
                else => break :other_os Error.Unexpected,
            }
        },
    } catch |err| {
        if (!(stdout.isTty(io) catch false)) {
            return Error.NotATty;
        } else return err;
    };
}
