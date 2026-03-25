const std = @import("std");
const termutils = @import("termutils.zig");

const TermSize = termutils.size.TermSize;

const RenderCommand = @This();

gpa: std.mem.Allocator,
writer: *std.Io.Writer,
size: TermSize,

pub fn init(
    gpa: std.mem.Allocator,
    writer: *std.Io.Writer,
    size: TermSize,
) RenderCommand {
    return .{
        .gpa = gpa,
        .writer = writer,
        .size = size,
    };
}
