const std = @import("std");
const l = @import("lightmix");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lightmix = b.dependency("lightmix", .{});
    const lightmix_filters = b.dependency("lightmix_filters", .{});
    const lightmix_synths = b.dependency("lightmix_synths", .{});

    const mod = b.addModule("kicking", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "lightmix", .module = lightmix.module("lightmix") },
            .{ .name = "lightmix_filters", .module = lightmix_filters.module("lightmix_filters") },
            .{ .name = "lightmix_synths", .module = lightmix_synths.module("lightmix_synths") },
        },
    });

    // Library linking on Linux
    if (target.result.os.tag == .linux) {
        mod.linkSystemLibrary("alsa", .{});
        mod.linkSystemLibrary("libpulse", .{});
        mod.linkSystemLibrary("libpipewire-0.3", .{});
    }

    // Sample generation
    const wave = try l.addWave(b, mod, .{
        .func_name = "testwave_gen",
        .wave = .{ .bits = 16, .format_code = .pcm },
    });
    l.installWave(b, wave);

    const play_step = b.step("play", "Play produced Wave file by lightmix");
    const play = try l.addPlay(b, wave, .{});
    play_step.dependOn(&play.step);

    // Unit tests
    const unit_tests = b.addTest(.{ .root_module = mod });
    const run_unit_tests = b.addRunArtifact(unit_tests);

    // Test step
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
