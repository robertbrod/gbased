const std = @import("std");

const CPU = @import("cpu.zig").SM83CPU;

const RegisterFile = @import("register_file.zig").RegisterFile;
const RegisterFlag = @import("register_file.zig").RegisterFlag;

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

                // 8-bit arithmetic and logical instructions
                0x80...0x85 => AddRegister.execute(cpu),
                0x87 => AddRegister.execute(cpu),
                0x86 => AddIndirectHL.execute(cpu),
                0xC6 => AddImmediate.execute(cpu),

                0x88...0x8D => AddWithCarry.execute(cpu),
                0x8F => AddWithCarry.execute(cpu),
                0x8E => AddWithCarryIndirectHL.execute(cpu),
                0xCE => AddWithCarryImmediate.execute(cpu),

                0x90...0x95 => SubRegister.execute(cpu),
                0x97 => SubRegister.execute(cpu),
                0x96 => SubIndirectHL.execute(cpu),
                0xD6 => SubImmediate.execute(cpu),

                0x98...0x9D => SubWithCarry.execute(cpu),
                0x9F => SubWithCarry.execute(cpu),
                0x9E => SubWithCarryIndirectHL.execute(cpu),
                0xDE => SubWithCarryImmediate.execute(cpu),

                0xB8...0xBD => CompareRegister.execute(cpu),
                0xBF => CompareRegister.execute(cpu),
                0xBE => CompareIndirectHL.execute(cpu),
                0xFE => CompareImmediate.execute(cpu),

                0x04 => IncrementRegister.execute(cpu),
                0x0C => IncrementRegister.execute(cpu),
                0x14 => IncrementRegister.execute(cpu),
                0x1C => IncrementRegister.execute(cpu),
                0x24 => IncrementRegister.execute(cpu),
                0x2C => IncrementRegister.execute(cpu),
                0x3C => IncrementRegister.execute(cpu),
                0x34 => IncrementIndirectHL.execute(cpu),

                0x05 => DecrementRegister.execute(cpu),
                0x0D => DecrementRegister.execute(cpu),
                0x15 => DecrementRegister.execute(cpu),
                0x1D => DecrementRegister.execute(cpu),
                0x25 => DecrementRegister.execute(cpu),
                0x2D => DecrementRegister.execute(cpu),
                0x3D => DecrementRegister.execute(cpu),
                0x35 => DecrementIndirectHL.execute(cpu),

                0xA0...0xA5 => AndRegister.execute(cpu),
                0xA7 => AndRegister.execute(cpu),
                0xA6 => AndRegisterIndirectHL.execute(cpu),
                0xE6 => AndRegisterImmediate.execute(cpu),

                0xB0...0xB5 => OrRegister.execute(cpu),
                0xB7 => OrRegister.execute(cpu),
                0xB6 => OrRegisterIndirectHL.execute(cpu),
                0xF6 => OrRegisterImmediate.execute(cpu),

                0xA8...0xAD => XorRegister.execute(cpu),
                0xAF => XorRegister.execute(cpu),
                0xAE => XorRegisterIndirectHL.execute(cpu),
                0xEE => XorRegisterImmediate.execute(cpu),

                0x3F => ComplementCarryFlag.execute(cpu),
                0x37 => SetCarryFlag.execute(cpu),

                0x27 => DecimalAdjustAccumulator.execute(cpu),
                0x2F => ComplementAccumulator.execute(cpu),

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

                // Done with opcode
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

// 8-bit arithmetic and logical instructions
const AddRegister = struct {
    // Opcode - 0b10000xxx
    // ADD r
    // Adds to the 8-bit A register, the 8-bit register r, and stores the result back into the A register
    pub fn execute(cpu: *CPU()) bool {
        switch (cpu.machine_cycle) {
            1 => {
                // This is just the fetch cycle which is done at the CPU level
            },
            2 => {
                const r: u3 = @truncate(cpu.register_file.register_ir); // Extract bits 0-2
                const z = cpu.register_file.get_value(r);
                const a = cpu.register_file.get_value(7); // accumulator

                // Calculate
                const val = @addWithOverflow(a, z);
                const half_carry = @addWithOverflow(@as(u4, @truncate(a)), @as(u4, @truncate(z)))[1];
                const full_carry = val[1];

                // Set result
                cpu.register_file.set_value(7, val[0]); // accumulator

                // Set flags
                cpu.register_file.set_flag(RegisterFlag.Zero, if (val[0] == 0) 0b1 else 0b0);
                cpu.register_file.set_flag(RegisterFlag.Subtract, 0);
                cpu.register_file.set_flag(RegisterFlag.HalfCarry, half_carry);
                cpu.register_file.set_flag(RegisterFlag.Carry, full_carry);

                // Done with opcode
                return true;
            },
            else => {},
        }

        return false;
    }
};

const AddIndirectHL = struct {
    // Opcode - 0b10000110
    // ADD (HL)
    // Adds to the 8-bit A register, data from the absolute address specified by the 16-bit register HL,
    // and stores the result back into the A register
    var z: u8 = 0;

    pub fn execute(cpu: *CPU()) bool {
        switch (cpu.machine_cycle) {
            1 => {
                // This is just the fetch cycle which is done at the CPU level
            },
            2 => {
                // Load value from HL
                z = cpu.mmu.getMemory(cpu.register_file.register_hl);
            },
            3 => {
                const a = cpu.register_file.get_value(7); // accumulator

                // Calculate
                const val = @addWithOverflow(a, z);
                const half_carry = @addWithOverflow(@as(u4, @truncate(a)), @as(u4, @truncate(z)))[1];
                const full_carry = val[1];

                // Set result
                cpu.register_file.set_value(7, val[0]); // accumulator

                // Set flags
                cpu.register_file.set_flag(RegisterFlag.Zero, if (val[0] == 0) 0b1 else 0b0);
                cpu.register_file.set_flag(RegisterFlag.Subtract, 0);
                cpu.register_file.set_flag(RegisterFlag.HalfCarry, half_carry);
                cpu.register_file.set_flag(RegisterFlag.Carry, full_carry);

                // Done with opcode
                return true;
            },
            else => {},
        }

        return false;
    }
};

