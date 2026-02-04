const std = @import("std");
const lightmix = @import("lightmix");
const lightmix_temperaments = @import("lightmix_temperaments");
const hatter = @import("hatter");
const du_patterns = @import("du_patterns");

const Wave = lightmix.Wave;
const Composer = lightmix.Composer;
const Scale = lightmix_temperaments.TwelveEqualTemperament;

pub const Options = struct {
    bpm: usize,
    amplitude: f32,

    sample_rate: u32,
    channels: u16,
};

pub fn generate(allocator: std.mem.Allocator, options: Options) !Wave(f128) {
    const samples_per_beat: usize = @intFromFloat(@as(f32, @floatFromInt(60)) / @as(f32, @floatFromInt(options.bpm)) * @as(f32, @floatFromInt(options.sample_rate)));

    const melodies: []const Composer(f128).WaveInfo = &.{
        .{
            .wave = try du_patterns.Drum.Base.A.generate(allocator, .{
                .frequency = Scale.gen(.{ .code = .c, .octave = 2 }),
                .bpm = options.bpm,
                .amplitude = options.amplitude,
                .sample_rate = options.sample_rate,
                .channels = options.channels,
            }),
            .start_point = samples_per_beat * 0,
        },
        .{
            .wave = try du_patterns.Drum.Base.A.generate(allocator, .{
                .frequency = Scale.gen(.{ .code = .c, .octave = 2 }),
                .bpm = options.bpm,
                .amplitude = options.amplitude,
                .sample_rate = options.sample_rate,
                .channels = options.channels,
            }),
            .start_point = samples_per_beat * 8,
        },
        .{
            .wave = try du_patterns.Drum.Base.A.generate(allocator, .{
                .frequency = Scale.gen(.{ .code = .c, .octave = 2 }),
                .bpm = options.bpm,
                .amplitude = options.amplitude,
                .sample_rate = options.sample_rate,
                .channels = options.channels,
            }),
            .start_point = samples_per_beat * 16,
        },
        .{
            .wave = try du_patterns.Drum.Base.OffBeats.generate(hatter.Closed, .{
                .bpm = options.bpm,
                .amplitude = options.amplitude,
                .allocator = allocator,
                .sample_rate = options.sample_rate,
                .channels = options.channels,
            }),
            .start_point = samples_per_beat * 16,
        },
        .{
            .wave = try du_patterns.Drum.Base.A.generate(allocator, .{
                .frequency = Scale.gen(.{ .code = .c, .octave = 2 }),
                .bpm = options.bpm,
                .amplitude = options.amplitude,
                .sample_rate = options.sample_rate,
                .channels = options.channels,
            }),
            .start_point = samples_per_beat * 24,
        },
        .{
            .wave = try du_patterns.Drum.Base.OffBeats.generate(hatter.Closed, .{
                .bpm = options.bpm,
                .amplitude = options.amplitude,
                .allocator = allocator,
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
