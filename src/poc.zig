const std = @import("std");
const print = std.debug.print;
const expect = std.testing.expect;

const Cpu = struct {
    memory: [65535]u8,

    accumulator: u8,
    zero_flag: u1,
    subtraction_flag: u1, // BCD
    half_carry_flag: u1, // BCD
    carry_flag: u1,

    reg_b: u8,
    reg_c: u8,
    reg_d: u8,
    reg_e: u8,
    reg_h: u8,
    reg_l: u8,

    sp: u16,
    pc: u16,

    cycle_count: u64,

    pub fn init(allocator: std.mem.Allocator) !*Cpu {
        var self = try allocator.create(Cpu);

        @memset(self.memory[0..], 0);

        self.pc = 0x0000;
        self.sp = 0xFFFE; // top of HRAM

        self.cycle_count = 0;

        self.accumulator = 0;
        self.zero_flag = 0;
        self.subtraction_flag = 0;
        self.half_carry_flag = 0;
        self.carry_flag = 0;

        self.reg_b = 0;
        self.reg_c = 0;
        self.reg_d = 0;
        self.reg_e = 0;
        self.reg_h = 0;
        self.reg_l = 0;

        return self;
    }

    pub fn deinit(self: *Cpu, allocator: std.mem.Allocator) void {
        allocator.destroy(self);
    }

    pub fn load_instruction_byte(self: *Cpu, address: u16, instruction: u8) void {
        self.memory[address] = instruction;
    }

    pub fn load_operand_byte(self: *Cpu, address: u16, operand: u8) void {
        self.memory[address] = operand;
    }

    pub fn execute(self: *Cpu) void {
        const instruction = self.memory[self.pc];
        switch (instruction) {
            0x00 => self.instr_nop(),
            0x04 => self.instr_inc_b(),
            0x06 => self.instr_ld_b(),
            else => unreachable,
        }
    }

    pub fn instr_nop(self: *Cpu) void {
        self.pc += 1;
        self.cycle_count += 4;
    }

    pub fn instr_inc_b(self: *Cpu) void {
        self.pc += 1;

        const reg_b_old = self.reg_b;
        self.reg_b +%= 1;

        self.zero_flag = if (self.reg_b == 0) 1 else 0;
        self.subtraction_flag = 0;

        const nibble = reg_b_old & 0x0F;
        self.half_carry_flag = if ((nibble + 1) & 0x10 == 0x10) 1 else 0;

        self.cycle_count += 4;
    }

    pub fn instr_ld_b(self: *Cpu) void {
        self.pc += 1;

        const operand = self.memory[self.pc];
        self.pc += 1;

        self.reg_b = operand;

        self.cycle_count += 8;
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();
    var cpu = try Cpu.init(allocator);
    defer cpu.deinit(allocator);

    // NOP
    cpu.load_instruction_byte(0x0000, 0x00);

    // INC B
    cpu.load_instruction_byte(0x0001, 0x04);

    // LD B - 32
    cpu.load_instruction_byte(0x0002, 0x06);
    cpu.load_operand_byte(0x0003, 0x20);

    cpu.execute();
    cpu.execute();
    cpu.execute();
}

test "multiple instructions" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();
    var cpu = try Cpu.init(allocator);
    defer cpu.deinit(allocator);

    // NOP
    cpu.load_instruction_byte(0x0000, 0x00);

    // INC B
    cpu.load_instruction_byte(0x0001, 0x04);

    // LD B - 32
    cpu.load_instruction_byte(0x0002, 0x06);
    cpu.load_operand_byte(0x0003, 0x20);

    cpu.execute();
    cpu.execute();
    cpu.execute();

    try std.testing.expectEqual(cpu.pc, 4);
    try std.testing.expectEqual(cpu.cycle_count, 16);
}

test "NOP instruction" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();
    var cpu = try Cpu.init(allocator);
    defer cpu.deinit(allocator);

    // NOP
    cpu.load_instruction_byte(0x0000, 0x00);

    cpu.execute();

    try std.testing.expectEqual(cpu.pc, 1);
    try std.testing.expectEqual(cpu.cycle_count, 4);
}

test "INC_B instruction" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();
    var cpu = try Cpu.init(allocator);

    // INC B
    cpu.load_instruction_byte(0x0000, 0x04);

    cpu.execute();

    try std.testing.expectEqual(cpu.pc, 1);
    try std.testing.expectEqual(cpu.cycle_count, 4);
    try std.testing.expectEqual(cpu.reg_b, 1);
    try std.testing.expectEqual(cpu.zero_flag, 0);
    try std.testing.expectEqual(cpu.subtraction_flag, 0);
    try std.testing.expectEqual(cpu.half_carry_flag, 0);

    cpu.deinit(allocator);
    cpu = try Cpu.init(allocator);

    // testing zero flag and overflow
    cpu.reg_b = 255;

    // INC B
    cpu.load_instruction_byte(0x0000, 0x04);

    cpu.execute();

    try std.testing.expectEqual(cpu.zero_flag, 1);

    cpu.deinit(allocator);
    cpu = try Cpu.init(allocator);
    defer cpu.deinit(allocator);

    // testing half carry flag
    cpu.reg_b = 15;

    // INC B
    cpu.load_instruction_byte(0x0000, 0x04);

    cpu.execute();

    try std.testing.expectEqual(cpu.half_carry_flag, 1);
}

test "LD B instruction" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();
    var cpu = try Cpu.init(allocator);
    defer cpu.deinit(allocator);

    // LD B - 32
    cpu.load_instruction_byte(0x0000, 0x06);
    cpu.load_operand_byte(0x0001, 0x20);

    cpu.execute();
    try std.testing.expectEqual(cpu.pc, 2);
    try std.testing.expectEqual(cpu.cycle_count, 8);
    try std.testing.expectEqual(cpu.reg_b, 32);
}
