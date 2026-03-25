const std = @import("std");
const events = @import("events.zig");

pub const KeyInput = enum {
    Quit,
    Next,
    Previous,
    None,

    fn fromStdin(stdin: *std.Io.Reader) !KeyInput {
        switch (try stdin.peekByte()) {
            'q', ' ', 'l', 'h' => |c| {
                stdin.toss(1);
                return .fromSlice(&.{c});
            },
            // TODO: Not supported under windows
            '\x1b' => {
                const esc = try stdin.take(3);
                return .fromSlice(esc);
            },
            else => {
                stdin.toss(1);
                return .None;
            },
        }
    }

    fn fromSlice(slice: []const u8) KeyInput {
        if (slice.len == 0) return .None;

        return switch (slice[0]) {
            'q' => .Quit,
            ' ', 'l' => .Next,
            'h' => .Previous,
            '\x1b' => if (slice.len >= 3) switch (slice[2]) {
                'D' => .Previous,
                'C' => .Next,
                else => .None,
            } else .None,
            else => .None,
        };
    }

    test "fromSlice handles known keys" {
        const cases = .{
            .{ "q", .Quit },
            .{ " ", .Next },
            .{ "l", .Next },
            .{ "h", .Previous },
            .{ &.{ '\x1b', '[', 'C' }, .Next },
            .{ &.{ '\x1b', '[', 'D' }, .Previous },
        };
        inline for (cases) |case| {
            try std.testing.expectEqual(case[1], fromSlice(case[0]));
        }
    }

    test "fromSlice ignores unsupported input" {
        const cases = .{
            "",
            "x",
            &.{ '\x1b', '[' },
            &.{ '\x1b', '[', 'A' },
        };
        inline for (cases) |case| {
            try std.testing.expectEqual(.None, fromSlice(case));
        }
    }

    test "fromStdin handles known keys" {
        const cases = .{
            .{ "qx", .Quit, 'x' },
            .{ " l", .Next, 'l' },
            .{ "hy", .Previous, 'y' },
            .{ &.{ '\x1b', '[', 'C', 'z' }, .Next, 'z' },
        };
        inline for (cases) |case| {
            var reader: std.Io.Reader = .fixed(case[0]);
            try std.testing.expectEqual(case[1], try fromStdin(&reader));
            try std.testing.expectEqual(case[2], try reader.peekByte());
        }
    }

    test "fromStdin consumes unsupported input" {
        const cases = .{
            .{ "xq", 'q' },
            .{ &.{ '\x1b', '[', 'A', 'q' }, 'q' },
        };
        inline for (cases) |case| {
            var reader: std.Io.Reader = .fixed(case[0]);
            try std.testing.expectEqual(.None, try fromStdin(&reader));
            try std.testing.expectEqual(case[1], try reader.peekByte());
        }
    }
};

pub fn watch(io: std.Io) error{Canceled}!void {
    innerWatch(io) catch |err| {
        if (err == error.Canceled) return error.Canceled;
        events.put(io, .{ .error_occured = err }) catch {};
    };
}

pub fn cancle(io: std.Io) void {
    std.Io.File.stdin().close(io);
}

fn innerWatch(io: std.Io) !void {
    var stdin_buf: [1024]u8 = undefined;
    var stdin_reader = std.Io.File.stdin().readerStreaming(io, &stdin_buf);
    const stdin = &stdin_reader.interface;

    while (true) {
        try io.checkCancel();
        const key = try KeyInput.fromStdin(stdin);
        if (key != .None) try events.put(io, .{ .key_pressed = key });
        // if (key == .Quit) return;
    }
}
