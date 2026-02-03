const std = @import("std");
const lightmix = @import("lightmix");
const du_synths = @import("drumming-uhouho_synths");

const Wave = lightmix.Wave;
const Composer = lightmix.Composer;

pub fn generate(allocator: std.mem.Allocator, comptime options: Options(type)) !Wave(f128) {
    const samples_per_beat: usize = @intFromFloat(@as(f32, @floatFromInt(60)) / @as(f32, @floatFromInt(options.bpm)) * @as(f32, @floatFromInt(options.sample_rate)));

    var waveinfo_list: std.array_list.Aligned(Composer(f128).WaveInfo, null) = .empty;
    defer waveinfo_list.deinit(allocator);

    {
        var wave_list: std.array_list.Aligned(Wave(f128), null) = .empty;
        defer wave_list.deinit(allocator);

        for (0..8) |_| {
            var result: Wave(f128) = undefined;

            switch (options.state) {
                .closed => {
                    result = try du_synths.HighHat.Closed.gen(f128, .{
                        .amplitude = options.amplitude,
                        .allocator = allocator,

                        .sample_rate = options.sample_rate,
                        .channels = options.channels,
                    });
                },
                .opened => {
                    result = try du_synths.HighHat.Opened.gen(f128, .{
                        .amplitude = options.amplitude,
                        .allocator = allocator,

                        .sample_rate = options.sample_rate,
                        .channels = options.channels,
                    });
                },
            }

            try wave_list.append(allocator, result);
        }

        var start_point: usize = samples_per_beat / 2;
        for (wave_list.items) |wave| {
            try waveinfo_list.append(allocator, .{ .wave = wave, .start_point = start_point });

            start_point = start_point + samples_per_beat;
        }
    }

    const composer: Composer(f128) = try Composer(f128).init_with(waveinfo_list.items, allocator, .{
        .sample_rate = options.sample_rate,
        .channels = options.channels,
    });
    defer composer.deinit();

    return composer.finalize(.{});
}

pub fn Options(comptime Utils: type) type {
    return struct {
        utils: Utils,

        bpm: usize,
        amplitude: f32,
        state: HighHatState,

        sample_rate: usize,
        channels: usize,
    };
}

const HighHatState = enum {
    closed,
    opened,
};
