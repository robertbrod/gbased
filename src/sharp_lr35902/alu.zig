pub fn ALU() type {
    return struct {
        const Self = @This();

        pub fn init() Self {
            return .{};
        }

        pub fn deinit(_: *Self) void {}
    };
}

test "ALU Initialization" {
    const alu = ALU().init();
    defer alu.deinit();
}