const AddImmediate = struct {
    // Opcode - 0b11000110
    // ADD n
    // Adds to the 8-bit A register, the immediate data n, and stores the result back into the A register
    var z: u8 = 0;

    pub fn execute(cpu: *CPU()) bool {
        switch (cpu.machine_cycle) {
            1 => {
                // This is just the fetch cycle which is done at the CPU level
            },
            2 => {
                // Load value from immediate data
                z = cpu.mmu.getMemory(cpu.register_file.program_counter);
                cpu.register_file.program_counter += 1;
            },
            3 => {
                const a = cpu.register_file.get_value(7); // accumulator

                // Calculate
                const val = @addWithOverflow(a, z);
                const half_carry = @addWithOverflow(@as(u4, @truncate(a)), @as(u4, @truncate(z)))[1];
                const full_carry = val[1];

                // Set result
                cpu.register_file.set_value(7, val[0]); // accumulator

                // Set flags
                cpu.register_file.set_flag(RegisterFlag.Zero, if (val[0] == 0) 0b1 else 0b0);
                cpu.register_file.set_flag(RegisterFlag.Subtract, 0);
                cpu.register_file.set_flag(RegisterFlag.HalfCarry, half_carry);
                cpu.register_file.set_flag(RegisterFlag.Carry, full_carry);

                // Done with opcode
                return true;
            },
            else => {},
        }

        return false;
    }
};

const AddWithCarry = struct {
    // Opcode - 0b10001xxx
    // ADC r
    // Adds to the 8-bit A register, the carry flag and the 8-bit register r, and stores the result back
    // into the A register
    pub fn execute(cpu: *CPU()) bool {
        switch (cpu.machine_cycle) {
            1 => {
                // This is just the fetch cycle which is done at the CPU level
            },
            2 => {
                const r: u3 = @truncate(cpu.register_file.register_ir); // Extract bits 0-2
                const z = cpu.register_file.get_value(r);
                const a = cpu.register_file.get_value(7); // accumulator
                const c = cpu.register_file.get_flag(RegisterFlag.Carry);

                // Calculate
                var half_val = @addWithOverflow(@as(u4, @truncate(a)), @as(u4, @truncate(z)));
                var val = @addWithOverflow(a, z);
                var half_carry = half_val[1];
                var full_carry = val[1];

                val = @addWithOverflow(val[0], c);
                half_val = @addWithOverflow(half_val[0], c);
                half_carry = half_carry | half_val[1];
                full_carry = full_carry | val[1];

                // Set result
                cpu.register_file.set_value(7, val[0]); // accumulator

                // Set flags
                cpu.register_file.set_flag(RegisterFlag.Zero, if (val[0] == 0) 0b1 else 0b0);
                cpu.register_file.set_flag(RegisterFlag.Subtract, 0);
                cpu.register_file.set_flag(RegisterFlag.HalfCarry, half_carry);
                cpu.register_file.set_flag(RegisterFlag.Carry, full_carry);

                // Done with opcode
                return true;
            },
            else => {},
        }

        return false;
    }
};

const AddWithCarryIndirectHL = struct {
    // Opcode - 0b10001110
    // ADC (HL)
    // Adds to the 8-bit A register, the carry flag and data from the absolute address specified by the
    // 16-bit register HL, and stores the result back into the A register
    var z: u8 = 0;

    pub fn execute(cpu: *CPU()) bool {
        switch (cpu.machine_cycle) {
            1 => {
                // This is just the fetch cycle which is done at the CPU level
            },
            2 => {
                // Load value from HL
                z = cpu.mmu.getMemory(cpu.register_file.register_hl);
            },
            3 => {
                const a = cpu.register_file.get_value(7); // accumulator
                const c = cpu.register_file.get_flag(RegisterFlag.Carry);

                // Calculate
                var half_val = @addWithOverflow(@as(u4, @truncate(a)), @as(u4, @truncate(z)));
                var val = @addWithOverflow(a, z);
                var half_carry = half_val[1];
                var full_carry = val[1];

                val = @addWithOverflow(val[0], c);
                half_val = @addWithOverflow(half_val[0], c);
                half_carry = half_carry | half_val[1];
                full_carry = full_carry | val[1];

                // Set result
                cpu.register_file.set_value(7, val[0]); // accumulator

                // Set flags
                cpu.register_file.set_flag(RegisterFlag.Zero, if (val[0] == 0) 0b1 else 0b0);
                cpu.register_file.set_flag(RegisterFlag.Subtract, 0);
                cpu.register_file.set_flag(RegisterFlag.HalfCarry, half_carry);
                cpu.register_file.set_flag(RegisterFlag.Carry, full_carry);

                // Done with opcode
                return true;
            },
            else => {},
        }

        return false;
    }
};

