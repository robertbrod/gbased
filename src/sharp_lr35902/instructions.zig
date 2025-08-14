const std = @import("std");

const CPU = @import("cpu.zig").SM83CPU;

const RegisterFile = @import("register_file.zig").RegisterFile;

// This file contains all the SM83 instruction definitions and their execution logic.

pub const CPUErrors = error{
    UnknownInstructionError,
};

pub fn InstructionSet() type {
    return struct {
        const Self = @This();

        pub fn init() Self {
            return .{};
        }

        pub fn deinit(_: *Self) void {}

        pub fn execute(_: *Self, cpu: *CPU()) CPUErrors!bool {
            // Map opcode to the instruction
            // https://www.pastraiser.com/cpu/gameboy/gameboy_opcodes.html
            return switch (cpu.register_file.register_ir) {
                // 8-bit load instructions
                0x40...0x45 => LoadRegister.execute(cpu),
                0x47...0x4D => LoadRegister.execute(cpu),
                0x4F => LoadRegister.execute(cpu),
                0x50...0x55 => LoadRegister.execute(cpu),
                0x57...0x5D => LoadRegister.execute(cpu),
                0x5F => LoadRegister.execute(cpu),
                0x60...0x65 => LoadRegister.execute(cpu),
                0x67...0x6D => LoadRegister.execute(cpu),
                0x6F => LoadRegister.execute(cpu),

                0x06 => LoadRegisterImmediate.execute(cpu),
                0x0E => LoadRegisterImmediate.execute(cpu),
                0x16 => LoadRegisterImmediate.execute(cpu),
                0x1E => LoadRegisterImmediate.execute(cpu),
                0x26 => LoadRegisterImmediate.execute(cpu),
                0x2E => LoadRegisterImmediate.execute(cpu),
                0x3E => LoadRegisterImmediate.execute(cpu),

                0x46 => LoadRegisterIndirect.execute(cpu),
                0x56 => LoadRegisterIndirect.execute(cpu),
                0x66 => LoadRegisterIndirect.execute(cpu),
                0x4E => LoadRegisterIndirect.execute(cpu),
                0x5E => LoadRegisterIndirect.execute(cpu),
                0x6E => LoadRegisterIndirect.execute(cpu),
                0x7E => LoadRegisterIndirect.execute(cpu),

                0x70...0x75 => LoadFromRegisterIndirect.execute(cpu),
                0x77 => LoadFromRegisterIndirect.execute(cpu),

                0x36 => LoadFromImmediateIndirect.execute(cpu),

                0x0A => LoadAccumulatorIndirectBC.execute(cpu),
                0x1A => LoadAccumulatorIndirectDE.execute(cpu),
                0x02 => LoadFromAccumulatorIndirectBC.execute(cpu),
                0x12 => LoadFromAccumulatorIndirectDE.execute(cpu),

                0xFA => LoadAccumulatorDirect.execute(cpu),
                0xEA => LoadFromAccumulatorDirect.execute(cpu),

                0xF2 => LoadAccumulatorIndirectC.execute(cpu),
                0xE2 => LoadFromAccumulatorIndirectC.execute(cpu),

                0xF0 => LoadAccumulatorDirectN.execute(cpu),
                0xE0 => LoadFromAccumulatorDirectN.execute(cpu),

                0x3A => LoadAccumulatorIndirectHLDecrement.execute(cpu),
                0x32 => LoadFromAccumulatorIndirectHLDecrement.execute(cpu),
                0x2A => LoadAccumulatorIndirectHLIncrement.execute(cpu),
                0x22 => LoadFromAccumulatorIndirectHLIncrement.execute(cpu),

                // 16-bit load instructions
                0x01 => LoadRegisterPair.execute(cpu),
                0x11 => LoadRegisterPair.execute(cpu),
                0x21 => LoadRegisterPair.execute(cpu),
                0x31 => LoadRegisterPair.execute(cpu),

                0x08 => LoadFromStackPointer.execute(cpu),

                0xF9 => LoadStackPointerFromHL.execute(cpu),

                0xC5 => PushStack.execute(cpu),
                0xD5 => PushStack.execute(cpu),
                0xE5 => PushStack.execute(cpu),
                0xF5 => PushStack.execute(cpu),

                0xC1 => PopStack.execute(cpu),
                0xD1 => PopStack.execute(cpu),
                0xE1 => PopStack.execute(cpu),
                0xF1 => PopStack.execute(cpu),

                0xF8 => LoadFromAdjustedStackPointer.execute(cpu),

                // Misc instructions
                0x00 => NOP.execute(cpu),

                else => return CPUErrors.UnknownInstructionError,
            };
        }
    };
}

