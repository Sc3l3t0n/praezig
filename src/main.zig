const std = @import("std");
const termutils = @import("termutils.zig");
const args = @import("args.zig");

const Program = @import("Program.zig");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const gpa = init.gpa;

    var stdout_buf: [1024]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writerStreaming(io, &stdout_buf);
    const stdout = &stdout_writer.interface;

    var stderr_buf: [1024]u8 = undefined;
    var stderr_writer = std.Io.File.stderr().writerStreaming(io, &stderr_buf);
    const stderr = &stderr_writer.interface;

    const command = try args.processArgToCommand(gpa, init.minimal.args);
    const path = path: switch (command) {
        .help => {
            try args.printHelp(stdout);
            try stdout.flush();
            std.process.exit(0);
        },
        .version => {
            try args.printVersion(stdout);
            try stdout.flush();
            std.process.exit(0);
        },
        .path => |p| break :path p,
        .none => {
            try stderr.writeAll("No argument provided. Write `--help` to see available.\n");
            try stderr.flush();
            std.process.exit(1);
        },
        .unknown => |s| {
            try stderr.print("Unkown command '{s}'. Write `--help` to see available.\n", .{s});
            try stderr.flush();
            std.process.exit(1);
        },
    };
    defer gpa.free(path);

    if (!args.validateFilePath(io, path)) {
        try stderr.print("Path is invalid: {s}\n", .{path});
        try stderr.flush();
        std.process.exit(1);
    }

    var program = Program.init(
        io,
        gpa,
        stdout,
        stderr,
        path,
    ) catch {
        try stderr.flush();
        std.process.exit(1);
    };
    defer program.deinit();

    try program.run(io);
}

test {
    std.testing.refAllDecls(@This());
}
