const std = @import("std");
const memory = @import("memory");
const sm83 = @import("sm83");
const Timer = @import("timer").Timer;

pub fn SoC() type {
    return struct {
        const Self = @This();

        alloc: std.mem.Allocator,

        // External pointers
        timer: *Timer(),
        mmu: *memory.MemoryManagementUnit(),

        // Internal objects
        cpu: sm83.SM83CPU(),
        // TODO: PPU
        // TODO: APU

        pub fn init(alloc: std.mem.Allocator, timer: *Timer()) !*Self {
            const mmu = try memory.MemoryManagementUnit().init(alloc);
            const cpu = try sm83.SM83CPU().init(.{
                .alloc = alloc,
                .mmu = mmu,
                .timer = timer,
            });

            const new_soc = try alloc.create(Self);

            new_soc.* = .{
                .alloc = alloc,

                .timer = timer,
                .mmu = mmu,

                .cpu = cpu,
            };

            return new_soc;
        }

        pub fn deinit(self: *Self) void {
            self.mmu.deinit();
            self.cpu.deinit();

            self.alloc.destroy(self);
        }

        pub fn start(self: *Self) !void {
            try self.cpu.start();
        }

        pub fn stop(self: *Self) void {
            self.cpu.stop();
        }
    };
}
