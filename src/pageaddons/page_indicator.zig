const std = @import("std");
const Terminal = @import("../Terminal.zig");
const HorizontalAlignment = @import("../alignments.zig").Horizontal;

/// String length of the seperator ' / '
const seperator_len = 3;

pub fn print(
    term: Terminal,
    /// Page index in array (0-based)
    index: usize,
    max_page: usize,
) !void {
    const settings = term.settings;

    const page_num = index + 1;
    const page_num_places = numPlaces(page_num);
    const max_page_num_places = numPlaces(max_page);
    const length = page_num_places + max_page_num_places + seperator_len;

    // TODO: Clamp padding for terminals narrower than the rendered indicator.
    const padding: usize = switch (settings.alignments.horizontal.page_indicator) {
        .center => (term.size.col - length) / 2,
        .left => 4,
        .right => term.size.col - length - 4,
    };

    try term.setFg(settings.colors.text.page_indicator, .bold);
    try term.defaultBg();

    try term.splatByteAll(' ', padding);
    try term.print("{d}", .{page_num});

    try term.setFg(settings.colors.decorations.page_indicator, .bold);
    try term.defaultBg();

    try term.writeAll(" / ");

    try term.setFg(settings.colors.text.page_indicator, .bold);
    try term.defaultBg();
    try term.print("{d}", .{max_page});
    try term.writeByte('\n');
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
    const term: Terminal = .{ .stdout = writer, .size = .{ .col = 10 } };

    try print(term, 0, 10);

    const expected = "\x1b[1;97m\x1b[40m  1" ++
        "\x1b[1;97m\x1b[40m / " ++
        "\x1b[1;97m\x1b[40m10\n";

    try t.expectEqualStrings(expected, writer_instance.written());
}
