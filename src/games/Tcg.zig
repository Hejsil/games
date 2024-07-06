allocator: std.mem.Allocator,
camera: c.Camera2D,

arena: shape.Rectangle,
arena_thickness: f32,

players: [2]Player,
hover: Hover,

pub fn init() Game {
    return .{
        .allocator = std.heap.c_allocator,
        .camera = .{},
        .arena = .{
            .center = .{ .x = 0, .y = 0 },
            .half_wh = .{ .x = 1920 / 2, .y = 1080 / 2 },
        },
        .arena_thickness = 10,
        .players = [_]Player{.{
            .hand = Hand.initWithCards(&.{
                .{ .cost = 1, .attack = 1, .health = 1 },
                .{ .cost = 2, .attack = 2, .health = 2 },
                .{ .cost = 3, .attack = 3, .health = 3 },
                .{ .cost = 4, .attack = 4, .health = 4 },
                .{ .cost = 5, .attack = 5, .health = 5 },
                .{ .cost = 6, .attack = 6, .health = 6 },
            }),
            .board = Player.empty.board,
        }} ** 2,
        .hover = Hover.none,
    };
}

pub fn updatePhase(game: *Game) void {
    const width: f32 = @floatFromInt(c.GetRenderWidth());
    const height: f32 = @floatFromInt(c.GetRenderHeight());
    const width_ratio = width / (game.arena.half_wh.x * 2);
    const height_ratio = height / (game.arena.half_wh.y * 2);
    game.camera = .{
        .offset = .{ .x = (width / 2.0), .y = (height / 2.0) },
        .zoom = @min(width_ratio, height_ratio),
    };

    game.updateHover();
}

fn updateHover(game: *Game) void {
    // const cursor_screen_pos = c.GetMousePosition();
    // const cursor_world_pos = c.GetScreenToWorld2D(cursor_screen_pos, game.camera);

    for (&game.players, 0..) |*player, player_i| {
        const cards = player.hand.cards();
        for (0..cards.len) |card_i_forward| {
            // Because we render cards from first to last, visually the last card will be on top.
            // Therefor, to ensure hovers work correctly, we need to do backwards iteration here.
            const card_i_backwards = (cards.len - 1) - card_i_forward;
            // const card = cards[card_i_backwards];
            // TODO:
            // const card_rect = ;
            game.hover = Hover.initHand(.{
                .player = @intCast(player_i),
                .hand = @intCast(card_i_backwards),
            });
            return;
        }
    }
}

pub fn drawPhase(game: *Game) void {
    c.BeginMode2D(game.camera);

    c.DrawRectangleLinesEx(.{
        .x = game.arena.center.x - (game.arena.half_wh.x + game.arena_thickness),
        .y = game.arena.center.y - (game.arena.half_wh.y + game.arena_thickness),
        .width = (game.arena.half_wh.x + game.arena_thickness) * 2,
        .height = (game.arena.half_wh.y + game.arena_thickness) * 2,
    }, game.arena_thickness, colors.foreground);

    game.drawHover();

    game.players[1].hand.draw(.{
        .center = .{ .x = 0, .y = -game.arena.half_wh.y },
        .rotation = std.math.pi,
    });
    game.players[0].hand.draw(.{
        .center = .{ .x = 0, .y = game.arena.half_wh.y },
        .rotation = 0,
    });

    // const cursor_screen_pos = c.GetMousePosition();
    // const cursor_world_pos = c.GetScreenToWorld2D(cursor_screen_pos, game.camera);
    // draw2d.text(.{
    //     .text = "Hello World",
    //     .center = .{ .x = cursor_world_pos.x, .y = cursor_world_pos.y },
    //     .color = c.RED,
    //     .size = 100,
    //     .spacing = 10,
    //     .rotation = @floatCast(c.GetTime()),
    // });
    // c.DrawCircleV(cursor_world_pos, 10, c.RED);
    c.EndMode2D();
}

fn drawHover(game: *const Game) void {
    const player_index = game.hover.player.unwrap() orelse return;
    const player = &game.players[player_index];
    if (game.hover.hand.unwrap()) |hand_index| {
        const card = player.hand.cards()[hand_index];
        card.draw(.{
            .center = .{
                .x = game.arena.center.x + game.arena.half_wh.x * 0.7,
                .y = game.arena.center.y,
            },
            .scale = 1.5,
        });
    }
}

pub const DrawOptions = struct {
    center: math.Vector,
    rotation: f32 = 0,
    scale: f32 = 1,
};

pub const Hover = struct {
    player: OptionalIndex,
    hand: OptionalIndex,
    board: OptionalIndex,

    pub const none = Hover{
        .player = .none,
        .hand = .none,
        .board = .none,
    };

    pub fn initHand(opt: struct { player: u8, hand: u8 }) Hover {
        return .{
            .player = OptionalIndex.some(opt.player),
            .hand = OptionalIndex.some(opt.hand),
            .board = .none,
        };
    }

    pub fn initBoard(opt: struct { player: u8, board: u8 }) Hover {
        return .{
            .player = OptionalIndex.some(opt.player),
            .hand = .none,
            .board = OptionalIndex.some(opt.board),
        };
    }

    pub const OptionalIndex = enum(u8) {
        none = std.math.maxInt(u8),
        _,

        pub fn some(index: u8) OptionalIndex {
            const res: OptionalIndex = @enumFromInt(index);
            std.debug.assert(res != .none);
            return res;
        }

        pub fn unwrap(index: OptionalIndex) ?u8 {
            if (index == .none)
                return null;
            return @intFromEnum(index);
        }
    };
};

