const std = @import("std");

const RegisterFile = @import("register_file.zig").RegisterFile;

// This file contains all the SM83 instruction definitions and their execution logic.

const InstructionType = enum {
    LoadRegister,
    // Add more instruction types as needed
};

const Instruction = struct {
    instruction_type: InstructionType,

    pub fn match(self: Instruction, opcode: u8) bool {
        return switch (self.instruction_type) {
            InstructionType.LoadRegister => LoadRegisterInstruction.match(opcode),
        };
    }

    pub fn execute(self: Instruction, opcode: u8, register_file: *RegisterFile) void {
        switch (self.instruction_type) {
            InstructionType.LoadRegister => LoadRegisterInstruction.execute(opcode, register_file),
        }
    }
};

pub const InstructionSet = struct {
    gpa: std.mem.Allocator,
    instructions: []Instruction,

    pub fn init(gpa: std.mem.Allocator) !@This() {
        const instruction_types = @typeInfo(InstructionType).@"enum";

        const instructions = try gpa.alloc(Instruction, instruction_types.fields.len);

        inline for (instruction_types.fields, 0..) |instruction_type, i| {
            instructions[i] = Instruction{ .instruction_type = @enumFromInt(instruction_type.value) };
        }

        return .{ .gpa = gpa, .instructions = instructions };
    }

    pub fn deinit(self: *@This()) void {
        self.gpa.free(self.instructions);
    }
};

test "Create InstructionSet" {
    const gpa = std.testing.allocator;
    var instruction_set = try InstructionSet.init(gpa);
    defer instruction_set.deinit();

    // Test that the instruction set initializes correctly
    try std.testing.expect(instruction_set.instructions.len == @typeInfo(InstructionType).@"enum".fields.len);
    try std.testing.expect(instruction_set.instructions[0].instruction_type == InstructionType.LoadRegister);
}

// All instruction implementations are defined here
// https://www.pastraiser.com/cpu/gameboy/gameboy_opcodes.html
const LoadRegisterInstruction = struct {
    // Opcode - 0b01xxxyyy
    // LD r1, r2
    // Load value from r1 into  r1

    // Timing cycles
    const load_cycle_count: u1 = 0;
    const exe_cycle_count: u3 = 1;

    pub fn match(opcode: u8) bool {
        return (opcode & 0b01000000) == 0b01000000 and (opcode & 0b01000110) != 0b01000110;
    }

    pub fn execute(opcode: u8, register_file: *RegisterFile) void {
        const r1: u3 = @intCast(opcode >> 3 & 0b00000111); // Extract bits 3-5
        const r2: u3 = @intCast(opcode & 0b00000111); // Extract bits 0-2

        register_file.set_register_value(r1, register_file.get_register_value(r2));
    }
};
