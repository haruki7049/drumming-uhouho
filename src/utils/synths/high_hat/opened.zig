const std = @import("std");
const lightmix = @import("lightmix");

const Wave = lightmix.Wave;

const Self = @This();

pub fn generate(allocator: std.mem.Allocator, options: Options) Wave {
    const base_data: []const f32 = generate_closed_high_hat_data(
        options.amplitude,
        allocator,
    );
    defer allocator.free(base_data);

    const result: Wave = Wave.init(base_data, allocator, .{
        .sample_rate = options.sample_rate,
        .channels = options.channels,
    })
        .filter(attack)
        .filter(decay);

    return result;
}

fn generate_closed_high_hat_data(amplitude: f32, allocator: std.mem.Allocator) []const f32 {
    var result: std.array_list.Aligned(f32, null) = .empty;
    defer result.deinit(allocator);

    var prng = std.Random.DefaultPrng.init(0);
    const rand = prng.random();

    const length: usize = 22050;
    for (0..length) |_| {
        const v: f32 = rand.float(f32) / 3 - 1.0;
        result.append(allocator, v * amplitude) catch @panic("Out of memory");
    }

    return result.toOwnedSlice(allocator) catch @panic("Out of memory");
}

pub const Options = struct {
    amplitude: f32,

    sample_rate: usize,
    channels: usize,
};

fn decay(original_wave: Wave) !Wave {
    var result: std.array_list.Aligned(f32, null) = .empty;

    for (original_wave.data, 0..) |data, n| {
        const i = original_wave.data.len - n;
        const volume: f32 = @as(f32, @floatFromInt(i)) * (1.0 / @as(f32, @floatFromInt(original_wave.data.len)));

        const new_data = data * volume;
        try result.append(original_wave.allocator, new_data);
    }

    return Wave{
        .data = try result.toOwnedSlice(original_wave.allocator),
        .allocator = original_wave.allocator,

        .sample_rate = original_wave.sample_rate,
        .channels = original_wave.channels,
    };
}

fn attack(original_wave: Wave) !Wave {
    const allocator = original_wave.allocator;
    var result: std.array_list.Aligned(f32, null) = .empty;

    const length: usize = 1000;
    for (original_wave.data, 1..) |data, n| {
        if (n < length) {
            const percent: f32 = @as(f32, @floatFromInt(n)) / @as(f32, @floatFromInt(length));
            try result.append(allocator, percent * data);

            continue;
        }

        try result.append(allocator, data);
    }

    return Wave{
        .data = try result.toOwnedSlice(allocator),
        .allocator = allocator,

        .sample_rate = original_wave.sample_rate,
        .channels = original_wave.channels,
    };
}
