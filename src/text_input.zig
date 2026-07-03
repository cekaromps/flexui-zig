const std = @import("std");
const rl = @import("raylib");
const component = @import("component.zig");

pub const TextInput = struct {
    rect: rl.Rectangle = .{ .x = 0, .y = 0, .width = 0, .height = 0 },
    value: std.ArrayList(u8),
    placeholder: [:0]const u8 = "",
    maxLength: usize = 256,
    focused: bool = false,
    font: rl.Font,

    pub fn init(allocator: std.mem.Allocator, font: rl.font) TextInput {
        return .{
            .value = std.ArrayList(u8).init(allocator),
            .font = font
        };
    }

    pub fn deinit(self: *TextInput) void {
        self.value.deinit();
    }
    
    pub fn cStr(self: *TextInput) [*:0]const u8 {
        self.value.ensureTotalCapacity(self.value.items.len+1) catch return "";
        self.value.items.ptr[self.value.items.len] = 0;
        return @ptrCast(self.value.items.ptr);
    }

    pub fn handleInput(ptr: *anyopaque) void {
        const self: *TextInput = @ptrCast(@alignCast(ptr));
        if(!self.enabled) return;
        if(rl.IsMouseButtonPressed(rl.MOUSE_BUTTON_LEFT))
            self.focused = rl.CheckCollisionPointRec(rl.GetMousePosition(), self.rect);
        if(!self.focused) return;
        if(rl.IsKeyPressed(rl.KEY_BACKSPACE) and self.value.items.len > 0)
            _ = self.value.pop();

        const ctrlDown = rl.IsKeyDown(rl.KEY_LEFT_CONTROL) or rl.IsKeyDown(rl.KEY_RIGHT_CONTROL);
        if (ctrlDown and rl.IsKeyPresssed(rl.KEY_V)) {
            const clip: [*:0]const u8 = rl.GetClipboardText();
            // Zig slice we can iterate/index
            const clip_slice = std.mem.span(clip);
            for (clip_slice) |c| {
                if (c == '\n' or c == '\r' or c == '\t') break;
                if (self.value.items.len >= self.maxLength) break;
                self.value.append(c) catch break;
            }
        }

        var ch = rl.GetCharPressed();
        while (ch > 0) : (ch = rl.GetCharPressed()) {
            if (ch >= 32 and self.value.items.len < self.maxLength)
                self.value.append(@intCast(ch)) catch {};
        }
    }
    pub fn draw(ptr: *anyopaque) void {
        const self: *TextInput = @ptrCast(@alignCast(ptr));
        if(!self.visible) return;
        rl.DrawRectangleRec(self.rect, .{.r=30, .g=30, .b=30, .a=255});
        rl.DrawRectangleLinesEx(self.rect, 2, if(self.focused) rl.WHITE else rl.GRAY);
        const fs: f32 = self.rect.height * 0.55;
        const padding = 8;
        const display: [*:0]const u8 = if(self.value.items.len == 0) self.placeholder else self.cStr();
        const color = if(self.value.items.len == 0) rl.GRAY else rl.WHITE;
        rl.DrawTextEx(self.font, display,
            .{self.rect.x + padding, self.rect.y + (self.rect.height - fs)/2.0},
            fs, 1, color
        );
        const blinkOn: i32 = @intFromFloat(rl.GetTime() * 2);
        if(self.focused and @mod(blinkOn, 2) == 0) {
            const ts = rl.MeasureTextEx(self.font, self.cStr(), fs, 1);
            const cx: f32 = self.rect.x + padding + ts.x + 2;
            const cy: f32 = self.rect.x + (self.rect.height - fs) / 2.0;
            rl.DrawLineEx(.{.x=cx, .y=cy}, .{.x=cx,.y=cy + fs}, 2, rl.WHITE);
        }
    }
};
