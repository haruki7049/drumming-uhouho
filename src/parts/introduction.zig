const std = @import("std");
const lightmix = @import("lightmix");

const Wave = lightmix.Wave;
const Composer = lightmix.Composer;

fn Options(comptime Utils: type) type {
    return struct {
        utils: Utils,

        bpm: usize,
        amplitude: f32,

        sample_rate: usize,
        channels: usize,
    };
}

pub fn generate(allocator: std.mem.Allocator, comptime options: Options(type)) !Wave(f128) {
    const samples_per_beat: usize = @intFromFloat(@as(f32, @floatFromInt(60)) / @as(f32, @floatFromInt(options.bpm)) * @as(f32, @floatFromInt(options.sample_rate)));

    const melodies: []const Composer(f128).WaveInfo = &.{
        .{
            .wave = try options.utils.Generators.Drum.Base.A.generate(allocator, .{
                .utils = options.utils,
                .frequency = options.utils.Scale.generate_freq(.{ .code = .c, .octave = 2 }),
                .bpm = options.bpm,
                .amplitude = options.amplitude,
                .sample_rate = options.sample_rate,
                .channels = options.channels,
            }),
            .start_point = samples_per_beat * 0,
        },
        .{
            .wave = try options.utils.Generators.Drum.Base.A.generate(allocator, .{
                .utils = options.utils,
                .frequency = options.utils.Scale.generate_freq(.{ .code = .c, .octave = 2 }),
                .bpm = options.bpm,
                .amplitude = options.amplitude,
                .sample_rate = options.sample_rate,
                .channels = options.channels,
            }),
            .start_point = samples_per_beat * 8,
        },
        .{
            .wave = try options.utils.Generators.Drum.Base.A.generate(allocator, .{
                .utils = options.utils,
                .frequency = options.utils.Scale.generate_freq(.{ .code = .c, .octave = 2 }),
                .bpm = options.bpm,
                .amplitude = options.amplitude,
                .sample_rate = options.sample_rate,
                .channels = options.channels,
            }),
            .start_point = samples_per_beat * 16,
        },
        .{
            .wave = try options.utils.Generators.Drum.HighHat.OffBeats.generate(allocator, .{
                .utils = options.utils,
                .bpm = options.bpm,
                .amplitude = options.amplitude,
                .state = .closed,
                .sample_rate = options.sample_rate,
                .channels = options.channels,
            }),
            .start_point = samples_per_beat * 16,
        },
        .{
            .wave = try options.utils.Generators.Drum.Base.A.generate(allocator, .{
                .utils = options.utils,
                .frequency = options.utils.Scale.generate_freq(.{ .code = .c, .octave = 2 }),
                .bpm = options.bpm,
                .amplitude = options.amplitude,
                .sample_rate = options.sample_rate,
                .channels = options.channels,
            }),
            .start_point = samples_per_beat * 24,
        },
        .{
            .wave = try options.utils.Generators.Drum.HighHat.OffBeats.generate(allocator, .{
                .utils = options.utils,
                .bpm = options.bpm,
                .amplitude = options.amplitude,
                .state = .closed,
                .sample_rate = options.sample_rate,
                .channels = options.channels,
            }),
            .start_point = samples_per_beat * 24,
        },
    };

    const composer: Composer(f128) = try Composer(f128).init_with(melodies, allocator, .{
        .sample_rate = options.sample_rate,
        .channels = options.channels,
    });
    defer composer.deinit();

    return try composer.finalize(.{});
}
