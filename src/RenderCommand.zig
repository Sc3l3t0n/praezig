const std = @import("std");
const termutils = @import("termutils.zig");

const TermSize = termutils.size.TermSize;

const RenderCommand = @This();

writer: *std.Io.Writer,
size: TermSize,

pub fn init(
    writer: *std.Io.Writer,
    size: TermSize,
) RenderCommand {
    return .{
        .writer = writer,
        .size = size,
    };
}
