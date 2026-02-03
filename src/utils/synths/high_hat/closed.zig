const std = @import("std");
const lightmix = @import("lightmix");
const lightmix_filters = @import("lightmix_filters");

const Wave = lightmix.Wave;
const Self = @This();

const decay = lightmix_filters.volume.decay;
const DecayArgs = lightmix_filters.volume.DecayArgs;

pub fn generate(allocator: std.mem.Allocator, options: Options) !Wave(f128) {
    const base_samples: []const f128 = generate_closed_high_hat_samples(
        options.amplitude,
        allocator,
    );

    var result: Wave(f128) = Wave(f128){
        .samples = base_samples,
        .allocator = allocator,
        .sample_rate = options.sample_rate,
        .channels = options.channels,
    };
    try result.filter(attack);
    try result.filter_with(DecayArgs, decay, .{});
    try result.filter_with(DecayArgs, decay, .{});
    try result.filter_with(DecayArgs, decay, .{});
    try result.filter_with(DecayArgs, decay, .{});

    return result;
}

fn generate_closed_high_hat_samples(amplitude: f128, allocator: std.mem.Allocator) []const f128 {
    var result: std.array_list.Aligned(f128, null) = .empty;
    defer result.deinit(allocator);

    var prng = std.Random.DefaultPrng.init(0);
    const rand = prng.random();

    const length: usize = 22050;
    for (0..length) |_| {
        const v: f128 = @as(f128, (rand.float(f64) / 3 - 1.0));
        result.append(allocator, v * amplitude) catch @panic("Out of memory");
    }

    return result.toOwnedSlice(allocator) catch @panic("Out of memory");
}

pub const Options = struct {
    amplitude: f128,

    sample_rate: u32,
    channels: u16,
};

fn attack(comptime T: type, original: Wave(T)) !Wave(T) {
    const allocator = original.allocator;
    var result: std.array_list.Aligned(T, null) = .empty;

    const length: usize = 100;
    for (original.samples, 1..) |sample, n| {
        if (n < length) {
            const percent: T = @as(T, @floatFromInt(n)) / @as(T, @floatFromInt(length));
            try result.append(allocator, percent * sample);

            continue;
        }

        try result.append(allocator, sample);
    }

    return Wave(T){
        .samples = try result.toOwnedSlice(allocator),
        .allocator = allocator,

        .sample_rate = original.sample_rate,
        .channels = original.channels,
    };
}