const AddWithCarryImmediate = struct {
    // Opcode - 0b11001110
    // ADC n
    // Adds to the 8-bit A register, the carry flag and the immediate data n, and stores the result back
    // into the A register
    var z: u8 = 0;

    pub fn execute(cpu: *CPU()) bool {
        switch (cpu.machine_cycle) {
            1 => {
                // This is just the fetch cycle which is done at the CPU level
            },
            2 => {
                // Load value from immediate data
                z = cpu.mmu.getMemory(cpu.register_file.program_counter);
                cpu.register_file.program_counter += 1;
            },
            3 => {
                const a = cpu.register_file.get_value(7); // accumulator
                const c = cpu.register_file.get_flag(RegisterFlag.Carry);

                // Calculate
                var half_val = @addWithOverflow(@as(u4, @truncate(a)), @as(u4, @truncate(z)));
                var val = @addWithOverflow(a, z);
                var half_carry = half_val[1];
                var full_carry = val[1];

                val = @addWithOverflow(val[0], c);
                half_val = @addWithOverflow(half_val[0], c);
                half_carry = half_carry | half_val[1];
                full_carry = full_carry | val[1];

                // Set result
                cpu.register_file.set_value(7, val[0]); // accumulator

                // Set flags
                cpu.register_file.set_flag(RegisterFlag.Zero, if (val[0] == 0) 0b1 else 0b0);
                cpu.register_file.set_flag(RegisterFlag.Subtract, 0);
                cpu.register_file.set_flag(RegisterFlag.HalfCarry, half_carry);
                cpu.register_file.set_flag(RegisterFlag.Carry, full_carry);

                // Done with opcode
                return true;
            },
            else => {},
        }

        return false;
    }
};

const SubRegister = struct {
    // Opcode - 0b10010xxx
    // SUB r
    // Subtracts from the 8-bit A register, the 8-bit register r, and stores the result back into the A
    // register
    pub fn execute(cpu: *CPU()) bool {
        switch (cpu.machine_cycle) {
            1 => {
                // This is just the fetch cycle which is done at the CPU level
            },
            2 => {
                const r: u3 = @truncate(cpu.register_file.register_ir); // Extract bits 0-2
                const z = cpu.register_file.get_value(r);
                const a = cpu.register_file.get_value(7); // accumulator

                // Calculate
                const val = @subWithOverflow(a, z);
                const half_carry = @subWithOverflow(@as(u4, @truncate(a)), @as(u4, @truncate(z)))[1];
                const full_carry = val[1];

                // Set result
                cpu.register_file.set_value(7, val[0]); // accumulator

                // Set flags
                cpu.register_file.set_flag(RegisterFlag.Zero, if (val[0] == 0) 0b1 else 0b0);
                cpu.register_file.set_flag(RegisterFlag.Subtract, 1);
                cpu.register_file.set_flag(RegisterFlag.HalfCarry, half_carry);
                cpu.register_file.set_flag(RegisterFlag.Carry, full_carry);

                // Done with opcode
                return true;
            },
            else => {},
        }

        return false;
    }
};

const SubIndirectHL = struct {
    // Opcode - 0b10010110
    // SUB (HL)
    // Subtracts from the 8-bit A register, data from the absolute address specified by the 16-bit
    // register HL, and stores the result back into the A register
    var z: u8 = 0;

    pub fn execute(cpu: *CPU()) bool {
        switch (cpu.machine_cycle) {
            1 => {
                // This is just the fetch cycle which is done at the CPU level
            },
            2 => {
                // Load value from HL
                z = cpu.mmu.getMemory(cpu.register_file.register_hl);
            },
            3 => {
                const a = cpu.register_file.get_value(7); // accumulator

                // Calculate
                const val = @subWithOverflow(a, z);
                const half_carry = @subWithOverflow(@as(u4, @truncate(a)), @as(u4, @truncate(z)))[1];
                const full_carry = val[1];

                // Set result
                cpu.register_file.set_value(7, val[0]); // accumulator

                // Set flags
                cpu.register_file.set_flag(RegisterFlag.Zero, if (val[0] == 0) 0b1 else 0b0);
                cpu.register_file.set_flag(RegisterFlag.Subtract, 1);
                cpu.register_file.set_flag(RegisterFlag.HalfCarry, half_carry);
                cpu.register_file.set_flag(RegisterFlag.Carry, full_carry);

                // Done with opcode
                return true;
            },
            else => {},
        }

        return false;
    }
};

const SubImmediate = struct {
    // Opcode - 0b11010110
    // SUB n
    // Subtracts from the 8-bit A register, the immediate data n, and stores the result back into the A
    // register
    var z: u8 = 0;

    pub fn execute(cpu: *CPU()) bool {
        switch (cpu.machine_cycle) {
            1 => {
                // This is just the fetch cycle which is done at the CPU level
            },
            2 => {
                // Load value from immediate data
                z = cpu.mmu.getMemory(cpu.register_file.program_counter);
                cpu.register_file.program_counter += 1;
            },
            3 => {
                const a = cpu.register_file.get_value(7); // accumulator

                // Calculate
                const val = @subWithOverflow(a, z);
                const half_carry = @subWithOverflow(@as(u4, @truncate(a)), @as(u4, @truncate(z)))[1];
                const full_carry = val[1];

                // Set result
                cpu.register_file.set_value(7, val[0]); // accumulator

                // Set flags
                cpu.register_file.set_flag(RegisterFlag.Zero, if (val[0] == 0) 0b1 else 0b0);
                cpu.register_file.set_flag(RegisterFlag.Subtract, 1);
                cpu.register_file.set_flag(RegisterFlag.HalfCarry, half_carry);
                cpu.register_file.set_flag(RegisterFlag.Carry, full_carry);

                // Done with opcode
                return true;
            },
            else => {},
        }

        return false;
    }
};

