const std = @import("std");

pub const ThreadParams = struct {
    mutex: std.Thread.Mutex = .{},
    stop_flag: bool = false,
    stop_signal: std.Thread.Condition = .{},
};
