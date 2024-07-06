pub const Vector = struct {
    x: f32,
    y: f32,
};

pub fn rotate(point: Vector, centr: Vector, a: f32) Vector {
    if (a == 0)
        return point;

    const translated = Vector{
        .x = point.x - centr.x,
        .y = point.y - centr.y,
    };
    const rotated = rotateOrigin(translated, a);
    return .{
        .x = rotated.x + centr.x,
        .y = rotated.y + centr.y,
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

pub fn angle(point: Vector, center: Vector) f32 {
    const translated = Vector{
        .x = point.x - center.x,
        .y = point.y - center.y,
    };
    return angleOrigin(translated);
}

pub fn angleOrigin(point: Vector) f32 {
    return std.math.atan2(point.y, point.x);
}

test angleOrigin {
    try std.testing.expectEqual(@as(f32, std.math.pi * 0.0), angleOrigin(.{ .x = 1, .y = 0 }));
    try std.testing.expectEqual(@as(f32, std.math.pi * 0.5), angleOrigin(.{ .x = 0, .y = 1 }));
    try std.testing.expectEqual(@as(f32, std.math.pi * 1.0), angleOrigin(.{ .x = -1, .y = 0 }));
    try std.testing.expectEqual(@as(f32, std.math.pi * -0.5), angleOrigin(.{ .x = 0, .y = -1 }));
}

pub fn length(vec: Vector) f32 {
    return std.math.sqrt(length2(vec));
}

test length {
    try std.testing.expectEqual(@as(f32, 2.0), length(.{ .x = 2, .y = 0 }));
    try std.testing.expectEqual(@as(f32, 2.0), length(.{ .x = 0, .y = 2 }));
    try std.testing.expectEqual(@as(f32, 2.828427), length(.{ .x = 2, .y = 2 }));
}

pub fn length2(vec: Vector) f32 {
    return vec.x * vec.x + vec.y * vec.y;
}

test length2 {
    try std.testing.expectEqual(@as(f32, 4.0), length2(.{ .x = 2, .y = 0 }));
    try std.testing.expectEqual(@as(f32, 4.0), length2(.{ .x = 0, .y = 2 }));
    try std.testing.expectEqual(@as(f32, 8.0), length2(.{ .x = 2, .y = 2 }));
}

pub fn normalize(vec: Vector) Vector {
    const l = length(vec);
    return divScalar(vec, l);
}

test normalize {
    try std.testing.expectEqual(Vector{ .x = 1, .y = 0 }, normalize(.{ .x = 1, .y = 0 }));
    try std.testing.expectEqual(Vector{ .x = 0, .y = 1 }, normalize(.{ .x = 0, .y = 1 }));
    try std.testing.expectEqual(
        Vector{ .x = 0.7071067811865475, .y = 0.7071067811865475 },
        normalize(.{ .x = 1, .y = 1 }),
    );
    try std.testing.expectEqual(
        @as(f32, 0.99999994),
        length(normalize(.{ .x = 1, .y = 1 })),
    );
}

pub fn add(a: Vector, b: Vector) Vector {
    return .{ .x = a.x + b.x, .y = a.y + b.y };
}

pub fn sub(a: Vector, b: Vector) Vector {
    return .{ .x = a.x - b.x, .y = a.y - b.y };
}

pub fn mulScalar(vec: Vector, scalar: f32) Vector {
    return .{ .x = vec.x * scalar, .y = vec.y * scalar };
}

pub fn divScalar(vec: Vector, scalar: f32) Vector {
    return .{ .x = vec.x / scalar, .y = vec.y / scalar };
}

pub fn expectEqualVectors(expected: Vector, actual: Vector) !void {
    const abs_eps = std.math.floatEps(f32) * 2;
    const rel_eps = std.math.sqrt(abs_eps);
    if (@abs(expected.x) < 1 and @abs(actual.x) < 1) {
        try std.testing.expectApproxEqAbs(expected.x, actual.x, abs_eps);
    } else {
        try std.testing.expectApproxEqRel(expected.x, actual.x, rel_eps);
    }
    if (@abs(expected.y) < 1 and @abs(actual.y) < 1) {
        try std.testing.expectApproxEqAbs(expected.y, actual.y, abs_eps);
    } else {
        try std.testing.expectApproxEqRel(expected.y, actual.y, rel_eps);
    }
}

test {
    std.testing.refAllDecls(@This());
}

const c = @import("c.zig");
const std = @import("std");
