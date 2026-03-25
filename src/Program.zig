const std = @import("std");
const events = @import("events.zig");
const input = @import("input.zig");
const termutils = @import("termutils.zig");
const size = termutils.size;

const Presentation = @import("Presentation.zig");
const Attributes = @import("Attributes.zig");
const Page = @import("Page.zig");
const RenderCommand = @import("RenderCommand.zig");
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

    var cmd: RenderCommand = .init(
        program.gpa,
        stdout,
        init_size_event.window_resize,
    );

    var index: usize = 0;
    // NOTE: Fixes the first page missing some colors
    try Page.printEmpty(stdout, cmd.size);
    try stdout.flush();

    try program.printPage(cmd, index);

    while (true) {
        switch (try events.get(io)) {
            .key_pressed => |key| {
                switch (key) {
                    .Quit => break,
                    .Next => index = std.math.clamp(index + 1, 0, program.presentation.pageAmount() - 1),
                    .Previous => index = std.math.clamp(index -| 1, 0, program.presentation.pageAmount() - 1),
                    .None => continue,
                }
                try stdout.print(termutils.backspace, .{});
            },
            .window_resize => |ts| cmd.size = ts,
            .error_occured => break, // TODO: Handle recoverable
        }

        try program.printPage(cmd, index);
    }

    try stdout.print(termutils.main_screen, .{});
    try stdout.flush();
}

pub fn printPage(program: *Program, cmd: RenderCommand, index: usize) !void {
    try program.presentation.printPage(
        cmd,
        index,
    );
    try cmd.writer.flush();
}
