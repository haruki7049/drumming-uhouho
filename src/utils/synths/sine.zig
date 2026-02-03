const std = @import("std");
const lightmix = @import("lightmix");

const Wave = lightmix.Wave;

const Self = @This();

pub fn generate(allocator: std.mem.Allocator, options: Options) !Wave(f128) {
    const sample_rate: f128 = @floatFromInt(options.sample_rate);
    const base_samples: []const f128 = generate_sine_samples(options.frequency, options.amplitude, options.length, sample_rate, allocator);

    return Wave(f128){
        .samples = base_samples,
        .allocator = allocator,
        .sample_rate = options.sample_rate,
        .channels = options.channels,
    };
}

fn generate_sine_samples(frequency: f128, amplitude: f128, length: usize, sample_rate: f128, allocator: std.mem.Allocator) []const f128 {
    const radians_per_sec: f128 = frequency * 2.0 * std.math.pi;

    var result: std.array_list.Aligned(f128, null) = .empty;
    defer result.deinit(allocator);

    for (0..length) |i| {
        const v: f128 = std.math.sin(@as(f128, @floatFromInt(i)) * radians_per_sec / sample_rate) * amplitude;
        result.append(allocator, v) catch @panic("Out of memory");
    }

    return result.toOwnedSlice(allocator) catch @panic("Out of memory");
}

pub const Options = struct {
    length: usize,
    frequency: f128,
    amplitude: f128,

    sample_rate: u32,
    channels: u16,
};
