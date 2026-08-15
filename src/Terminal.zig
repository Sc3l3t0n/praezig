const std = @import("std");
const termutils = @import("termutils.zig");

const Settings = @import("Settings.zig");
const TermSize = @import("termutils.zig").size.TermSize;
const Writer = std.Io.Writer;
const colors = termutils.colors;
const Color = termutils.colors.Color;
const Style = termutils.style.Style;

const Terminal = @This();

stdout: *Writer,
settings: Settings = .{},
size: TermSize = .{},

pub fn init(
    stdout: *Writer,
    settings: Settings,
    size: TermSize,
) Terminal {
    return .{
        .stdout = stdout,
        .settings = settings,
        .size = size,
    };
}

// --- Writer Wrappers ---

pub fn print(term: Terminal, comptime fmt: []const u8, args: anytype) !void {
    try term.stdout.print(fmt, args);
}

pub fn writeAll(term: Terminal, bytes: []const u8) !void {
    try term.stdout.writeAll(bytes);
}

pub fn writeByte(term: Terminal, byte: u8) !void {
    try term.stdout.writeByte(byte);
}

pub fn splatByteAll(term: Terminal, byte: u8, n: usize) !void {
    try term.stdout.splatByteAll(byte, n);
}

// --- Color Wrappers ---

pub fn setFg(term: Terminal, color: Color, weight: Color.Weight) !void {
    try color.printFg(term.stdout, weight);
}

pub fn defaultFg(term: Terminal) !void {
    try term.settings.colors.text.normal_text.printFg(term.stdout, .normal);
}

pub fn resetFg(term: Terminal) !void {
    try term.writeAll(colors.reset_foreground);
}

pub fn setBg(term: Terminal, color: Color) !void {
    try color.printBg(term.stdout);
}

pub fn defaultBg(term: Terminal) !void {
    try term.settings.colors.background.printBg(term.stdout);
}

pub fn resetBg(term: Terminal) !void {
    try term.writeAll(colors.reset_background);
}

pub fn resetColors(term: Terminal) !void {
    try term.writeAll(colors.reset);
}

// --- Style Wrappers ---

pub fn enableStyle(term: Terminal, style: termutils.style.Style) !void {
    try style.printEnable(term.stdout);
}

pub fn disableStyle(term: Terminal, style: termutils.style.Style) !void {
    try style.printDisable(term.stdout);
}

pub fn enableStyleAll(term: Terminal, styles: []const termutils.style.Style) !void {
    try Style.printEnableAll(styles, term.stdout);
}

pub fn disableStyleAll(term: Terminal, styles: []const termutils.style.Style) !void {
    try Style.printDisableAll(styles, term.stdout);
}

// --- Other Wrappers ---

pub fn clearScreen(term: Terminal) !void {
    try term.writeAll(termutils.clear_and_home);
}
