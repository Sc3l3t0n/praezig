const std = @import("std");
const parser = @import("parser.zig");
const termutils = @import("termutils.zig");
const page = @import("page.zig");

const Attributes = @import("attributes.zig").Attributes;
const Parsed = parser.Parsed;
const Allocator = std.mem.Allocator;
const Writer = std.Io.Writer;
const Reader = std.Io.Reader;

pub const Program = struct {
    stdout: *Writer,
    stdin: *Reader,
    allocator: std.mem.Allocator,

    pages: std.ArrayList(page.Page),
    attributes: ?Attributes,
    termsize: termutils.size.TermSize,

    pub fn init(
        io: std.Io,
        allocator: Allocator,
        stdout: *Writer,
        stdin: *Reader,
        path: []const u8,
    ) !Program {
        const parsed = try parser.Parser.fromFile(io, allocator, path);
        return .{
            .stdout = stdout,
            .stdin = stdin,
            .allocator = allocator,
            .pages = parsed.pages,
            .attributes = parsed.attributes,
            .termsize = try termutils.size.getTerminalSize(io),
        };
    }

    pub fn deinit(self: *Program) void {
        for (self.pages.items) |*p| {
            p.deinit();
        }
        self.pages.deinit(self.allocator);
        if (self.attributes) |*a| a.deinit();
    }

    pub fn setup(self: *Program) void {
        if (self.attributes) |*attributes| {
            for (self.pages.items) |*p| {
                p.attributes = attributes;
            }
        }
    }

    pub fn run(self: *Program) !void {
        const stdout = self.stdout;

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
        try page.Page.printEmpty(self.termsize, stdout);
        try stdout.flush();

        while (true) {
            var curPage = &self.pages.items[index];
            var buffer: [4]u8 = undefined;
            curPage.size = &self.termsize;

            if (index != prevIndex) {
                try curPage.print(stdout);
                try stdout.flush();
            }

            prevIndex = index;

            _ = try self.stdin.readSliceShort(&buffer);

            switch (checkInput(&buffer)) {
                .Quit => break,
                .Next => index = std.math.clamp(index + 1, 0, self.pages.items.len - 1),
                .Previous => index = std.math.clamp(index -| 1, 0, self.pages.items.len - 1),
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
    };

    fn checkInput(buffer: []u8) KeyInput {
        return switch (buffer[0]) {
            'q' => KeyInput.Quit,
            ' ', 'l' => KeyInput.Next,
            'h' => KeyInput.Previous,
            else => if (buffer.len >= 3) {
                return switch (buffer[2]) {
                    'D' => KeyInput.Previous,
                    'C' => KeyInput.Next,
                    else => KeyInput.None,
                };
            } else KeyInput.None,
        };
    }
};
