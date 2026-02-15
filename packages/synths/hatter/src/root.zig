const std = @import("std");
const lightmix = @import("lightmix");
const lightmix_filters = @import("lightmix_filters");
const Wave = lightmix.Wave;

pub const Closed = @import("./closed.zig");

pub fn gen(allocator: std.mem.Allocator) !Wave(f128) {
    var closed: Wave(f128) = try Closed.gen(f128, .{
        .amplitude = 1.0,
        .allocator = allocator,
        .sample_rate = 44100,
        .channels = 1,
    });
    try closed.filter(normalize);

    return closed;
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
