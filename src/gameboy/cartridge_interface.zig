const std = @import("std");

// Example cartridge header:
// 00000100: 00c3 5001 ceed 6666 cc0d 000b 0373 0083  ..P...ff.....s..
// 00000110: 000c 000d 0008 111f 8889 000e dccc 6ee6  ..............n.
// 00000120: dddd d999 bbbb 6763 6e0e eccc dddc 999f  ......gcn.......
// 00000130: bbb9 333e 4a41 4d45 5320 2042 4f4e 4420  ..3>JAMES  BOND
// 00000140: 2030 3037 3031 0303 0402 0133 009c fd22   00701.....3..."
const CartridgeHeader = struct {
    const Self = @This();

    // 0100-0103 - Entry point
    entry_point: ?[0x4]u8 = null,

    // 0104-0133 - Nintendo logo
    // This area contains a bitmap image that is displayed when the Game Boy is powered on
    // It must match the following dump, otherwise the boot ROM won’t allow the game to run
    // CE ED 66 66 CC 0D 00 0B 03 73 00 83 00 0C 00 0D
    // 00 08 11 1F 88 89 00 0E DC CC 6E E6 DD DD D9 99
    // BB BB 67 63 6E 0E EC CC DD DC 99 9F BB B9 33 3E
    nintendo_logo: ?[0x30]u8 = null,

    // 0134-0143 - Title
    // These bytes contain the title of the game in upper case ASCII.
    // If the title is less than 16 characters long, the remaining bytes should be padded with $00s.
    cartridge_title: ?[0x10]u8 = null,

    // 013F-0142 - Manufacturer code
    // In older cartridges these bytes were part of the Title.
    // In newer cartridges they contain a 4-character manufacturer code (in uppercase ASCII).
    // The purpose of the manufacturer code is unknown.
    manufacturer_code: ?[0x4]u8 = null,

    // 0143 - CGB flag
    // In older cartridges this byte was part of the Title.
    // The CGB and later models interpret this byte to decide whether to enable Color mode or to fall back to monochrome compatibility mode.
    // Typical values:
    //     0x80: The game supports CGB enhancements, but is backwards compatible with monochrome Game Boys
    //     0xC0: The game works on CGB only
    // Setting bit 7 will trigger a write of this register value to KEY0 register which sets the CPU mode.
    cgb_flag: ?[0x1]u8 = null,

    // 0144-0145 - New licensee code
    // This area contains a two-character ASCII “licensee code” indicating the game’s publisher
    // It is only meaningful if the Old licensee is exactly 0x33 otherwise, the old code must be considered.
    new_licensee_code: ?[0x2]u8 = null,

    // 0146 - SGB flag
    // This byte specifies whether the game supports SGB functions.
    sgb_flag: ?[0x1]u8 = null,

    // 0147 - Cartridge type
    // This byte indicates what kind of hardware is present on the cartridge — most notably its mapper.
    cartridge_type: ?[0x1]u8 = null,

    // 0148 - ROM size
    // This byte indicates how much ROM is present on the cartridge.
    // $00  32 KiB  2 (no banking)
    // $01  64 KiB  4
    // $02  128 KiB 8
    // $03  256 KiB 16
    // $04  512 KiB 32
    // $05  1 MiB   64
    // $06  2 MiB   128
    // $07  4 MiB   256
    // $08  8 MiB   512
    // $52  1.1 MiB 72
    // $53  1.2 MiB 80
    // $54  1.5 MiB 96
    rom_size: ?[0x1]u8 = null,

    // 0149 - RAM size
    // This byte indicates how much RAM is present on the cartridge, if any.
    // If the cartridge type does not include “RAM” in its name, this should be set to 0.
    // $00  0       No RAM
    // $01  –       Unused 12
    // $02  8 KiB   1 bank
    // $03  32 KiB  4 banks of 8 KiB each
    // $04  128 KiB 16 banks of 8 KiB each
    // $05  64 KiB 8 banks of 8 KiB each
    ram_size: ?[0x1]u8 = null,

    // 014A - Destination code
    // This byte specifies whether this version of the game is intended to be sold in Japan or elsewhere.
    // $00  Japan (and possibly overseas)
    // $01  Overseas only
    destination_code: ?[0x1]u8 = null,

    // 014B — Old licensee code
    // This byte is used in older (pre-SGB) cartridges to specify the game’s publisher.
    // However, the value $33 indicates that the New licensee codes must be considered instead.
    old_licensee_code: ?[0x1]u8 = null,

    // 014C - Mask ROM version number
    // The byte specifies the version number of the game. It is usually $00
    version_number: ?[0x1]u8 = null,

    // 014D - Header checksum
    // This byte contains an 8-bit checksum computed from the cartridge header bytes $0134–014C
    header_checksum: ?[0x1]u8 = null,

    // 014E - O14F - Global checksum
    global_checksum: ?[0x2]u8 = null,
};

const Cartridge = struct {
    const Self = @This();

    header: CartridgeHeader,
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

        pub fn readCartridge(catridge_buffer: []u8) void {
            _ = catridge_buffer;
        }
    };
}
