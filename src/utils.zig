const std = @import("std");

const Dir = std.Io.Dir;
const Allocator = std.mem.Allocator;

// Returns the path argument passed to the program
// If no path is provided, prints an error message to stderr and returns an error
pub fn extractPathArg(
    gpa: Allocator,
    args: std.process.Args,
) (error{MissingPathArgument} || Allocator.Error)![]u8 {
    var iter = try args.iterateAllocator(gpa);
    defer iter.deinit();

    const rel_path = iter.next() orelse {
        return error.MissingPathArgument;
    };

    return try gpa.dupe(u8, rel_path);
}

pub fn validatePath(io: std.Io, path: []const u8) bool {
    if (std.fs.path.isAbsolute(path)) {
        Dir.openDirAbsolute(io, path, .{}) catch return false;
    } else {
        Dir.cwd().access(io, path, .{}) catch return false;
    }
    return true;
}
