const std = @import("std");
const events = @import("events.zig");
const input = @import("input.zig");
const termutils = @import("termutils.zig");
const size = termutils.size;

const Presentation = @import("Presentation.zig");
const Attributes = @import("Attributes.zig");
const Page = @import("Page.zig");
const Allocator = std.mem.Allocator;
const Writer = std.Io.Writer;
const Reader = std.Io.Reader;

pub const Program = @This();

gpa: std.mem.Allocator,
stdout: *Writer,

presentation: Presentation,

pub fn init(
    io: std.Io,
    gpa: Allocator,
    stdout: *Writer,
    path: []const u8,
) !Program {
    return .{
        .gpa = gpa,
        .stdout = stdout,
        .presentation = try Presentation.fromFile(io, gpa, path),
    };
}

pub fn deinit(program: *Program) void {
    program.presentation.deinit(program.gpa);
}

pub fn run(program: *Program, io: std.Io) !void {
    const stdout = program.stdout;

    try events.start(io);
    defer events.stop(io);

    try stdout.print(termutils.alternate_screen, .{});
    try stdout.print(termutils.cursor_hide, .{});
    try stdout.flush();

    try termutils.kb_input.setRawMode(io, true);
    defer termutils.kb_input.setRawMode(io, false) catch {};

    const init_size_event = try events.get(io);
    var term_size = init_size_event.window_resize;

    var index: usize = 0;
    var prevIndex: usize = 1;
    // NOTE: Fixes the first page missing some colors
    try Page.printEmpty(stdout, term_size);
    try stdout.flush();

    while (true) {
        if (index != prevIndex) {
            try program.presentation.printPage(
                program.gpa,
                stdout,
                &term_size,
                index,
            );
            try stdout.flush();
        }
        prevIndex = index;

        switch (try events.get(io)) {
            .key_pressed => |key| {
                switch (key) {
                    .Quit => break,
                    .Next => index = std.math.clamp(index + 1, 0, program.presentation.pageAmount() - 1),
                    .Previous => index = std.math.clamp(index -| 1, 0, program.presentation.pageAmount() - 1),
                    .None => {},
                }
                try stdout.print(termutils.backspace, .{});
            },
            .window_resize => |ts| term_size = ts,
            .error_occured => break, // TODO: Handle recoverable
        }
    }

    try stdout.print(termutils.main_screen, .{});
    try stdout.flush();
}
