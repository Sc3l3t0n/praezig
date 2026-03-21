const std = @import("std");
const parser = @import("parser.zig");
const termutils = @import("termutils.zig");
const utils = @import("utils.zig");

const Program = @import("program.zig").Program;

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const gpa = init.gpa;

    var stdout_buf: [1024]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writerStreaming(io, &stdout_buf);
    const stdout = &stdout_writer.interface;

    var stderr_buf: [1024]u8 = undefined;
    var stderr_writer = std.Io.File.stderr().writerStreaming(io, &stderr_buf);
    const stderr = &stderr_writer.interface;

    var stdin_buf: [1024]u8 = undefined;
    var stdin_reader = std.Io.File.stdin().readerStreaming(io, &stdin_buf);
    const stdin = &stdin_reader.interface;

    // Parse command line arguments
    const path = utils.extractPathArg(gpa, init.minimal.args) catch |err|
        switch (err) {
            error.MissingPathArgument => {
                try stderr.writeAll("No path provided");
                try stderr.flush();
                std.process.exit(1);
            },
            else => return err,
        };
    defer gpa.free(path);

    if (!utils.validatePath(io, path)) {
        try stderr.print("Path is invalid: {s}", .{path});
        try stderr.flush();
        std.process.exit(1);
    }

    var program = try Program.init(
        init.gpa,
        stdout,
        stdin,
        path,
    );
    defer program.deinit();

    program.setup();
    try program.run();
}

test {
    std.testing.refAllDecls(@This());
}
