const std = @import("std");

pub fn Clock() type {
    return struct {
        const Self = @This();

        // Clock Timing
        const ClockFrequency = 0x400000;
        // const TimerFrequency = 0x4;
        const ClockInterval: f64 = @as(f64, @floatFromInt(std.time.ns_per_s)) / ClockFrequency;
        startTime: i128 = 0,
        currentTime: f64 = 0,
        nextTick: f64 = 0,

        // Allocation
        alloc: std.mem.Allocator,

        pub fn init(alloc: std.mem.Allocator) !*Self {
            const new_timer = try alloc.create(Self);

            new_timer.* = .{
                .alloc = alloc,
            };

            return new_timer;
        }

        pub fn deinit(self: *Self) void {
            self.alloc.destroy(self);
        }

        pub fn getElapsedTicks(self: *Self) u32 {
            // If first time, set initial timestamp
            if (self.startTime == 0) {
                self.startTime = std.time.nanoTimestamp();
            }

            self.currentTime = @as(f64, @floatFromInt(std.time.nanoTimestamp() - self.startTime));
            var ticks: u32 = 0;

            // Calculate the number of ticks that have passed since last loop
            while (self.currentTime >= self.nextTick) {
                self.nextTick += ClockInterval;
                ticks += 1;
            }

            return ticks;
        }
    };
}