const SubWithCarry = struct {
    // Opcode - 0b10011xxx
    // SBC r
    // Subtracts from the 8-bit A register, the carry flag and the 8-bit register r, and stores the result
    // back into the A register
    pub fn execute(cpu: *CPU()) bool {
        switch (cpu.machine_cycle) {
            1 => {
                // This is just the fetch cycle which is done at the CPU level
            },
            2 => {
                const r: u3 = @truncate(cpu.register_file.register_ir); // Extract bits 0-2
                const z = cpu.register_file.get_value(r);
                const a = cpu.register_file.get_value(7); // accumulator
                const c = cpu.register_file.get_flag(RegisterFlag.Carry);

                // Calculate
                var half_val = @subWithOverflow(@as(u4, @truncate(a)), @as(u4, @truncate(z)));
                var val = @subWithOverflow(a, z);
                var half_carry = half_val[1];
                var full_carry = val[1];

                val = @subWithOverflow(val[0], c);
                half_val = @subWithOverflow(half_val[0], c);
                half_carry = half_carry | half_val[1];
                full_carry = full_carry | val[1];

                // Set result
                cpu.register_file.set_value(7, val[0]); // accumulator

                // Set flags
                cpu.register_file.set_flag(RegisterFlag.Zero, if (val[0] == 0) 0b1 else 0b0);
                cpu.register_file.set_flag(RegisterFlag.Subtract, 1);
                cpu.register_file.set_flag(RegisterFlag.HalfCarry, half_carry);
                cpu.register_file.set_flag(RegisterFlag.Carry, full_carry);

                // Done with opcode
                return true;
            },
            else => {},
        }

        return false;
    }
};

const SubWithCarryIndirectHL = struct {
    // Opcode - 0b10011110
    // SBC (HL)
    // Subtracts from the 8-bit A register, the carry flag and data from the absolute address specified
    // by the 16-bit register HL, and stores the result back into the A register
    var z: u8 = 0;

    pub fn execute(cpu: *CPU()) bool {
        switch (cpu.machine_cycle) {
            1 => {
                // This is just the fetch cycle which is done at the CPU level
            },
            2 => {
                // Load value from HL
                z = cpu.mmu.getMemory(cpu.register_file.register_hl);
            },
            3 => {
                const a = cpu.register_file.get_value(7); // accumulator
                const c = cpu.register_file.get_flag(RegisterFlag.Carry);

                // Calculate
                var half_val = @subWithOverflow(@as(u4, @truncate(a)), @as(u4, @truncate(z)));
                var val = @subWithOverflow(a, z);
                var half_carry = half_val[1];
                var full_carry = val[1];

                val = @subWithOverflow(val[0], c);
                half_val = @subWithOverflow(half_val[0], c);
                half_carry = half_carry | half_val[1];
                full_carry = full_carry | val[1];

                // Set result
                cpu.register_file.set_value(7, val[0]); // accumulator

                // Set flags
                cpu.register_file.set_flag(RegisterFlag.Zero, if (val[0] == 0) 0b1 else 0b0);
                cpu.register_file.set_flag(RegisterFlag.Subtract, 1);
                cpu.register_file.set_flag(RegisterFlag.HalfCarry, half_carry);
                cpu.register_file.set_flag(RegisterFlag.Carry, full_carry);

                // Done with opcode
                return true;
            },
            else => {},
        }

        return false;
    }
};

const SubWithCarryImmediate = struct {
    // Opcode - 0b11011110
    // SBC n
    // Subtracts from the 8-bit A register, the carry flag and the immediate data n, and stores the
    // result back into the A register
    var z: u8 = 0;

    pub fn execute(cpu: *CPU()) bool {
        switch (cpu.machine_cycle) {
            1 => {
                // This is just the fetch cycle which is done at the CPU level
            },
            2 => {
                // Load value from immediate data
                z = cpu.mmu.getMemory(cpu.register_file.program_counter);
                cpu.register_file.program_counter += 1;
            },
            3 => {
                const a = cpu.register_file.get_value(7); // accumulator
                const c = cpu.register_file.get_flag(RegisterFlag.Carry);

                // Calculate
                var half_val = @subWithOverflow(@as(u4, @truncate(a)), @as(u4, @truncate(z)));
                var val = @subWithOverflow(a, z);
                var half_carry = half_val[1];
                var full_carry = val[1];

                val = @subWithOverflow(val[0], c);
                half_val = @subWithOverflow(half_val[0], c);
                half_carry = half_carry | half_val[1];
                full_carry = full_carry | val[1];

                // Set result
                cpu.register_file.set_value(7, val[0]); // accumulator

                // Set flags
                cpu.register_file.set_flag(RegisterFlag.Zero, if (val[0] == 0) 0b1 else 0b0);
                cpu.register_file.set_flag(RegisterFlag.Subtract, 1);
                cpu.register_file.set_flag(RegisterFlag.HalfCarry, half_carry);
                cpu.register_file.set_flag(RegisterFlag.Carry, full_carry);

                // Done with opcode
                return true;
            },
            else => {},
        }

        return false;
    }
};

const CompareRegister = struct {
    // Opcode - 0b10111xxx
    // CP r
    // Subtracts from the 8-bit A register, the 8-bit register r, and updates flags based on the result.
    // This instruction is basically identical to SUB r, but does not update the A register
    pub fn execute(cpu: *CPU()) bool {
        switch (cpu.machine_cycle) {
            1 => {
                // This is just the fetch cycle which is done at the CPU level
            },
            2 => {
                const r: u3 = @truncate(cpu.register_file.register_ir); // Extract bits 0-2
                const z = cpu.register_file.get_value(r);
                const a = cpu.register_file.get_value(7); // accumulator

                // Calculate
                const val = @subWithOverflow(a, z);
                const half_carry = @subWithOverflow(@as(u4, @truncate(a)), @as(u4, @truncate(z)))[1];
                const full_carry = val[1];

                // Set flags
                cpu.register_file.set_flag(RegisterFlag.Zero, if (val[0] == 0) 0b1 else 0b0);
                cpu.register_file.set_flag(RegisterFlag.Subtract, 1);
                cpu.register_file.set_flag(RegisterFlag.HalfCarry, half_carry);
                cpu.register_file.set_flag(RegisterFlag.Carry, full_carry);

                // Done with opcode
                return true;
            },
            else => {},
        }

        return false;
    }
};

