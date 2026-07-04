# flexui-zig

A small immediate-mode UI kit for [raylib](https://www.raylib.com/), built on
[raylib-zig](https://github.com/raylib-zig/raylib-zig). It gives you a
`Button`, a `TextInput`, and a `FlexBox` layout container to arrange them
with — a Zig port of a small C++ raylib UI library.

There's no inheritance here (Zig doesn't have it). Widgets are plain structs
    with `draw`/`handleInput` functions, wrapped into a `Component` — a small
manual vtable (a `*anyopaque` pointer plus a handful of function pointers)
    that lets `FlexBox` hold a mix of different widget types and call the right
    function for each one without knowing its concrete type ahead of time.

## Installation
Add it as a dependency in your `build.zig.zon`:
```zig
.dependencies = .{
    .flexui = .{
        .url = "git+https://github.com/cekaromps/flexui-zig#<commit>",
            .hash = "...", // zig will tell you the correct hash on first build
    },
},
```
Then wire it into `build.zig`:
```zig
const flexui_dep = b.dependency("flexui", .{ .target = target, .optimize = optimize });
exe.root_module.addImport("flexui", flexui_dep.module("flexui"));
```

`flexui`'s own `build.zig` already depends on and links `raylib-zig` for
you, so you don't need to add that dependency yourself unless you also want
to call raylib functions directly in your own code (which you almost
        certainly do, for `initWindow`, the main loop, etc.) — in that case add
`raylib_zig` as its own dependency too, the same way `flexui`'s `build.zig`
does it.

## Quick start
```zig
const std = @import("std");
const rl = @import("raylib");
const flexui = @import("flexui");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    rl.initWindow(800, 600, "my app");
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    const font = try rl.getFontDefault();

    var name_input = flexui.TextInput.init(allocator, font);
    defer name_input.deinit();
    name_input.placeholder = "Type something...";

    var my_btn = flexui.Button{
        .label = "Click me",
            .font = font,
            .onClick = onClick,
    };

    var layout = flexui.FlexBox.init(allocator);
    defer layout.deinit();
    layout.direction = .Column;
    layout.gap = 16;
    layout.padding = 40;

    try layout.add(.{ .fixedW = -1, .fixedH = 50, .component = name_input.component() });
    try layout.add(.{ .fixedW = 200, .fixedH = 50, .component = my_btn.component() });

    while (!rl.windowShouldClose()) {
        const bounds = rl.Rectangle{
            .x = 0, .y = 0,
                .width = @floatFromInt(rl.getScreenWidth()),
                .height = @floatFromInt(rl.getScreenHeight()),
        };

        try layout.handleInput(bounds);

        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(.{ .r = 20, .g = 20, .b = 20, .a = 255 });

        try layout.layout(bounds);
    }
}
fn onClick(ctx: ?*anyopaque) void {
    _ = ctx;
    std.debug.print("clicked!\n", .{});
}
```

A fuller version of this — a text input feeding a greeting into a button
callback via `ctx` — lives in `examples/basic/main.zig`. Run it with:

```
zig build run -Dexamples=true
```

## Concepts

### Widgets don't know about layout, and layout doesn't know about widgets

`Button` and `TextInput` each expose `draw(ptr)`/`handleInput(ptr)`/`setRect(ptr, rect)`
as plain functions, plus a `.component()` method that packages a pointer to
the specific instance together with those functions into a `Component`.
`FlexBox` only ever talks to `Component` — it never needs to know it's
holding a `Button` versus a `TextInput`.

This is the direct replacement for C++ virtual dispatch: instead of a
vtable pointer the compiler sets up for you automatically when you
construct an object, `.component()` builds that same "pointer + matching
functions" bundle explicitly, by hand.

### Callbacks and `ctx`

Zig function pointers can't capture local variables the way a C++ lambda
can. `Button.onClick` is `?*const fn (ctx: ?*anyopaque) void` — if your
callback needs data (which widget to read from, some app state, etc.), you
pass it in yourself via `Button.ctx` at construction time, and cast it back
inside the callback:

```zig
const AppState = struct { input: *flexui.TextInput };
var state = AppState{ .input = &my_input };

var btn = flexui.Button{
    .label = "Submit",
        .font = font,
        .onClick = onSubmit,
        .ctx = &state,
};

fn onSubmit(ctx: ?*anyopaque) void {
    const state: *AppState = @ptrCast(@alignCast(ctx.?));
    std.debug.print("input was: {s}\n", .{state.input.value.items});
}
```

### Ownership

`Button` owns nothing that needs cleanup — every field is either a value
type or a borrowed pointer/handle (its `Font`, for instance, is loaded and
        freed by whoever set up the screen, not by `Button` itself).

`TextInput` and `FlexBox` both own a growable buffer (`TextInput.value`,
        `FlexBox.children`) and therefore need explicit setup/teardown:

```zig
var input = flexui.TextInput.init(allocator, font);
defer input.deinit();

var layout = flexui.FlexBox.init(allocator);
defer layout.deinit();
```

Skipping `deinit()` is a silent leak, not a compile error — there's no
destructor to catch it for you.

## API

### `Button`

```zig
pub const Button = struct {
rect: rl.Rectangle = ...,      // set by FlexBox each frame; can also position manually
          label: [:0]const u8,           // required
          font: rl.Font,                 // required
          style: ButtonStyle = ButtonStyles.Primary(),
          visible: bool = true,
          enabled: bool = true,          // false skips input handling, keeps drawing
          onClick: ?*const fn (ctx: ?*anyopaque) void = null,
          ctx: ?*anyopaque = null,
          hovered: bool = false,         // read-only, updated by handleInput/draw
};
```

Construct directly with a struct literal; only `label` and `font` are
required. Call `.component()` to hand it to a `FlexBox`, or drive it
manually by calling `Button.draw(&btn)`/`Button.handleInput(&btn)` yourself
each frame if you're not using `FlexBox` at all.

### `ButtonStyle` / `ButtonStyles`

    ```zig
    flexui.ButtonStyles.Primary()  // blue, filled
    flexui.ButtonStyles.Danger()   // red, filled
flexui.ButtonStyles.Ghost()    // transparent, border + text only
    ```

    Each returns a `ButtonStyle` value — assign it to `Button.style`. Build
    your own by constructing a `ButtonStyle` literal directly if none of the
    presets fit:

    ```zig
    btn.style = .{
        .colorNormal = .{ .r = 50, .g = 200, .b = 100, .a = 255 },
            .colorHovered = .{ .r = 80, .g = 230, .b = 130, .a = 255 },
            .colorBorder = .{ .r = 30, .g = 150, .b = 70, .a = 255 },
            .colorText = rl.Color.white,
            .roundness = 0.3,
    };
```

### `TextInput`

```zig
pub const TextInput = struct {
value: std.ArrayList(u8) = .empty,  // current text - read via .items
           placeholder: [:0]const u8 = "",
           maxLength: usize = 256,
           focused: bool = false,              // read-only, set by handleInput
           visible: bool = true,
           enabled: bool = true,
           font: rl.Font,                      // required (via init)
};
```

Must be constructed via `init`, not a bare struct literal, since it owns an
allocator-backed buffer:

```zig
var input = flexui.TextInput.init(allocator, font);
defer input.deinit();
```

Supports typing, backspace, and Ctrl+V paste (newlines/tabs in pasted
        content are treated as terminators, since this is a single-line field).
Read the current text via `input.value.items` (a `[]const u8` slice).

### `FlexBox` / `FlexChild`

```zig
pub const FlexBox = struct {
direction: FlexDirection = .Row,      // .Row or .Column
               align_items: FlexAlign = .Stretch,    // .Start, .Center, .End, .Stretch
               justify: FlexJustify = .Start,        // .Start, .Center, .End, .SpaceBetween
               gap: f32 = 8.0,
               padding: f32 = 0.0,
};

pub const FlexChild = struct {
fixedW: f32,                // -1 = no fixed width (grows/stretches)
            fixedH: f32,                // -1 = no fixed height (grows/stretches)
            grow: f32 = 0,               // relative growth factor when fixed_main < 0
            visible: bool = true,
            component: ?Component = null,
};
```

```zig
var layout = flexui.FlexBox.init(allocator);
defer layout.deinit();
layout.direction = .Column;
layout.gap = 16;
layout.padding = 40;

try layout.add(.{ .fixedW = -1, .fixedH = 50, .component = my_widget.component() });
```

Each frame, call both:

```zig
try layout.handleInput(bounds);  // hit-testing, focus, clicks
try layout.layout(bounds);       // actually draws everything
```

**Known quirk:** `align_items = .Stretch` currently overrides any child's
explicit fixed cross-axis size — a child asking for `fixedW = 200` inside a
`.Stretch` container will still stretch to fill the full width. Use
`align_items = .Start` (or `.Center`/`.End`) if you need a child to keep an
exact cross-axis size.

### `Component`

You'll only touch this directly if you're wiring up a new widget type
(anything beyond `Button`/`TextInput`). The pattern to copy:

```zig
pub fn component(self: *MyWidget) component_mod.Component {
    return .{
        .ptr = self,
            .setRectFn = setRect,      // fn (ptr: *anyopaque, rect: rl.Rectangle) void
            .drawFn = draw,            // fn (ptr: *anyopaque) void
            .handleInputFn = handleInput,
            .updateFn = component_mod.noopUpdate,  // or your own if you need per-frame logic
            .deinitFn = component_mod.noopDeinit,  // or your own cleanup
    };
}
```

## Building
```
zig build                        # builds the flexui static library only
zig build -Dexamples=true        # also builds examples/basic
zig build run -Dexamples=true    # builds and runs examples/basic
```

## A note on the raylib binding

This depends on [raylib-zig](https://github.com/raylib-zig/raylib-zig),
whose function names are `camelCase` (`rl.initWindow`, not raylib's C-side
        `InitWindow`), and whose colors/keys/mouse buttons are enum-style members
rather than top-level constants: `rl.Color.white` (not `rl.WHITE`),
       `rl.KeyboardKey.v` (not `rl.KEY_V`), `rl.MouseButton.left` (not
               `rl.MOUSE_BUTTON_LEFT`). Keep that in mind if you're translating snippets
       from raylib's C or C++ docs.

