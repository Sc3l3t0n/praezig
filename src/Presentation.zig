const std = @import("std");
const mem = std.mem;
const fs = std.fs;

const Io = std.Io;
const Settings = @import("Settings.zig");
const Page = @import("Page.zig");
const Row = @import("Row.zig");
const Terminal = @import("Terminal.zig");

const Presentation = @This();

pub const PrintError = error{
    TooSmall,
} || std.Io.Writer.Error;

pages: []Page,
settings: Settings,

pub fn deinit(presentation: *Presentation, gpa: mem.Allocator) void {
    presentation.settings.deinit(gpa);
    for (presentation.pages) |*page| {
        page.deinit(gpa);
    }
    gpa.free(presentation.pages);
    presentation.* = undefined;
}

pub fn printPage(
    presentation: *Presentation,
    term: Terminal,
    index: usize,
) !void {
    if (index >= presentation.pages.len) return error.IndexOutOfRange;

    presentation.pages[index].print(
        term,
        index,
        presentation.pages.len,
    ) catch |err| switch (err) {
        error.TooSmall => try Page.printTooSmall(term),
        else => return err,
    };
}

pub fn pageAmount(presentation: Presentation) usize {
    return presentation.pages.len;
}
