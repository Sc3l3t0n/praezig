const std = @import("std");
const parser = @import("parser.zig");
const termutils = @import("termutils.zig");
const program = @import("program.zig");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    const stdin = std.io.getStdIn().reader();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) @panic("Memory Leak");
    }
    const allocator = gpa.allocator();

    var p = try program.Program.initFromFile(allocator, stdout.any(), stdin.any(), "/home/sceleton/dev/zig/praezig/test/test1.md");
    defer p.deinit();
    try p.run();
}

test {
    std.testing.refAllDecls(@This());
}