// test "Create InstructionSet" {
//     const gpa = std.testing.allocator;
//     var instruction_set = try InstructionSet().init(gpa);
//     defer instruction_set.deinit();

//     // Test that the instruction set initializes correctly
//     try std.testing.expect(instruction_set.instructions.len == @typeInfo(InstructionType).@"enum".fields.len);
//     try std.testing.expect(instruction_set.instructions[0].instruction_type == InstructionType.LoadRegister);
// }

// All instruction implementations are defined here
// https://www.pastraiser.com/cpu/gameboy/gameboy_opcodes.html

// 8-bit load instructions
const LoadRegister = struct {
    // Opcode - 0b01xxxyyy
    // LD r1, r2
    // Load value from r1 into r2

    pub fn execute(cpu: *CPU()) bool {
        switch (cpu.machine_cycle) {
            1 => {
                // This is just the fetch cycle which is done at the CPU level
            },
            2 => {
                const r1: u3 = @truncate(cpu.register_file.register_ir >> 3); // Extract bits 3-5
                const r2: u3 = @truncate(cpu.register_file.register_ir); // Extract bits 0-2

                cpu.register_file.set_value(r1, cpu.register_file.get_value(r2));

                // Done with opcode
                return true;
            },
            else => {},
        }

        return false;
    }
};

const LoadRegisterImmediate = struct {
    // Opcode - 0b00xxx110
    // LD r, n
    // Load immediate data n into r
    var z: u8 = 0;

    pub fn execute(cpu: *CPU()) bool {
        switch (cpu.machine_cycle) {
            1 => {
                // This is just the fetch cycle which is done at the CPU level
            },
            2 => {
                z = cpu.mmu.getMemory(cpu.register_file.program_counter);
                cpu.register_file.program_counter += 1;
            },
            3 => {
                const r: u3 = @truncate(cpu.register_file.register_ir >> 3); // Extract bits 3-5
                cpu.register_file.set_value(r, z);

                // Done with opcode
                return true;
            },
            else => {},
        }

        return false;
    }
};

const LoadRegisterIndirect = struct {
    // Opcode - 0b01xxx110
    // LD r, (HL)
    // Load data from HL address into r
    var z: u8 = 0;

    pub fn execute(cpu: *CPU()) bool {
        switch (cpu.machine_cycle) {
            1 => {
                // This is just the fetch cycle which is done at the CPU level
            },
            2 => {
                z = cpu.mmu.getMemory(cpu.register_file.register_hl);
            },
            3 => {
                const r: u3 = @truncate(cpu.register_file.register_ir >> 3); // Extract bits 3-5

                cpu.register_file.set_value(r, z);

                // Done with opcode
                return true;
            },
            else => {},
        }

        return false;
    }
};

const LoadFromRegisterIndirect = struct {
    // Opcode - 0b01110xxx
    // LD (HL), r
    // Load data from r into HL address
    pub fn execute(cpu: *CPU()) bool {
        switch (cpu.machine_cycle) {
            1 => {
                // This is just the fetch cycle which is done at the CPU level
            },
            2 => {
                const r: u3 = @truncate(cpu.register_file.register_ir); // Extract bits 0-2

                const val = cpu.register_file.get_value(r);
                cpu.mmu.setMemory(cpu.register_file.register_hl, val);
            },
            3 => {
                // Done with opcode
                return true;
            },
            else => {},
        }

        return false;
    }
};

