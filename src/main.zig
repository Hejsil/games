pub fn main() !void {
    var game = Game{};

    c.SetConfigFlags(c.FLAG_WINDOW_RESIZABLE);
    c.InitWindow(1920, 1080, "raylib");
    c.SetTargetFPS(60);

    // Test
    while (!c.WindowShouldClose()) {
        game.state.updatePhase();
        c.BeginDrawing();
        c.ClearBackground(colors.background);
        game.state.drawPhase();
        c.DrawFPS(10, 10);
        c.EndDrawing();
    }
}

const Game = struct {
    state: State = .{ .main_menu = .{} },
};

const State = union(enum) {
    main_menu: MainMenu,
    tic_tac_toe: TicTacToe,
    bullet_hell: BulletHell,
    tcg: Tcg,

    pub fn updatePhase(state: *State) void {
        switch (state.*) {
            inline else => |*s| s.updatePhase(),
        }
    }

    pub fn drawPhase(state: *State) void {
        switch (state.*) {
            inline else => |*s| s.drawPhase(),
        }
    }
};

const MainMenu = struct {
    selected: usize = 0,

    // Assumes `main_menu` is the first state
    const menu_items = std.meta.tags(std.meta.Tag(State))[1..];

    fn init() MainMenu {
        return .{};
    }

    fn updatePhase(menu: *MainMenu) void {
        if (c.IsKeyPressed(c.KEY_DOWN)) {
            menu.selected += 1;
            menu.selected = @min(menu.selected, menu_items.len - 1);
        }
        if (c.IsKeyPressed(c.KEY_UP)) {
            menu.selected -|= 1;
        }
        if (c.IsKeyPressed(c.KEY_ENTER)) {
            const state: *State = @fieldParentPtr("main_menu", menu);
            state.* = switch (menu_items[menu.selected]) {
                inline else => |tag| blk: {
                    var res = @unionInit(State, @tagName(tag), undefined);
                    const field_ptr = &@field(res, @tagName(tag));
                    const T = @TypeOf(field_ptr.*);
                    field_ptr.* = T.init();
                    break :blk res;
                },
            };
        }
    }

    fn drawPhase(menu: *MainMenu) void {
        const width: f32 = @floatFromInt(c.GetRenderWidth());
        const height: f32 = @floatFromInt(c.GetRenderHeight());
        const size = @min(width, height);
        const center_w = width / 2;
        const center_h = height / 2;

        const font_size = size / 10;
        const line_size = size / 120;
        for (menu_items, 0..) |menu_item, i| {
            const i_f32: f32 = @floatFromInt(i);
            const selected_f32: f32 = @floatFromInt(menu.selected);
            const distance_from_selected = i_f32 - selected_f32;

            const menu_item_str = @tagName(menu_item);
            const menu_item_size: f32 = @floatFromInt(c.MeasureText(
                menu_item_str.ptr,
                @intFromFloat(font_size),
            ));

            const menu_item_x = center_w - menu_item_size / 2;
            const menu_item_y = (center_h + font_size * distance_from_selected) - font_size / 2;
            c.DrawText(
                menu_item_str.ptr,
                @intFromFloat(menu_item_x),
                @intFromFloat(menu_item_y),
                @intFromFloat(font_size),
                colors.foreground,
            );
            if (i == menu.selected) {
                const line_y = menu_item_y + font_size - line_size / 2;
                c.DrawLineEx(
                    .{ .x = menu_item_x, .y = line_y },
                    .{ .x = menu_item_x + menu_item_size, .y = line_y },
                    line_size,
                    colors.foreground,
                );
            }
        }
    }
};

test {
    std.testing.refAllDecls(@This());
}

const BulletHell = @import("games/BulletHell.zig");
const Tcg = @import("games/Tcg.zig");
const TicTacToe = @import("games/TicTacToe.zig");

const c = @import("c.zig");
const colors = @import("colors.zig");

const std = @import("std");
