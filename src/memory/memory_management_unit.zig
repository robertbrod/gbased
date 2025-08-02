const std = @import("std");
const Gameboy = @import("gameboy");
const options = @import("options.zig");

pub const MemoryErrors = error{
    InvalidMemory,
};

// TODO: implement better/more accurate behavior around accessing memory that are blocked off
// E.g. reading/writing from OAM when it should be blocked off
// For now it is just returning 0xFF which seems to be the more common behavior in these situations
pub fn MemoryManagementUnit() type {
    return struct {
        const Self = @This();

        alloc: std.mem.Allocator,

        cartridge_interface: *Gameboy.CartridgeInterface(),

        // 8000-9FFF:   8 KiB Video RAM (VRAM). In CGB mode, switchable bank 0/1
        video_ram: [0x2000]u8,

        // C000-CFFF:   4 KiB Work RAM (WRAM).
        // D000-DFFF:   4 KiB Work RAM (WRAM). In CGB mode, switchable bank 1–7
        work_ram: [0x2000]u8,

        // E000-FDFF:   Echo RAM (mirror of C000–DDFF). Nintendo says use of this area is prohibited.
        //[0x1E00]u8,

        // FE00-FE9F:   Object attribute memory (OAM).
        object_attribute_memory: [0xA0]u8,

        // FEA0-FEFF:   Not Usable. Nintendo says use of this area is prohibited.
        // [0x60]u8

        // FF00-FF7F:   I/O Registers.
        io_registers: [0x80]u8,

        // FF80-FFFE:   High RAM (HRAM).
        high_ram: ?*[0x7F]u8 = null,

        // FFFF-FFFF:   Interrupt Enable register (IE)
        ie_register: u8,

        pub fn init(opts: options.MMUptions) !*Self {
            // Allocate memory on heap for memory map
            const new_memory_management_unit = try opts.alloc.create(Self);

            // Initialize values for memory map
            new_memory_management_unit.* = .{
                .alloc = opts.alloc,
                .cartridge_interface = opts.cartridge_interface,
                .video_ram = [_]u8{0} ** 0x2000,
                .work_ram = [_]u8{0} ** 0x2000,
                .object_attribute_memory = [_]u8{0} ** 0xA0,
                .io_registers = [_]u8{0} ** 0x80,
                .ie_register = 0,
            };

            return new_memory_management_unit;
        }

        pub fn deinit(self: *Self) void {
            // Deallocate memory from heap
            self.alloc.destroy(self);
        }

        pub fn mapHighRAM(self: *Self, high_ram: *[0x7F]u8) void {
            self.high_ram = high_ram;
        }

        pub fn getMemory(self: *Self, address: u16) u8 {
            // Map address to appropriate memory location
            if (address <= 0x7FFF) {
                // catridge_rom
                // Start: 0000 0000 0000 0000
                // End:   0111 1111 1111 1111
                // Mask:  0111 1111 1111 1111
                return self.cartridge_interface.readByte(address & 0x7FFF);
            } else if (address <= 0x9FFF) {
                // video_ram
                // Start: 1000 0000 0000 0000
                // End:   1001 1111 1111 1111
                // Mask:  0001 1111 1111 1111
                return self.video_ram[address & 0x1FFF];
            } else if (address <= 0xBFFF) {
                // external_ram
                // Start: 1010 0000 0000 0000
                // End:   1011 1111 1111 1111
                // Mask:  0001 1111 1111 1111
                return self.cartridge_interface.readByte(address & 0x1FFF);
            } else if (address <= 0xDFFF) {
                // work_ram
                // Start: 1100 0000 0000 0000
                // End:   1101 1111 1111 1111
                // Mask:  0001 1111 1111 1111
                return self.work_ram[address & 0x1FFF];
            } else if (address <= 0xFDFF) {
                // Echo RAM - prohibited
                // Start: 1110 0000 0000 0000
                // End:   1111 1101 1111 1111
            } else if (address <= 0xFE9F) {
                // object_attribute_memory
                // Start: 1111 1110 0000 0000
                // End:   1111 1110 1001 1111
                // Mask:  0000 0000 1111 1111
                return self.object_attribute_memory[address & 0xFF];
            } else if (address <= 0xFEFF) {
                // Prohibited
                // Start: 1111 1110 1010 0000
                // End:   1111 1110 1111 1111
            } else if (address <= 0xFF7F) {
                // io_registers
                // Start: 1111 1111 0000 0000
                // End:   1111 1111 0111 1111
                // Mask:  0000 0000 0111 1111
                return self.io_registers[address & 0x7F];
            } else if (address <= 0xFFFE) {
                //high_ram
                // Start: 1111 1111 1000 0000
                // End:   1111 1111 1111 1110
                // Mask:  0000 0000 0111 1111
                if (self.high_ram) |high_ram| {
                    return high_ram[address & 0x7F];
                }
            } else if (address == 0xFFFF) {
                // ie_register
                // 1111 1111 1111 1111
                return self.ie_register;
            }

            return 0xFF;
        }

        pub fn getMemoryPointer(self: *Self, address: u16) !*u8 {
            // Map address to appropriate memory location
            if (address <= 0x7FFF) {
                // catridge_rom
                // Start: 0000 0000 0000 0000try
                // End:   0111 1111 1111 1111
                // Mask:  0111 1111 1111 1111
                return try self.cartridge_interface.getMemoryPointer(address & 0x7FFF);
            } else if (address <= 0x9FFF) {
                // video_ram
                // Start: 1000 0000 0000 0000
                // End:   1001 1111 1111 1111
                // Mask:  0001 1111 1111 1111
                return &self.video_ram[address & 0x1FFF];
            } else if (address <= 0xBFFF) {
                // external_ram
                // Start: 1010 0000 0000 0000
                // End:   1011 1111 1111 1111
                // Mask:  0001 1111 1111 1111
                return try self.cartridge_interface.getMemoryPointer(address & 0x1FFF);
            } else if (address <= 0xDFFF) {
                // work_ram
                // Start: 1100 0000 0000 0000
                // End:   1101 1111 1111 1111
                // Mask:  0001 1111 1111 1111
                return &self.work_ram[address & 0x1FFF];
            } else if (address <= 0xFDFF) {
                // Echo RAM - prohibited
                // Start: 1110 0000 0000 0000
                // End:   1111 1101 1111 1111
                return MemoryErrors.InvalidMemory;
            } else if (address <= 0xFE9F) {
                // object_attribute_memory
                // Start: 1111 1110 0000 0000
                // End:   1111 1110 1001 1111
                // Mask:  0000 0000 1111 1111
                return &self.object_attribute_memory[address & 0xFF];
            } else if (address <= 0xFEFF) {
                // Prohibited
                // Start: 1111 1110 1010 0000
                // End:   1111 1110 1111 1111
                return MemoryErrors.InvalidMemory;
            } else if (address <= 0xFF7F) {
                // io_registers
                // Start: 1111 1111 0000 0000
                // End:   1111 1111 0111 1111
                // Mask:  0000 0000 0111 1111
                return &self.io_registers[address & 0x7F];
            } else if (address <= 0xFFFE) {
                //high_ram
                // Start: 1111 1111 1000 0000
                // End:   1111 1111 1111 1110
                // Mask:  0000 0000 0111 1111
                if (self.high_ram) |high_ram| {
                    return &high_ram[address & 0x7F];
                }
            } else if (address == 0xFFFF) {
                // ie_register
                // 1111 1111 1111 1111
                return &self.ie_register;
            } else {
                return MemoryErrors.InvalidMemory;
            }

            return MemoryErrors.InvalidMemory;
        }

        pub fn setMemory(self: *Self, address: u16, val: u8) void {
            // Map address to appropriate memory location
            if (address <= 0x7FFF) {
                // catridge_rom
                // Start: 0000 0000 0000 0000
                // End:   0111 1111 1111 1111
                // Mask:  0111 1111 1111 1111
                self.cartridge_interface.writeByte(address & 0x7FFF, val);
            } else if (address <= 0x9FFF) {
                // video_ram
                // Start: 1000 0000 0000 0000
                // End:   1001 1111 1111 1111
                // Mask:  0001 1111 1111 1111
                self.video_ram[address & 0x1FFF] = val;
            } else if (address <= 0xBFFF) {
                // external_ram
                // Start: 1010 0000 0000 0000
                // End:   1011 1111 1111 1111
                // Mask:  0001 1111 1111 1111
                self.cartridge_interface.writeByte(address & 0x1FFF, val);
            } else if (address <= 0xDFFF) {
                // work_ram
                // Start: 1100 0000 0000 0000
                // End:   1101 1111 1111 1111
                // Mask:  0001 1111 1111 1111
                self.work_ram[address & 0x1FFF] = val;
            } else if (address <= 0xFDFF) {
                // Echo RAM - prohibited
                // Start: 1110 0000 0000 0000
                // End:   1111 1101 1111 1111
                // No-op
            } else if (address <= 0xFE9F) {
                // object_attribute_memory
                // Start: 1111 1110 0000 0000
                // End:   1111 1110 1001 1111
                // Mask:  0000 0000 1111 1111
                self.object_attribute_memory[address & 0xFF] = val;
            } else if (address <= 0xFEFF) {
                // Prohibited
                // Start: 1111 1110 1010 0000
                // End:   1111 1110 1111 1111
                // No-op
            } else if (address <= 0xFF7F) {
                // io_registers
                // Start: 1111 1111 0000 0000
                // End:   1111 1111 0111 1111
                // Mask:  0000 0000 0111 1111
                self.io_registers[address & 0x7F] = val;
            } else if (address <= 0xFFFE) {
                //high_ram
                // Start: 1111 1111 1000 0000
                // End:   1111 1111 1111 1110
                // Mask:  0000 0000 0111 1111
                if (self.high_ram) |high_ram| {
                    high_ram[address & 0x7F] = val;
                }
            } else if (address == 0xFFFF) {
                // ie_register
                // 1111 1111 1111 1111
                self.ie_register = val;
            }

            // No-op
        }
    };
}

