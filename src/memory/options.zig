const std = @import("std");
const CartridgeInterface = @import("gameboy").CartridgeInterface();

pub const MMUptions = struct { alloc: std.mem.Allocator, cartridge_interface: *CartridgeInterface };
