const std = @import("std");
const alignments = @import("alignments.zig");

const Presentation = @import("Presentation.zig");
const Color = @import("termutils.zig").colors.Color;
const Style = @import("termutils.zig").style.Style;
const Terminal = @import("Terminal.zig");

pub const Type = enum {
    Heading,
    SubHeading,
    Text,
    BulletPoint,
    // TODO: SubBulletPoint,
    // TODO: NumberedPoint,
};

pub const Options = struct {
    verticalAlignment: alignments.Vertical = .center,
    horizontalAlignment: alignments.Horizontal = .left,
    indent: u8 = 1,
};

const Row = @This();

row_type: Type,
content: []const u8,
content_height: u8,
options: Options,

pub fn init(
    row_type: Type,
    content: []const u8,
    options: Options,
) Row {
    // TODO: Determin content height based on content.
    return Row{
        .row_type = row_type,
        .content = content,
        .content_height = 1,
        .options = options,
    };
}

pub fn deinit(row: *Row, gpa: std.mem.Allocator) void {
    gpa.free(row.content);
    row.* = undefined;
}

pub fn get_height(row: Row) u8 {
    return switch (row.row_type) {
        .Heading, .SubHeading => row.content_height + 1,
        else => row.content_height,
    };
}

pub fn print_empty(term: Terminal) std.Io.Writer.Error!void {
    try term.splatByteAll(
        ' ',
        term.size.col,
    );
}

/// Renders row to writer
pub fn print(row: Row, term: Terminal) Presentation.PrintError!void {
    const settings = term.settings;

    // TODO: Fold line here
    if (row.content.len >= term.size.col) {
        return Presentation.PrintError.TooSmall;
    }

    try term.splatByteAll(' ', 2 * row.options.indent);

    switch (row.row_type) {
        .Heading => {
            const styles = [_]Style{ .bold, .underline };
            try term.enableStyleAll(&styles);

            try term.setFg(settings.colors.text.heading, .bold);
            try term.defaultBg();

            try term.writeAll(row.content);
            try term.writeByte('\n');

            try term.disableStyleAll(&styles);
        },
        .SubHeading => {
            const styles = [_]Style{ .bold, .underline };
            try term.enableStyleAll(&styles);

            try term.setFg(settings.colors.text.sub_heading, .bold);
            try term.defaultBg();

            try term.writeAll(row.content);
            try term.writeByte('\n');

            try term.disableStyleAll(&styles);
        },
        .Text => {
            try term.setFg(settings.colors.text.normal_text, .normal);
            try term.defaultBg();

            try term.writeAll(row.content);
        },
        .BulletPoint => {
            try term.setFg(settings.colors.decorations.bullet_point, .normal);
            try term.defaultBg();

            try term.writeAll(if (@import("builtin").os.tag == .windows) "* " else "▶ ");
            try term.setFg(settings.colors.text.bullet_point, .normal);
            try term.defaultBg();

            try term.writeAll(row.content);
        },
    }

    try term.writeByte('\n');
}