const CompareIndirectHL = struct {
    // Opcode - 0b10111110
    // CP (HL)
    // Subtracts from the 8-bit A register, data from the absolute address specified by the 16-bit
    // register HL, and updates flags based on the result. This instruction is basically identical to SUB
    // (HL), but does not update the A register
    var z: u8 = 0;

    pub fn execute(cpu: *CPU()) bool {
        switch (cpu.machine_cycle) {
            1 => {
                // This is just the fetch cycle which is done at the CPU level
            },
            2 => {
                // Load value from HL
                z = cpu.mmu.getMemory(cpu.register_file.register_hl);
            },
            3 => {
                const a = cpu.register_file.get_value(7); // accumulator

                // Calculate
                const val = @subWithOverflow(a, z);
                const half_carry = @subWithOverflow(@as(u4, @truncate(a)), @as(u4, @truncate(z)))[1];
                const full_carry = val[1];

                // Set flags
                cpu.register_file.set_flag(RegisterFlag.Zero, if (val[0] == 0) 0b1 else 0b0);
                cpu.register_file.set_flag(RegisterFlag.Subtract, 1);
                cpu.register_file.set_flag(RegisterFlag.HalfCarry, half_carry);
                cpu.register_file.set_flag(RegisterFlag.Carry, full_carry);

                // Done with opcode
                return true;
            },
            else => {},
        }

        return false;
    }
};

const CompareImmediate = struct {
    // Opcode - 0b11111110
    // CP n
    // Subtracts from the 8-bit A register, the immediate data n, and updates flags based on the result.
    // This instruction is basically identical to SUB n, but does not update the A register
    var z: u8 = 0;

    pub fn execute(cpu: *CPU()) bool {
        switch (cpu.machine_cycle) {
            1 => {
                // This is just the fetch cycle which is done at the CPU level
            },
            2 => {
                // Load value from immediate data
                z = cpu.mmu.getMemory(cpu.register_file.program_counter);
                cpu.register_file.program_counter += 1;
            },
            3 => {
                const a = cpu.register_file.get_value(7); // accumulator

                // Calculate
                const val = @subWithOverflow(a, z);
                const half_carry = @subWithOverflow(@as(u4, @truncate(a)), @as(u4, @truncate(z)))[1];
                const full_carry = val[1];

                // Set flags
                cpu.register_file.set_flag(RegisterFlag.Zero, if (val[0] == 0) 0b1 else 0b0);
                cpu.register_file.set_flag(RegisterFlag.Subtract, 1);
                cpu.register_file.set_flag(RegisterFlag.HalfCarry, half_carry);
                cpu.register_file.set_flag(RegisterFlag.Carry, full_carry);

                // Done with opcode
                return true;
            },
            else => {},
        }

        return false;
    }
};

const IncrementRegister = struct {
    // Opcode - 0b00xxx100
    // INC r
    // Increments data in the 8-bit register r
    pub fn execute(cpu: *CPU()) bool {
        switch (cpu.machine_cycle) {
            1 => {
                // This is just the fetch cycle which is done at the CPU level
            },
            2 => {
                const r: u3 = @truncate(cpu.register_file.register_ir); // Extract bits 0-2
                const z = cpu.register_file.get_value(r);

                // Calculate
                const val = @addWithOverflow(z, 1);
                const half_carry = @addWithOverflow(@as(u4, @truncate(z)), 1)[1];
                const full_carry = val[1];

                // Set result
                cpu.register_file.set_value(r, val[0]);

                // Set flags
                cpu.register_file.set_flag(RegisterFlag.Zero, if (val[0] == 0) 0b1 else 0b0);
                cpu.register_file.set_flag(RegisterFlag.Subtract, 0);
                cpu.register_file.set_flag(RegisterFlag.HalfCarry, half_carry);
                cpu.register_file.set_flag(RegisterFlag.Carry, full_carry);

                // Done with opcode
                return true;
            },
            else => {},
        }

        return false;
    }
};

const IncrementIndirectHL = struct {
    // Opcode - 0b00110100
    // INC (HL)
    // Increments data at the absolute address specified by the 16-bit register HL.
    var z: u8 = 0;

    pub fn execute(cpu: *CPU()) bool {
        switch (cpu.machine_cycle) {
            1 => {
                // This is just the fetch cycle which is done at the CPU level
            },
            2 => {
                // Load value from HL
                z = cpu.mmu.getMemory(cpu.register_file.register_hl);
            },
            3 => {
                // Calculate
                const val = @addWithOverflow(z, 1);
                const half_carry = @addWithOverflow(@as(u4, @truncate(z)), 1)[1];
                const full_carry = val[1];

                // Set result
                cpu.mmu.setMemory(cpu.register_file.register_hl, val[0]);

                // Set flags
                cpu.register_file.set_flag(RegisterFlag.Zero, if (val[0] == 0) 0b1 else 0b0);
                cpu.register_file.set_flag(RegisterFlag.Subtract, 0);
                cpu.register_file.set_flag(RegisterFlag.HalfCarry, half_carry);
                cpu.register_file.set_flag(RegisterFlag.Carry, full_carry);

                // Done with opcode
                return true;
            },
            else => {},
        }

        return false;
    }
};

