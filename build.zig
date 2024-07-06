const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "games",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        // .use_llvm = false,
        // .use_lld = false,
    });
    b.installArtifact(exe);

    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);

    for ([_]*std.Build.Step.Compile{ exe, exe_unit_tests }) |comp| {
        comp.linkSystemLibrary2("raylib", .{});
        comp.linkSystemLibrary2("GL", .{});
        comp.linkSystemLibrary2("rt", .{});
        comp.linkSystemLibrary2("dl", .{});
        comp.linkSystemLibrary2("m", .{});
        comp.linkSystemLibrary2("X11", .{});
    }
}
