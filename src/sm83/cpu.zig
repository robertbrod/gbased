const std = @import("std");

const ALU = @import("alu.zig").ALU;
const RegisterFile = @import("register_file.zig").RegisterFile;
const idu = @import("idu.zig");
const InstructionSet = @import("instructions.zig").InstructionSet;

const SM83CPU = struct {
    alu: ALU,
    register_file: RegisterFile,
    instruction_set: InstructionSet,

    pub fn init(gpa: std.mem.Allocator) !@This() {
        return .{
            .alu = ALU.init(),
            .register_file = RegisterFile.init(),
            .instruction_set = try InstructionSet.init(gpa),
        };
    }

    pub fn deinit(self: *@This()) void {
        // Cleanup logic
        self.alu.deinit();
        self.register_file.deinit();
        self.instruction_set.deinit();
    }

    // TODO: implement action instruction timing

    pub fn process_instruction(self: *@This(), opcode: u8) void {
        for (self.instruction_set.instructions) |inst| {
            if (inst.match(opcode)) {
                // Execute the instruction
                inst.execute(opcode, &self.register_file);
                break;
            }
        }
    }
};

pub const sm83_cpu = SM83CPU.init();

test "SM83 CPU Initialization" {
    const gpa = std.testing.allocator;
    var cpu = try SM83CPU.init(gpa);
    defer cpu.deinit();

    // Test that the CPU initializes correctly
    try std.testing.expect(cpu.register_file.program_counter == 0);
    try std.testing.expect(cpu.register_file.stack_pointer == 0);
    try std.testing.expect(cpu.register_file.accumulator == 0);
}

test "SM83 Load Register Instruction" {
    const gpa = std.testing.allocator;
    var cpu = try SM83CPU.init(gpa);
    defer cpu.deinit();

    cpu.register_file.set_register_value(1, 6);

    cpu.process_instruction(0b01000001); // LD A, B

    // Test that the CPU initializes correctly
    const reg_a = cpu.register_file.get_register_value(0);
    try std.testing.expect(reg_a == 6);
}
