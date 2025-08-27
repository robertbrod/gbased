const std = @import("std");
const memory = @import("memory");

const options = @import("options.zig");

const ALU = @import("alu.zig").ALU;
const IDU = @import("idu.zig").IDU;
const DMA = @import("dma.zig").DMA;
const RegisterFile = @import("register_file.zig").RegisterFile;
const InstructionSet = @import("instructions.zig").InstructionSet;
const Instruction = @import("instructions.zig").Instruction;

pub fn SM83CPU() type {
    return struct {
        const Self = @This();

        // External pointers
        mmu: *memory.MemoryManagementUnit(),

        // Processing
        alu: ALU(),
        idu: IDU(),
        dma: DMA(),
        register_file: *RegisterFile(),
        instruction_set: InstructionSet(),

        machine_cycle: u4 = 1,

        // Interrupt master enabled
        ime: bool = false,
        ime_next: bool = false,

        pub fn init(opts: options.SoCOptions) !Self {
            const register_file = try RegisterFile().init(opts.alloc);

            // Load first instruction
            register_file.register_ir = opts.mmu.getMemory(register_file.program_counter);

            return .{
                .mmu = opts.mmu,

                .alu = ALU().init(register_file),
                .idu = IDU().init(),
                .dma = DMA().init(opts),
                .register_file = register_file,
                .instruction_set = InstructionSet().init(),
            };
        }

        pub fn deinit(self: *Self) void {
            // Cleanup logic
            self.alu.deinit();
            self.idu.deinit();
            self.dma.deinit();
            self.register_file.deinit();
            self.instruction_set.deinit();
        }

        pub fn machine_tick(self: *Self) !void {
            // Instruction 'enable interrupts' sets a flag which sets the IME value on the next machine cycle
            // Process that flag here
            if (self.ime_next) {
                self.ime = true;
                self.ime_next = false;
            }

            try self.process_instruction();

            self.dma.machine_tick();

            // TODO: interrupt handling
        }

        fn process_instruction(self: *Self) !void {
            // CPU has a fetch/execute overlap
            // Meaning: during the last step of the current instruction
            // then the we are also fetching the next instruction

            // Execute current instruction
            // const current_instruction = try self.fetchInstruction();

            const instruction_done = try self.instruction_set.execute(self);

            // Current instruction done -> fetch the next instruction
            if (instruction_done) {
                try self.fetchNextInstruction();
            }

            // Increment machine cycle
            self.machine_cycle += 1;
        }

        fn fetchNextInstruction(self: *Self) !void {
            self.register_file.register_ir = self.mmu.getMemory(self.register_file.program_counter);
            self.register_file.program_counter += 1;

            // Reset machine cycle count
            self.machine_cycle = 1;
        }
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
