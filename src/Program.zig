const std = @import("std");
const events = @import("events.zig");
const input = @import("input.zig");
const termutils = @import("termutils.zig");
const size = termutils.size;

const Presentation = @import("Presentation.zig");
const Page = @import("Page.zig");
const Terminal = @import("Terminal.zig");
const Allocator = std.mem.Allocator;
const Writer = std.Io.Writer;
const Reader = std.Io.Reader;
const Parser = @import("Parser.zig");

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
    var parser = Parser.init(gpa);
    defer parser.deinit();

    parser.runFromFile(io, path) catch |err| {
        try stderr.print("The error '{t}' occured.\n", .{err});
        if (parser.err) |perr| {
            try stderr.print("Error messages:\n {f}", .{perr});
        }

        return err;
    };

    return .{
        .gpa = gpa,
        .stdout = stdout,
        .stderr = stderr,
        .presentation = try parser.result(),
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

    var term: Terminal = .init(
        stdout,
        program.presentation.settings,
        try size.getTerminalSize(io),
    );

    var index: usize = 0;
    try program.printPage(term, index);

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
            .window_resize => |ts| term.size = ts,
            .error_occured => |err| {
                try program.stderr.print("Error occured: {t}\n", .{err});
                try program.stderr.flush();
                break;
            },
        }

        try program.printPage(term, index);
    }
}

pub fn printPage(program: *Program, term: Terminal, index: usize) !void {
    try program.presentation.printPage(term, index);
    try term.stdout.flush();
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
