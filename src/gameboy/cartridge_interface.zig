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

    fn getPublisher(self: *Self) []const u8 {
        // 0x33 indicates that we should read the publisher from the new licensee code bytes on the cartridge header
        if (self.header.old_licensee_code == 0x33) {
            if (std.mem.eql(u8, &self.header.new_licensee_code, "00")) {
                return "None";
            } else if (std.mem.eql(u8, &self.header.new_licensee_code, "01")) {
                return "Nintendo Research & Development";
            } else if (std.mem.eql(u8, &self.header.new_licensee_code, "08")) {
                return "Capcom";
            } else if (std.mem.eql(u8, &self.header.new_licensee_code, "13")) {
                return "EA (Electronic Arts)";
            } else if (std.mem.eql(u8, &self.header.new_licensee_code, "18")) {
                return "Hudson Soft";
            } else if (std.mem.eql(u8, &self.header.new_licensee_code, "19")) {
                return "B-AI";
            } else if (std.mem.eql(u8, &self.header.new_licensee_code, "20")) {
                return "KSS";
            } else if (std.mem.eql(u8, &self.header.new_licensee_code, "22")) {
                return "Planning Office WADA";
            } else if (std.mem.eql(u8, &self.header.new_licensee_code, "24")) {
                return "PCM Complete";
            } else if (std.mem.eql(u8, &self.header.new_licensee_code, "25")) {
                return "San-X";
            } else if (std.mem.eql(u8, &self.header.new_licensee_code, "28")) {
                return "Kemco";
            } else if (std.mem.eql(u8, &self.header.new_licensee_code, "29")) {
                return "SETA Corporation";
            } else if (std.mem.eql(u8, &self.header.new_licensee_code, "30")) {
                return "Viacom";
            } else if (std.mem.eql(u8, &self.header.new_licensee_code, "31")) {
                return "Nintendo";
            } else if (std.mem.eql(u8, &self.header.new_licensee_code, "32")) {
                return "Bandai";
            } else if (std.mem.eql(u8, &self.header.new_licensee_code, "33")) {
                return "Ocean Software/Acclaim Entertainment";
            } else if (std.mem.eql(u8, &self.header.new_licensee_code, "34")) {
                return "Konami";
            } else if (std.mem.eql(u8, &self.header.new_licensee_code, "35")) {
                return "HectorSoft";
            } else if (std.mem.eql(u8, &self.header.new_licensee_code, "37")) {
                return "Taito";
            } else if (std.mem.eql(u8, &self.header.new_licensee_code, "38")) {
                return "Hudson Soft";
            } else if (std.mem.eql(u8, &self.header.new_licensee_code, "39")) {
                return "Banpresto";
            } else if (std.mem.eql(u8, &self.header.new_licensee_code, "41")) {
                return "Ubi Soft";
            } else if (std.mem.eql(u8, &self.header.new_licensee_code, "42")) {
                return "Atlus";
            } else if (std.mem.eql(u8, &self.header.new_licensee_code, "44")) {
                return "Malibu Interactive";
            } else if (std.mem.eql(u8, &self.header.new_licensee_code, "46")) {
                return "Angel";
            } else if (std.mem.eql(u8, &self.header.new_licensee_code, "47")) {
                return "Bullet-Proof Software";
            } else if (std.mem.eql(u8, &self.header.new_licensee_code, "49")) {
                return "Irem";
            } else if (std.mem.eql(u8, &self.header.new_licensee_code, "50")) {
                return "Absolute";
            } else if (std.mem.eql(u8, &self.header.new_licensee_code, "51")) {
                return "Acclaim Entertainment";
            } else if (std.mem.eql(u8, &self.header.new_licensee_code, "52")) {
                return "Activision";
            } else if (std.mem.eql(u8, &self.header.new_licensee_code, "53")) {
                return "Sammy USA Corporation";
            } else if (std.mem.eql(u8, &self.header.new_licensee_code, "54")) {
                return "Konami";
            } else if (std.mem.eql(u8, &self.header.new_licensee_code, "55")) {
                return "Hi Tech Expressions";
            } else if (std.mem.eql(u8, &self.header.new_licensee_code, "56")) {
                return "LJN";
            } else if (std.mem.eql(u8, &self.header.new_licensee_code, "57")) {
                return "Matchbox";
            } else if (std.mem.eql(u8, &self.header.new_licensee_code, "58")) {
                return "Mattel";
            } else if (std.mem.eql(u8, &self.header.new_licensee_code, "59")) {
                return "Milton Bradley Company";
            } else if (std.mem.eql(u8, &self.header.new_licensee_code, "60")) {
                return "Titus Interactive";
            } else if (std.mem.eql(u8, &self.header.new_licensee_code, "61")) {
                return "Virgin Games Ltd.";
            } else if (std.mem.eql(u8, &self.header.new_licensee_code, "64")) {
                return "Lucasfilm Games";
            } else if (std.mem.eql(u8, &self.header.new_licensee_code, "67")) {
                return "Ocean Software";
            } else if (std.mem.eql(u8, &self.header.new_licensee_code, "69")) {
                return "EA (Electronic Arts)";
            } else if (std.mem.eql(u8, &self.header.new_licensee_code, "70")) {
                return "Infogrames";
            } else if (std.mem.eql(u8, &self.header.new_licensee_code, "71")) {
                return "Interplay Entertainment";
            } else if (std.mem.eql(u8, &self.header.new_licensee_code, "72")) {
                return "Broderbund";
            } else if (std.mem.eql(u8, &self.header.new_licensee_code, "73")) {
                return "Sculptured Software";
            } else if (std.mem.eql(u8, &self.header.new_licensee_code, "75")) {
                return "The Sales Curve Limited";
            } else if (std.mem.eql(u8, &self.header.new_licensee_code, "78")) {
                return "THQ";
            } else if (std.mem.eql(u8, &self.header.new_licensee_code, "79")) {
                return "Accolade";
            } else if (std.mem.eql(u8, &self.header.new_licensee_code, "80")) {
                return "Misawa Entertainment";
            } else if (std.mem.eql(u8, &self.header.new_licensee_code, "83")) {
                return "lozc";
            } else if (std.mem.eql(u8, &self.header.new_licensee_code, "86")) {
                return "Tokuma Shoten";
            } else if (std.mem.eql(u8, &self.header.new_licensee_code, "87")) {
                return "Tsukuda Original";
            } else if (std.mem.eql(u8, &self.header.new_licensee_code, "91")) {
                return "Chunsoft Co.";
            } else if (std.mem.eql(u8, &self.header.new_licensee_code, "92")) {
                return "Video System";
            } else if (std.mem.eql(u8, &self.header.new_licensee_code, "93")) {
                return "Ocean Software/Acclaim Entertainment";
            } else if (std.mem.eql(u8, &self.header.new_licensee_code, "95")) {
                return "Varie";
            } else if (std.mem.eql(u8, &self.header.new_licensee_code, "96")) {
                return "Yonezawa/s’pal";
            } else if (std.mem.eql(u8, &self.header.new_licensee_code, "97")) {
                return "Kaneko";
            } else if (std.mem.eql(u8, &self.header.new_licensee_code, "99")) {
                return "Pack-In-Video";
            } else if (std.mem.eql(u8, &self.header.new_licensee_code, "A4")) {
                return "Konami (Yu-Gi-Oh!)";
            } else {
                return "Unknown Publisher";
            }
        } else {
            switch (self.header.old_licensee_code) {
                0x00 => return "None",
                0x01 => return "Nintendo",
                0x08 => return "Capcom",
                0x09 => return "HOT-B",
                0x0A => return "Jaleco",
                0x0B => return "Coconuts Japan",
                0x0C => return "Elite Systems",
                0x13 => return "EA (Electronic Arts)",
                0x18 => return "Hudson Soft",
                0x19 => return "ITC Entertainment",
                0x1A => return "Yanoman",
                0x1D => return "Japan Clary",
                0x1F => return "Virgin Games Ltd.",
                0x24 => return "PCM Complete",
                0x25 => return "San-X",
                0x28 => return "Kemco",
                0x29 => return "SETA Corporation",
                0x30 => return "Infogrames",
                0x31 => return "Nintendo",
                0x32 => return "Bandai",
                0x34 => return "Konami",
                0x35 => return "HectorSoft",
                0x38 => return "Capcom",
                0x39 => return "Banpresto",
                0x3C => return "Entertainment Interactive (stub)",
                0x3E => return "Gremlin",
                0x41 => return "Ubi Soft",
                0x42 => return "Atlus",
                0x44 => return "Malibu Interactive",
                0x46 => return "Angel",
                0x47 => return "Spectrum HoloByte",
                0x49 => return "Irem",
                0x4A => return "Virgin Games Ltd.",
                0x4D => return "Malibu Interactive",
                0x4F => return "U.S. Gold",
                0x50 => return "Absolute",
                0x51 => return "Acclaim Entertainment",
                0x52 => return "Activision",
                0x53 => return "Sammy USA Corporation",
                0x54 => return "GameTek",
                0x55 => return "Park Place",
                0x56 => return "LJN",
                0x57 => return "Matchbox",
                0x59 => return "Milton Bradley Company",
                0x5A => return "Mindscape",
                0x5B => return "Romstar",
                0x5C => return "Naxat Soft",
                0x5D => return "Tradewest",
                0x60 => return "Titus Interactive",
                0x61 => return "Virgin Games Ltd.",
                0x67 => return "Ocean Software",
                0x69 => return "EA (Electronic Arts)",
                0x6E => return "Elite Systems",
                0x6F => return "Electro Brain",
                0x70 => return "Infogrames",
                0x71 => return "Interplay Entertainment",
                0x72 => return "Broderbund",
                0x73 => return "Sculptured Software",
                0x75 => return "The Sales Curve Limited",
                0x78 => return "THQ",
                0x79 => return "Accolade",
                0x7A => return "Triffix Entertainment",
                0x7C => return "MicroProse",
                0x7F => return "Kemco",
                0x80 => return "Misawa Entertainment",
                0x83 => return "LOZC G.",
                0x86 => return "Tokuma Shoten",
                0x8B => return "Bullet-Proof Software",
                0x8C => return "Vic Tokai Corp.",
                0x8E => return "Ape Inc.",
                0x8F => return "I’Max",
                0x91 => return "Chunsoft Co.",
                0x92 => return "Video System",
                0x93 => return "Tsubaraya Productions",
                0x95 => return "Varie",
                0x96 => return "Yonezawa/S’Pal",
                0x97 => return "Kemco",
                0x99 => return "Arc",
                0x9A => return "Nihon Bussan",
                0x9B => return "Tecmo",
                0x9C => return "Imagineer",
                0x9D => return "Banpresto",
                0x9F => return "Nova",
                0xA1 => return "Hori Electric",
                0xA2 => return "Bandai",
                0xA4 => return "Konami",
                0xA6 => return "Kawada",
                0xA7 => return "Takara",
                0xA9 => return "Technos Japan",
                0xAA => return "Broderbund",
                0xAC => return "Toei Animation",
                0xAD => return "Toho",
                0xAF => return "Namco",
                0xB0 => return "Acclaim Entertainment",
                0xB1 => return "ASCII Corporation or Nexsoft",
                0xB2 => return "Bandai",
                0xB4 => return "Square Enix",
                0xB6 => return "HAL Laboratory",
                0xB7 => return "SNK",
                0xB9 => return "Pony Canyon",
                0xBA => return "Culture Brain",
                0xBB => return "Sunsoft",
                0xBD => return "Sony Imagesoft",
                0xBF => return "Sammy Corporation",
                0xC0 => return "Taito",
                0xC2 => return "Kemco",
                0xC3 => return "Square",
                0xC4 => return "Tokuma Shoten",
                0xC5 => return "Data East",
                0xC6 => return "Tonkin House",
                0xC8 => return "Koei",
                0xC9 => return "UFL",
                0xCA => return "Ultra Games",
                0xCB => return "VAP, Inc.",
                0xCC => return "Use Corporation",
                0xCD => return "Meldac",
                0xCE => return "Pony Canyon",
                0xCF => return "Angel",
                0xD0 => return "Taito",
                0xD1 => return "SOFEL (Software Engineering Lab)",
                0xD2 => return "Quest",
                0xD3 => return "Sigma Enterprises",
                0xD4 => return "ASK Kodansha Co.",
                0xD6 => return "Naxat Soft",
                0xD7 => return "Copya System",
                0xD9 => return "Banpresto",
                0xDA => return "Tomy",
                0xDB => return "LJN",
                0xDD => return "Nippon Computer Systems",
                0xDE => return "Human Ent.",
                0xDF => return "Altron",
                0xE0 => return "Jaleco",
                0xE1 => return "Towa Chiki",
                0xE2 => return "Yutaka",
                0xE3 => return "Varie",
                0xE5 => return "Epoch",
                0xE7 => return "Athena",
                0xE8 => return "Asmik Ace Entertainment",
                0xE9 => return "Natsume",
                0xEA => return "King Records",
                0xEB => return "Atlus",
                0xEC => return "Epic/Sony Records",
                0xEE => return "IGS",
                0xF0 => return "A Wave",
                0xF3 => return "Extreme Entertainment",
                0xFF => return "LJN",
                else => return "Unknown Publisher",
            }
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

    try std.testing.expectEqual("Nintendo Research & Development", cartridge_interface.*.cartridge.?.getPublisher());
}
