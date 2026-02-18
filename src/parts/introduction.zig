const std = @import("std");
const lightmix = @import("lightmix");
const lightmix_synths = @import("lightmix_synths");
const lightmix_temperaments = @import("lightmix_temperaments");
const hatter = @import("hatter");
const du_patterns = @import("du_patterns");

const Wave = lightmix.Wave;
const Composer = lightmix.Composer;
const Scale = lightmix_temperaments.TwelveEqualTemperament;

pub const Options = struct {
    bpm: usize,
    amplitude: f32,
    allocator: std.mem.Allocator,
    sample_rate: u32,
    channels: u16,
};

pub fn gen(comptime T: type, options: Options) !Wave(T) {
    const samples_per_beat: usize = @intFromFloat(@as(f32, @floatFromInt(60)) / @as(f32, @floatFromInt(options.bpm)) * @as(f32, @floatFromInt(options.sample_rate)));

    const melodies: []const Composer(T).WaveInfo = &.{
        .{
            .wave = try du_patterns.Base.A.gen(lightmix_synths.Basic.Sine, .{
                .allocator = options.allocator,
                .frequency = Scale.gen(.{ .code = .c, .octave = 2 }),
                .bpm = options.bpm,
                .amplitude = options.amplitude,
                .sample_rate = options.sample_rate,
                .channels = options.channels,
            }),
            .start_point = samples_per_beat * 0,
        },
        .{
            .wave = try du_patterns.Base.A.gen(lightmix_synths.Basic.Sine, .{
                .allocator = options.allocator,
                .frequency = Scale.gen(.{ .code = .c, .octave = 2 }),
                .bpm = options.bpm,
                .amplitude = options.amplitude,
                .sample_rate = options.sample_rate,
                .channels = options.channels,
            }),
            .start_point = samples_per_beat * 8,
        },
        .{
            .wave = try du_patterns.Base.A.gen(lightmix_synths.Basic.Sine, .{
                .allocator = options.allocator,
                .frequency = Scale.gen(.{ .code = .c, .octave = 2 }),
                .bpm = options.bpm,
                .amplitude = options.amplitude,
                .sample_rate = options.sample_rate,
                .channels = options.channels,
            }),
            .start_point = samples_per_beat * 16,
        },
        .{
            .wave = try du_patterns.Base.OffBeats.gen(hatter.Closed, .{
                .bpm = options.bpm,
                .amplitude = options.amplitude,
                .allocator = options.allocator,
                .sample_rate = options.sample_rate,
                .channels = options.channels,
            }),
            .start_point = samples_per_beat * 16,
        },
        .{
            .wave = try du_patterns.Base.A.gen(lightmix_synths.Basic.Sine, .{
                .allocator = options.allocator,
                .frequency = Scale.gen(.{ .code = .c, .octave = 2 }),
                .bpm = options.bpm,
                .amplitude = options.amplitude,
                .sample_rate = options.sample_rate,
                .channels = options.channels,
            }),
            .start_point = samples_per_beat * 24,
        },
        .{
            .wave = try du_patterns.Base.OffBeats.gen(hatter.Closed, .{
                .bpm = options.bpm,
                .amplitude = options.amplitude,
                .allocator = options.allocator,
                .sample_rate = options.sample_rate,
                .channels = options.channels,
            }),
            .start_point = samples_per_beat * 24,
        },
    };

    defer for (melodies) |melody| {
        melody.wave.deinit();
    };

    const composer: Composer(T) = try Composer(T).init_with(melodies, options.allocator, .{
        .sample_rate = options.sample_rate,
        .channels = options.channels,
    });
    defer composer.deinit();

    return try composer.finalize(.{});
}
