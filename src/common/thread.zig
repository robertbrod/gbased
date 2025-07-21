const std = @import("std");

pub const ThreadParams = struct {
    mutex: std.Thread.Mutex = .{},
    stop_flag: std.atomic.Value(bool) = std.atomic.Value(bool).init(false),
    stop_signal: std.Thread.Condition = .{},
};
