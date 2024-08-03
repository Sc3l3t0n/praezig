const std = @import("std");
const parser = @import("parser.zig");
const termutils = @import("termutils.zig");
const page = @import("page.zig");

pub const Program = struct {
    writer: std.io.AnyWriter,
    reader: std.io.AnyReader,
    allocator: std.mem.Allocator,

    pages: std.ArrayList(page.Page),
    termsize: termutils.size.TermSize,

    const Self = @This();

    pub fn init(
        allocator: std.mem.Allocator,
        writer: std.io.AnyWriter,
        reader: std.io.AnyReader,
        content: []const u8,
    ) !Self {
        return Self{
            .writer = writer,
            .reader = reader,
            .allocator = allocator,
            .pages = try parser.Parser.parse(allocator, content),
            .termsize = try termutils.size.getTerminalSize(),
        };
    }

    pub fn initFromFile(
        allocator: std.mem.Allocator,
        writer: std.io.AnyWriter,
        reader: std.io.AnyReader,
        path: []const u8,
    ) !Self {
        return Self{
            .writer = writer,
            .reader = reader,
            .allocator = allocator,
            .pages = try parser.Parser.fromFile(allocator, path),
            .termsize = try termutils.size.getTerminalSize(),
        };
    }

    pub fn deinit(self: *Self) void {
        for (self.pages.items) |*p| {
            p.deinit();
        }
        self.pages.deinit();
    }

    pub fn run(self: *Self) !void {
        var bw = std.io.bufferedWriter(self.writer);
        const stdout = bw.writer();

        try stdout.print(termutils.alternateScreen, .{});
        try stdout.print(termutils.cursorHide, .{});
        try bw.flush();

        try termutils.kb_input.setRawMode(true);
        defer {
            termutils.kb_input.setRawMode(false) catch {};
        }

        var index: usize = 0;

        // Note: Fixes the first page missing some colors
        try page.Page.print_empty(self.termsize, stdout);
        try bw.flush();

        while (true) {
            var curPage = &self.pages.items[index];
            var buffer: [4]u8 = undefined;
            curPage.size = &self.termsize;
            try curPage.print(stdout);
            try bw.flush();
            _ = try self.reader.read(buffer[0..]);

            switch (checkInput(&buffer)) {
                .Quit => break,
                .Next => index = std.math.clamp(index + 1, 0, self.pages.items.len - 1),
                .Previous => index = std.math.clamp(index -| 1, 0, self.pages.items.len - 1),
                .None => {},
            }

            try stdout.print(termutils.backspace, .{});
        }

        try stdout.print(termutils.mainScreen, .{});
        try bw.flush();
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
