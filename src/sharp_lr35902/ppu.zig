const std = @import("std");
const memory = @import("memory");

const options = @import("options.zig");

pub fn PPU() type {
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
            const new_ppu: Self = .{
                .alloc = opts.alloc,

                .mmu = opts.mmu,
            };

            return new_ppu;
        }

        pub fn deinit(_: *Self) void {
            // Cleanup logic
        }

        // TODO: implement actual logic
        pub fn tick(self: *Self) void {
            self.processDot();

            self.dot += 1;

            // 456 dots per line
            if (self.dot == 456) {
                self.dot = 0;
                self.scan_line = (self.scan_line + 1) % 154;
            }
        }

        pub fn processDot(self: *Self) void {
            // TODO: implement PPU logic

            if (self.dot == 0 and self.scan_line == 0) {
                std.debug.print("PPU: New frame - {d}\n", .{std.time.milliTimestamp()});
            }
        }
    };
}
