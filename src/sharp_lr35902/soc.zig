const std = @import("std");
const memory = @import("memory");

const options = @import("options.zig");
const cpu = @import("cpu.zig");
const ppu = @import("ppu.zig");
const apu = @import("apu.zig");
const boot = @import("boot_rom.zig");

pub fn SoC() type {
    return struct {
        const Self = @This();

        alloc: std.mem.Allocator,

        // Internal objects
        cpu: cpu.SM83CPU(),
        ppu: ppu.PPU(),
        apu: apu.APU(),
        high_ram: [0x7F]u8 = [_]u8{0} ** 0x7F,
        boot_rom: [0x100]u8 = boot.BootRom(),

        // Tick Tracking
        tick_num: u4 = 0,

        pub fn init(opts: options.SoCOptions) !*Self {
            const new_soc = try opts.alloc.create(Self);

            new_soc.alloc = opts.alloc;
            new_soc.cpu = try cpu.SM83CPU().init(opts);
            new_soc.ppu = try ppu.PPU().init(opts);
            new_soc.apu = try apu.APU().init(opts);

            return new_soc;
        }

        pub fn deinit(self: *Self) void {
            self.cpu.deinit();
            self.ppu.deinit();

            self.alloc.destroy(self);
        }

        pub fn tick(self: *Self) !void {
            // PPU processes every tick
            self.ppu.tick();

            // CPU processes every machine cycle (4 clock ticks)
            if (self.tick_num == 0) {
                try self.cpu.machineTick();
            }

            self.tick_num = (self.tick_num + 1) % 4;
        }
    };
}
