const std = @import("std");
const memory = @import("memory");

pub const SoCOptions = struct {
    alloc: std.mem.Allocator,
    mmu: *memory.MemoryManagementUnit(),
};
