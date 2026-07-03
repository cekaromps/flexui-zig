const std = @import("std");
const rl = @import("raylib");

// Manual vtable: `ptr` is the type-erased widget instance, and each fn
// pointer knows how to operate on it. `setRectFn` exists because FlexBox
// computes each child's rect during layout and needs a way to write it
// back into the *specific* widget instance `ptr` points at - the widget
// itself owns its own `rect` field (used for drawing/hit-testing), this
// just keeps it in sync with what the layout decided.
pub const Component = struct {
    ptr: *anyopaque,
    setRectFn: *const fn (ptr: *anyopaque, rect: rl.Rectangle) void,
    drawFn: *const fn (ptr: *anyopaque) void,
    handleInputFn: *const fn (ptr: *anyopaque) void,
    updateFn: *const fn (ptr: *anyopaque) void,
    deinitFn: *const fn (ptr: *anyopaque) void,
};

pub fn noopUpdate(_: *anyopaque) void {}
pub fn noopDeinit(_: *anyopaque) void {}
