const std = @import("std");
const Settings = @import("../Settings.zig");
const HorizontalAlignment = @import("../style.zig").HorizontalAlignment;

pub fn print(
    value: []const u8,
    alignment: HorizontalAlignment,
    writer: *std.Io.Writer,
    width: usize,
    settings: Settings,
) !void {
    const padding: usize = switch (alignment) {
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

    try print("Test", .center, writer, 10);

    const expected =
        \\   Test
        \\==========
    ;

    try t.expectEqualStrings(expected, writer_instance.written());
}
