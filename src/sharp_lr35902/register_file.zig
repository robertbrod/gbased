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
    };
}

test "Register Initialization" {
    const register = RegisterFile().init();
    defer register.deinit();
}
