const std = @import("std");
const lightmix = @import("lightmix");

const Wave = lightmix.Wave;

const Self = @This();

pub fn generate(allocator: std.mem.Allocator, options: Options) Wave {
    const sample_rate: f32 = @floatFromInt(options.sample_rate);
    const base_data: []const f32 = generate_guitar_note(
        options.frequency,
        options.amplitude,
        options.length,
        sample_rate,
        allocator,
    );
    defer allocator.free(base_data);

    const result: Wave = Wave.init(base_data, allocator, .{
        .sample_rate = options.sample_rate,
        .channels = options.channels,
    });

    return result;
}

fn generate_guitar_note(frequency: f32, amplitude: f32, length: usize, sample_rate: f32, allocator: std.mem.Allocator) []const f32 {
    const decay: f32 = 0.996;
    const filter_strength: f32 = 0.6; // Increase this to cut more highs

    var result: std.array_list.Aligned(f32, null) = .empty;
    defer result.deinit(allocator);

    const period = @as(usize, @intFromFloat(sample_rate / frequency));
    var buffer: [2000]f32 = undefined;
    var prng = std.Random.DefaultPrng.init(0);
    const rand = prng.random();

    for (buffer[0..period]) |*val| {
        val.* = rand.float(f32) * 2.0 - 1.0;
    }

    // Karplus–Strong loop
    var idx: usize = 0;
    var i: usize = 0;
    var prev_avg: f32 = 0.0;
    while (i < length) : (i += 1) {
        const next_idx = (idx + 1) % period;

        // Simple averaging (original)
        const current_avg = (buffer[idx] + buffer[next_idx]) * 0.5 * decay;

        // Additional smoothing (LPF)
        const final_val = (current_avg * (1.0 - filter_strength) + prev_avg * filter_strength) * decay;

        const v: f32 = final_val * amplitude;

        result.append(allocator, v) catch @panic("Out of memory");

        buffer[idx] = final_val;
        prev_avg = final_val;
        idx = next_idx;
    }

    return result.toOwnedSlice(allocator) catch @panic("Out of memory");
}

pub const Options = struct {
    length: usize,
    frequency: f32,
    amplitude: f32,

    sample_rate: usize,
    channels: usize,
};