const DecrementRegister = struct {
    // Opcode - 0b00xxx101
    // DEC r
    // Decrements data in the 8-bit register r
    pub fn execute(cpu: *CPU()) bool {
        switch (cpu.machine_cycle) {
            1 => {
                // This is just the fetch cycle which is done at the CPU level
            },
            2 => {
                const r: u3 = @truncate(cpu.register_file.register_ir); // Extract bits 0-2
                const z = cpu.register_file.get_value(r);

                // Calculate
                const val = @subWithOverflow(z, 1);
                const half_carry = @subWithOverflow(@as(u4, @truncate(z)), 1)[1];
                const full_carry = val[1];

                // Set result
                cpu.register_file.set_value(r, val[0]);

                // Set flags
                cpu.register_file.set_flag(RegisterFlag.Zero, if (val[0] == 0) 0b1 else 0b0);
                cpu.register_file.set_flag(RegisterFlag.Subtract, 1);
                cpu.register_file.set_flag(RegisterFlag.HalfCarry, half_carry);
                cpu.register_file.set_flag(RegisterFlag.Carry, full_carry);

                // Done with opcode
                return true;
            },
            else => {},
        }

        return false;
    }
};

const DecrementIndirectHL = struct {
    // Opcode - 0b00110101
    // DEC (HL)
    // DEcrements data at the absolute address specified by the 16-bit register HL.
    var z: u8 = 0;

    pub fn execute(cpu: *CPU()) bool {
        switch (cpu.machine_cycle) {
            1 => {
                // This is just the fetch cycle which is done at the CPU level
            },
            2 => {
                // Load value from HL
                z = cpu.mmu.getMemory(cpu.register_file.register_hl);
            },
            3 => {
                // Calculate
                const val = @subWithOverflow(z, 1);
                const half_carry = @subWithOverflow(@as(u4, @truncate(z)), 1)[1];
                const full_carry = val[1];

                // Set result
                cpu.mmu.setMemory(cpu.register_file.register_hl, val[0]);

                // Set flags
                cpu.register_file.set_flag(RegisterFlag.Zero, if (val[0] == 0) 0b1 else 0b0);
                cpu.register_file.set_flag(RegisterFlag.Subtract, 1);
                cpu.register_file.set_flag(RegisterFlag.HalfCarry, half_carry);
                cpu.register_file.set_flag(RegisterFlag.Carry, full_carry);

                // Done with opcode
                return true;
            },
            else => {},
        }

        return false;
    }
};

const AndRegister = struct {
    // Opcode - 0b10100xxx
    // AND r
    // Performs a bitwise AND operation between the 8-bit A register and the 8-bit register r, and
    // stores the result back into the A register
    pub fn execute(cpu: *CPU()) bool {
        switch (cpu.machine_cycle) {
            1 => {
                // This is just the fetch cycle which is done at the CPU level
            },
            2 => {
                const r: u3 = @truncate(cpu.register_file.register_ir); // Extract bits 0-2
                const z = cpu.register_file.get_value(r);
                const a = cpu.register_file.get_value(7); // accumulator

                // Calculate
                const val = a & z;

                // Set result
                cpu.register_file.set_value(7, val); // accumulator

                // Set flags
                cpu.register_file.set_flag(RegisterFlag.Zero, if (val == 0) 0b1 else 0b0);
                cpu.register_file.set_flag(RegisterFlag.Subtract, 0);
                cpu.register_file.set_flag(RegisterFlag.HalfCarry, 1);
                cpu.register_file.set_flag(RegisterFlag.Carry, 0);

                // Done with opcode
                return true;
            },
            else => {},
        }

        return false;
    }
};

const AndRegisterIndirectHL = struct {
    // Opcode - 0b10100110
    // AND (HL)
    // Performs a bitwise AND operation between the 8-bit A register and data from the absolute
    // address specified by the 16-bit register HL, and stores the result back into the A register
    var z: u8 = 0;

    pub fn execute(cpu: *CPU()) bool {
        switch (cpu.machine_cycle) {
            1 => {
                // This is just the fetch cycle which is done at the CPU level
            },
            2 => {
                // Load value from HL
                z = cpu.mmu.getMemory(cpu.register_file.register_hl);
            },
            3 => {
                const a = cpu.register_file.get_value(7); // accumulator

                // Calculate
                const val = a & z;

                // Set result
                cpu.register_file.set_value(7, val); // accumulator

                // Set flags
                cpu.register_file.set_flag(RegisterFlag.Zero, if (val == 0) 0b1 else 0b0);
                cpu.register_file.set_flag(RegisterFlag.Subtract, 0);
                cpu.register_file.set_flag(RegisterFlag.HalfCarry, 1);
                cpu.register_file.set_flag(RegisterFlag.Carry, 0);

                // Done with opcode
                return true;
            },
            else => {},
        }

        return false;
    }
};

const AndRegisterImmediate = struct {
    // Opcode - 0b11100110
    // AND n
    // Performs a bitwise AND operation between the 8-bit A register and immediate data n, and
    // stores the result back into the A register
    var z: u8 = 0;

    pub fn execute(cpu: *CPU()) bool {
        switch (cpu.machine_cycle) {
            1 => {
                // This is just the fetch cycle which is done at the CPU level
            },
            2 => {
                // Load value from immediate data
                z = cpu.mmu.getMemory(cpu.register_file.program_counter);
                cpu.register_file.program_counter += 1;
            },
            3 => {
                const a = cpu.register_file.get_value(7); // accumulator

                // Calculate
                const val = a & z;

                // Set result
                cpu.register_file.set_value(7, val); // accumulator

                // Set flags
                cpu.register_file.set_flag(RegisterFlag.Zero, if (val == 0) 0b1 else 0b0);
                cpu.register_file.set_flag(RegisterFlag.Subtract, 0);
                cpu.register_file.set_flag(RegisterFlag.HalfCarry, 1);
                cpu.register_file.set_flag(RegisterFlag.Carry, 0);

                // Done with opcode
                return true;
            },
            else => {},
        }

        return false;
    }
};

