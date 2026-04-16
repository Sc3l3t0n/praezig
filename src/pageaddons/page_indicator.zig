const std = @import("std");
const Settings = @import("../Settings.zig");
const HorizontalAlignment = @import("../style.zig").HorizontalAlignment;

/// String length of the seperator ' / '
const seperator_len = 3;

pub fn print(
    /// Page index in array (0-based)
    index: usize,
    max_page: usize,
    alignment: HorizontalAlignment,
    writer: *std.Io.Writer,
    width: usize,
    settings: Settings,
) !void {
    const page_num = index + 1;
    const page_num_places = numPlaces(page_num);
    const max_page_num_places = numPlaces(max_page);
    const length = page_num_places + max_page_num_places + seperator_len;

    // TODO: Clamp padding for terminals narrower than the rendered indicator.
    const padding: usize = switch (alignment) {
        .center => (width - length) / 2,
        .left => 4,
        .right => width - length - 4,
    };

    try settings.colors.text.page_indicator.printFg(writer, .bold);
    try settings.colors.background.printBg(writer);

    try writer.splatByteAll(' ', padding);
    try writer.print("{d}", .{page_num});

    try settings.colors.decorations.page_indicator.printFg(writer, .bold);
    try settings.colors.background.printBg(writer);
    try writer.writeAll(" / ");

    try settings.colors.text.page_indicator.printFg(writer, .bold);
    try settings.colors.background.printBg(writer);
    try writer.print("{d}", .{max_page});
    try writer.writeByte('\n');
}

fn numPlaces(n: usize) usize {
    if (n < 10) return 1;
    return 1 + numPlaces(n / 10);
}

test {
    const t = std.testing;
    const gpa = t.allocator;

    var writer_instance = std.Io.Writer.Allocating.init(gpa);
    defer writer_instance.deinit();
    const writer = &writer_instance.writer;

    try print(0, 10, .center, writer, 10, .{});

    const expected = "\x1b[1;97m\x1b[40m  1" ++
        "\x1b[1;97m\x1b[40m / " ++
        "\x1b[1;97m\x1b[40m10\n";

    try t.expectEqualStrings(expected, writer_instance.written());
}
