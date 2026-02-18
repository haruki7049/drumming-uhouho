const std = @import("std");
const lightmix = @import("lightmix");
const lightmix_filters = @import("lightmix_filters");
const lightmix_synths = @import("lightmix_synths");

const Wave = lightmix.Wave;
const cutAttack = lightmix_filters.volume.cutAttack;
const CutAttackArgs = lightmix_filters.volume.CutAttackArgs;
const decay = lightmix_filters.volume.decay;
const DecayArgs = lightmix_filters.volume.DecayArgs;

pub fn gen(comptime T: type, options: Options) !Wave(T) {
    var drum = try lightmix_synths.Basic.Sine.gen(T, .{
        .frequency = options.frequency,
        .length = options.length,
        .amplitude = options.amplitude,
        .allocator = options.allocator,
        .sample_rate = options.sample_rate,
        .channels = options.channels,
    });

    for (0..1) |_| {
        try drum.filter_with(CutAttackArgs, cutAttack, .{});
    }
    for (0..12) |_| {
        try drum.filter_with(DecayArgs, decay, .{});
    }

    return drum;
}

pub const Options = struct {
    allocator: std.mem.Allocator,
    frequency: f32,
    length: usize,
    amplitude: f32,
    sample_rate: u32,
    channels: u16,
};

pub fn testwave_gen(allocator: std.mem.Allocator) !Wave(f128) {
    var result: Wave(f128) = try gen(f128, .{
        .allocator = allocator,
        .frequency = 110.0,
        .length = 44100,
        .amplitude = 1.0,
        .sample_rate = 44100,
        .channels = 1,
    });
    try result.filter(normalize);

    return result;
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
