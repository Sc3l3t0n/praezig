const std = @import("std");
const termutils = @import("termutils.zig");
const utils = @import("utils.zig");

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

    // Parse command line arguments
    const path = utils.extractPathArg(gpa, init.minimal.args) catch |err|
        switch (err) {
            error.MissingPathArgument => {
                try stderr.writeAll("No path provided\n");
                try stderr.flush();
                std.process.exit(1);
            },
            else => return err,
        };
    defer gpa.free(path);

    if (!utils.validatePath(io, path)) {
        try stderr.print("Path is invalid: {s}\n", .{path});
        try stderr.flush();
        std.process.exit(1);
    }

    var program = try Program.init(
        io,
        gpa,
        stdout,
        stderr,
        path,
    );
    defer program.deinit();

    try program.run(io);
}

test {
    std.testing.refAllDecls(@This());
}
