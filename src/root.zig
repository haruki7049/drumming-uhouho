const std = @import("std");
const lightmix = @import("lightmix");

const Wave = lightmix.Wave;
const Composer = lightmix.Composer;
const WaveInfo = Composer.WaveInfo;

const Parts = @import("./parts.zig");

pub fn gen(allocator: std.mem.Allocator) !Wave(f128) {
    var introduction: Wave(f128) = try Parts.Introduction.generate(allocator, .{
        .bpm = 170,
        .amplitude = 1.0,

        .sample_rate = 44100,
        .channels = 1,
    });
    try introduction.filter(normalize);

    return introduction;
}

fn normalize(comptime T: type, original_wave: Wave(T)) !Wave(T) {
    const allocator = original_wave.allocator;
    var result: std.array_list.Aligned(T, null) = .empty;

    var max_volume: T = 0.0;
    for (original_wave.samples) |sample| {
        if (@abs(sample) > max_volume)
            max_volume = @abs(sample);
    }

    for (original_wave.samples) |sample| {
        const volume: T = 1.0 / max_volume;

        const new_sample: T = sample * volume;
        try result.append(allocator, new_sample);
    }

    return Wave(T){
        .samples = try result.toOwnedSlice(allocator),
        .allocator = allocator,

        .sample_rate = original_wave.sample_rate,
        .channels = original_wave.channels,
    };
}
