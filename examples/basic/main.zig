const std = @import("std");
const rl = @import("raylib");
const flexui = @import("flexui");

// Shared state the button callbacks reach through `ctx`. This is the
// Zig stand-in for a C++ lambda's `[this]` capture - since Zig fn
// pointers can't close over anything, whatever a callback needs has to
// be passed explicitly via `ctx` and cast back on the other side.
const AppState = struct {
    name_input: *flexui.TextInput,
    should_quit: bool = false,
    message_buf: [256:0]u8 = [_:0]u8{0} ** 256,
    message: [:0]const u8 = "Enter your name and click Greet",
};

fn onGreetClick(ctx: ?*anyopaque) void {
    const state: *AppState = @ptrCast(@alignCast(ctx.?));
    const name = state.name_input.value.items;
    const display_name = if (name.len == 0) "stranger" else name;
    state.message = std.fmt.bufPrintZ(&state.message_buf, "Hello, {s}!", .{display_name}) catch "Hello!";
}

fn onQuitClick(ctx: ?*anyopaque) void {
    const state: *AppState = @ptrCast(@alignCast(ctx.?));
    state.should_quit = true;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    rl.InitWindow(800, 600, "flexui basic example");
    defer rl.CloseWindow();
    rl.SetTargetFPS(60);

    const font = rl.GetFontDefault();

    var name_input = flexui.TextInput.init(allocator, font);
    defer name_input.deinit();
    name_input.placeholder = "Your name...";

    var state = AppState{ .name_input = &name_input };

    var greet_btn = flexui.Button{
        .label = "Greet",
        .font = font,
        .style = flexui.ButtonStyles.Primary(),
        .onClick = onGreetClick,
        .ctx = &state,
    };

    var quit_btn = flexui.Button{
        .label = "Quit",
        .font = font,
        .style = flexui.ButtonStyles.Danger(),
        .onClick = onQuitClick,
        .ctx = &state,
    };

    var layout = flexui.FlexBox.init(allocator);
    defer layout.deinit();
    layout.direction = .Column;
    // .Start (not .Stretch) so the buttons keep their requested 200px
    // width - see the note on computeLayout's Stretch behavior.
    layout.align_items = .Start;
    layout.justify = .Start;
    layout.gap = 16;
    layout.padding = 40;

    // fixedW = -1 on the text input means "no fixed cross size" - it
    // still ends up full-width because cross_fixed < 0 triggers the
    // stretch branch regardless of align_items.
    try layout.add(.{ .fixedW = -1, .fixedH = 50, .component = name_input.component() });
    try layout.add(.{ .fixedW = 200, .fixedH = 50, .component = greet_btn.component() });
    try layout.add(.{ .fixedW = 200, .fixedH = 50, .component = quit_btn.component() });

    while (!rl.WindowShouldClose() and !state.should_quit) {
        const bounds = rl.Rectangle{
            .x = 0,
            .y = 0,
            .width = @floatFromInt(rl.GetScreenWidth()),
            .height = @floatFromInt(rl.GetScreenHeight()),
        };

        try layout.handleInput(bounds);

        rl.BeginDrawing();
        defer rl.EndDrawing();
        rl.ClearBackground(.{ .r = 20, .g = 20, .b = 20, .a = 255 });

        try layout.layout(bounds);

        const msg_size = rl.MeasureTextEx(font, state.message, 24, 1);
        rl.DrawTextEx(font, state.message, .{
            .x = (bounds.width - msg_size.x) / 2.0,
            .y = bounds.height - 80,
        }, 24, 1, rl.WHITE);
    }
}
