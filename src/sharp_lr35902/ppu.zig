const std = @import("std");
const memory = @import("memory");

const options = @import("options.zig");

pub fn PPU() type {
    return struct {
        const Self = @This();

        // Allocation
        alloc: std.mem.Allocator,

        // External pointers
        mmu: *memory.MemoryManagementUnit(),

        // Register Pointers
        // Have them be first class properties for easier referencing
        lcd_control: *u8,
        lcd_status: *u8,
        scroll_y: *u8,
        scroll_x: *u8,
        lcd_y: *u8,
        ly_compare: *u8,
        dma_transfer: *u8,
        bg_palette: *u8,
        obj_palette0: *u8,
        obj_palette1: *u8,
        window_y: *u8,
        window_x: *u8,

        // PPU Internal State
        scan_line: u8 = 0,
        x_pos: u8 = 0,
        dot: u16 = 0,

        pub fn init(opts: options.SoCOptions) !Self {
            const new_ppu: Self = .{
                .alloc = opts.alloc,

                .mmu = opts.mmu,

                // $FF40 - LCD Control
                .lcd_control = try opts.mmu.getMemoryPointer(0xFF40),
                // $FF41 - LCD Status
                .lcd_status = try opts.mmu.getMemoryPointer(0xFF41),
                // $FF42 - Scroll Y
                .scroll_y = try opts.mmu.getMemoryPointer(0xFF42),
                // $FF43 - Scroll X
                .scroll_x = try opts.mmu.getMemoryPointer(0xFF43),
                // $FF44 - LCD Y
                .lcd_y = try opts.mmu.getMemoryPointer(0xFF44),
                // $FF45 - LY Compare
                .ly_compare = try opts.mmu.getMemoryPointer(0xFF45),
                // $FF46 - DMA Transfer and Start Address
                .dma_transfer = try opts.mmu.getMemoryPointer(0xFF46),
                // $FF47 - BG Palette Data
                .bg_palette = try opts.mmu.getMemoryPointer(0xFF47),
                // $FF48 - Object Palette 0 Data
                .obj_palette0 = try opts.mmu.getMemoryPointer(0xFF48),
                // $FF49 - Object Palette 1 Data
                .obj_palette1 = try opts.mmu.getMemoryPointer(0xFF49),
                // $FF4A - Window Y Position
                .window_y = try opts.mmu.getMemoryPointer(0xFF4A),
                // $FF4B - Window X Position
                .window_x = try opts.mmu.getMemoryPointer(0xFF4B),
            };

            return new_ppu;
        }

        pub fn deinit(_: *Self) void {
            // Cleanup logic
        }

        // TODO: implement actual logic
        pub fn tick(self: *Self) void {
            if (self.dot == 0 and self.scan_line == 0) {
                std.debug.print("PPU: New frame - {d}\n", .{std.time.milliTimestamp()});
            }

            _ = switch (self.getMode()) {
                2 => self.runMode2(),
                3 => self.runMode3(),
                0 => self.runMode0(),
                1 => self.runMode1(),
            };
        }

        // TODO: implement PPU logic

        // Searching for OBJs which overlap this line
        // 80 dots
        // VRAM, CGB palettes
        fn runMode2(self: *Self) void {
            self.dot += 1;

            if (self.dot == 80) {
                self.setMode(3);

                // Check interrupt
            }
        }

        // Waiting until the end of the scanline
        // 376 - mode 3’s duration
        // VRAM, OAM, CGB palettes
        fn runMode3(self: *Self) void {
            self.dot += 1;

            if (self.dot == 252) {
                self.setMode(0);
            }
        }

        // Waiting until the end of the scanline
        // 376 - mode 3’s duration
        // VRAM, OAM, CGB palettes
        fn runMode0(self: *Self) void {
            // First 80 dots of a scanline
            self.dot += 1;

            // No-op

            if (self.dot == 456) {
                self.dot = 0;
                self.scan_line += 1;

                if (self.scan_line == 144) {
                    self.setMode(1);
                } else {
                    self.setMode(2);
                }

                // self.mode = 3;
            }
        }

        // Waiting until the next frame
        // 4560 dots (10 scanlines)
        // VRAM, OAM, CGB palettes
        fn runMode1(self: *Self) void {
            self.dot += 1;

            // No-op

            // Reached end of line
            if (self.dot == 456) {
                self.dot = 0;
                self.scan_line += 1;

                // Finished mode 1 => mode 2
                if (self.scan_line == 154) {
                    self.scan_line = 0;
                    self.setMode(2);
                }
            }
        }

        // LCD Registers
        // $FF40 - LCD Control
        // https://gbdev.io/pandocs/LCDC.html#ff40--lcdc-lcd-control
        // Bit 7 - LCD & PPU enable: 0 = Off; 1 = On
        // Bit 6 - Window tile map: 0 = 0x9800–0x9BFF; 1 = 0x9C00–0x9FFF
        // Bit 5 - Window enable: 0 = Off; 1 = On
        // Bit 4 - BG & Window tiles: 0 = 0x8800–0x97FF; 1 = 0x8000-0x8FFF
        // Bit 3 - BG tile map: 0 = 0x9800-0x9BFF; 1 = 0x9C00-0x9FFF
        // Bit 2 - OBJ size: 0 = 8x8; 1 = 8x16
        // Bit 1 - OBJ enable: 0 = Off; 1 = On
        // Bit 0 - BG & window enable/priority: 0 = Off; 1 = On

        // $FF41 - LCD Status
        // https://gbdev.io/pandocs/STAT.html#ff41--stat-lcd-status
        // Bit 7 - Unused
        // Bit 6 - LYC int select (Read/Write): If set, selects the LYC == LY condition for the STAT interrupt.
        // Bit 5 - Mode 2 int select (Read/Write): If set, selects the Mode 2 condition for the STAT interrupt.
        // Bit 4 - Mode 1 int select (Read/Write): If set, selects the Mode 1 condition for the STAT interrupt.
        // Bit 3 - Mode 0 int select (Read/Write): If set, selects the Mode 0 condition for the STAT interrupt.
        // Bit 2 - LYC == LY (Read-only): Set when LY contains the same value as LYC; it is constantly updated.
        // Bit 1 + 0 - PPU mode (Read-only): Indicates the PPU’s current status. Reports 0 instead when the PPU is disabled.

        // $FF42 - Scroll Y
        // $FF43 - SCroll X
        // $FF44 - LCDC Y
        // $FF45 - LY Compare
        // $FF46 - DMA Transfer and Start Address
        // $FF47 - BG Palette Data
        // $FF48 - Object Palette 0 Data
        // $FF49 - Object Palette 1 Data
        // $FF4A - Window Y Position
        // $FF4B - Window X Position

        // LCD Register Helpers
        fn getMode(self: *Self) u2 {
            // 2 lowest bits of LCD status register
            return @as(u2, @intCast(self.lcd_status.* & 0b11));
        }

        fn setMode(self: *Self, mode: u2) void {
            // 2 lowest bits of LCD status register
            self.lcd_status.* = (self.lcd_status.* & 0b00) | mode;
        }

        fn checkInterrupts(self: *Self) !void {
            const lcdStatus = try self.getSTAT();

            // Bit 6 - LYC int select (Read/Write): If set, selects the LYC == LY condition for the STAT interrupt.
            if (lcdStatus & 0b01000000 == 0b01000000) {
                if (try self.getLY() == try self.getLYC()) {
                    self.setSTATInterrupt();
                }
            }
            // Bit 5 - Mode 2 int select (Read/Write): If set, selects the Mode 2 condition for the STAT interrupt.
            else if (lcdStatus & 0b00100000 == 0b00100000) {
                if (self.mode == 2) {
                    try self.setSTATInterrupt();
                }
            }
            // Bit 4 - Mode 1 int select (Read/Write): If set, selects the Mode 1 condition for the STAT interrupt.
            else if (lcdStatus & 0b00010000 == 0b00010000) {
                if (self.mode == 2) {
                    try self.setSTATInterrupt();
                }
            }
            // Bit 3 - Mode 0 int select (Read/Write): If set, selects the Mode 0 condition for the STAT interrupt.
            else if (lcdStatus & 0b00001000 == 0b00001000) {
                if (self.mode == 2) {
                    try self.setSTATInterrupt();
                }
            }
        }

        fn setSTATInterrupt(_: *Self) !void {}
    };
}