const LoadFromImmediateIndirect = struct {
    // Opcode - 0b00110110
    // LD (HL), n
    // Load immediate data n into HL address
    var z: u8 = 0;

    pub fn execute(cpu: *CPU()) bool {
        switch (cpu.machine_cycle) {
            1 => {
                // This is just the fetch cycle which is done at the CPU level
            },
            2 => {
                z = cpu.mmu.getMemory(cpu.register_file.program_counter);
                cpu.register_file.program_counter += 1;
            },
            3 => {
                cpu.mmu.setMemory(cpu.register_file.register_hl, z);
            },
            4 => {
                // Done with opcode
                return true;
            },
            else => {},
        }

        return false;
    }
};

const LoadAccumulatorIndirectBC = struct {
    // Opcode - 0b00001010
    // LD A, (BC)
    // Load into A register, data from the address of BC
    var z: u8 = 0;

    pub fn execute(cpu: *CPU()) bool {
        switch (cpu.machine_cycle) {
            1 => {
                // This is just the fetch cycle which is done at the CPU level
            },
            2 => {
                z = cpu.mmu.getMemory(cpu.register_file.register_bc);
            },
            3 => {
                cpu.register_file.accumulator = z;

                // Done with opcode
                return true;
            },
            else => {},
        }

        return false;
    }
};

const LoadAccumulatorIndirectDE = struct {
    // Opcode - 0b00011010
    // LD A, (DE)
    // Load into A register, data from the address of DE
    var z: u8 = 0;

    pub fn execute(cpu: *CPU()) bool {
        switch (cpu.machine_cycle) {
            1 => {
                // This is just the fetch cycle which is done at the CPU level
            },
            2 => {
                z = cpu.mmu.getMemory(cpu.register_file.register_de);
            },
            3 => {
                cpu.register_file.accumulator = z;

                // Done with opcode
                return true;
            },
            else => {},
        }

        return false;
    }
};

const LoadFromAccumulatorIndirectBC = struct {
    // Opcode - 0b00000010
    // LD (BC), A
    // Load into A register, data from the address of BC
    pub fn execute(cpu: *CPU()) bool {
        switch (cpu.machine_cycle) {
            1 => {
                // This is just the fetch cycle which is done at the CPU level
            },
            2 => {
                cpu.mmu.setMemory(cpu.register_file.register_bc, cpu.register_file.accumulator);
            },
            3 => {
                // Done with opcode
                return true;
            },
            else => {},
        }

        return false;
    }
};

const LoadFromAccumulatorIndirectDE = struct {
    // Opcode - 0b00010010
    // LD (DE), A
    // Load into A register, data from the address of DE
    pub fn execute(cpu: *CPU()) bool {
        switch (cpu.machine_cycle) {
            1 => {
                // This is just the fetch cycle which is done at the CPU level
            },
            2 => {
                cpu.mmu.setMemory(cpu.register_file.register_de, cpu.register_file.accumulator);
            },
            3 => {
                // Done with opcode
                return true;
            },
            else => {},
        }

        return false;
    }
};

const LoadAccumulatorDirect = struct {
    // Opcode - 0b11111010
    // LD A, (nn)
    // Load to the 8-bit A register, data from the absolute address specified by the 16-bit operand nn
    var addr: u16 = 0;
    var z: u8 = 0;

    pub fn execute(cpu: *CPU()) bool {
        switch (cpu.machine_cycle) {
            1 => {
                // This is just the fetch cycle which is done at the CPU level
            },
            2 => {
                // Lowest 8 bits
                addr = cpu.mmu.getMemory(cpu.register_file.program_counter);
                cpu.register_file.program_counter += 1;
            },
            3 => {
                // Highest 8 bits
                addr |= @as(u16, @intCast(cpu.mmu.getMemory(cpu.register_file.program_counter))) << 8;
                cpu.register_file.program_counter += 1;
            },
            4 => {
                z = cpu.mmu.getMemory(addr);
            },
            5 => {
                cpu.register_file.accumulator = z;

                // Done with opcode
                return true;
            },
            else => {},
        }

        return false;
    }
};