const Player = struct {
    hand: Hand,
    board: [max_board_size]Card,

    pub const empty = Player{
        .hand = Hand.empty,
        .board = [_]Card{Card.none} ** max_board_size,
    };

    pub const max_board_size = 10;
};

pub const Hand = struct {
    cards_buffer: [max_cards]Card,

    pub const max_cards = 10;

    pub const empty = Hand{
        .cards_buffer = [_]Card{Card.none} ** max_cards,
    };

    pub fn initWithCards(the_cards: []const Card) Hand {
        var res: Hand = empty;
        @memcpy(res.cards_buffer[0..the_cards.len], the_cards);
        return res;
    }

    pub fn cards(hand: *const Hand) []const Card {
        for (hand.cards_buffer, 0..) |card, i| {
            if (card.isNone())
                return hand.cards_buffer[0..i];
        }

        return &hand.cards_buffer;
    }

    pub fn cardRectangle(hand: *const Hand, card_index: usize, opt: DrawOptions) shape.Rectangle {
        const cards_in_hand = hand.cards();
        std.debug.assert(cards_in_hand.len != 0);

        const distance_between_cards = Card.draw_width / 2.0;
        const card_width = Card.draw_width * opt.scale;
        const card_height = Card.draw_height * opt.scale;
        const hand_width = card_width + distance_between_cards *
            @as(f32, @floatFromInt(cards_in_hand.len - 1));

        const first_card_x = (opt.center.x - hand_width / 2) + card_width / 2;
        const card_x = first_card_x + distance_between_cards * @as(f32, @floatFromInt(card_index));
        return .{
            .center = math.rotate(.{ .x = card_x, .y = opt.center.y }, opt.center, opt.rotation),
            .half_wh = .{ .x = card_width / 2, .y = card_height / 2 },
            .rotation = opt.rotation,
        };
    }

    pub fn draw(hand: *const Hand, opt: DrawOptions) void {
        const cards_in_hand = hand.cards();
        if (cards_in_hand.len == 0)
            return;

        for (cards_in_hand, 0..) |card, i| {
            const card_rect = hand.cardRectangle(i, opt);
            card.draw(.{
                .center = card_rect.center,
                .rotation = card_rect.rotation,
                .scale = opt.scale,
            });
        }
    }
};

pub const Card = struct {
    cost: u8,
    attack: u8,
    health: u8,

    pub const none = Card{ .cost = 0, .attack = 0, .health = 0 };

    pub fn isNone(card: Card) bool {
        inline for (@typeInfo(Card).Struct.fields) |field| {
            if (@field(card, field.name) != @field(none, field.name))
                return false;
        }
        return true;
    }

    const draw_width = 200.0;
    const draw_height = 300.0;

    pub fn draw(card: Card, opt: DrawOptions) void {
        const width = draw_width * opt.scale;
        const height = draw_height * opt.scale;

        const top_left = math.Vector{
            .x = opt.center.x - width / 2,
            .y = opt.center.y - height / 2,
        };
        const bot_right = math.Vector{
            .x = opt.center.x + width / 2,
            .y = opt.center.y + height / 2,
        };

        draw2d.rectangleFill(.{
            .center = opt.center,
            .half_wh = .{ .x = width / 2, .y = height / 2 },
            .color = colors.foreground,
            .rotation = opt.rotation,
        });
        draw2d.rectangleBorder(.{
            .center = opt.center,
            .half_wh = .{ .x = width / 2, .y = height / 2 },
            .color = c.RED,
            .rotation = opt.rotation,
            .thickness = 4,
        });

        const text_size = 40;
        const text_spacing = 5;

        const text_left_offset = width * 0.1;
        const text_right_offset = width * 0.1;
        const text_top_offset = height * 0.09;
        const text_bot_offset = height * 0.08;

        const cost_pos = math.Vector{
            .x = top_left.x + text_left_offset,
            .y = top_left.y + text_top_offset,
        };
        var cost_buf: [255]u8 = undefined;
        const cost_text = std.fmt.bufPrintZ(&cost_buf, "{}", .{card.cost}) catch unreachable;
        draw2d.textZ(.{
            .text = cost_text.ptr,
            .center = cost_pos,
            .color = c.RED,
            .size = text_size,
            .spacing = text_spacing,
            .rotation = opt.rotation,
        });

        const attack_pos = math.Vector{
            .x = top_left.x + text_left_offset,
            .y = bot_right.y - text_bot_offset,
        };
        var attack_buf: [255]u8 = undefined;
        const attack_text = std.fmt.bufPrintZ(&attack_buf, "{}", .{card.attack}) catch unreachable;
        draw2d.textZ(.{
            .text = attack_text.ptr,
            .center = attack_pos,
            .color = c.RED,
            .size = text_size,
            .spacing = text_spacing,
            .rotation = opt.rotation,
        });

        const health_pos = math.Vector{
            .x = bot_right.x - text_right_offset,
            .y = bot_right.y - text_bot_offset,
        };
        var health_buf: [255]u8 = undefined;
        const health_text = std.fmt.bufPrintZ(&health_buf, "{}", .{card.health}) catch unreachable;
        draw2d.textZ(.{
            .text = health_text.ptr,
            .center = health_pos,
            .color = c.RED,
            .size = text_size,
            .spacing = text_spacing,
            .rotation = opt.rotation,
        });
    }
};

const Game = @This();

test {
    std.testing.refAllDecls(@This());
}

const c = @import("../c.zig");
const colors = @import("../colors.zig");
const draw2d = @import("../draw2d.zig");
const math = @import("../math2d.zig");
const shape = @import("../shape2d.zig");

const std = @import("std");
