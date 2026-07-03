const std = @import("std");
const rl  = @import("raylib");

pub const ButtonStyle = struct {
    colorNormal: rl.Color,
    colorHovered: rl.Color,
    colorBorder: rl.Color,
    colorText: rl.Color,
    roundness: f32,
    borderWidth: 2.0,
    fontSize: 0,
};

pub const ButtonStyles = struct {
    pub fn Primary() ButtonStyle {
        return .{
            .colorNormal  = .{.r=0, .g=120, .b=215, .a=255},
            .colorHovered = .{.r=0, .g=150, .b=255, .a=255},
            .colorBorder  = .{.r=0, .g=80, .b=180, .a=255},
            .colorText    = rl.WHITE,
            .roundness    = 0.3
        };
    }

    pub fn Danger() ButtonStyle {
        return .{
            .colorNormal  = .{.r=200, .g=50, .b=50, .a=255},
            .colorHovered = .{.r=230, .g=80, .b=80, .a=255},
            .colorBorder  = .{.r=150, .g=30, .b=30, .a=255},
            .colorText    = rl.WHITE,
            .roundness    = 0.3
        };
    }

    pub fn Ghost() ButtonStyle {
        return .{
            .colorNormal  = .{.r=0, .g=0, .b=0, .a=0},
            .colorHovered = .{.r=255, .g=255, .b=255, .a=20},
            .colorBorder  = rl.WHITE,
            .colorText    = rl.WHITE,
            .roundness    = 0.3
        };
    }
};
