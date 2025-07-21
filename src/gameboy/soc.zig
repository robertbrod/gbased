const std = @import("std");
const memory = @import("memory");
const sm83 = @import("sm83");

const Timer = @import("timer").Timer;
const ThreadParams = @import("common").ThreadParams;

pub fn SoC() type {
    return struct {
        const Self = @This();

        alloc: std.mem.Allocator,

        // Threading

        // Threading
        thread: ?*std.Thread = null,
        thread_params: ThreadParams = .{},

        // External pointers
        timer: *Timer(),
        mmu: *memory.MemoryManagementUnit(),

        // Internal objects
        cpu: sm83.SM83CPU(),
        ppu: sm83.PPU(),
        // TODO: APU

        pub fn init(alloc: std.mem.Allocator, timer: *Timer()) !*Self {
            const mmu = try memory.MemoryManagementUnit().init(alloc);
            const cpu = try sm83.SM83CPU().init(.{
                .alloc = alloc,
                .mmu = mmu,
                .timer = timer,
            });
            const ppu = try sm83.PPU().init(.{
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
                .ppu = ppu,
            };

            return new_soc;
        }

        pub fn deinit(self: *Self) void {
            self.mmu.deinit();
            self.cpu.deinit();
            self.ppu.deinit();

            self.alloc.destroy(self);
        }

        // TODO: probably move thread code into common struct
        pub fn start(self: *Self) !void {
            self.thread = try self.alloc.create(std.Thread);

            if (self.thread) |thread| {
                thread.* = try std.Thread.spawn(.{}, run, .{self});
            }
        }

        pub fn stop(self: *Self) void {
            // Signal the thread to stop
            self.thread_params.stop_flag.store(true, .monotonic);

            if (self.thread) |thread| {
                thread.join();
                self.alloc.destroy(thread);
                self.thread = null;
            }
        }

        pub fn run(self: *Self) !void {
            var tickSubscription = try self.timer.subscribe();
            defer self.timer.unsubscribe(tickSubscription);

            while (!self.thread_params.stop_flag.load(.monotonic)) {
                var ticks: std.ArrayList(u32) = try tickSubscription.flush();

                while (ticks.pop()) |tickCount| {
                    for (0..tickCount) |_| {
                        self.ppu.tick();
                        self.cpu.tick();
                    }
                }

                // We responsible for cleaning up tick ArrayList
                ticks.deinit();
            }
        }
    };
}
