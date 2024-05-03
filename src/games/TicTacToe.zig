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
    const render_size = renderSize();
    const center_cell = cellRect(render_size, 1, 1);
    const thickness = center_cell.width / 20;
    const font_size = center_cell.width / 2;

    var scores_buf: [100]u8 = undefined;
    const scores = std.fmt.bufPrintZ(&scores_buf, "{} | {}", .{
        game.scores[@intFromEnum(Player.x)],
        game.scores[@intFromEnum(Player.o)],
    }) catch unreachable;

    const center_x = (center_cell.x + center_cell.width / 2);
    const scores_size: f32 = @floatFromInt(c.MeasureText(scores.ptr, @intFromFloat(font_size)));
    const score_pos = center_x - scores_size / 2;
    c.DrawText(
        scores.ptr,
        @intFromFloat(score_pos),
        @intFromFloat(thickness),
        @intFromFloat(font_size),
        colors.foreground,
    );

    // trial and error math to make the symbols line up with the text
    const symbol_size = font_size * 0.5;
    drawX(
        (center_x - symbol_size * 0.5) - symbol_size * 3,
        thickness + symbol_size * 0.4,
        symbol_size,
        thickness,
    );
    drawO(
        (center_x - symbol_size * 0.5) + symbol_size * 3,
        thickness + symbol_size * 0.4,
        symbol_size,
        thickness,
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
        colors.foreground,
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
        colors.foreground,
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
        colors.foreground,
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
        colors.foreground,
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
        colors.foreground,
    );

    for (0..3) |y| {
        for (0..3) |x| {
            const cell_rect = cellRect(render_size, x, y);
            const padding = cell_rect.width / 10;

            const pos: u4 = @intCast(x + y * 3);
            const x_is_set: u1 = @truncate(game.bitboards[@intFromEnum(Player.x)] >> pos);
            const o_is_set: u1 = @truncate(game.bitboards[@intFromEnum(Player.o)] >> pos);
            if (x_is_set != 0) {
                drawX(
                    cell_rect.x + padding,
                    cell_rect.y + padding,
                    cell_rect.width - (padding * 2),
                    thickness,
                );
            }
            if (o_is_set != 0) {
                drawO(
                    cell_rect.x + padding,
                    cell_rect.y + padding,
                    cell_rect.width - (padding * 2),
                    thickness,
                );
            }
        }
    }
}

fn drawX(x: f32, y: f32, size: f32, thickness: f32) void {
    c.DrawLineEx(
        .{ .x = x + thickness, .y = y + thickness },
        .{ .x = (x + size) - thickness, .y = (y + size) - thickness },
        thickness,
        colors.foreground,
    );
    c.DrawLineEx(
        .{ .x = (x + size) - thickness, .y = y + thickness },
        .{ .x = x + thickness, .y = (y + size) - thickness },
        thickness,
        colors.foreground,
    );
}

fn drawO(x: f32, y: f32, size: f32, thinkness: f32) void {
    c.DrawRing(
        .{ .x = x + size / 2, .y = y + size / 2 },
        (size / 2) - thinkness,
        (size / 2),
        0,
        360,
        0,
        colors.foreground,
    );
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
const colors = @import("../colors.zig");

const std = @import("std");
