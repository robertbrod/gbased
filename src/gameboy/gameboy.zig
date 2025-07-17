const std = @import("std");
const SoC = @import("soc.zig").SoC;

pub fn GameBoy() type {
    return struct {
        const Self = @This();

        soc: SoC(),

        pub fn init(alloc: std.mem.Allocator) !Self {
            const soc = try SoC().init(alloc);

            return .{
                .soc = soc,
            };
        }

        pub fn deinit(self: *Self) void {
            self.soc.deinit();
        }
    };
}
