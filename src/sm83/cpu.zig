const std = @import("std");
const memory = @import("memory");

const ALU = @import("alu.zig").ALU;
const RegisterFile = @import("register_file.zig").RegisterFile;
const IDU = @import("idu.zig").IDU;
const InstructionSet = @import("instructions.zig").InstructionSet;

const Options = struct {
    alloc: std.mem.Allocator,
    mmu: *const memory.MemoryManagementUnit(),
};

pub fn SM83CPU() type {
    return struct {
        const Self = @This();

        mmu: *const memory.MemoryManagementUnit(),

        alu: ALU(),
        idu: IDU(),
        register_file: *RegisterFile(),
        instruction_set: InstructionSet(),

        pub fn init(options: Options) !Self {
            const register_file = try RegisterFile().init(options.alloc);
            const alu = ALU().init();
            const idu = IDU().init();
            const instruction_set = try InstructionSet().init(options.alloc);

            const new_cpu: Self = .{
                .mmu = options.mmu,

                .alu = alu,
                .idu = idu,
                .register_file = register_file,
                .instruction_set = instruction_set,
            };

            return new_cpu;
        }

        pub fn deinit(self: *Self) void {
            // Cleanup logic
            self.alu.deinit();
            self.idu.deinit();
            self.register_file.deinit();
            self.instruction_set.deinit();
        }

        // TODO: implement action instruction timing

        pub fn process_instruction(self: *Self, opcode: u8) void {
            for (self.instruction_set.instructions) |inst| {
                if (inst.match(opcode)) {
                    // Execute the instruction
                    inst.execute(opcode, &self.register_file);
                    break;
                }
            }
        }

        // // Register number map
        // // 0 -> B
        // // 1 -> C
        // // 2 -> D
        // // 3 -> E
        // // 4 -> H
        // // 5 -> L
        // // 6 -> (HL) get value of memory management unit based on address in HL
        // // 7 -> A
        // pub fn get_value(self: *Self, reg_num: u3) RegisterFileErrors!u8 {
        //     switch (reg_num) {
        //         0 => return @intCast(self.register_bc >> 8), // B
        //         1 => return @intCast(self.register_bc & 0xFF), // C
        //         2 => return @intCast(self.register_de >> 8), // D
        //         3 => return @intCast(self.register_de & 0xFF), // E
        //         4 => return @intCast(self.register_hl >> 8), // H
        //         5 => return @intCast(self.register_hl & 0xFF), // L
        //         6 => return 0, // TODO: read memory of HL
        //         7 => return self.accumulator, // A
        //     }
        // }

        // pub fn set_value(self: *Self, reg_num: u3, value: u8) void {
        //     switch (reg_num) {
        //         0 => self.register_bc = (self.register_bc & 0x00FF) | (@as(u16, value) << 8), // B
        //         1 => self.register_bc = (self.register_bc & 0xFF00) | @as(u16, value), // C
        //         2 => self.register_de = (self.register_de & 0x00FF) | (@as(u16, value) << 8), // D
        //         3 => self.register_de = (self.register_de & 0xFF00) | @as(u16, value), // E
        //         4 => self.register_hl = (self.register_hl & 0x00FF) | (@as(u16, value) << 8), // H
        //         5 => self.register_hl = (self.register_hl & 0xFF00) | @as(u16, value), // L
        //         6 => return, // TODO: write memory of HL
        //         7 => self.accumulator = value, // A
        //     }
        // }
    };
}

test "SM83 CPU Initialization" {
    const gpa = std.testing.allocator;
    var cpu = try SM83CPU().init(gpa);
    defer cpu.deinit();

    // Test that the CPU initializes correctly
    try std.testing.expect(cpu.register_file.program_counter == 0);
    try std.testing.expect(cpu.register_file.stack_pointer == 0);
    try std.testing.expect(cpu.register_file.accumulator == 0);
}

test "SM83 Load Register Instruction" {
    const gpa = std.testing.allocator;
    var cpu = try SM83CPU().init(gpa);
    defer cpu.deinit();

    cpu.register_file.set_register_value(1, 6);

    cpu.process_instruction(0b01000001); // LD A, B

    // Test that the CPU initializes correctly
    const reg_a = cpu.register_file.get_register_value(0);
    try std.testing.expect(reg_a == 6);
}
