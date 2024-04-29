pub fn main() !void {
    var game = Game{ .state = .{
        .tic_tac_toe = .{},
    } };

    c.InitWindow(800, 450, "raylib");

    while (!c.WindowShouldClose()) {
        game.state.update();
        c.BeginDrawing();
        game.state.draw();
        c.EndDrawing();
    }
}

pub const Game = struct {
    state: State,
};

pub const State = union(enum) {
    tic_tac_toe: TicTacToe,

    pub fn update(state: *State) void {
        switch (state.*) {
            inline else => |*s| s.update(),
        }
    }

    pub fn draw(state: *State) void {
        switch (state.*) {
            inline else => |*s| s.draw(),
        }
    }
};

test {}

const TicTacToe = @import("games/TicTacToe.zig");

const c = @import("c.zig");

const std = @import("std");
