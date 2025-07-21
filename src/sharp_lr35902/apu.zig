const std = @import("std");
const memory = @import("memory");

const options = @import("options.zig");

pub fn APU() type {
    return struct {
        const Self = @This();

        // Allocation
        alloc: std.mem.Allocator,

        // External pointers
        mmu: *memory.MemoryManagementUnit(),

        // PPU State
        scan_line: u8 = 0,
        dot: u16 = 0,

        pub fn init(opts: options.SoCOptions) !Self {
            return .{
                .alloc = opts.alloc,

                .mmu = opts.mmu,
            };
        }

        pub fn deinit(_: *Self) void {
            // Cleanup logic
        }

        // TODO: implement actual logic
        pub fn tick(_: *Self) void {}
    };
}
