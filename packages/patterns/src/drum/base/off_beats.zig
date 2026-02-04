const std = @import("std");
const lightmix = @import("lightmix");

const Wave = lightmix.Wave;
const Composer = lightmix.Composer;

pub fn generate(comptime S: type, options: Options) !Wave(f128) {
    const samples_per_beat: usize = @intFromFloat(@as(f32, @floatFromInt(60)) / @as(f32, @floatFromInt(options.bpm)) * @as(f32, @floatFromInt(options.sample_rate)));

    var waveinfo_list: std.array_list.Aligned(Composer(f128).WaveInfo, null) = .empty;
    defer waveinfo_list.deinit(options.allocator);

    {
        var wave_list: std.array_list.Aligned(Wave(f128), null) = .empty;
        defer wave_list.deinit(options.allocator);

        for (0..8) |_| {
            var result: Wave(f128) = undefined;

            result = try S.gen(f128, .{
                .amplitude = options.amplitude,
                .allocator = options.allocator,

                .sample_rate = options.sample_rate,
                .channels = options.channels,
            });

            try wave_list.append(options.allocator, result);
        }

        var start_point: usize = samples_per_beat / 2;
        for (wave_list.items) |wave| {
            try waveinfo_list.append(options.allocator, .{ .wave = wave, .start_point = start_point });

            start_point = start_point + samples_per_beat;
        }
    }

    const composer: Composer(f128) = try Composer(f128).init_with(waveinfo_list.items, options.allocator, .{
        .sample_rate = options.sample_rate,
        .channels = options.channels,
    });
    defer composer.deinit();

    return composer.finalize(.{});
}

const Options = struct {
    bpm: usize,
    amplitude: f32,
    allocator: std.mem.Allocator,

    sample_rate: u32,
    channels: u16,
};
