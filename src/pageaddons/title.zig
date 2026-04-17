const std = @import("std");
const Terminal = @import("../Terminal.zig");
const HorizontalAlignment = @import("../alignments.zig").Horizontal;

pub fn print(
    term: Terminal,
    value: []const u8,
) !void {
    const settings = term.settings;
    const width = term.size.col;
    const padding: usize = switch (settings.alignments.horizontal.title) {
        .center => (width - value.len) / 2,
        .left => 0,
        .right => width - value.len,
    };

    try term.setFg(settings.colors.text.title, .bold);
    try term.defaultBg();

    try term.splatByteAll(' ', padding);
    try term.writeAll(value);
    try term.writeByte('\n');

    try term.setFg(settings.colors.decorations.title, .bold);
    try term.defaultBg();
    try term.splatByteAll('=', width);
}

test {
    const t = std.testing;
    const gpa = t.allocator;

    var writer_instance = std.Io.Writer.Allocating.init(gpa);
    defer writer_instance.deinit();
    const writer = &writer_instance.writer;
    const term: Terminal = .{ .stdout = writer, .size = .{ .col = 10 } };

    try print(term, "Test");

    const expected = "\x1b[1;97m\x1b[40m   Test\n" ++
        "\x1b[1;97m\x1b[40m==========";

    try t.expectEqualStrings(expected, writer_instance.written());
}
