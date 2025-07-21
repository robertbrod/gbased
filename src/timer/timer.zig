const std = @import("std");

pub fn Timer() type {
    return struct {
        const Self = @This();

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
    };
}
