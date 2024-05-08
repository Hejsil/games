pub const Vector = c.Vector2;
pub const Color = c.Color;
pub const Rectangle = c.Rectangle;

pub const GridOptions = struct {
    center: Vector,
    rows: usize,
    columns: usize,
    cell_size: Vector,
    color: Color,
    thickness: f32,
    rotation: f32 = 0,
};

pub fn grid(opt: GridOptions) void {
    if (opt.rows == 0 or opt.columns == 0)
        return;

    const row_lines = opt.rows + 1;
    const column_lines = opt.columns + 1;
    const rows_f: f32 = @floatFromInt(opt.rows);
    const columns_f: f32 = @floatFromInt(opt.columns);

    const top_left = Vector{
        .x = (opt.center.x - (rows_f / 2) * opt.cell_size.x),
        .y = (opt.center.y - (columns_f / 2) * opt.cell_size.y),
    };
    for (0..row_lines) |row| {
        const row_f: f32 = @floatFromInt(row);
        const line_start = Vector{
            .x = top_left.x - opt.thickness / 2,
            .y = top_left.y + opt.cell_size.y * row_f,
        };
        const line_end = Vector{
            .x = line_start.x + opt.cell_size.x * columns_f + opt.thickness,
            .y = line_start.y,
        };
        c.DrawLineEx(
            rotate(line_start, opt.center, opt.rotation),
            rotate(line_end, opt.center, opt.rotation),
            opt.thickness,
            opt.color,
        );
    }
    for (0..column_lines) |column| {
        const column_f: f32 = @floatFromInt(column);
        const line_start = Vector{
            .x = top_left.x + opt.cell_size.x * column_f,
            .y = top_left.y - opt.thickness / 2,
        };
        const line_end = Vector{
            .x = line_start.x,
            .y = line_start.y + opt.cell_size.y * rows_f + opt.thickness,
        };
        c.DrawLineEx(
            rotate(line_start, opt.center, opt.rotation),
            rotate(line_end, opt.center, opt.rotation),
            opt.thickness,
            opt.color,
        );
    }
}

pub fn getCell(row: usize, column: usize, opt: GridOptions) c.Rectangle {
    std.debug.assert(row < opt.rows);
    std.debug.assert(column < opt.columns);

    const row_f: f32 = @floatFromInt(row);
    const column_f: f32 = @floatFromInt(column);
    const rows_f: f32 = @floatFromInt(opt.rows);
    const columns_f: f32 = @floatFromInt(opt.columns);
    const grid_top_left = Vector{
        .x = (opt.center.x - (rows_f / 2) * opt.cell_size.x),
        .y = (opt.center.y - (columns_f / 2) * opt.cell_size.y),
    };
    return .{
        .x = grid_top_left.x + opt.cell_size.x * column_f,
        .y = grid_top_left.y + opt.cell_size.y * row_f,
        .width = opt.cell_size.x,
        .height = opt.cell_size.y,
    };
}

pub const XOptions = struct {
    center: Vector,
    size: Vector,
    color: Color,
    thickness: f32,
    rotation: f32 = 0,
};

pub fn x(opt: XOptions) void {
    // To ensure that the thickness of the X does not leave the confines of the bounding box, we pad
    // the start and end location of the lines.
    const padding = opt.thickness; // TODO: This is not correct, but good enough

    const top_left = Vector{
        .x = opt.center.x - (opt.size.x / 2) + padding,
        .y = opt.center.y - (opt.size.y / 2) + padding,
    };
    const bot_right = Vector{
        .x = opt.center.x + (opt.size.x / 2) - padding,
        .y = opt.center.y + (opt.size.y / 2) - padding,
    };
    const top_right = Vector{
        .x = bot_right.x,
        .y = top_left.y,
    };
    const bot_left = Vector{
        .x = top_left.x,
        .y = bot_right.y,
    };

    const first_line_start = rotate(top_left, opt.center, opt.rotation);
    const first_line_end = rotate(bot_right, opt.center, opt.rotation);
    const second_line_start = rotate(top_right, opt.center, opt.rotation);
    const second_line_end = rotate(bot_left, opt.center, opt.rotation);
    c.DrawLineEx(first_line_start, first_line_end, opt.thickness, opt.color);
    c.DrawLineEx(second_line_start, second_line_end, opt.thickness, opt.color);
}

pub const PlusOptions = struct {
    center: Vector,
    size: Vector,
    color: Color,
    thickness: f32,
    rotation: f32 = 0,
};

pub fn plus(opt: PlusOptions) void {
    const left = opt.center.x - (opt.size.x / 2);
    const right = opt.center.x + (opt.size.x / 2);
    const top = opt.center.y - (opt.size.y / 2);
    const bot = opt.center.y + (opt.size.y / 2);

    const first_line_start = rotate(.{ .x = left, .y = opt.center.y }, opt.center, opt.rotation);
    const first_line_end = rotate(.{ .x = right, .y = opt.center.y }, opt.center, opt.rotation);
    const second_line_start = rotate(.{ .x = opt.center.x, .y = top }, opt.center, opt.rotation);
    const second_line_end = rotate(.{ .x = opt.center.x, .y = bot }, opt.center, opt.rotation);
    c.DrawLineEx(first_line_start, first_line_end, opt.thickness, opt.color);
    c.DrawLineEx(second_line_start, second_line_end, opt.thickness, opt.color);
}

pub const RingOptions = struct {
    center: Vector,
    radius: f32,
    color: Color,
    thickness: f32,
};

pub fn ring(opt: RingOptions) void {
    c.DrawRing(
        opt.center,
        opt.radius - opt.thickness,
        opt.radius,
        0,
        360,
        0,
        opt.color,
    );
}

fn rotate(point: Vector, center: Vector, a: f32) Vector {
    const translated = Vector{
        .x = point.x - center.x,
        .y = point.y - center.y,
    };
    const rotated = rotateOrigin(translated, a);
    return .{
        .x = rotated.x + center.x,
        .y = rotated.y + center.y,
    };
}

pub fn rotateOrigin(point: Vector, a: f32) Vector {
    const cos = std.math.cos(a);
    const sin = std.math.sin(a);
    return .{
        .x = point.x * cos - point.y * sin,
        .y = point.y * cos + point.x * sin,
    };
}

const c = @import("c.zig");
const std = @import("std");
