const std = @import("std");

const lightmix = @import("lightmix");
const Wave = lightmix.Wave;
const Composer = lightmix.Composer;

pub fn gen(comptime T: type, options: Options(T)) !Wave(T) {
    const wave_len = options.target.samples.len;

    var waveinfo_list: std.array_list.Aligned(Composer(T).WaveInfo, null) = .empty;
    defer waveinfo_list.deinit(options.allocator);

    var start_point = options.start_point;
    for (0..options.times) |_| {
        std.debug.print("start_point: {d}\n", .{start_point});

        try waveinfo_list.append(options.allocator, .{ .wave = options.target, .start_point = start_point });
        start_point += wave_len;
    }

    const composer = try Composer(T).init_with(waveinfo_list.items, options.allocator, .{
        .sample_rate = options.sample_rate,
        .channels = options.channels,
    });
    defer composer.deinit();

    return try composer.finalize(.{});
}

pub fn Options(comptime T: type) type {
    return struct {
        bpm: usize,
        allocator: std.mem.Allocator,
        target: Wave(T),
        times: usize,
        ratio: f64,
        start_point: usize,
        sample_rate: u32,
        channels: u16,
    };
}
