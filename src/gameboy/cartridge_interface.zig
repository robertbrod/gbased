const std = @import("std");

const CatridgeData = struct {

    // 0100-0103 - Entry point
    entry_point: [0x4]u8,

    // 0104-0133 - Nintendo logo
    // This area contains a bitmap image that is displayed when the Game Boy is powered on
    // It must match the following dump, otherwise the boot ROM won’t allow the game to run
    // CE ED 66 66 CC 0D 00 0B 03 73 00 83 00 0C 00 0D
    // 00 08 11 1F 88 89 00 0E DC CC 6E E6 DD DD D9 99
    // BB BB 67 63 6E 0E EC CC DD DC 99 9F BB B9 33 3E
    nintendo_logo: [0x30]u8,

    // 0134-0143 - Title
    // These bytes contain the title of the game in upper case ASCII.
    // If the title is less than 16 characters long, the remaining bytes should be padded with $00s.
    cartridge_title: [0x10]u8,

    // 013F-0142 - Manufacturer code
    // In older cartridges these bytes were part of the Title.
    // In newer cartridges they contain a 4-character manufacturer code (in uppercase ASCII).
    // The purpose of the manufacturer code is unknown.
    manufacturer_code: [0x4]u8,

    // 0143 - CGB flag
    // In older cartridges this byte was part of the Title.
    // The CGB and later models interpret this byte to decide whether to enable Color mode or to fall back to monochrome compatibility mode.
    // Typical values:
    //     0x80: The game supports CGB enhancements, but is backwards compatible with monochrome Game Boys
    //     0xC0: The game works on CGB only
    // Setting bit 7 will trigger a write of this register value to KEY0 register which sets the CPU mode.
    cgb_flag: [0x1]u8,

    // 0144-0145 - New licensee code
    // This area contains a two-character ASCII “licensee code” indicating the game’s publisher
    // It is only meaningful if the Old licensee is exactly 0x33 otherwise, the old code must be considered.
    new_licensee_code: [0x2]u8,

    // 0146 - SGB flag
    // This byte specifies whether the game supports SGB functions.
    sgb_flag: [0x1]u8,

    // 0147 - Cartridge type
    // This byte indicates what kind of hardware is present on the cartridge — most notably its mapper.
    cartridge_type: [0x1]u8,
};

pub fn CartridgeInterface() type {
    return struct {
        const Self = @This();

        alloc: std.mem.Allocator,

        pub fn init(alloc: std.mem.Allocator) !*Self {
            const cartridge_interface = try alloc.create(Self);

            cartridge_interface.* = .{
                .alloc = alloc,
            };

            return cartridge_interface;
        }

        pub fn deinit(self: *Self) void {
            self.alloc.destroy(self);
        }

        // Example cartridge header:
        // 00000100: 00c3 5001 ceed 6666 cc0d 000b 0373 0083  ..P...ff.....s..
        // 00000110: 000c 000d 0008 111f 8889 000e dccc 6ee6  ..............n.
        // 00000120: dddd d999 bbbb 6763 6e0e eccc dddc 999f  ......gcn.......
        // 00000130: bbb9 333e 4a41 4d45 5320 2042 4f4e 4420  ..3>JAMES  BOND
        // 00000140: 2030 3037 3031 0303 0402 0133 009c fd22   00701.....3..."
        pub fn read_cartridge(catridge_buffer: []u8) void {
            _ = catridge_buffer;
        }
    };
}
