
import std.math.prelude;

/// A 64-bit xorshift pseudo-random generator. Copies of an `Random` value have
/// independent state; pass a pointer when advancing it.
struct Random {
    ulong state;
}


Random Random::new(ulong seed) => Random{normalize_seed(seed)};

ulong normalize_seed(ulong seed) {
    if (seed == 0) {
        return 88172645463325252;
    }
    return seed;
}


/// Replace the generator state. A zero seed is replaced with a non-zero one.
void reseed(Random* rng, ulong seed) {
    if (rng == nullptr) {
        return;
    }
    rng.state = normalize_seed(seed);
}

/// Advance the generator and return 64 random bits.
ulong next(Random* rng) {
    if (rng == nullptr) {
        return 0;
    }
    ulong value = rng.state;
    value = value ^ (value << 13);
    value = value ^ (value >> 7);
    value = value ^ (value << 17);
    rng.state = value;
    return value;
}

/// A random unsigned 32-bit value.
uint next_uint(Random* rng) => (next(rng) >> 32) as uint;

/// A non-negative random 32-bit integer.
int next_int(Random* rng) => (next(rng) & 2147483647) as int;

/// A random integer in the half-open range [low, high). Returns `low` when
/// the range is empty or inverted.
int range(Random* rng, int low, int high) {
    if (rng == nullptr || high <= low) {
        return low;
    }
    ulong span = (high - low) as ulong;
    ulong offset = next(rng) % span;
    return low + (offset as int);
}

/// A random double in [0.0, 1.0).
double to_double(Random* rng) {
    if (rng == nullptr) {
        return 0.0;
    }
    ulong bits = next(rng) >> 11;
    return (bits as double) / 9007199254740992.0;
}

/// A random double in [low, high).
double range_double(Random* rng, double low, double high) {
    if (high <= low) {
        return low;
    }
    return low + (high - low) * to_double(rng);
}

/// A random boolean.
bool to_bool(Random* rng) => (next(rng) & 1) == 1;

/// A random result from a die with `sides` faces, in [1, sides].
int roll(Random* rng, int sides) {
    if (sides <= 0) {
        return 1;
    }
    return range(rng, 1, sides + 1);
}

/// Shuffle an array or slice in place with Fisher-Yates.
void shuffle<T>(T[] values, Random* rng) {
    if (rng == nullptr) {
        return;
    }
    for (int index = values.length - 1; index > 0; index = index - 1) {
        int other = range(rng, 0, index + 1);
        T temporary = values[index];
        values[index] = values[other];
        values[other] = temporary;
    }
}

int get_in_range(Random* rng, int low, int high) => range(rng, low, high);