const LoadFromAccumulatorDirect = struct {
    // Opcode - 0b11101010
    // LD (nn), A
    // Load to the absolute address specified by the 16-bit operand nn, data from the 8-bit A register
    var addr: u16 = 0;
    var z: u8 = 0;

    pub fn execute(cpu: *CPU()) bool {
        switch (cpu.machine_cycle) {
            1 => {
                // This is just the fetch cycle which is done at the CPU level
            },
            2 => {
                // Lowest 8 bits
                addr = cpu.mmu.getMemory(cpu.register_file.program_counter);
                cpu.register_file.program_counter += 1;
            },
            3 => {
                // Highest 8 bits
                addr |= @as(u16, @intCast(cpu.mmu.getMemory(cpu.register_file.program_counter))) << 8;
                cpu.register_file.program_counter += 1;
            },
            4 => {
                cpu.mmu.setMemory(addr, cpu.register_file.accumulator);
            },
            5 => {
                // Done with opcode
                return true;
            },
            else => {},
        }

        return false;
    }
};

const LoadAccumulatorIndirectC = struct {
    // Opcode - 0b11110010
    // LDH A, (C)
    // Load to the 8-bit A register, data from the address specified by the 8-bit C register. The full
    // 16-bit absolute address is obtained by setting the most significant byte to 0xFF and the least
    // significant byte to the value of C, so the possible range is 0xFF00-0xFFFF
    var z: u8 = 0;

    pub fn execute(cpu: *CPU()) bool {
        switch (cpu.machine_cycle) {
            1 => {
                // This is just the fetch cycle which is done at the CPU level
            },
            2 => {
                const addr: u16 = 0xFF00 | cpu.register_file.register_bc;
                z = cpu.mmu.getMemory(addr);
            },
            3 => {
                cpu.register_file.accumulator = z;

                // Done with opcode
                return true;
            },
            else => {},
        }

        return false;
    }
};

const LoadFromAccumulatorIndirectC = struct {
    // Opcode - 0b11100010
    // LDH (C), A
    // Load to the address specified by the 8-bit C register, data from the 8-bit A register. The full
    // 16-bit absolute address is obtained by setting the most significant byte to 0xFF and the least
    // significant byte to the value of C, so the possible range is 0xFF00-0xFFFF
    pub fn execute(cpu: *CPU()) bool {
        switch (cpu.machine_cycle) {
            1 => {
                // This is just the fetch cycle which is done at the CPU level
            },
            2 => {
                const addr: u16 = 0xFF00 | cpu.register_file.register_bc;
                cpu.mmu.setMemory(addr, cpu.register_file.accumulator);
            },
            3 => {
                // Done with opcode
                return true;
            },
            else => {},
        }

        return false;
    }
};

const LoadAccumulatorDirectN = struct {
    // Opcode - 0b11110000
    // LDH (n), A
    // Load to the address specified by the 8-bit immediate data n, data from the 8-bit A register. The
    // full 16-bit absolute address is obtained by setting the most significant byte to 0xFF and the
    // least significant byte to the value of n, so the possible range is 0xFF00-0xFFFF
    var z: u8 = 0;

    pub fn execute(cpu: *CPU()) bool {
        switch (cpu.machine_cycle) {
            1 => {
                // This is just the fetch cycle which is done at the CPU level
            },
            2 => {
                z = cpu.mmu.getMemory(cpu.register_file.program_counter);
                cpu.register_file.program_counter += 1;
            },
            3 => {
                const addr: u16 = 0xFF00 | @as(u16, @intCast(z));
                z = cpu.mmu.getMemory(addr);
            },
            4 => {
                cpu.register_file.accumulator = z;

                // Done with opcode
                return true;
            },
            else => {},
        }

        return false;
    }
};

