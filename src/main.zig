const std = @import("std");
const parser = @import("parser.zig");
const termutils = @import("termutils.zig");
const program = @import("program.zig");
const utils = @import("utils.zig");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    const stdin = std.io.getStdIn().reader();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) @panic("Memory Leak");
    }
    const allocator = gpa.allocator();

    // Parse command line arguments
    const path = utils.getPathArg(allocator) catch {
        return;
    };
    defer allocator.free(path);

    var p = try program.Program.init(
        allocator,
        stdout.any(),
        stdin.any(),
        path,
    );
    defer p.deinit();
    p.setup();
    try p.run();
}

test {
    std.testing.refAllDecls(@This());
}
