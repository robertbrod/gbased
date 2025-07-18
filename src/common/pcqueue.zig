const std = @import("std");

pub const PCQueueErrors = error{
    QueueFull,
};

pub fn PCQueue(comptime T: type) type {
    return struct {
        pub const Producer = struct {
            const Self = @This();

            queue: *Queue,

            fn init(queue: *Queue) Self {
                return .{
                    .queue = queue,
                };
            }

            fn deinit(self: *Self) void {
                self.queue = null;
            }

            pub fn send(self: *const Self, item: T) PCQueueErrors!void {
                try self.queue.send(item);
            }
        };

        pub const Consumer = struct {
            const Self = @This();

            queue: *Queue,

            fn init(queue: *Queue) Self {
                return .{
                    .queue = queue,
                };
            }

            fn deinit(self: *Self) void {
                self.queue = null;
            }

            pub fn receive(self: *const Self) T {
                return self.queue.receive();
            }
        };

        const Queue = @This();

        // Data allocation
        alloc: std.mem.Allocator,

        // Thread safety between producer and consumer
        mutex: std.Thread.Mutex,
        condition: std.Thread.Condition,

        // Data
        data: []T,
        capacity: u16,
        size: u16 = 0,
        producerIndex: u16 = 0,
        consumerIndex: u16 = 0,

        // Producer/Consumer
        producer: Producer,
        consumer: Consumer,

        pub fn init(alloc: std.mem.Allocator, queue_length: u16) !*Queue {
            const new_queue = try alloc.create(Queue);

            new_queue.* = Queue{
                .alloc = alloc,

                .mutex = std.Thread.Mutex{},
                .condition = std.Thread.Condition{},

                .data = try alloc.alloc(T, queue_length),
                .capacity = queue_length,

                .producer = Producer.init(new_queue),
                .consumer = Consumer.init(new_queue),
            };

            return new_queue;
        }

        pub fn deinit(self: *Queue) void {
            self.alloc.free(self.data);
            self.alloc.destroy(self);
        }

        fn send(self: *Queue, item: T) PCQueueErrors!void {
            self.mutex.lock();
            defer self.mutex.unlock();

            if (self.size == self.capacity) {
                return PCQueueErrors.QueueFull;
            }

            self.data[self.producerIndex] = item;
            self.producerIndex = (self.producerIndex + 1) % self.capacity;
            self.size += 1;

            self.condition.signal();
        }

        fn receive(self: *Queue) T {
            self.mutex.lock();
            defer self.mutex.unlock();

            // Block until we have a message to receive
            while (self.size == 0) {
                self.condition.wait(&self.mutex);
            }

            const item = self.data[self.consumerIndex];
            self.consumerIndex = (self.consumerIndex + 1) % self.capacity;
            self.size -= 1;

            return item;
        }
    };
}
