const std = @import("std");
const Settings = @import("../Settings.zig");
const HorizontalAlignment = @import("../alignments.zig").Horizontal;

pub fn print(
    value: []const u8,
    writer: *std.Io.Writer,
    width: usize,
    settings: Settings,
) !void {
    const padding: usize = switch (settings.alignments.horizontal.title) {
        .center => (width - value.len) / 2,
        .left => 0,
        .right => width - value.len,
    };

    try settings.colors.text.title.printFg(writer, .bold);
    try settings.colors.background.printBg(writer);

    try writer.splatByteAll(' ', padding);
    try writer.writeAll(value);
    try writer.writeByte('\n');

    try settings.colors.decorations.title.printFg(writer, .bold);
    try settings.colors.background.printBg(writer);
    try writer.splatByteAll('=', width);
}

test {
    const t = std.testing;
    const gpa = t.allocator;

    var writer_instance = std.Io.Writer.Allocating.init(gpa);
    defer writer_instance.deinit();
    const writer = &writer_instance.writer;

    try print("Test", writer, 10, .{});

    const expected = "\x1b[1;97m\x1b[40m   Test\n" ++
        "\x1b[1;97m\x1b[40m==========";

    try t.expectEqualStrings(expected, writer_instance.written());
}
