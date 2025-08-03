const std = @import("std");
const Cartridge = @import("cartridge/cartridge.zig").Cartridge();

const CartridgeInterfaceErrors = error{
    NoCartridgePresent,
};

pub fn CartridgeInterface() type {
    return struct {
        const Self = @This();

        alloc: std.mem.Allocator,
        cartridge: ?*Cartridge = null,

        pub fn init(alloc: std.mem.Allocator) !*Self {
            const cartridge_interface = try alloc.create(Self);

            cartridge_interface.* = .{
                .alloc = alloc,
            };

            return cartridge_interface;
        }

        pub fn deinit(self: *Self) void {
            if (self.cartridge) |cartridge| {
                cartridge.deinit();
            }

            self.alloc.destroy(self);
        }

        pub fn readCartridge(self: *Self, cartridge_buffer: []u8) !void {
            if (self.cartridge) |cartridge| {
                cartridge.deinit();
            }

            self.cartridge = try Cartridge.init(self.alloc, cartridge_buffer);
        }

        pub fn readByte(self: *Self, address: u16) u8 {
            if (self.cartridge) |cartridge| {
                return cartridge.readByte(address);
            }
            return 0xFF;
        }

        pub fn getMemoryPointer(self: *Self, address: u16) *u8 {
            return self.cartridge.getMemoryPointer(address) orelse CartridgeInterfaceErrors.NoCartridgePresent;
        }

        pub fn writeByte(self: *Self, address: u16, val: u8) void {
            if (self.cartridge) |cartridge| {
                if (address <= 0x7FFF) {
                    cartridge.rom[address] = val;
                } else {
                    cartridge.rom[address] = val;
                }
            }

            // No-op
        }
    };
}

test "Read Cartridge" {
    const gpa = std.testing.allocator;
    const cartridge_interface = try CartridgeInterface().init(gpa);
    defer cartridge_interface.deinit();

    const cartridge_buffer = try gpa.alloc(u8, 0x800000); // 8MB
    defer gpa.free(cartridge_buffer);

    _ = try std.fs.cwd().readFile("James Bond 007.gb", cartridge_buffer);

    try cartridge_interface.readCartridge(cartridge_buffer);

    try std.testing.expectEqual("Nintendo Research & Development", cartridge_interface.*.cartridge.?.getPublisher());
}
