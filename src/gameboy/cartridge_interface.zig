const std = @import("std");

const CartridgeErrors = error{
    InvalidNintendoLogo,
};

const CartridgeType = enum(u8) {
    ROM_ONLY = 0x00,
    MBC1 = 0x01,
    MBC1_RAM = 0x02,
    MBC1_RAM_BATTERY = 0x03,
    MBC2 = 0x05,
    MBC2_BATTERY = 0x06,
    ROM_RAM = 0x08,
    ROM_RAM_BATTERY = 0x09,
    MMM01 = 0x0B,
    MMM01_RAM = 0x0C,
    MMM01_RAM_BATTERY = 0x0D,
    MBC3_TIMER_BATTERY = 0x0F,
    MBC3_TIMER_RAM_BATTERY = 0x10,
    MBC3 = 0x11,
    MBC3_RAM = 0x12,
    MBC3_RAM_BATTERY = 0x13,
    MBC5 = 0x19,
    MBC5_RAM = 0x1A,
    MBC5_RAM_BATTERY = 0x1B,
    MBC5_RUMBLE = 0x1C,
    MBC5_RUMBLE_RAM = 0x1D,
    MBC5_RUMBLE_RAM_BATTERY = 0x1E,
    MBC6 = 0x20,
    MBC7_SENSOR_RUMBLE_RAM_BATTERY = 0x22,
    POCKET_CAMERA = 0xFC,
    BANDAI_TAMA5 = 0xFD,
    HuC3 = 0xFE,
    HuC1_RAM_BATTERY = 0xFF,
};

const Destination = enum(u8) { JAPAN_OVERSEAS = 0x00, OVERSEAS = 0x01 };

// TODO
const NewLicensee = enum(u8) {};

// TODO
const OldLicensee = enum(u8) {};

const CartridgeHeader = struct {
    const Self = @This();

    const valid_nintendo_logo = [_]u8{
        0xCE, 0xED, 0x66, 0x66, 0xCC, 0x0D, 0x00, 0x0B, 0x03, 0x73, 0x00, 0x83, 0x00, 0x0C, 0x00, 0x0D,
        0x00, 0x08, 0x11, 0x1F, 0x88, 0x89, 0x00, 0x0E, 0xDC, 0xCC, 0x6E, 0xE6, 0xDD, 0xDD, 0xD9, 0x99,
        0xBB, 0xBB, 0x67, 0x63, 0x6E, 0x0E, 0xEC, 0xCC, 0xDD, 0xDC, 0x99, 0x9F, 0xBB, 0xB9, 0x33, 0x3E,
    };

    // 0100-0103 - Entry point
    entry_point: [0x4]u8 = undefined,

    // 0104-0133 - Nintendo logo
    // This area contains a bitmap image that is displayed when the Game Boy is powered on
    // The boot ROM won’t allow the game to run if the nintendo logo is invalid
    nintendo_logo: [0x30]u8 = undefined,

    // 0134-0143 - Title
    // These bytes contain the title of the game in upper case ASCII.
    // If the title is less than 16 characters long, the remaining bytes should be padded with $00s.
    title: [0x10]u8 = undefined,

    // 013F-0142 - Manufacturer code
    // In older cartridges these bytes were part of the Title.
    // In newer cartridges they contain a 4-character manufacturer code (in uppercase ASCII).
    // The purpose of the manufacturer code is unknown.
    manufacturer_code: [0x4]u8 = undefined,

    // 0143 - CGB flag
    // In older cartridges this byte was part of the Title.
    // The CGB and later models interpret this byte to decide whether to enable Color mode or to fall back to monochrome compatibility mode.
    // Typical values:
    //     0x80: The game supports CGB enhancements, but is backwards compatible with monochrome Game Boys
    //     0xC0: The game works on CGB only
    // Setting bit 7 will trigger a write of this register value to KEY0 register which sets the CPU mode.
    cgb_flag: u8 = undefined,

    // 0144-0145 - New licensee code
    // This area contains a two-character ASCII “licensee code” indicating the game’s publisher
    // It is only meaningful if the Old licensee is exactly 0x33 otherwise, the old code must be considered.
    new_licensee_code: [0x2]u8 = undefined,

    // 0146 - SGB flag
    // This byte specifies whether the game supports SGB functions.
    sgb_flag: u8 = undefined,

    // 0147 - Cartridge type
    // This byte indicates what kind of hardware is present on the cartridge — most notably its mapper.
    cartridge_type: u8 = undefined,

    // 0148 - ROM size
    // This byte indicates how much ROM is present on the cartridge.
    rom_size: u8 = undefined,

    // 0149 - RAM size
    // This byte indicates how much RAM is present on the cartridge, if any.
    // If the cartridge type does not include “RAM” in its name, this should be set to 0.
    ram_size: u8 = undefined,

    // 014A - Destination code
    // This byte specifies whether this version of the game is intended to be sold in Japan or elsewhere.
    // $00  Japan (and possibly overseas)
    // $01  Overseas only
    destination_code: u8 = undefined,

    // 014B — Old licensee code
    // This byte is used in older (pre-SGB) cartridges to specify the game’s publisher.
    // However, the value $33 indicates that the New licensee codes must be considered instead.
    old_licensee_code: u8 = undefined,

    // 014C - Mask ROM version number
    // The byte specifies the version number of the game. It is usually $00
    version_number: u8 = undefined,

    // 014D - Header checksum
    // This byte contains an 8-bit checksum computed from the cartridge header bytes $0134–014C
    checksum: u8 = undefined,

    // 014E - O14F - Global checksum
    global_checksum: [0x2]u8 = undefined,

    pub fn init(cartridge_buffer: []const u8) !Self {
        var header: Self = .{};

        @memcpy(&header.entry_point, cartridge_buffer[0x0100..0x0104]);
        @memcpy(&header.nintendo_logo, cartridge_buffer[0x0104..0x0134]);
        @memcpy(&header.title, cartridge_buffer[0x0134..0x0144]);
        @memcpy(&header.manufacturer_code, cartridge_buffer[0x013F..0x0143]);

        header.cgb_flag = cartridge_buffer[0x0143];

        @memcpy(&header.new_licensee_code, cartridge_buffer[0x0144..0x0146]);

        header.sgb_flag = cartridge_buffer[0x0146];
        header.cartridge_type = cartridge_buffer[0x0147];
        header.rom_size = cartridge_buffer[0x0148];
        header.ram_size = cartridge_buffer[0x0149];
        header.destination_code = cartridge_buffer[0x014A];
        header.old_licensee_code = cartridge_buffer[0x014B];
        header.version_number = cartridge_buffer[0x014C];
        header.checksum = cartridge_buffer[0x014D];

        @memcpy(&header.global_checksum, cartridge_buffer[0x014E..0x0150]);

        try header.validate();

        return header;
    }

    pub fn validate(self: *Self) !void {
        if (!std.mem.eql(u8, &self.nintendo_logo, &valid_nintendo_logo)) return CartridgeErrors.InvalidNintendoLogo;

        // TODO additional validation
    }
};

