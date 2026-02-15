const std = @import("std");
const lightmix = @import("lightmix");
const lightmix_filters = @import("lightmix_filters");
const lightmix_synths = @import("lightmix_synths");

const Wave = lightmix.Wave;
const Composer = lightmix.Composer;

const cutAttack = lightmix_filters.volume.cutAttack;
const CutAttackArgs = lightmix_filters.volume.CutAttackArgs;
const decay = lightmix_filters.volume.decay;
const DecayArgs = lightmix_filters.volume.DecayArgs;

pub fn generate(allocator: std.mem.Allocator, options: Options) !Wave(f128) {
    const samples_per_beat: usize = @intFromFloat(@as(f32, @floatFromInt(60)) / @as(f32, @floatFromInt(options.bpm)) * @as(f32, @floatFromInt(options.sample_rate)));

    var waveinfo_list: std.array_list.Aligned(Composer(f128).WaveInfo, null) = .empty;
    defer waveinfo_list.deinit(allocator);

    defer for (waveinfo_list.items) |waveinfo| {
        waveinfo.wave.deinit();
    };

    {
        var wave_list: std.array_list.Aligned(Wave(f128), null) = .empty;
        defer wave_list.deinit(allocator);

        for (0..7) |_| {
            var result: Wave(f128) = try lightmix_synths.Basic.Sine.gen(f128, .{
                .frequency = options.frequency,
                .length = samples_per_beat,
                .amplitude = options.amplitude,
                .allocator = allocator,

                .sample_rate = options.sample_rate,
                .channels = options.channels,
            });

            // Filters
            for (0..1) |_| {
                try result.filter_with(CutAttackArgs, cutAttack, .{});
            }

            for (0..6) |_| {
                try result.filter_with(DecayArgs, decay, .{});
            }

            try wave_list.append(allocator, result);
        }

        var start_point: usize = 0;
        for (wave_list.items) |wave| {
            try waveinfo_list.append(allocator, .{ .wave = wave, .start_point = start_point });

            start_point = start_point + samples_per_beat;
        }
    }

    {
        var wave_list: std.array_list.Aligned(Wave(f128), null) = .empty;
        defer wave_list.deinit(allocator);

        for (0..2) |_| {
            var result: Wave(f128) = try lightmix_synths.Basic.Sine.gen(f128, .{
                .frequency = options.frequency,
                .length = samples_per_beat,
                .amplitude = options.amplitude,
                .allocator = allocator,

                .sample_rate = options.sample_rate,
                .channels = options.channels,
            });

            // Filters
            for (0..1) |_| {
                try result.filter_with(CutAttackArgs, cutAttack, .{});
            }

            for (0..6) |_| {
                try result.filter_with(DecayArgs, decay, .{});
            }

            try wave_list.append(allocator, result);
        }

        var start_point: usize = samples_per_beat * 7;
        for (wave_list.items) |wave| {
            try waveinfo_list.append(allocator, .{ .wave = wave, .start_point = start_point });

            start_point = start_point + (samples_per_beat / 2);
        }
    }

    const composer: Composer(f128) = try Composer(f128).init_with(waveinfo_list.items, allocator, .{
        .sample_rate = options.sample_rate,
        .channels = options.channels,
    });
    defer composer.deinit();

    return try composer.finalize(.{});
}

pub const Options = struct {
    bpm: usize,
    frequency: f32,
    amplitude: f32,
    sample_rate: u32,
    channels: u16,
};
