const std = @import("std");

pub fn Timer() type {
    return struct {
        const Self = @This();
        // const TimerFrequency = 0x400000;
        const TimerFrequency = 0x1;
        const TimerInterval: f64 = @as(f64, @floatFromInt(std.time.ns_per_s)) / TimerFrequency;
        const TimerEdgeInterval: f64 = TimerInterval / 2;

        alloc: std.mem.Allocator,
        thread: ?*std.Thread,
        mutex: std.Thread.Mutex,
        stop_flag: bool,
        stop_signal: std.Thread.Condition,

        pub fn init(alloc: std.mem.Allocator) !Self {
            return .{
                .alloc = alloc,
                .thread = null,
                .mutex = std.Thread.Mutex{},
                .stop_flag = false,
                .stop_signal = std.Thread.Condition{},
            };
        }

        pub fn deinit(self: *Self) void {
            // Make sure we are stopped
            self.stop();
        }

        pub fn start(self: *Self) !void {
            self.mutex.lock();
            defer self.mutex.unlock();
            self.thread = try self.alloc.create(std.Thread);

            if (self.thread) |thread| {
                std.debug.print("{*}\n", .{thread});
                std.debug.print("Main: {*}\n", .{self});
                thread.* = try std.Thread.spawn(.{}, tick, .{self});
            }
        }

        pub fn stop(self: *Self) void {
            // Signal the thread to stop
            self.mutex.lock();
            self.stop_signal.signal();
            self.stop_flag = true;
            self.mutex.unlock();

            if (self.thread) |thread| {
                thread.join();
                self.alloc.destroy(thread);
                self.thread = null;
            }
        }

        pub fn tick(self: *Self) !void {
            std.debug.print("Thread: {*}\n", .{self});
            const threadStart = std.time.nanoTimestamp();
            var nextTick: f64 = 0;
            var riseEdge = true;
            while (true) {
                self.mutex.lock();
                defer self.mutex.unlock();

                // Calculate delay for next tick
                const executionTime = @as(f64, @floatFromInt(std.time.nanoTimestamp() - threadStart));
                const delay = @as(u64, @intFromFloat(@max(nextTick - executionTime, 0)));

                if (self.stop_flag) {
                    // Stop flag has been signaled => exit function
                    return;
                } else {
                    self.stop_signal.timedWait(&self.mutex, delay) catch |err| {
                        // Wait timed out => the thread is not stopped
                        if (err == error.Timeout) {
                            // Bump next tick time
                            nextTick += TimerEdgeInterval;

                            // Execute tick notifications here
                            if (riseEdge) {
                                std.debug.print("Tick: Rise Edge\n", .{});
                            } else {
                                std.debug.print("Tick: Fall Edge\n", .{});
                            }
                            riseEdge = !riseEdge;

                            continue;
                        }

                        return err;
                    };
                }
            }
        }
    };
}
