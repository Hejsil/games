pub const Color = c.Color;

pub const GridOptions = struct {
    center: math.Vector,
    rows: usize,
    columns: usize,
    cell_size: math.Vector,
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

    const top_left = math.Vector{
        .x = (opt.center.x - (rows_f / 2) * opt.cell_size.x),
        .y = (opt.center.y - (columns_f / 2) * opt.cell_size.y),
    };
    for (0..row_lines) |row| {
        const row_f: f32 = @floatFromInt(row);
        const line_start = math.Vector{
            .x = top_left.x - opt.thickness / 2,
            .y = top_left.y + opt.cell_size.y * row_f,
        };
        const line_end = math.Vector{
            .x = line_start.x + opt.cell_size.x * columns_f + opt.thickness,
            .y = line_start.y,
        };
        c.DrawLineEx(
            toC(math.rotate(line_start, opt.center, opt.rotation)),
            toC(math.rotate(line_end, opt.center, opt.rotation)),
            opt.thickness,
            opt.color,
        );
    }
    for (0..column_lines) |column| {
        const column_f: f32 = @floatFromInt(column);
        const line_start = math.Vector{
            .x = top_left.x + opt.cell_size.x * column_f,
            .y = top_left.y - opt.thickness / 2,
        };
        const line_end = math.Vector{
            .x = line_start.x,
            .y = line_start.y + opt.cell_size.y * rows_f + opt.thickness,
        };
        c.DrawLineEx(
            toC(math.rotate(line_start, opt.center, opt.rotation)),
            toC(math.rotate(line_end, opt.center, opt.rotation)),
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
    const grid_top_left = math.Vector{
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
    center: math.Vector,
    size: math.Vector,
    color: Color,
    thickness: f32,
    rotation: f32 = 0,
};

pub fn x(opt: XOptions) void {
    // To ensure that the thickness of the X does not leave the confines of the bounding box, we pad
    // the start and end location of the lines.
    const padding = opt.thickness; // TODO: This is not correct, but good enough

    const top_left = math.Vector{
        .x = opt.center.x - (opt.size.x / 2) + padding,
        .y = opt.center.y - (opt.size.y / 2) + padding,
    };
    const bot_right = math.Vector{
        .x = opt.center.x + (opt.size.x / 2) - padding,
        .y = opt.center.y + (opt.size.y / 2) - padding,
    };
    const top_right = math.Vector{
        .x = bot_right.x,
        .y = top_left.y,
    };
    const bot_left = math.Vector{
        .x = top_left.x,
        .y = bot_right.y,
    };

    c.DrawLineEx(
        toC(math.rotate(top_left, opt.center, opt.rotation)),
        toC(math.rotate(bot_right, opt.center, opt.rotation)),
        opt.thickness,
        opt.color,
    );
    c.DrawLineEx(
        toC(math.rotate(top_right, opt.center, opt.rotation)),
        toC(math.rotate(bot_left, opt.center, opt.rotation)),
        opt.thickness,
        opt.color,
    );
}

pub const PlusOptions = struct {
    center: math.Vector,
    size: math.Vector,
    color: Color,
    thickness: f32,
    rotation: f32 = 0,
};

pub fn plus(opt: PlusOptions) void {
    const left = opt.center.x - (opt.size.x / 2);
    const right = opt.center.x + (opt.size.x / 2);
    const top = opt.center.y - (opt.size.y / 2);
    const bot = opt.center.y + (opt.size.y / 2);

    c.DrawLineEx(
        toC(math.rotate(.{ .x = left, .y = opt.center.y }, opt.center, opt.rotation)),
        toC(math.rotate(.{ .x = right, .y = opt.center.y }, opt.center, opt.rotation)),
        opt.thickness,
        opt.color,
    );
    c.DrawLineEx(
        toC(math.rotate(.{ .x = opt.center.x, .y = top }, opt.center, opt.rotation)),
        toC(math.rotate(.{ .x = opt.center.x, .y = bot }, opt.center, opt.rotation)),
        opt.thickness,
        opt.color,
    );
}

pub const RingOptions = struct {
    center: math.Vector,
    radius: f32,
    color: Color,
    thickness: f32,
};

pub fn ring(opt: RingOptions) void {
    c.DrawRing(
        toC(opt.center),
        opt.radius - opt.thickness,
        opt.radius,
        0,
        360,
        0,
        opt.color,
    );
}

pub const ArrowOptions = struct {
    center: math.Vector,
    length: f32,
    head_length: f32,
    color: Color,
    thickness: f32,
    rotation: f32 = 0,
};

pub fn arrow(opt: ArrowOptions) void {
    const shaft_vec = math.Vector{
        // 45deg vector of length 1 has x and y as the funny number below
        .x = (0.70710678118654752440 * opt.length),
        .y = (0.70710678118654752440 * opt.length),
    };
    const shaft_vec_half = math.Vector{
        .x = shaft_vec.x / 2,
        .y = shaft_vec.y / 2,
    };
    const shaft_start = math.Vector{
        .x = opt.center.x - shaft_vec_half.x,
        .y = opt.center.y - shaft_vec_half.y,
    };
    const shaft_end = math.Vector{
        .x = (opt.center.x + shaft_vec_half.x) - opt.thickness / 2,
        .y = (opt.center.y + shaft_vec_half.y) - opt.thickness / 2,
    };

    const thick_half = opt.thickness / 2;
    const head_tip = math.Vector{
        .x = opt.center.x + shaft_vec_half.x,
        .y = opt.center.y + shaft_vec_half.y,
    };
    const head1_start = math.Vector{
        .x = head_tip.x - thick_half,
        .y = head_tip.y,
    };
    const head1_end = math.Vector{
        .x = head_tip.x - thick_half,
        .y = head_tip.y - opt.head_length,
    };
    const head2_start = math.Vector{
        .x = head_tip.x,
        .y = head_tip.y - thick_half,
    };
    const head2_end = math.Vector{
        .x = head_tip.x - opt.head_length,
        .y = head_tip.y - thick_half,
    };

    const base_angle = -(std.math.pi / 4.0);
    c.DrawLineEx(
        toC(math.rotate(head1_start, opt.center, opt.rotation + base_angle)),
        toC(math.rotate(head1_end, opt.center, opt.rotation + base_angle)),
        opt.thickness,
        opt.color,
    );
    c.DrawLineEx(
        toC(math.rotate(head2_start, opt.center, opt.rotation + base_angle)),
        toC(math.rotate(head2_end, opt.center, opt.rotation + base_angle)),
        opt.thickness,
        opt.color,
    );
    c.DrawLineEx(
        toC(math.rotate(shaft_start, opt.center, opt.rotation + base_angle)),
        toC(math.rotate(shaft_end, opt.center, opt.rotation + base_angle)),
        opt.thickness,
        opt.color,
    );
}

pub const RectangleFillOptions = struct {
    center: math.Vector,
    half_wh: math.Vector,
    color: Color,
    rotation: f32 = 0,
};

pub fn rectangleFill(opt: RectangleFillOptions) void {
    c.DrawLineEx(
        toC(math.rotate(.{
            .x = opt.center.x - opt.half_wh.x,
            .y = opt.center.y,
        }, opt.center, opt.rotation)),
        toC(math.rotate(.{
            .x = opt.center.x + opt.half_wh.x,
            .y = opt.center.y,
        }, opt.center, opt.rotation)),
        opt.half_wh.y * 2,
        opt.color,
    );
}

pub const RectangleBorderOptions = struct {
    center: math.Vector,
    half_wh: math.Vector,
    color: Color,
    thickness: f32,
    rotation: f32 = 0,
};

pub fn rectangleBorder(opt: RectangleBorderOptions) void {
    c.DrawLineEx(
        toC(math.rotate(.{
            .x = opt.center.x - opt.half_wh.x,
            .y = opt.center.y - (opt.half_wh.y - opt.thickness / 2),
        }, opt.center, opt.rotation)),
        toC(math.rotate(.{
            .x = opt.center.x + opt.half_wh.x,
            .y = opt.center.y - (opt.half_wh.y - opt.thickness / 2),
        }, opt.center, opt.rotation)),
        opt.thickness,
        opt.color,
    );
    c.DrawLineEx(
        toC(math.rotate(.{
            .x = opt.center.x - opt.half_wh.x,
            .y = opt.center.y + (opt.half_wh.y - opt.thickness / 2),
        }, opt.center, opt.rotation)),
        toC(math.rotate(.{
            .x = opt.center.x + opt.half_wh.x,
            .y = opt.center.y + (opt.half_wh.y - opt.thickness / 2),
        }, opt.center, opt.rotation)),
        opt.thickness,
        opt.color,
    );

    c.DrawLineEx(
        toC(math.rotate(.{
            .x = opt.center.x - (opt.half_wh.x - opt.thickness / 2),
            .y = opt.center.y - opt.half_wh.y,
        }, opt.center, opt.rotation)),
        toC(math.rotate(.{
            .x = opt.center.x - (opt.half_wh.x - opt.thickness / 2),
            .y = opt.center.y + opt.half_wh.y,
        }, opt.center, opt.rotation)),
        opt.thickness,
        opt.color,
    );
    c.DrawLineEx(
        toC(math.rotate(.{
            .x = opt.center.x + (opt.half_wh.x - opt.thickness / 2),
            .y = opt.center.y - opt.half_wh.y,
        }, opt.center, opt.rotation)),
        toC(math.rotate(.{
            .x = opt.center.x + (opt.half_wh.x - opt.thickness / 2),
            .y = opt.center.y + opt.half_wh.y,
        }, opt.center, opt.rotation)),
        opt.thickness,
        opt.color,
    );
}

pub const TextOptions = struct {
    text: []const u8,
    center: math.Vector,
    color: Color,
    size: f32,
    spacing: f32,
    rotation: f32 = 0,
};

pub fn text(opt: TextOptions) void {
    var buf: [255]u8 = undefined;
    const text_z = std.fmt.bufPrintZ(&buf, "{s}", .{
        opt.text,
    }) catch unreachable; // TODO: Handle more text

    textZ(.{
        .text = text_z.ptr,
        .center = opt.center,
        .color = opt.color,
        .size = opt.size,
        .spacing = opt.spacing,
        .rotation = opt.rotation,
    });
}

pub const TextZOptions = struct {
    text: [*:0]const u8,
    center: math.Vector,
    color: Color,
    size: f32,
    spacing: f32,
    rotation: f32 = 0,
};

pub fn textZ(opt: TextZOptions) void {
    const font = c.GetFontDefault();
    const text_size = c.MeasureTextEx(font, opt.text, opt.size, opt.spacing);
    c.DrawTextPro(
        font,
        opt.text,
        .{ .x = opt.center.x, .y = opt.center.y },
        .{ .x = text_size.x / 2, .y = text_size.y / 2 },
        std.math.radiansToDegrees(opt.rotation),
        opt.size,
        opt.spacing,
        opt.color,
    );
    // rectangleBorder(.{
    //     .center = opt.center,
    //     .half_wh = .{ .x = text_size.x / 2, .y = text_size.y / 2 },
    //     .color = opt.color,
    //     .rotation = opt.rotation,
    //     .thickness = 2,
    // });
}

fn toC(vec: math.Vector) c.Vector2 {
    return .{ .x = vec.x, .y = vec.y };
}

test {
    std.testing.refAllDecls(@This());
}

const c = @import("c.zig");
const math = @import("math2d.zig");
const std = @import("std");
