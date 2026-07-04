const std = @import("std");
const rl = @import("raylib");
const component_mod = @import("component.zig");
const Component = component_mod.Component;

pub const FlexDirection = enum { Row, Column };
pub const FlexAlign     = enum { Start, Center, End, Stretch };
pub const FlexJustify   = enum { Start, Center, End, SpaceBetween };

const LayoutResult = struct {
    rect: rl.Rectangle,
};

pub const FlexChild = struct {
    fixedW: f32,
    fixedH: f32,
    grow: f32 = 0,
    visible: bool = true,
    // The bound widget instance (Button, TextInput, ...) wrapped as a
    // Component. This is what lets a fixed set of fn pointers on
    // Component dispatch to *this specific* widget - a plain function
    // pointer here couldn't carry that per-instance context.
    component: ?Component = null,
};

pub const FlexBox = struct {
    direction: FlexDirection = .Row,
    align_items: FlexAlign   = .Stretch,
    justify: FlexJustify     = .Start,

    gap: f32 = 8.0,
    padding: f32 = 0.0,
    children: std.ArrayList(FlexChild) = .empty,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) FlexBox {
        return .{
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *FlexBox) void {
        self.children.deinit(self.allocator);
    }

    pub fn computeLayout(self: *FlexBox, bounds: rl.Rectangle) ![]LayoutResult {
        const is_row: bool = (self.direction == .Row);
        const main_axis_size: f32 = if (is_row) bounds.width else bounds.height;
        const cross_axis_size: f32 = if (is_row) bounds.height else bounds.width;

        var n: f32 = 0;
        for (self.children.items) |c| {
            if (c.visible) n += 1;
        }

        var total_fixed: f32 = 0;
        var total_grow: f32 = 0;
        for (self.children.items) |c| {
            const fixed_main: f32 = if (is_row) c.fixedW else c.fixedH;
            if (fixed_main >= 0) {
                total_fixed += fixed_main;
            } else {
                total_grow += if (c.grow > 0) c.grow else 1;
            }
        }

        const total_gap: f32 = self.gap * (if (n > 0) n - 1 else 0);
        var remaining: f32 = main_axis_size - total_fixed - total_gap - self.padding * 2;
        if (remaining < 0) remaining = 0;

        var cursor: f32 = if (is_row) bounds.x + self.padding else bounds.y + self.padding;

        if (total_grow == 0) {
            if (self.justify == .Center) {
                cursor += remaining / 2;
            } else if (self.justify == .End) {
                cursor += remaining;
            }
        }

        var space_between_extra: f32 = 0;
        if (self.justify == .SpaceBetween and n > 1 and total_grow == 0) {
            space_between_extra = remaining / (n - 1);
        }

        var results: std.ArrayList(LayoutResult) = .empty;
        errdefer results.deinit(self.allocator);

        for (self.children.items) |c| {
            if (!c.visible) continue;

            const fixed_main: f32 = if (is_row) c.fixedW else c.fixedH;
            const main_size: f32 = if (fixed_main >= 0)
                fixed_main
            else
                remaining * ((if (c.grow > 0) c.grow else 1) / total_grow);

            const cross_fixed: f32 = if (is_row) c.fixedH else c.fixedW;
            const cross_size: f32 = if (self.align_items == .Stretch or cross_fixed < 0)
                cross_axis_size - self.padding * 2
            else
                cross_fixed;

            var cross_pos: f32 = if (is_row) bounds.y + self.padding else bounds.x + self.padding;
            if (self.align_items == .Center) {
                cross_pos += (cross_axis_size + self.padding * 2 - cross_size) / 2;
            } else if (self.align_items == .End) {
                cross_pos += (cross_axis_size + self.padding * 2 - cross_size);
            }

            const childRect: rl.Rectangle = if (is_row)
                .{ .x = cursor, .y = cross_pos, .width = main_size, .height = cross_size }
            else
                .{ .x = cross_pos, .y = cursor, .width = cross_size, .height = main_size };

            try results.append(self.allocator, .{ .rect = childRect });

            cursor += main_size + self.gap + space_between_extra;
        }

        return results.toOwnedSlice(self.allocator);
    }

    pub fn add(self: *FlexBox, child: FlexChild) !void {
        try self.children.append(self.allocator, child);
    }

    pub fn layout(self: *FlexBox, bounds: rl.Rectangle) !void {
        const results = try self.computeLayout(bounds);
        defer self.allocator.free(results);

        for (self.children.items, results) |child, result| {
            if (child.visible) {
                if (child.component) |c| {
                    c.setRectFn(c.ptr, result.rect);
                    c.drawFn(c.ptr);
                }
            }
        }
    }

    pub fn handleInput(self: *FlexBox, bounds: rl.Rectangle) !void {
        const results = try self.computeLayout(bounds);
        defer self.allocator.free(results);

        for (self.children.items, results) |child, result| {
            if (child.visible) {
                if (child.component) |c| {
                    c.setRectFn(c.ptr, result.rect);
                    c.handleInputFn(c.ptr);
                }
            }
        }
    }
};
