player: Player = .x,
bitboards: [2]u16 = [_]u16{ 0, 0 },
scores: [2]u16 = [_]u16{ 0, 0 },

const Player = enum {
    x,
    o,

    fn next(player: Player) Player {
        return switch (player) {
            .x => .o,
            .o => .x,
        };
    }
};

const winning_boards = [_]u16{
    0b0000000000000111,
    0b0000000000111000,
    0b0000000111000000,
    0b0000000001001001,
    0b0000000010010010,
    0b0000000100100100,
    0b0000000100010001,
    0b0000000001010100,
};

pub fn update(game: *Game) void {
    if (!c.IsMouseButtonPressed(c.MOUSE_BUTTON_LEFT))
        return;

    const click_pos = c.GetMousePosition();
    const render_size = renderSize();

    const players_board = &game.bitboards[@intFromEnum(game.player)];
    outer: for (0..3) |y| {
        for (0..3) |x| {
            const pos: u4 = @intCast(x + y * 3);
            const x_is_set: u1 = @truncate(game.bitboards[@intFromEnum(Player.x)] >> pos);
            const o_is_set: u1 = @truncate(game.bitboards[@intFromEnum(Player.o)] >> pos);
            if (x_is_set != 0 or o_is_set != 0)
                continue;

            const cell_rect = cellRect(render_size, x, y);
            if (c.CheckCollisionPointRec(click_pos, cell_rect)) {
                players_board.* |= @as(u16, 1) << pos;
                game.player = game.player.next();
                break :outer;
            }
        }
    }

    outer: for (game.bitboards, 0..) |board, i| {
        for (winning_boards) |winning_board| {
            if (board & winning_board == winning_board) {
                game.bitboards = .{ 0, 0 };
                game.scores[i] += 1;
                game.player = .x;
                break :outer;
            }
        }
    }
}

pub fn draw(game: *Game) void {
    c.ClearBackground(c.RAYWHITE);

    const render_size = renderSize();
    const center_cell = cellRect(render_size, 1, 1);
    const thickness = center_cell.width / 20;
    const font_size: c_int = @intFromFloat(center_cell.width / 2);

    var scores_buf: [100]u8 = undefined;
    const scores = std.fmt.bufPrintZ(&scores_buf, "X {} | {} O", .{
        game.scores[@intFromEnum(Player.x)],
        game.scores[@intFromEnum(Player.o)],
    }) catch unreachable;

    const scores_size: f32 = @floatFromInt(c.MeasureText(scores.ptr, font_size));
    const score_pos = (center_cell.x + center_cell.width / 2) - scores_size / 2;
    c.DrawText(
        scores.ptr,
        @intFromFloat(score_pos),
        @intFromFloat(thickness),
        font_size,
        c.LIGHTGRAY,
    );

    c.DrawLineEx(
        .{
            .x = center_cell.x,
            .y = center_cell.y - center_cell.height,
        },
        .{
            .x = center_cell.x,
            .y = center_cell.y + center_cell.height * 2,
        },
        thickness,
        c.LIGHTGRAY,
    );

    c.DrawLineEx(
        .{
            .x = center_cell.x,
            .y = center_cell.y - center_cell.height,
        },
        .{
            .x = center_cell.x,
            .y = center_cell.y + center_cell.height * 2,
        },
        thickness,
        c.LIGHTGRAY,
    );
    c.DrawLineEx(
        .{
            .x = center_cell.x + center_cell.width,
            .y = center_cell.y - center_cell.height,
        },
        .{
            .x = center_cell.x + center_cell.width,
            .y = center_cell.y + center_cell.height * 2,
        },
        thickness,
        c.LIGHTGRAY,
    );
    c.DrawLineEx(
        .{
            .x = center_cell.x - center_cell.width,
            .y = center_cell.y,
        },
        .{
            .x = center_cell.x + center_cell.width * 2,
            .y = center_cell.y,
        },
        thickness,
        c.LIGHTGRAY,
    );
    c.DrawLineEx(
        .{
            .x = center_cell.x - center_cell.width,
            .y = center_cell.y + center_cell.height,
        },
        .{
            .x = center_cell.x + center_cell.width * 2,
            .y = center_cell.y + center_cell.height,
        },
        thickness,
        c.LIGHTGRAY,
    );

    for (0..3) |y| {
        for (0..3) |x| {
            const cell_rect = cellRect(render_size, x, y);
            const padding = cell_rect.width / 10;

            const pos: u4 = @intCast(x + y * 3);
            const x_is_set: u1 = @truncate(game.bitboards[@intFromEnum(Player.x)] >> pos);
            const o_is_set: u1 = @truncate(game.bitboards[@intFromEnum(Player.o)] >> pos);
            if (x_is_set != 0) {
                c.DrawLineEx(
                    .{
                        .x = cell_rect.x + padding,
                        .y = cell_rect.y + padding,
                    },
                    .{
                        .x = (cell_rect.x + cell_rect.width) - padding,
                        .y = (cell_rect.y + cell_rect.height) - padding,
                    },
                    thickness,
                    c.LIGHTGRAY,
                );
                c.DrawLineEx(
                    .{
                        .x = (cell_rect.x + cell_rect.width) - padding,
                        .y = cell_rect.y + padding,
                    },
                    .{
                        .x = cell_rect.x + padding,
                        .y = (cell_rect.y + cell_rect.height) - padding,
                    },
                    thickness,
                    c.LIGHTGRAY,
                );
            }
            if (o_is_set != 0) {
                c.DrawRing(
                    .{
                        .x = cell_rect.x + cell_rect.width / 2,
                        .y = cell_rect.y + cell_rect.height / 2,
                    },
                    cell_rect.width / 2 - (padding + thickness),
                    cell_rect.width / 2 - padding,
                    0,
                    360,
                    0,
                    c.LIGHTGRAY,
                );
            }
        }
    }
}

fn cellRect(screen_size: c.Vector2, x: usize, y: usize) c.Rectangle {
    const x_f: f32 = @floatFromInt(x);
    const y_f: f32 = @floatFromInt(y);
    const smallest_dim = @min(screen_size.x, screen_size.y);
    const cell_size = smallest_dim / 4;
    const top_left = c.Vector2{
        .x = (screen_size.x - smallest_dim) / 2 + cell_size / 2,
        .y = (screen_size.y - smallest_dim) / 2 + cell_size,
    };
    return .{
        .x = top_left.x + (x_f * cell_size),
        .y = top_left.y + (y_f * cell_size),
        .width = cell_size,
        .height = cell_size,
    };
}

fn renderSize() c.Vector2 {
    return .{
        .x = @floatFromInt(c.GetRenderWidth()),
        .y = @floatFromInt(c.GetRenderHeight()),
    };
}

const Game = @This();

const c = @import("../c.zig");

const std = @import("std");
