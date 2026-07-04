const std = @import("std");
const rl = @import("raylib");
const component_mod = @import("component.zig");

pub const TextInput = struct {
    rect: rl.Rectangle = .{ .x = 0, .y = 0, .width = 0, .height = 0 },
    value: std.ArrayList(u8) = .empty,
    allocator: std.mem.Allocator,
    placeholder: [:0]const u8 = "",
    maxLength: usize = 256,
    focused: bool = false,
    visible: bool = true,
    enabled: bool = true,
    font: rl.Font,

    pub fn init(allocator: std.mem.Allocator, font: rl.Font) TextInput {
        return .{
            .allocator = allocator,
            .font = font,
        };
    }

    pub fn deinit(self: *TextInput) void {
        self.value.deinit(self.allocator);
    }

    pub fn cStr(self: *TextInput) [:0]const u8 {
        self.value.ensureTotalCapacity(self.allocator, self.value.items.len + 1) catch return "";
        self.value.items.ptr[self.value.items.len] = 0;
        return self.value.items.ptr[0..self.value.items.len :0];
    }

    pub fn setRect(ptr: *anyopaque, rect: rl.Rectangle) void {
        const self: *TextInput = @ptrCast(@alignCast(ptr));
        self.rect = rect;
    }

    pub fn handleInput(ptr: *anyopaque) void {
        const self: *TextInput = @ptrCast(@alignCast(ptr));
        if (!self.enabled) return;
        if (rl.isMouseButtonPressed(rl.MouseButton.left))
            self.focused = rl.checkCollisionPointRec(rl.getMousePosition(), self.rect);
        if (!self.focused) return;

        if (rl.isKeyPressed(rl.KeyboardKey.backspace) and self.value.items.len > 0)
            _ = self.value.pop();

        const ctrlDown = rl.isKeyDown(rl.KeyboardKey.left_control) or rl.isKeyDown(rl.KeyboardKey.right_control);
        if (ctrlDown and rl.isKeyPressed(rl.KeyboardKey.v)) {
            const clip_slice = rl.getClipboardText();
            for (clip_slice) |c| {
                if (c == '\n' or c == '\r' or c == '\t') break;
                if (self.value.items.len >= self.maxLength) break;
                self.value.append(self.allocator, c) catch break;
            }
        }

        var ch = rl.getCharPressed();
        while (ch > 0) : (ch = rl.getCharPressed()) {
            if (ch >= 32 and self.value.items.len < self.maxLength)
                self.value.append(self.allocator, @intCast(ch)) catch {};
        }
    }

    pub fn draw(ptr: *anyopaque) void {
        const self: *TextInput = @ptrCast(@alignCast(ptr));
        if (!self.visible) return;
        rl.drawRectangleRec(self.rect, .{ .r = 30, .g = 30, .b = 30, .a = 255 });
        rl.drawRectangleLinesEx(self.rect, 2, if (self.focused) rl.Color.white else rl.Color.gray);
        const fs: f32 = self.rect.height * 0.55;
        const padding: f32 = 8;
        const display: [:0]const u8 = if (self.value.items.len == 0) self.placeholder else self.cStr();
        const color = if (self.value.items.len == 0) rl.Color.gray else rl.Color.white;
        rl.drawTextEx(self.font, display, .{
            .x = self.rect.x + padding,
            .y = self.rect.y + (self.rect.height - fs) / 2.0,
        }, fs, 1, color);

        const blinkOn: i32 = @intFromFloat(rl.getTime() * 2);
        if (self.focused and @mod(blinkOn, 2) == 0) {
            const ts = rl.measureTextEx(self.font, self.cStr(), fs, 1);
            const cx: f32 = self.rect.x + padding + ts.x + 2;
            const cy: f32 = self.rect.y + (self.rect.height - fs) / 2.0;
            rl.drawLineEx(.{ .x = cx, .y = cy }, .{ .x = cx, .y = cy + fs }, 2, rl.Color.white);
        }
    }

    pub fn component(self: *TextInput) component_mod.Component {
        return .{
            .ptr = self,
            .setRectFn = setRect,
            .drawFn = draw,
            .handleInputFn = handleInput,
            .updateFn = component_mod.noopUpdate,
            .deinitFn = component_mod.noopDeinit,
        };
    }
};