const LoadFromAccumulatorDirectN = struct {
    // Opcode - 0b11100000
    // LDH A, (n)
    // Load to the 8-bit A register, data from the address specified by the 8-bit immediate data n. The
    // full 16-bit absolute address is obtained by setting the most significant byte to 0xFF and the
    // least significant byte to the value of n, so the possible range is 0xFF00-0xFFFF
    var z: u8 = 0;

    pub fn execute(cpu: *CPU()) bool {
        switch (cpu.machine_cycle) {
            1 => {
                // This is just the fetch cycle which is done at the CPU level
            },
            2 => {
                z = cpu.mmu.getMemory(cpu.register_file.program_counter);
                cpu.register_file.program_counter += 1;
            },
            3 => {
                const addr: u16 = 0xFF00 | @as(u16, @intCast(z));
                cpu.mmu.setMemory(addr, cpu.register_file.accumulator);
            },
            4 => {
                // Done with opcode
                return true;
            },
            else => {},
        }

        return false;
    }
};

const LoadAccumulatorIndirectHLDecrement = struct {
    // Opcode - 0b00111010
    // LD A, (HL-)
    // Load to the 8-bit A register, data from the absolute address specified by the 16-bit register HL.
    // The value of HL is decremented after the memory read
    var z: u8 = 0;

    pub fn execute(cpu: *CPU()) bool {
        switch (cpu.machine_cycle) {
            1 => {
                // This is just the fetch cycle which is done at the CPU level
            },
            2 => {
                z = cpu.mmu.getMemory(cpu.register_file.register_hl);
                cpu.register_file.register_hl -= 1;
            },
            3 => {
                cpu.register_file.accumulator = z;

                // Done with opcode
                return true;
            },
            else => {},
        }

        return false;
    }
};

const LoadFromAccumulatorIndirectHLDecrement = struct {
    // Opcode - 0b00110010
    // LD (HL-), A
    // Load to the absolute address specified by the 16-bit register HL, data from the 8-bit A register.
    // The value of HL is decremented after the memory write

    pub fn execute(cpu: *CPU()) bool {
        switch (cpu.machine_cycle) {
            1 => {
                // This is just the fetch cycle which is done at the CPU level
            },
            2 => {
                cpu.mmu.setMemory(cpu.register_file.register_hl, cpu.register_file.accumulator);
                cpu.register_file.register_hl -= 1;
            },
            3 => {
                // Done with opcode
                return true;
            },
            else => {},
        }

        return false;
    }
};

const LoadAccumulatorIndirectHLIncrement = struct {
    // Opcode - 0b00101010
    // LD A, (HL+)
    // Load to the 8-bit A register, data from the absolute address specified by the 16-bit register HL.
    // The value of HL is incremented after the memory read
    var z: u8 = 0;

    pub fn execute(cpu: *CPU()) bool {
        switch (cpu.machine_cycle) {
            1 => {
                // This is just the fetch cycle which is done at the CPU level
            },
            2 => {
                z = cpu.mmu.getMemory(cpu.register_file.register_hl);
                cpu.register_file.register_hl += 1;
            },
            3 => {
                cpu.register_file.accumulator = z;

                // Done with opcode
                return true;
            },
            else => {},
        }

        return false;
    }
};

const LoadFromAccumulatorIndirectHLIncrement = struct {
    // Opcode - 0b00100010
    // LD (HL+), A
    // Load to the absolute address specified by the 16-bit register HL, data from the 8-bit A register.
    // The value of HL is incremented after the memory write

    pub fn execute(cpu: *CPU()) bool {
        switch (cpu.machine_cycle) {
            1 => {
                // This is just the fetch cycle which is done at the CPU level
            },
            2 => {
                cpu.mmu.setMemory(cpu.register_file.register_hl, cpu.register_file.accumulator);
                cpu.register_file.register_hl += 1;
            },
            3 => {
                // Done with opcode
                return true;
            },
            else => {},
        }

        return false;
    }
};

