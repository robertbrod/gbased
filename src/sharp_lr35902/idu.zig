pub fn IDU() type {
    return struct {
        const Self = @This();

        pub fn init() Self {
            return .{};
        }

        pub fn deinit(_: *Self) void {}

        // IDU is a simple increment/decrement unit
        // Takes a 16 bit register input and outputs a 16 bit register
        pub fn increment(register: u16) u16 {
            return register + 1;
        }

        pub fn decrement(register: u16) u16 {
            return register - 1;
        }
    };
}
