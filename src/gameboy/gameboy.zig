const std = @import("std");
const SoC = @import("soc.zig").SoC;
const Timer = @import("timer").Timer;

pub fn GameBoy() type {
    return struct {
        const Self = @This();

        soc: SoC(),
        timer: Timer(),

        pub fn init(alloc: std.mem.Allocator) !Self {
            const soc = try SoC().init(alloc);
            const timer = try Timer().init(alloc);

            return .{
                .soc = soc,
                .timer = timer,
            };
        }

        pub fn deinit(self: *Self) void {
            self.soc.deinit();
            self.timer.deinit();
        }

        pub fn start(self: *Self) !void {
            try self.timer.start();
        }

        pub fn stop(self: *Self) void {
            self.timer.stop();
        }
    };
}
