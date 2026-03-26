const std = @import("std");
const HorizontalAlignment = @import("../style.zig").HorizontalAlignment;

pub fn print(
    value: []const u8,
    alignment: HorizontalAlignment,
    writer: *std.Io.Writer,
    width: usize,
) !void {
    const padding: usize = switch (alignment) {
        .center => (width - value.len) / 2,
        .left => 0,
        .right => width - value.len,
    };

    try writer.splatByteAll(' ', padding);
    try writer.writeAll(value);
    try writer.writeByte('\n');
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