const OrRegister = struct {
    // Opcode - 0b10110xxx
    // OR r
    // Performs a bitwise OR operation between the 8-bit A register and the 8-bit register r, and stores
    // the result back into the A register
    pub fn execute(cpu: *CPU()) bool {
        switch (cpu.machine_cycle) {
            1 => {
                // This is just the fetch cycle which is done at the CPU level
            },
            2 => {
                const r: u3 = @truncate(cpu.register_file.register_ir); // Extract bits 0-2
                const z = cpu.register_file.get_value(r);
                const a = cpu.register_file.get_value(7); // accumulator

                // Calculate
                const val = a | z;

                // Set result
                cpu.register_file.set_value(7, val); // accumulator

                // Set flags
                cpu.register_file.set_flag(RegisterFlag.Zero, if (val == 0) 0b1 else 0b0);
                cpu.register_file.set_flag(RegisterFlag.Subtract, 0);
                cpu.register_file.set_flag(RegisterFlag.HalfCarry, 0);
                cpu.register_file.set_flag(RegisterFlag.Carry, 0);

                // Done with opcode
                return true;
            },
            else => {},
        }

        return false;
    }
};

const OrRegisterIndirectHL = struct {
    // Opcode - 0b10110110
    // OR (HL)
    // Performs a bitwise OR operation between the 8-bit A register and data from the absolute
    // address specified by the 16-bit register HL, and stores the result back into the A register
    var z: u8 = 0;

    pub fn execute(cpu: *CPU()) bool {
        switch (cpu.machine_cycle) {
            1 => {
                // This is just the fetch cycle which is done at the CPU level
            },
            2 => {
                // Load value from HL
                z = cpu.mmu.getMemory(cpu.register_file.register_hl);
            },
            3 => {
                const a = cpu.register_file.get_value(7); // accumulator

                // Calculate
                const val = a | z;

                // Set result
                cpu.register_file.set_value(7, val); // accumulator

                // Set flags
                cpu.register_file.set_flag(RegisterFlag.Zero, if (val == 0) 0b1 else 0b0);
                cpu.register_file.set_flag(RegisterFlag.Subtract, 0);
                cpu.register_file.set_flag(RegisterFlag.HalfCarry, 0);
                cpu.register_file.set_flag(RegisterFlag.Carry, 0);

                // Done with opcode
                return true;
            },
            else => {},
        }

        return false;
    }
};

const OrRegisterImmediate = struct {
    // Opcode - 0b11110110
    // OR n
    // Performs a bitwise OR operation between the 8-bit A register and immediate data n, and stores
    // the result back into the A register
    var z: u8 = 0;

    pub fn execute(cpu: *CPU()) bool {
        switch (cpu.machine_cycle) {
            1 => {
                // This is just the fetch cycle which is done at the CPU level
            },
            2 => {
                // Load value from immediate data
                z = cpu.mmu.getMemory(cpu.register_file.program_counter);
                cpu.register_file.program_counter += 1;
            },
            3 => {
                const a = cpu.register_file.get_value(7); // accumulator

                // Calculate
                const val = a | z;

                // Set result
                cpu.register_file.set_value(7, val); // accumulator

                // Set flags
                cpu.register_file.set_flag(RegisterFlag.Zero, if (val == 0) 0b1 else 0b0);
                cpu.register_file.set_flag(RegisterFlag.Subtract, 0);
                cpu.register_file.set_flag(RegisterFlag.HalfCarry, 0);
                cpu.register_file.set_flag(RegisterFlag.Carry, 0);

                // Done with opcode
                return true;
            },
            else => {},
        }

        return false;
    }
};

const XorRegister = struct {
    // Opcode - 0b10101xxx
    // XOR r
    // Performs a bitwise XOR operation between the 8-bit A register and the 8-bit register r, and
    // stores the result back into the A register
    pub fn execute(cpu: *CPU()) bool {
        switch (cpu.machine_cycle) {
            1 => {
                // This is just the fetch cycle which is done at the CPU level
            },
            2 => {
                const r: u3 = @truncate(cpu.register_file.register_ir); // Extract bits 0-2
                const z = cpu.register_file.get_value(r);
                const a = cpu.register_file.get_value(7); // accumulator

                // Calculate
                const val = a ^ z;

                // Set result
                cpu.register_file.set_value(7, val); // accumulator

                // Set flags
                cpu.register_file.set_flag(RegisterFlag.Zero, if (val == 0) 0b1 else 0b0);
                cpu.register_file.set_flag(RegisterFlag.Subtract, 0);
                cpu.register_file.set_flag(RegisterFlag.HalfCarry, 0);
                cpu.register_file.set_flag(RegisterFlag.Carry, 0);

                // Done with opcode
                return true;
            },
            else => {},
        }

        return false;
    }
};

