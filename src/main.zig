const std = @import("std");
const gameboy = @import("gameboy");

pub fn main() !void {
    const reader = std.io.getStdIn().reader();
    var debug = std.heap.DebugAllocator(.{}).init;
    const allocator = debug.allocator();
    defer std.debug.assert(debug.deinit() == std.heap.Check.ok);

    var gb = try gameboy.GameBoy().init(allocator);
    defer gb.deinit();

    try gb.start();

    _ = try reader.readByte();

    gb.stop();
}
