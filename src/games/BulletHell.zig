allocator: std.mem.Allocator = std.heap.c_allocator,
camera: c.Camera2D = .{},
enemy_rects: std.ArrayListUnmanaged(EnemyRectangle) = .{},

arena: shape.Rectangle = .{
    .center = .{ .x = 0, .y = 0 },
    .half_wh = .{ .x = 1920 / 2, .y = 1080 / 2 },
},
arena_thickness: f32 = 10,

player: Player = .{
    .hitbox = .{
        .center = .{ .x = 0, .y = 0 },
        .radius = 10,
    },
    .max_velocity = 300,
},

pub fn init() Game {
    var res = Game{};
    res.enemy_rects.append(res.allocator, .{
        .rectangle = .{
            .center = .{ .x = 0, .y = 0 },
            .half_wh = .{ .x = 100, .y = 10 },
        },
    }) catch @panic("OOM");
    return .{};
}

pub fn updatePhase(game: *Game) void {
    const frame_time = c.GetFrameTime();

    movePlayer(game);

    for (game.enemy_rects.items) |*rect| {
        rect.rectangle.rotation += frame_time * rect.angular_velocity;
        if (rect.rectangle.rotation >= std.math.tau)
            rect.rectangle.rotation = 0;
    }
}

fn movePlayer(game: *Game) void {
    const direction = keyboardDirectionVector();
    if (direction.x == 0 and direction.y == 0)
        return;

    const frame_time = c.GetFrameTime();
    const velocity = math.mulScalar(direction, game.player.max_velocity * frame_time);
    game.player.hitbox.center = math.add(game.player.hitbox.center, velocity);
}

/// Returns which direction the keyboard wants something to move. The vector returned will be
/// normalized or the {0,0} vector if no direction is desired.
fn keyboardDirectionVector() math.Vector {
    const up_pressed: f32 = @floatFromInt(@intFromBool(c.IsKeyDown(c.KEY_UP)));
    const down_pressed: f32 = @floatFromInt(@intFromBool(c.IsKeyDown(c.KEY_DOWN)));
    const left_pressed: f32 = @floatFromInt(@intFromBool(c.IsKeyDown(c.KEY_LEFT)));
    const right_pressed: f32 = @floatFromInt(@intFromBool(c.IsKeyDown(c.KEY_RIGHT)));

    const base_velocity = math.Vector{
        .x = -left_pressed + right_pressed,
        .y = -up_pressed + down_pressed,
    };
    if (base_velocity.x == 0 and base_velocity.y == 0)
        return base_velocity;

    return math.normalize(base_velocity);
}

pub fn drawPhase(game: *Game) void {
    const width: f32 = @floatFromInt(c.GetRenderWidth());
    const height: f32 = @floatFromInt(c.GetRenderHeight());
    const width_ratio = width / (game.arena.half_wh.x * 2);
    const height_ratio = height / (game.arena.half_wh.y * 2);

    c.BeginMode2D(.{
        .offset = .{ .x = (width / 2.0), .y = (height / 2.0) },
        .zoom = @min(width_ratio, height_ratio),
    });

    c.DrawRectangleLinesEx(.{
        .x = game.arena.center.x - (game.arena.half_wh.x + game.arena_thickness),
        .y = game.arena.center.y - (game.arena.half_wh.y + game.arena_thickness),
        .width = (game.arena.half_wh.x + game.arena_thickness) * 2,
        .height = (game.arena.half_wh.y + game.arena_thickness) * 2,
    }, game.arena_thickness, colors.foreground);

    c.DrawCircleV(
        .{ .x = game.player.hitbox.center.x, .y = game.player.hitbox.center.y },
        game.player.hitbox.radius,
        colors.foreground,
    );

    c.EndMode2D();
}

pub const EnemyRectangle = struct {
    rectangle: shape.Rectangle,
    angular_velocity: f32 = 0,
};

pub const Player = struct {
    hitbox: shape.Circle,
    max_velocity: f32,
};

const Game = @This();

test {
    std.testing.refAllDecls(@This());
}

const c = @import("../c.zig");
const colors = @import("../colors.zig");
const draw = @import("../draw2d.zig");
const math = @import("../math2d.zig");
const shape = @import("../shape2d.zig");

const std = @import("std");
