const std = @import("std");
const build_options = @import("build_options");

const Dir = std.Io.Dir;
const Allocator = std.mem.Allocator;

pub const Command = union(enum) {
    path: []const u8,
    help,
    version,
    none,
    unknown: []const u8,

    pub const string_map: std.StaticStringMap(std.meta.Tag(Command)) = .initComptime(.{
        .{ "--help", .help },
        .{ "-h", .help },
        .{ "--version", .version },
        .{ "-v", .version },
    });

    pub fn deinit(command: Command, gpa: Allocator) void {
        switch (command) {
            .path, .unknown => |s| gpa.free(s),
            else => {},
        }
    }
};

const help_message =
    \\ usage:
    \\   praezig [<path> | <option>]
    \\
    \\ arguments:
    \\ - <path>           Path pointing to a valid md file used for displaying the presentation
    \\ 
    \\ options:
    \\ - --help, -h       Displaying this help message
    \\ - --version, -v    Showing version of the current program
    \\
;

/// Prints `help_message` to the provided writer.
/// This does not flush.
pub fn printHelp(writer: *std.Io.Writer) !void {
    try writer.writeAll(help_message);
}

/// Print version from `build_options` to the provided writer.
/// This does not flush.
pub fn printVersion(writer: *std.Io.Writer) !void {
    try writer.print("{s}\n", .{build_options.version});
}

/// Processes args provided, and returns a `Command`.
/// If no valid one is provided, `Command.unknown` is returned.
/// If none at all is provided, `Command.none` is returned.
pub fn processArgToCommand(
    gpa: Allocator,
    args: std.process.Args,
) !Command {
    var iter = try args.iterateAllocator(gpa);
    defer iter.deinit();

    _ = iter.next();

    const arg = iter.next() orelse return .none;

    if (std.mem.startsWith(u8, arg, "-")) {
        const command = Command.string_map.get(arg);
        if (command) |c| {
            return switch (c) {
                inline .help, .version => |tag| @unionInit(Command, @tagName(tag), {}),
                else => unreachable, // no non void tags are inside parse map
            };
        } else {
            return .{ .unknown = try gpa.dupe(u8, arg) };
        }
    } else {
        return .{ .path = try gpa.dupe(u8, arg) };
    }
}

fn validateFile(io: std.Io, dir: std.Io.Dir, path: []const u8) bool {
    const stat = dir.statFile(io, path, .{}) catch return false;
    return stat.kind == .file;
}

/// Checks, if a path provided is a valid file.
pub fn validateFilePath(io: std.Io, path: []const u8) bool {
    return validateFile(io, .cwd(), path);
}

test "validatePath" {
    const t = std.testing;
    var tmp_dir = t.tmpDir(.{});
    defer tmp_dir.cleanup();

    const file = try tmp_dir.dir.createFile(t.io, "slides.md", .{});
    file.close(t.io);

    try t.expect(validateFile(t.io, tmp_dir.dir, "slides.md"));
    try t.expect(!validateFile(t.io, tmp_dir.dir, "test.md"));
    try t.expect(!validateFile(t.io, tmp_dir.dir, "."));
}