// 16-bit load instructions
const LoadRegisterPair = struct {
    // Opcode - 0b00xx0001
    // LD rr, nn
    // Load to the 16-bit register rr, the immediate 16-bit data nn
    var z: u16 = 0;

    pub fn execute(cpu: *CPU()) bool {
        switch (cpu.machine_cycle) {
            1 => {
                // This is just the fetch cycle which is done at the CPU level
            },
            2 => {
                // Lowest 8 bits
                z = cpu.mmu.getMemory(cpu.register_file.program_counter);
                cpu.register_file.program_counter += 1;
            },
            3 => {
                // Highest 8 bits
                z |= @as(u16, @intCast(cpu.mmu.getMemory(cpu.register_file.program_counter))) << 8;
                cpu.register_file.program_counter += 1;
            },
            4 => {
                const r: u2 = @truncate(cpu.register_file.register_ir >> 4); // Extract bits 4-5
                switch (r) {
                    // BC
                    0 => cpu.register_file.register_bc = z,
                    //DE
                    1 => cpu.register_file.register_de = z,
                    // HL
                    2 => cpu.register_file.register_hl = z,
                    // SP
                    3 => cpu.register_file.stack_pointer = z,
                }

                // Done with opcode
                return true;
            },
            else => {},
        }

        return false;
    }
};

const LoadFromStackPointer = struct {
    // Opcode - 0b00001000
    // LD (nn), SP
    // Load to the absolute address specified by the 16-bit operand nn, data from the 16-bit SP register
    var addr: u16 = 0;

    pub fn execute(cpu: *CPU()) bool {
        switch (cpu.machine_cycle) {
            1 => {
                // This is just the fetch cycle which is done at the CPU level
            },
            2 => {
                // Lowest 8 bits
                addr = cpu.mmu.getMemory(cpu.register_file.program_counter);
                cpu.register_file.program_counter += 1;
            },
            3 => {
                // Highest 8 bits
                addr |= @as(u16, @intCast(cpu.mmu.getMemory(cpu.register_file.program_counter))) << 8;
                cpu.register_file.program_counter += 1;
            },
            4 => {
                const val: u8 = @truncate(cpu.register_file.stack_pointer);
                cpu.mmu.setMemory(addr, val);
                addr += 1;
            },
            5 => {
                const val: u8 = @truncate(cpu.register_file.stack_pointer >> 8);
                cpu.mmu.setMemory(addr, val);
            },
            6 => {
                // Done with opcode
                return true;
            },
            else => {},
        }

        return false;
    }
};

const LoadStackPointerFromHL = struct {
    // Opcode - 0b11111001
    // LD SP, HL
    // Load to the 16-bit SP register, data from the 16-bit HL register

    pub fn execute(cpu: *CPU()) bool {
        switch (cpu.machine_cycle) {
            1 => {
                // This is just the fetch cycle which is done at the CPU level
            },
            2 => {
                cpu.register_file.stack_pointer = cpu.register_file.register_hl;
            },
            3 => {
                // Done with opcode
                return true;
            },
            else => {},
        }

        return false;
    }
};

const PushStack = struct {
    // Opcode - 0b11xx0101
    // PUSH rr
    // Push to the stack memory, data from the 16-bit register rr
    var addr: u16 = 0;

    pub fn execute(cpu: *CPU()) bool {
        switch (cpu.machine_cycle) {
            1 => {
                // This is just the fetch cycle which is done at the CPU level
            },
            2 => {
                cpu.register_file.stack_pointer -= 1;
            },
            3 => {
                const r: u2 = @truncate(cpu.register_file.register_ir >> 4); // Extract bits 4-5
                const val: u8 = switch (r) {
                    // BC
                    0 => @truncate(cpu.register_file.register_bc >> 8),
                    //DE
                    1 => @truncate(cpu.register_file.register_de >> 8),
                    // HL
                    2 => @truncate(cpu.register_file.register_hl >> 8),
                    // SP
                    3 => @truncate(cpu.register_file.stack_pointer >> 8),
                };

                cpu.mmu.setMemory(cpu.register_file.stack_pointer, val);
                cpu.register_file.stack_pointer -= 1;
            },
            4 => {
                const r: u2 = @truncate(cpu.register_file.register_ir >> 4); // Extract bits 4-5
                const val: u8 = switch (r) {
                    // BC
                    0 => @truncate(cpu.register_file.register_bc),
                    //DE
                    1 => @truncate(cpu.register_file.register_de),
                    // HL
                    2 => @truncate(cpu.register_file.register_hl),
                    // SP
                    3 => @truncate(cpu.register_file.stack_pointer),
                };

                cpu.mmu.setMemory(cpu.register_file.stack_pointer, val);
            },
            5 => {
                // Done with opcode
                return true;
            },
            else => {},
        }

        return false;
    }
};

