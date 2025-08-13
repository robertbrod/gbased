const std = @import("std");

pub fn RegisterFile() type {
    return struct {
        const Self = @This();

        alloc: std.mem.Allocator,

        // Instruction Register
        register_ir: u8 = 0,
        // Interrupt Enable
        register_ie: u8 = 0,

        accumulator: u8 = 0,
        flags: u8 = 0,

        // Pair of 8-bit registers
        register_bc: u16 = 0,
        register_de: u16 = 0,
        register_hl: u16 = 0,

        program_counter: u16 = 0,
        stack_pointer: u16 = 0,

        pub fn init(alloc: std.mem.Allocator) !*Self {
            // Allocate register file on the heap
            const new_register_file = try alloc.create(Self);

            // Initialize register file
            new_register_file.* = .{
                .alloc = alloc,
            };

            return new_register_file;
        }

        pub fn deinit(self: *Self) void {
            // Deallocate memory from heap
            self.alloc.destroy(self);
        }

        // Register number map
        // 0 -> B
        // 1 -> C
        // 2 -> D
        // 3 -> E
        // 4 -> H
        // 5 -> L
        // 6 -> (HL) get value of memory management unit based on address in HL
        // 7 -> A
        pub fn get_value(self: *Self, reg_num: u3) u8 {
            switch (reg_num) {
                0 => return @intCast(self.register_bc >> 8), // B
                1 => return @intCast(self.register_bc & 0xFF), // C
                2 => return @intCast(self.register_de >> 8), // D
                3 => return @intCast(self.register_de & 0xFF), // E
                4 => return @intCast(self.register_hl >> 8), // H
                5 => return @intCast(self.register_hl & 0xFF), // L
                6 => return 0, // This should never happen
                7 => return self.accumulator, // A
            }
        }

        pub fn set_value(self: *Self, reg_num: u3, value: u8) void {
            switch (reg_num) {
                0 => self.register_bc = (self.register_bc & 0x00FF) | (@as(u16, value) << 8), // B
                1 => self.register_bc = (self.register_bc & 0xFF00) | @as(u16, value), // C
                2 => self.register_de = (self.register_de & 0x00FF) | (@as(u16, value) << 8), // D
                3 => self.register_de = (self.register_de & 0xFF00) | @as(u16, value), // E
                4 => self.register_hl = (self.register_hl & 0x00FF) | (@as(u16, value) << 8), // H
                5 => self.register_hl = (self.register_hl & 0xFF00) | @as(u16, value), // L
                6 => return, // This should never happen
                7 => self.accumulator = value, // A
            }
        }
    };
}

test "Register Initialization" {
    const register = RegisterFile().init();
    defer register.deinit();
}
