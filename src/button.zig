const std = @import("std");
const rl = @import("raylib");
const component = @import("component.zig");
const button_style = @import("button_style.zig");
const ButtonStyle = button_style.ButtonStyle;
const ButtonStyles = button_style.ButtonStyles;

pub const Button = struct {
    rect: rl.Rectangle = .{ .x = 0, .y = 0, .width = 0, .height = 0},
    label: [:0]const u8,
    font: rl.font,
    style: ButtonStyle = ButtonStyles.Primary(),
    onClick: ?*const fn (ctx: ?*anyopaque) void = null,
    ctx: ?*anyopaque = null,
    hovered: bool = false,

    pub fn handleInput(ptr: *anyopaque) void {
        const self: *Button = @ptrCast(@alignCast(ptr));
        if(!self.enable) return;
        self.hovered = rl.CheckCollisionPointRec(rl.GetMousePosition(), self.rect);

        if(self.hovered and rl.IsMouseButtonPressed(rl.MOUSE_BUTTON_LEFT)) {
            if (self.onClick) |cb| cb(self.ctx);
        }
    }
    
    pub fn draw(ptr: *anyopaque) void {
        const self: *Button = @ptrCast(@alignCast(ptr));
        if(!self.visible) return;
        self.hovered = rl.CheckCollisionPointRec(rl.GetMousePosition(), self.rect);
        const bg = if (self.hovered) self.style.colorHovered else self.style.colorNormal;
        
        if(self.style.roundness > 0) {
            rl.DrawRectangleRounded(self.rect, self.style.roundness, 8, bg);
        } else {
            rl.DrawRectangleRec(self.rect, bg);
        }
        rl.DrawRectangleLinesEx(self.rect, self.style.borderWidth, self.style.colorBorder);

        const fs = if(self.style.fontSize > 0) self.style.font else self.rect.height * 0.5;
        const ts = rl.MeasureTextEx(self.font, self.label, fs, 1);
        rl.DrawTextEx(self.font, self.label, .{
            .x = self.rect.x + (self.rect.width - ts.x) / 2.0,
            .y = self.rect.y + (self.rect.height - ts.y) / 2.0,
        }, fs, 1, self.style.colorText);
    }
};

