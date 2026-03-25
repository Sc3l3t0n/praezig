const std = @import("std");
const HorizontalAlignment = @import("../style.zig").HorizontalAlignment;

value: []const u8,
alignment: HorizontalAlignment,

const Title = @This();

pub fn init(value: []const u8) Title {
    return .{
        .value = value,
        .alignment = HorizontalAlignment.center, // TODO: make this configurable
    };
}

pub fn deinit(title: *Title, gpa: std.mem.Allocator) void {
    gpa.free(title.value);
    title.* = undefined;
}

pub fn print(
    title: Title,
    writer: *std.Io.Writer,
    width: usize,
) !void {
    const padding: usize = switch (title.alignment) {
        .center => (width - title.value.len) / 2,
        .left => 0,
        .right => width - title.value.len,
    };

    try writer.splatByteAll(' ', padding);
    try writer.writeAll(title.value);
    try writer.writeByte('\n');
    try writer.splatByteAll('=', width);
}

test {
    const t = std.testing;
    const gpa = t.allocator;

    var writer_instance = std.Io.Writer.Allocating.init(gpa);
    defer writer_instance.deinit();
    const writer = &writer_instance.writer;

    var title = init(try gpa.dupe(u8, "Test"));
    defer title.deinit(gpa);

    try title.print(writer, 10);

    const expected = 
    \\   Test
    \\==========
    ;

    try t.expectEqualStrings(expected, writer_instance.written());
}
