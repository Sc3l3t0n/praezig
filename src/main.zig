const std = @import("std");
const parser = @import("parser.zig");
const termutils = @import("termutils.zig");

pub fn main() !void {
    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("Run `zig build test` to run the tests.\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const deinit_status = gpa.deinit();
        // fail test; can't try in defer as defer is executed after we return
        if (deinit_status == .leak) @panic("Memory Leak");
    }
    const allocator = gpa.allocator();

    const content =
        \\# This is a Test
        \\Another Test
        \\- Hallo
        \\- Welt
        \\---
        \\# This is a Test
        \\Another Test
        \\- Hallo
    ;
    _ = content;

    var pages = try parser.Parser.fromFile(allocator, "/home/sceleton/dev/zig/praezig/test/test1.md");

    // var pages = try parser.Parser.parse(allocator, content);
    defer {
        for (pages.items) |*page| {
            page.deinit();
        }
        pages.deinit();
    }

    const size = try termutils.size.getTerminalSize();

    try stdout.print(termutils.alternateScreen, .{});
    try bw.flush(); // don't forget to flush!

    for (pages.items) |*page| {
        page.size = size;
        try page.print(stdout);
        try bw.flush(); // don't forget to flush!
        std.time.sleep(2 * std.time.ns_per_s);
    }

    try stdout.print(termutils.mainScreen, .{});
    try bw.flush(); // don't forget to flush!
}
