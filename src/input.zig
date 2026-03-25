const std = @import("std");
const events = @import("events.zig");

pub const KeyInput = enum {
    Quit,
    Next,
    Previous,
    None,

    fn fromFile(io: std.Io, file: std.Io.File) !KeyInput {
        const Operation = struct {
            fn run(inner_io: std.Io, inner_file: std.Io.File, comptime n: usize) ![n]u8 {
                var buf: [n]u8 = undefined;

                const operation: std.Io.Operation = .{ .file_read_streaming = .{
                    .file = inner_file,
                    .data = &.{&buf},
                } };

                const result = try inner_io.operate(operation);
                _ = try result.file_read_streaming;
                return buf;
            }
        };

        const input = try Operation.run(io, file, 1);

        switch (input[0]) {
            'q', ' ', 'l', 'h' => |c| {
                return .fromSlice(&.{c});
            },
            // TODO: Not supported under windows
            '\x1b' => {
                const esc = try Operation.run(io, file, 2);
                return .escFromChar(esc[1]);
            },
            else => {
                return .None;
            },
        }
    }

    fn escFromChar(esc: u8) KeyInput {
        return switch (esc) {
            'D' => .Previous,
            'C' => .Next,
            else => .None,
        };
    }

    fn fromSlice(slice: []const u8) KeyInput {
        if (slice.len == 0) return .None;

        return switch (slice[0]) {
            'q' => .Quit,
            ' ', 'l' => .Next,
            'h' => .Previous,
            '\x1b' => if (slice.len >= 3) escFromChar(slice[2]) else .None,
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

    test "fromFile handles known keys" {
        const io = std.testing.io;
        const cases = .{
            .{ "qx", .Quit, 'x' },
            .{ " l", .Next, 'l' },
            .{ "hy", .Previous, 'y' },
            .{ &.{ '\x1b', '[', 'C', 'z' }, .Next, 'z' },
        };
        var tmp_dir = std.testing.tmpDir(.{});
        defer tmp_dir.cleanup();

        inline for (cases) |case| {
            const file = try tmp_dir.dir.createFile(io, "test", .{ .read = true });
            defer file.close(io);

            var file_buf: [4]u8 = undefined;
            var file_writer = file.writerStreaming(io, &file_buf);

            try file_writer.interface.writeAll(case[0]);
            try file_writer.flush();

            try file_writer.seekTo(0);
            try std.testing.expectEqual(case[1], fromFile(io, file) catch |err| {
                std.debug.print("{t}\n", .{err});
                return err;
            });

            var reader = file_writer.moveToReader();
            try std.testing.expectEqual(case[2], try reader.interface.takeByte());
        }
    }

    test "fromFile consumes unsupported input" {
        const io = std.testing.io;
        const cases = .{
            .{ "xq", 'q' },
            .{ &.{ '\x1b', '[', 'A', 'q' }, 'q' },
        };
        var tmp_dir = std.testing.tmpDir(.{});
        defer tmp_dir.cleanup();

        inline for (cases) |case| {
            const file = try tmp_dir.dir.createFile(io, "test", .{ .read = true });
            defer file.close(io);

            var file_buf: [4]u8 = undefined;
            var file_writer = file.writerStreaming(io, &file_buf);

            try file_writer.interface.writeAll(case[0]);
            try file_writer.flush();

            try file_writer.seekTo(0);
            try std.testing.expectEqual(.None, try fromFile(io, file));

            var reader = file_writer.moveToReader();
            try std.testing.expectEqual(case[1], try reader.interface.takeByte());
        }
    }

    test "fromFile canceles correctly" {
        const io = std.testing.io;
        var tmp_dir = std.testing.tmpDir(.{});
        defer tmp_dir.cleanup();

        const file = try tmp_dir.dir.createFile(io, "test", .{ .read = true });
        defer file.close(io);

        var future = io.async(fromFile, .{ io, file });
        try std.testing.expectError(error.Canceled, future.cancel(io));
    }
};

pub fn watch(io: std.Io) error{Canceled}!void {
    innerWatch(io) catch |err| {
        if (err == error.Canceled) return error.Canceled;
        events.put(io, .{ .error_occured = err }) catch {};
    };
}

fn innerWatch(io: std.Io) !void {
    const stdin = std.Io.File.stdin();
    while (true) {
        try io.checkCancel();
        const key = try KeyInput.fromFile(io, stdin);
        if (key != .None) try events.put(io, .{ .key_pressed = key });
        if (key == .Quit) return;
    }
}