const XorRegisterIndirectHL = struct {
    // Opcode - 0b10101110
    // XOR (HL)
    // Performs a bitwise XOR operation between the 8-bit A register and data from the absolute
    // address specified by the 16-bit register HL, and stores the result back into the A register
    var z: u8 = 0;

    pub fn execute(cpu: *CPU()) bool {
        switch (cpu.machine_cycle) {
            1 => {
                // This is just the fetch cycle which is done at the CPU level
            },
            2 => {
                // Load value from HL
                z = cpu.mmu.getMemory(cpu.register_file.register_hl);
            },
            3 => {
                const a = cpu.register_file.get_value(7); // accumulator

                // Calculate
                const val = a ^ z;

                // Set result
                cpu.register_file.set_value(7, val); // accumulator

                // Set flags
                cpu.register_file.set_flag(RegisterFlag.Zero, if (val == 0) 0b1 else 0b0);
                cpu.register_file.set_flag(RegisterFlag.Subtract, 0);
                cpu.register_file.set_flag(RegisterFlag.HalfCarry, 0);
                cpu.register_file.set_flag(RegisterFlag.Carry, 0);

                // Done with opcode
                return true;
            },
            else => {},
        }

        return false;
    }
};

const XorRegisterImmediate = struct {
    // Opcode - 0b11101110
    // XOR n
    // Performs a bitwise XOR operation between the 8-bit A register and immediate data n, and
    // stores the result back into the A register
    var z: u8 = 0;

    pub fn execute(cpu: *CPU()) bool {
        switch (cpu.machine_cycle) {
            1 => {
                // This is just the fetch cycle which is done at the CPU level
            },
            2 => {
                // Load value from immediate data
                z = cpu.mmu.getMemory(cpu.register_file.program_counter);
                cpu.register_file.program_counter += 1;
            },
            3 => {
                const a = cpu.register_file.get_value(7); // accumulator

                // Calculate
                const val = a ^ z;

                // Set result
                cpu.register_file.set_value(7, val); // accumulator

                // Set flags
                cpu.register_file.set_flag(RegisterFlag.Zero, if (val == 0) 0b1 else 0b0);
                cpu.register_file.set_flag(RegisterFlag.Subtract, 0);
                cpu.register_file.set_flag(RegisterFlag.HalfCarry, 0);
                cpu.register_file.set_flag(RegisterFlag.Carry, 0);

                // Done with opcode
                return true;
            },
            else => {},
        }

        return false;
    }
};

const ComplementCarryFlag = struct {
    // Opcode - 0b00111111
    // CCF
    // Flips the carry flag, and clears the N and H flags
    pub fn execute(cpu: *CPU()) bool {
        switch (cpu.machine_cycle) {
            1 => {
                // This is just the fetch cycle which is done at the CPU level
            },
            2 => {
                // Flip carry flag
                cpu.register_file.set_flag(RegisterFlag.Carry, ~cpu.register_file.get_flag(RegisterFlag.Carry));

                // Clear N and H
                cpu.register_file.set_flag(RegisterFlag.Subtract, 0);
                cpu.register_file.set_flag(RegisterFlag.HalfCarry, 0);

                // Done with opcode
                return true;
            },
            else => {},
        }
        return false;
    }
};

const SetCarryFlag = struct {
    // Opcode - 0b00110111
    // SCF
    // Sets the carry flag, and clears the N and H flags
    pub fn execute(cpu: *CPU()) bool {
        switch (cpu.machine_cycle) {
            1 => {
                // This is just the fetch cycle which is done at the CPU level
            },
            2 => {
                // Set carry flag
                cpu.register_file.set_flag(RegisterFlag.Carry, 1);

                // Clear N and H
                cpu.register_file.set_flag(RegisterFlag.Subtract, 0);
                cpu.register_file.set_flag(RegisterFlag.HalfCarry, 0);

                // Done with opcode
                return true;
            },
            else => {},
        }
        return false;
    }
};

const DecimalAdjustAccumulator = struct {
    // Opcode - 0b00100111
    // Performs BCD adjustment

    pub fn execute(cpu: *CPU()) bool {
        switch (cpu.machine_cycle) {
            1 => {
                // This is just the fetch cycle which is done at the CPU level
            },
            2 => {
                const subtract = cpu.register_file.get_flag(RegisterFlag.Subtract);
                const half_carry = cpu.register_file.get_flag(RegisterFlag.HalfCarry);
                const carry = cpu.register_file.get_flag(RegisterFlag.Carry);
                const accumulator = cpu.register_file.get_value(7);

                var offset: u8 = 0x0;

                if (subtract == 0b0) {
                    // Addition
                    if ((accumulator & 0xF) > 0x9 or half_carry == 0b1) {
                        offset |= 0x6;
                    }

                    if (accumulator > 0x99 or carry == 0b1) {
                        offset |= 0x60;
                    }

                    cpu.register_file.set_value(7, accumulator + offset);
                } else {
                    // Subtraction
                    if (half_carry == 0b1) {
                        offset |= 0x6;
                    }

                    if (carry == 0b1) {
                        offset |= 0x60;
                    }

                    cpu.register_file.set_value(7, accumulator - offset);
                }

                // Done with opcode
                return true;
            },
            else => {},
        }

        return false;
    }
};

const ComplementAccumulator = struct {
    // Opcode - 0b00101111
    // CPL
    // Flips all the bits in the 8-bit A register, and sets the N and H flags
    pub fn execute(cpu: *CPU()) bool {
        switch (cpu.machine_cycle) {
            1 => {
                // This is just the fetch cycle which is done at the CPU level
            },
            2 => {
                // Flip accumulator
                cpu.register_file.set_value(7, ~cpu.register_file.get_value(7));

                // Set N and H
                cpu.register_file.set_flag(RegisterFlag.Subtract, 1);
                cpu.register_file.set_flag(RegisterFlag.HalfCarry, 1);

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
