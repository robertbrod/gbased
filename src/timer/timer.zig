const std = @import("std");
const PCQueue = @import("common").PCQueue;
const PCQueueErrors = @import("common").PCQueueErrors;

pub fn Timer() type {
    return struct {
        const Self = @This();
        const Subscription = PCQueue(u32);

        // Timer frequency
        const TimerFrequency = 0x400000;
        // const TimerFrequency = 0x4;
        const TimerInterval: f64 = @as(f64, @floatFromInt(std.time.ns_per_s)) / TimerFrequency;

        // Allocation
        alloc: std.mem.Allocator,

        // Threading
        thread: ?*std.Thread = null,
        stop_flag: std.atomic.Value(bool) = std.atomic.Value(bool).init(false),
        mutex: std.Thread.Mutex = .{},

        // Subscriptions
        clock_subscriptions: std.ArrayList(*Subscription),

        pub fn init(alloc: std.mem.Allocator) !*Self {
            const new_timer = try alloc.create(Self);
            new_timer.* = .{
                .alloc = alloc,

                .clock_subscriptions = std.ArrayList(*Subscription).init(alloc),
            };

            return new_timer;
        }

        pub fn deinit(self: *Self) void {
            // Make sure we are stopped
            self.stop();

            for (self.clock_subscriptions.items) |subscription| {
                subscription.deinit();
            }
            self.clock_subscriptions.deinit();

            self.alloc.destroy(self);
        }

        pub fn subscribe(self: *Self) !Subscription.Consumer {
            self.mutex.lock();
            defer self.mutex.unlock();

            try self.clock_subscriptions.append(try Subscription.init(self.alloc, 100));

            return self.clock_subscriptions.getLast().consumer;
        }

        pub fn unsubscribe(self: *Self, sub: Subscription.Consumer) void {
            self.mutex.lock();
            defer self.mutex.unlock();

            for (0..self.clock_subscriptions.items.len) |i| {
                if (self.clock_subscriptions.items[i] == sub.queue) {
                    self.clock_subscriptions.items[i].deinit();
                    _ = self.clock_subscriptions.orderedRemove(i);

                    return;
                }
            }
        }

        // TODO: probably move thread code into common
        pub fn start(self: *Self) !void {
            self.thread = try self.alloc.create(std.Thread);

            if (self.thread) |thread| {
                thread.* = try std.Thread.spawn(.{}, Self.tick, .{self});
            }
        }

        pub fn stop(self: *Self) void {
            // Signal the thread to stop
            self.stop_flag.store(true, .monotonic);

            if (self.thread) |thread| {
                thread.join();
                self.alloc.destroy(thread);
                self.thread = null;
            }
        }

        pub fn tick(self: *Self) !void {
            // TODO: do we need rising edge and falling edge?

            const startTime = std.time.nanoTimestamp();
            var currentTime: f64 = 0;
            var nextTick: f64 = 0;
            var ticks: u32 = 0;

            while (!self.stop_flag.load(.monotonic)) {
                ticks = 0;
                currentTime = @as(f64, @floatFromInt(std.time.nanoTimestamp() - startTime));

                // Calculate the number of ticks that have passed since last loop
                while (currentTime >= nextTick) {
                    nextTick += TimerInterval;
                    ticks += 1;
                }

                if (ticks > 0) {
                    // Notify subscribers
                    self.mutex.lock();
                    defer self.mutex.unlock();

                    for (self.clock_subscriptions.items) |subscription| {
                        subscription.producer.send(ticks) catch |queue_err| {
                            if (queue_err == PCQueueErrors.QueueFull) {
                                // We don't really care if the queue is full
                            } else {
                                return queue_err;
                            }
                        };
                    }
                }

                // Yield thread to OS instead of sleeping to get a faster cycle
                std.Thread.yield() catch |err| {
                    if (err == std.Thread.YieldError.SystemCannotYield) {
                        std.Thread.sleep(0);
                    } else {
                        return err;
                    }
                };
            }
        }
    };
}
