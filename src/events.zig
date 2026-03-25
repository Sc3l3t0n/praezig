const std = @import("std");
const input = @import("input.zig");
const size = @import("termutils.zig").size;

const Queue = std.Io.Queue(Event);

const Events = @This();

pub const Event = union(enum) {
    key_pressed: input.KeyInput,
    window_resize: size.TermSize,
    error_occured: anyerror,
};

var event_buffer: [10]Event = undefined;
var queue: Queue = .init(&event_buffer);
var procuders: std.Io.Group = .init;

pub fn start(io: std.Io) !void {
    try procuders.concurrent(io, size.watch, .{io});
    try procuders.concurrent(io, input.watch, .{io});
}

pub fn stop(io: std.Io) void {
    queue.close(io);
    procuders.cancel(io);
}

pub fn put(io: std.Io, event: Event) !void {
    try queue.putOne(io, event);
}

pub fn get(io: std.Io) !Event {
    return try queue.getOne(io);
}

pub fn close(io: std.Io) void {
    queue.close(io);
}
