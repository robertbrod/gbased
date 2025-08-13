const std = @import("std");
const memory = @import("memory");
const SoC = @import("sharp_lr35902").SoC;
const Clock = @import("clock.zig").Clock;
const Timer = @import("timer").Timer;
const CartridgeInterface = @import("cartridge_interface.zig").CartridgeInterface();

pub fn GameBoy() type {
    return struct {
        const Self = @This();

        alloc: std.mem.Allocator,

        // Threading
        thread: ?*std.Thread = null,
        stop_flag: std.atomic.Value(bool) = std.atomic.Value(bool).init(false),

        clock: *Clock(),
        timer: *Timer(),
        mmu: *memory.MemoryManagementUnit(),
        soc: *SoC(), // Contains CPU + PPU + APU + HRAM
        // TODO: other top level components

        pub fn init(alloc: std.mem.Allocator) !*Self {
            const new_gameboy = try alloc.create(Self);

            const clock = try Clock().init(alloc);
            const timer = try Timer().init(alloc);
            const mmu = try memory.MemoryManagementUnit().init(alloc);
            const soc = try SoC().init(.{
                .alloc = alloc,
                .mmu = mmu,
            });

            // Map various parts of the system to the MMU
            mmu.mapHighRAM(&soc.high_ram);

            new_gameboy.* = .{
                .alloc = alloc,

                .clock = clock,
                .timer = timer,
                .mmu = mmu,
                .soc = soc,
            };

            return new_gameboy;
        }

        pub fn deinit(self: *Self) void {
            self.stop();

            self.clock.deinit();
            self.timer.deinit();
            self.mmu.deinit();
            self.soc.deinit();

            self.alloc.destroy(self);
        }

        // Region: Emulation API
        pub fn start(self: *Self) !void {
            self.thread = try self.alloc.create(std.Thread);

            if (self.thread) |thread| {
                thread.* = try std.Thread.spawn(.{}, Self.emulate, .{self});
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
        // EndRegion: Emulation API

        fn emulate(self: *Self) !void {
            var ticks: u32 = 0;
            while (!self.stop_flag.load(.monotonic)) {
                ticks = self.clock.getElapsedTicks();

                for (0..ticks) |_| {
                    try self.tick();
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

        pub fn tick(self: *Self) !void {
            // TODO: fill in tick notifications
            try self.soc.tick();
        }
    };
}
