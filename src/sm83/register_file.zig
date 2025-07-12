pub const RegisterFile = struct {
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

    pub fn init() @This() {
        return .{};
    }

    pub fn deinit(_: *@This()) void {
        // Cleanup logic for ALU if needed
    }

    // Register number map
    // 0 -> B
    // 1 -> C
    // 2 -> D
    // 3 -> E
    // 4 -> H
    // 5 -> L
    // 6 -> (HL)
    // 7 -> A
    pub fn get_register_value(self: *RegisterFile, reg_num: u3) u8 {
        switch (reg_num) {
            0 => return @intCast(self.register_bc >> 8), // B
            1 => return @intCast(self.register_bc & 0xFF), // C
            2 => return @intCast(self.register_de >> 8), // D
            3 => return @intCast(self.register_de & 0xFF), // E
            4 => return @intCast(self.register_hl >> 8), // H
            5 => return @intCast(self.register_hl & 0xFF), // L
            6 => return 0, // TODO: read memory of HL
            7 => return self.accumulator, // A
        }
    }

    pub fn set_register_value(self: *RegisterFile, reg_num: u3, value: u8) void {
        switch (reg_num) {
            0 => self.register_bc = (self.register_bc & 0x00FF) | (@as(u16, value) << 8), // B
            1 => self.register_bc = (self.register_bc & 0xFF00) | @as(u16, value), // C
            2 => self.register_de = (self.register_de & 0x00FF) | (@as(u16, value) << 8), // D
            3 => self.register_de = (self.register_de & 0xFF00) | @as(u16, value), // E
            4 => self.register_hl = (self.register_hl & 0x00FF) | (@as(u16, value) << 8), // H
            5 => self.register_hl = (self.register_hl & 0xFF00) | @as(u16, value), // L
            6 => return, // TODO: write memory of HL
            7 => self.accumulator = value, // A
        }
    }
};
