const std = @import("std");
const memory = @import("memory");
const sm83 = @import("sm83");

pub fn SoC() type {
    return struct {
        const Self = @This();

        mmu: *memory.MemoryManagementUnit(),
        cpu: sm83.SM83CPU(),
        // TODO: PPU
        // TODO: APU

        pub fn init(alloc: std.mem.Allocator) !Self {
            const mmu = try memory.MemoryManagementUnit().init(alloc);
            const cpu = try sm83.SM83CPU().init(.{
                .alloc = alloc,
                .mmu = mmu,
            });

            return .{
                .mmu = mmu,
                .cpu = cpu,
            };
        }

        pub fn deinit(self: *Self) void {
            self.mmu.deinit();
            self.cpu.deinit();
        }
    };
}
