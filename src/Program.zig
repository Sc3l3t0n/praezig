const std = @import("std");
const termutils = @import("termutils.zig");

const Presentation = @import("Presentation.zig");
const Attributes = @import("Attributes.zig");
const Page = @import("Page.zig");
const Allocator = std.mem.Allocator;
const Writer = std.Io.Writer;
const Reader = std.Io.Reader;

pub const Program = @This();

stdout: *Writer,
stdin: *Reader,
gpa: std.mem.Allocator,

presentation: Presentation,
termsize: termutils.size.TermSize,

pub fn init(
    io: std.Io,
    gpa: Allocator,
    stdout: *Writer,
    stdin: *Reader,
    path: []const u8,
) !Program {
    return .{
        .stdout = stdout,
        .stdin = stdin,
        .gpa = gpa,
        .presentation = try Presentation.fromFile(io, gpa, path),
        .termsize = try termutils.size.getTerminalSize(io),
    };
}

pub fn deinit(program: *Program) void {
    program.presentation.deinit(program.gpa);
}

pub fn run(program: *Program) !void {
    const stdout = program.stdout;

    try stdout.print(termutils.alternate_screen, .{});
    try stdout.print(termutils.cursor_hide, .{});
    try stdout.flush();

    try termutils.kb_input.setRawMode(true);
    defer {
        termutils.kb_input.setRawMode(false) catch {};
    }

    var index: usize = 0;
    var prevIndex: usize = 1;
    // NOTE: Fixes the first page missing some colors
    try Page.printEmpty(stdout, program.termsize);
    try stdout.flush();

    while (true) {
        if (index != prevIndex) {
            try program.presentation.printPage(
                program.gpa,
                stdout,
                &program.termsize,
                index,
            );
            try stdout.flush();
        }

        prevIndex = index;

        switch (try KeyInput.fromStdin(program.stdin)) {
            .Quit => break,
            .Next => index = std.math.clamp(index + 1, 0, program.presentation.pageAmount() - 1),
            .Previous => index = std.math.clamp(index -| 1, 0, program.presentation.pageAmount() - 1),
            .None => {},
        }

        try stdout.print(termutils.backspace, .{});
    }

    try stdout.print(termutils.main_screen, .{});
    try stdout.flush();
}

const KeyInput = enum {
    Quit,
    Next,
    Previous,
    None,

    fn fromStdin(stdin: *Reader) !KeyInput {
        switch (try stdin.peekByte()) {
            'q', ' ', 'l', 'h' => |c| {
                stdin.toss(1);
                return .fromSlice(&.{c});
            },
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
