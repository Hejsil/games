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
    const grid = gridOptions(render_size);

    const players_board = &game.bitboards[@intFromEnum(game.player)];
    outer: for (0..3) |row| {
        for (0..3) |column| {
            const pos: u4 = @intCast(column + row * 3);
            const x_is_set: u1 = @truncate(game.bitboards[@intFromEnum(Player.x)] >> pos);
            const o_is_set: u1 = @truncate(game.bitboards[@intFromEnum(Player.o)] >> pos);
            if (x_is_set != 0 or o_is_set != 0)
                continue;

            const cell_rect = draw2d.getCell(row, column, grid);
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
    const grid = gridOptions(render_size);
    const font_size = grid.thickness * 10;

    var scores_buf: [100]u8 = undefined;
    const scores = std.fmt.bufPrintZ(&scores_buf, "{}  {}", .{
        game.scores[@intFromEnum(Player.x)],
        game.scores[@intFromEnum(Player.o)],
    }) catch unreachable;

    const scores_size: f32 = @floatFromInt(c.MeasureText(scores.ptr, @intFromFloat(font_size)));
    const center_x = render_size.x / 2;
    const score_pos = center_x - scores_size / 2;
    c.DrawText(
        scores.ptr,
        @intFromFloat(score_pos),
        @intFromFloat(grid.thickness),
        @intFromFloat(font_size),
        colors.foreground,
    );

    const score_symbol_x_off = grid.cell_size.x;
    const score_symbol_y = grid.cell_size.y * 0.35;
    const symbol_size = font_size * 0.75;
    draw2d.x(.{
        .center = .{ .x = center_x - score_symbol_x_off, .y = score_symbol_y },
        .size = .{ .x = symbol_size, .y = symbol_size },
        .thickness = grid.thickness,
        .color = colors.foreground,
    });
    draw2d.ring(.{
        .center = .{ .x = center_x + score_symbol_x_off, .y = score_symbol_y },
        .radius = symbol_size / 2,
        .thickness = grid.thickness,
        .color = colors.foreground,
    });

    draw2d.grid(grid);

    for (0..3) |row| {
        for (0..3) |column| {
            const cell_rect = draw2d.getCell(row, column, grid);
            const padding = cell_rect.width / 10;
            const cell_center = draw2d.Vector{
                .x = cell_rect.x + cell_rect.width / 2,
                .y = cell_rect.y + cell_rect.height / 2,
            };

            const pos: u4 = @intCast(column + row * 3);
            const x_is_set: u1 = @truncate(game.bitboards[@intFromEnum(Player.x)] >> pos);
            const o_is_set: u1 = @truncate(game.bitboards[@intFromEnum(Player.o)] >> pos);
            if (x_is_set != 0) {
                draw2d.x(.{
                    .center = cell_center,
                    .size = .{
                        .x = cell_rect.width - padding,
                        .y = cell_rect.height - padding,
                    },
                    .thickness = grid.thickness,
                    .color = colors.foreground,
                });
            }
            if (o_is_set != 0) {
                draw2d.ring(.{
                    .center = cell_center,
                    .radius = (cell_rect.width - padding) / 2,
                    .thickness = grid.thickness,
                    .color = colors.foreground,
                });
            }
        }
    }
}

fn renderSize() c.Vector2 {
    return .{
        .x = @floatFromInt(c.GetRenderWidth()),
        .y = @floatFromInt(c.GetRenderHeight()),
    };
}

fn cellSize(screen_size: c.Vector2) f32 {
    const smallest_dim = @min(screen_size.x, screen_size.y);
    return smallest_dim / 4;
}

fn gridPosition(screen_size: c.Vector2) c.Vector2 {
    const cell_size = cellSize(screen_size);
    return .{
        .x = screen_size.x / 2,
        .y = screen_size.y / 2 + cell_size / 3,
    };
}

fn gridOptions(screen_size: c.Vector2) draw2d.GridOptions {
    const grid_pos = gridPosition(screen_size);
    const cell_size = cellSize(screen_size);
    const thickness = cell_size / 16;
    return draw2d.GridOptions{
        .rows = 3,
        .columns = 3,
        .center = grid_pos,
        .cell_size = .{ .x = cell_size, .y = cell_size },
        .thickness = thickness,
        .color = colors.foreground,
    };
}

const Game = @This();

const c = @import("../c.zig");
const colors = @import("../colors.zig");
const draw2d = @import("../draw2d.zig");

const std = @import("std");
