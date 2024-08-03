const std = @import("std");

// Error type for CLI errors
const CliError = error{
    // Error for when no path argument is provided
    MissingArgument,
};

// Returns the path argument passed to the program
// If no path is provided, prints an error message to stderr and returns an error
pub fn get_path_arg(allocator: std.mem.Allocator) ![]u8 {
    const stderr = std.io.getStdErr().writer();

    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();
    _ = args.next();

    const rel_path = args.next() orelse {
        try stderr.print("No path provided", .{});
        return CliError.MissingArgument;
    };

    const path = std.fs.cwd().realpathAlloc(allocator, rel_path) catch |err| {
        try std.io.getStdErr().writer().print("Path is invalid: {s}\n", .{rel_path});
        return err;
    };

    return path;
}