test "Fetch Memory" {
    const gpa = std.testing.allocator;
    const mmu = try gpa.create(MemoryManagementUnit);
    defer gpa.destroy(mmu);

    mmu.cartridge_rom = [_]u8{1} ** 0x8000;
    mmu.video_ram = [_]u8{2} ** 0x2000;
    mmu.external_ram = [_]u8{3} ** 0x2000;
    mmu.work_ram = [_]u8{4} ** 0x2000;
    mmu.object_attribute_memory = [_]u8{5} ** 0xA0;
    mmu.io_registers = [_]u8{6} ** 0x80;
    mmu.high_ram = [_]u8{6} ** 0x7F;
    mmu.ie_register = 7;

    try std.testing.expectEqual(1, mmu.getMemory(0x41AE));
    try std.testing.expectEqual(2, mmu.getMemory(0x8123));
    try std.testing.expectEqual(3, mmu.getMemory(0xB187));
    try std.testing.expectEqual(4, mmu.getMemory(0xCABC));
    try std.testing.expectError(MemoryErrors.InvalidMemory, mmu.getMemory(0xF382));
    try std.testing.expectEqual(5, mmu.getMemory(0xFE00));
    try std.testing.expectError(MemoryErrors.InvalidMemory, mmu.getMemory(0xFEA0));
    try std.testing.expectEqual(6, mmu.getMemory(0xFF90));
    try std.testing.expectEqual(6, mmu.getMemory(0xFFA3));
    try std.testing.expectEqual(7, mmu.getMemory(0xFFFF));
}