const PopStack = struct {
    // Opcode - 0b11xx0001
    // POP rr
    // Pops to the 16-bit register rr, data from the stack memory
    var z: u16 = 0;

    pub fn execute(cpu: *CPU()) bool {
        switch (cpu.machine_cycle) {
            1 => {
                // This is just the fetch cycle which is done at the CPU level
            },
            2 => {
                // Lowest 8 bits
                z = cpu.mmu.getMemory(cpu.register_file.stack_pointer);
                cpu.register_file.stack_pointer += 1;
            },
            3 => {
                // Highest 8 bits
                z |= @as(u16, @intCast(cpu.mmu.getMemory(cpu.register_file.stack_pointer))) << 8;
                cpu.register_file.stack_pointer += 1;
            },
            4 => {
                const r: u2 = @truncate(cpu.register_file.register_ir >> 4); // Extract bits 4-5
                switch (r) {
                    // BC
                    0 => cpu.register_file.register_bc = z,
                    //DE
                    1 => cpu.register_file.register_de = z,
                    // HL
                    2 => cpu.register_file.register_hl = z,
                    // SP
                    3 => cpu.register_file.stack_pointer = z,
                }

                return true;
            },
            else => {},
        }

        return false;
    }
};

const LoadFromAdjustedStackPointer = struct {
    // Opcode - 0b11111000
    // LD HL, SP+e
    // Load to the HL register, 16-bit data calculated by adding the signed 8-bit operand e to the 16-
    // bit value of the SP register
    var z: u8 = 0;

    pub fn execute(cpu: *CPU()) bool {
        switch (cpu.machine_cycle) {
            1 => {
                // This is just the fetch cycle which is done at the CPU level
            },
            2 => {
                // Read as unsigned int
                z = cpu.mmu.getMemory(cpu.register_file.program_counter);
                cpu.register_file.program_counter += 1;
            },
            3 => {
                const lsb: u8 = @truncate(cpu.register_file.stack_pointer);
                const val = @addWithOverflow(lsb, z);

                cpu.register_file.set_value(5, val[0]); // L register

                // Calculate carry bits
                const half_carry = @addWithOverflow(@as(u4, @truncate(lsb)), @as(u4, @truncate(z)))[1];
                const full_carry = val[1];

                cpu.register_file.flags = (cpu.register_file.flags & 0b11000000) | (@as(u8, @intCast(half_carry)) << 5) | (@as(u8, @intCast(full_carry)) << 4);
            },
            4 => {
                const z_sign = (z & 0b10000000) == 0b10000000;
                const adj: u8 = if (z_sign) 0xFF else 0x00;
                const msb: u8 = @truncate(cpu.register_file.stack_pointer >> 8);
                const full_carry: u1 = @truncate(cpu.register_file.flags >> 4);

                // Zig discards overflow by default which is the desired behavior here
                const val: u8 = msb + adj + full_carry;
                cpu.register_file.set_value(4, val); // H register

                // Done with opcode
                return true;
            },
            else => {},
        }

        return false;
    }
};

// Misc Instructions
const NOP = struct {
    // Opcode - 0b00000000
    // No operation

    pub fn execute(cpu: *CPU()) bool {
        switch (cpu.machine_cycle) {
            1 => {
                // This is just the fetch cycle which is done at the CPU level
            },
            2 => {
                // Done with opcode
                return true;
            },
            else => {},
        }

        return false;
    }
};
