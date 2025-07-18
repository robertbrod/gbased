const std = @import("std");
const PCQueue = @import("common").PCQueue;
const PCQueueErrors = @import("common").PCQueueErrors;

pub fn Timer() type {
    return struct {
        const Self = @This();
        const Subscription = PCQueue(bool);

        // Timer frequency
        // const TimerFrequency = 0x400000;
        const TimerFrequency = 0x10;
        const TimerInterval: f64 = @as(f64, @floatFromInt(std.time.ns_per_s)) / TimerFrequency;
        const TimerEdgeInterval: f64 = TimerInterval / 2;

        // Allocation
        alloc: std.mem.Allocator,

        // Threading
        thread: ?*std.Thread,
        mutex: std.Thread.Mutex,
        stop_flag: bool,
        stop_signal: std.Thread.Condition,

        // Subscriptions
        subscriptions: std.ArrayList(*Subscription),

        pub fn init(alloc: std.mem.Allocator) Self {
            std.debug.print("Tick Interval {d}ns\n", .{TimerInterval});

            return .{
                .alloc = alloc,

                .thread = null,
                .mutex = std.Thread.Mutex{},
                .stop_flag = false,
                .stop_signal = std.Thread.Condition{},

                .subscriptions = std.ArrayList(*Subscription).init(alloc),
            };
        }

        pub fn deinit(self: *Self) void {
            // Make sure we are stopped
            self.stop();

            for (self.subscriptions.items) |subscription| {
                subscription.deinit();
            }

            self.subscriptions.deinit();
        }

        pub fn subscribe(self: *Self) !Subscription.Consumer {
            try self.subscriptions.append(try Subscription.init(self.alloc, 100));

            return self.subscriptions.getLast().consumer;
        }

        pub fn start(self: *Self) !void {
            self.mutex.lock();
            defer self.mutex.unlock();
            self.thread = try self.alloc.create(std.Thread);

            if (self.thread) |thread| {
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

                                for (self.subscriptions.items) |subscription| {
                                    subscription.producer.send(true) catch |queue_err| {
                                        if (queue_err == PCQueueErrors.QueueFull) {
                                            std.debug.print("Tick: Queue Full\n", .{});
                                            // Ignore queue full errors with sending ticks
                                        } else {
                                            return queue_err;
                                        }
                                    };
                                }
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
