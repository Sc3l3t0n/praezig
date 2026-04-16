const std = @import("std");
const events = @import("events.zig");
const input = @import("input.zig");
const termutils = @import("termutils.zig");
const size = termutils.size;

const Presentation = @import("Presentation.zig");
const Page = @import("Page.zig");
const RenderCommand = @import("RenderCommand.zig");
const Allocator = std.mem.Allocator;
const Writer = std.Io.Writer;
const Reader = std.Io.Reader;

pub const Program = @This();

gpa: std.mem.Allocator,
stdout: *Writer,
stderr: *Writer,

presentation: Presentation,

pub fn init(
    io: std.Io,
    gpa: Allocator,
    stdout: *Writer,
    stderr: *Writer,
    path: []const u8,
) !Program {
    return .{
        .gpa = gpa,
        .stdout = stdout,
        .stderr = stderr,
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

    try program.enterPresentationMode(io);
    defer program.leavePresentationMode(io);

    var cmd: RenderCommand = .init(
        stdout,
        try size.getTerminalSize(io),
    );

    var index: usize = 0;

    // NOTE: Fixes the first page missing some colors
    try Page.printEmpty(stdout, cmd.size, program.presentation.settings);
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
            .error_occured => |err| {
                try program.stderr.print("Error occured: {t}\n", .{err});
                try program.stderr.flush();
                break;
            },
        }

        try program.printPage(cmd, index);
    }
}

pub fn printPage(program: *Program, cmd: RenderCommand, index: usize) !void {
    try program.presentation.printPage(
        cmd,
        index,
    );
    try cmd.writer.flush();
}

fn enterPresentationMode(program: *Program, io: std.Io) !void {
    try program.stdout.print(termutils.alternate_screen, .{});
    try program.stdout.print(termutils.cursor_hide, .{});
    try program.stdout.flush();
    try termutils.kb_input.setRawMode(io, true);
}

fn leavePresentationMode(program: *Program, io: std.Io) void {
    termutils.kb_input.setRawMode(io, false) catch {};
    program.stdout.print(termutils.main_screen, .{}) catch {};
    program.stdout.print(termutils.cursor_show, .{}) catch {};
    program.stdout.flush() catch {};
}
