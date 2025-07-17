const std = @import("std");
const sm83 = @import("sm83");
const gameboy = @import("gameboy");
const memory = @import("memory");

pub fn main() !void {
    var debug = std.heap.DebugAllocator(.{}).init;
    const allocator = debug.allocator();
    defer std.debug.assert(debug.deinit() == std.heap.Check.ok);

    var gb = try gameboy.GameBoy().init(allocator);
    defer gb.deinit();

    // Prints to stderr, ignoring potential errors.
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});
}
