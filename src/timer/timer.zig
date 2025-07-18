const std = @import("std");
const PCQueue = @import("common").PCQueue;
const ThreadParams = @import("common").ThreadParams;
const PCQueueErrors = @import("common").PCQueueErrors;

pub fn Timer() type {
    return struct {
        const Self = @This();
        const Subscription = PCQueue(bool);

        // Timer frequency
        // const TimerFrequency = 0x400000;
        const TimerFrequency = 0x4;
        const TimerInterval: f64 = @as(f64, @floatFromInt(std.time.ns_per_s)) / TimerFrequency;
        const TimerEdgeInterval: f64 = TimerInterval / 2;

        // Allocation
        alloc: std.mem.Allocator,

        // Threading
        thread: ?*std.Thread,
        thread_params: ThreadParams,

        // Subscriptions
        subscriptions: std.ArrayList(*Subscription),

        pub fn init(alloc: std.mem.Allocator) !*Self {
            std.debug.print("Tick Interval {d}ns\n", .{TimerInterval});

            const new_timer = try alloc.create(Self);
            new_timer.* = .{
                .alloc = alloc,

                .thread = null,
                .thread_params = .{},

                .subscriptions = std.ArrayList(*Subscription).init(alloc),
            };

            return new_timer;
        }

        pub fn deinit(self: *Self) void {
            // Make sure we are stopped
            self.stop();

            for (self.subscriptions.items) |subscription| {
                subscription.deinit();
            }

            self.subscriptions.deinit();

            self.alloc.destroy(self);
        }

        pub fn subscribe(self: *Self) !Subscription.Consumer {
            try self.subscriptions.append(try Subscription.init(self.alloc, 100));

            return self.subscriptions.getLast().consumer;
        }

        pub fn unsubscribe(self: *Self, sub: Subscription.Consumer) void {
            for (0..self.subscriptions.items.len) |i| {
                if (self.subscriptions.items[i] == sub.queue) {
                    self.subscriptions.items[i].deinit();
                    _ = self.subscriptions.orderedRemove(i);

                    return;
                }
            }
        }

        // TODO: probably move thread code into common
        pub fn start(self: *Self) !void {
            self.thread_params.mutex.lock();
            defer self.thread_params.mutex.unlock();
            self.thread = try self.alloc.create(std.Thread);

            if (self.thread) |thread| {
                thread.* = try std.Thread.spawn(.{}, Self.tick, .{self});
            }
        }

        pub fn stop(self: *Self) void {
            // Signal the thread to stop
            self.thread_params.mutex.lock();
            self.thread_params.stop_signal.signal();
            self.thread_params.stop_flag = true;
            self.thread_params.mutex.unlock();

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
            while (!self.thread_params.stop_flag) {
                self.thread_params.mutex.lock();
                defer self.thread_params.mutex.unlock();

                // Calculate delay for next tick
                const executionTime = @as(f64, @floatFromInt(std.time.nanoTimestamp() - threadStart));
                const delay = @as(u64, @intFromFloat(@max(nextTick - executionTime, 0)));

                self.thread_params.stop_signal.timedWait(&self.thread_params.mutex, delay) catch |err| {
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
                                        // Why is the queue full?
                                        std.debug.assert(false);
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
    };
}
