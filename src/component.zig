const std = @import("std");
const rl = @import("raylib");

pub const Component = struct {
    rect: rl.Rectangle = .{ .x = 0, .y = 0, .width = 0, .height = 0},
    visible: bool = true,
    enabled: bool = true,

    ptr: *anyopaque,
    handleInput: *const fn (ptr: *anyopaque) void,
    updateFn: *const fn (ptr: *anyopaque) void,
    drawFn: *const fn (ptr: *anyopaque) void,
    deinitFn: *const fn (ptr: *anyopaque) void,
};