const Cartridge = struct {
    const Self = @This();

    alloc: std.mem.Allocator,

    header: CartridgeHeader,

    rom: []u8,
    ram: []u8,

    pub fn init(alloc: std.mem.Allocator, cartridge_buffer: []u8) !*Self {
        const cartridge = try alloc.create(Self);
        const header = try CartridgeHeader.init(cartridge_buffer);

        cartridge.* = .{
            .alloc = alloc,
            .header = header,
            .rom = &[_]u8{},
            .ram = &[_]u8{},
        };

        try cartridge.allocateRam(alloc, &header);
        try cartridge.allocateRom(alloc, &header);

        return cartridge;
    }

    pub fn deinit(self: *Self) void {
        self.alloc.free(self.rom);
        self.alloc.free(self.ram);

        self.alloc.destroy(self);
    }

    fn allocateRam(self: *Self, alloc: std.mem.Allocator, header: *const CartridgeHeader) !void {
        switch (header.ram_size) {
            0x00 => self.ram = try alloc.alloc(u8, 0),
            0x01 => self.ram = try alloc.alloc(u8, 0),
            0x02 => self.ram = try alloc.alloc(u8, 0x2000), // 8 KiB
            0x03 => self.ram = try alloc.alloc(u8, 0x8000), // 32 KiB
            0x04 => self.ram = try alloc.alloc(u8, 0x20000), // 128 KiB
            0x05 => self.ram = try alloc.alloc(u8, 0x10000), // 64 KiB
            else => unreachable,
        }
    }

    fn allocateRom(self: *Self, alloc: std.mem.Allocator, header: *const CartridgeHeader) !void {
        switch (header.rom_size) {
            0x00 => self.rom = try alloc.alloc(u8, 0x4000), // 32 KiB
            0x01 => self.rom = try alloc.alloc(u8, 0x10000), // 64 KiB
            0x02 => self.rom = try alloc.alloc(u8, 0x20000), // 128 KiB
            0x03 => self.rom = try alloc.alloc(u8, 0x40000), // 256 KiB
            0x04 => self.rom = try alloc.alloc(u8, 0x80000), // 512 KiB
            0x05 => self.rom = try alloc.alloc(u8, 0x100000), // 1 MiB
            0x06 => self.rom = try alloc.alloc(u8, 0x200000), // 2 MiB
            0x07 => self.rom = try alloc.alloc(u8, 0x400000), // 4 MiB
            0x08 => self.rom = try alloc.alloc(u8, 0x800000), // 8 MiB
            0x52 => self.rom = try alloc.alloc(u8, 0x119999), // 1.1 MiB
            0x53 => self.rom = try alloc.alloc(u8, 0x133333), // 1.2 MiB
            0x54 => self.rom = try alloc.alloc(u8, 0x180000), // 1.5 MiB
            else => unreachable,
        }
    }
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

    // Output the cartridge header in JSON
    const writer = std.io.getStdErr().writer();
    var json_ws = std.json.writeStream(writer, .{ .whitespace = .indent_2 });
    defer json_ws.deinit();
    try json_ws.write(cartridge_interface.*.cartridge.?.header);
}
