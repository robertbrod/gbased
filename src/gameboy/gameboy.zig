const std = @import("std");
const SoC = @import("soc.zig").SoC;
const Timer = @import("timer").Timer;

pub fn GameBoy() type {
    return struct {
        const Self = @This();

        soc: *SoC(),
        timer: *Timer(),

        pub fn init(alloc: std.mem.Allocator) !Self {
            const timer = try Timer().init(alloc);
            const soc = try SoC().init(alloc, timer);

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
            try self.soc.start();
        }

        pub fn stop(self: *Self) void {
            self.soc.stop();
            self.timer.stop();
        }
    };
}
