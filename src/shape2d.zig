pub const Rectangle = struct {
    center: math.Vector,
    half_wh: math.Vector,
    rotation: f32 = 0,

    pub fn topLeft(rectangle: Rectangle) math.Vector {
        const base_top_left = math.sub(rectangle.center, rectangle.half_wh);
        return math.rotate(base_top_left, rectangle.center, rectangle.rotation);
    }

    pub fn topRight(rectangle: Rectangle) math.Vector {
        const base_top_right = math.Vector{
            .x = rectangle.center.x + rectangle.half_wh.x,
            .y = rectangle.center.y - rectangle.half_wh.y,
        };
        return math.rotate(base_top_right, rectangle.center, rectangle.rotation);
    }

    pub fn botLeft(rectangle: Rectangle) math.Vector {
        const base_bot_right = math.Vector{
            .x = rectangle.center.x - rectangle.half_wh.x,
            .y = rectangle.center.y + rectangle.half_wh.y,
        };
        return math.rotate(base_bot_right, rectangle.center, rectangle.rotation);
    }

    pub fn botRight(rectangle: Rectangle) math.Vector {
        const base_bot_right = math.add(rectangle.center, rectangle.half_wh);
        return math.rotate(base_bot_right, rectangle.center, rectangle.rotation);
    }
};

test Rectangle {
    const no_rot_rect = Rectangle{
        .center = .{ .x = 1, .y = 2 },
        .half_wh = .{ .x = 2, .y = 4 },
    };
    try math.expectEqualVectors(math.Vector{ .x = -1, .y = -2 }, no_rot_rect.topLeft());
    try math.expectEqualVectors(math.Vector{ .x = 3, .y = -2 }, no_rot_rect.topRight());
    try math.expectEqualVectors(math.Vector{ .x = -1, .y = 6 }, no_rot_rect.botLeft());
    try math.expectEqualVectors(math.Vector{ .x = 3, .y = 6 }, no_rot_rect.botRight());

    const rot_rect = Rectangle{
        .center = .{ .x = 1, .y = 2 },
        .half_wh = .{ .x = 2, .y = 4 },
        .rotation = std.math.pi / 2.0,
    };
    try math.expectEqualVectors(math.Vector{ .x = 5, .y = 0 }, rot_rect.topLeft());
    try math.expectEqualVectors(math.Vector{ .x = 5, .y = 4 }, rot_rect.topRight());
    try math.expectEqualVectors(math.Vector{ .x = -3, .y = 0 }, rot_rect.botLeft());
    try math.expectEqualVectors(math.Vector{ .x = -3, .y = 4 }, rot_rect.botRight());
}

pub const Circle = struct {
    center: math.Vector,
    radius: f32,
};

test {
    std.testing.refAllDecls(@This());
}

const c = @import("c.zig");
const math = @import("math2d.zig");
const std = @import("std");
