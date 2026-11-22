
import std.math.prelude;

/// A 64-bit xorshift pseudo-random generator. Copies of an `Rng` value have
/// independent state; pass a pointer when advancing it.
struct Rng {
    ulong state;
}

ulong rng_normalize_seed(ulong seed) {
    if (seed == 0) {
        return 88172645463325252;
    }
    return seed;
}

Rng make_rng(ulong seed) => Rng{rng_normalize_seed(seed)};

/// Replace the generator state. A zero seed is replaced with a non-zero one.
void rng_reseed(Rng* rng, ulong seed) {
    if (rng == nullptr) {
        return;
    }
    rng.state = rng_normalize_seed(seed);
}

/// Advance the generator and return 64 random bits.
ulong rng_next(Rng* rng) {
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
uint rng_next_uint(Rng* rng) => (rng_next(rng) >> 32) as uint;

/// A non-negative random 32-bit integer.
int rng_next_int(Rng* rng) => (rng_next(rng) & 2147483647) as int;

/// A random integer in the half-open range [low, high). Returns `low` when
/// the range is empty or inverted.
int rng_range(Rng* rng, int low, int high) {
    if (rng == nullptr || high <= low) {
        return low;
    }
    ulong span = (high - low) as ulong;
    ulong offset = rng_next(rng) % span;
    return low + (offset as int);
}

/// A random double in [0.0, 1.0).
double rng_double(Rng* rng) {
    if (rng == nullptr) {
        return 0.0;
    }
    ulong bits = rng_next(rng) >> 11;
    return (bits as double) / 9007199254740992.0;
}

/// A random double in [low, high).
double rng_range_double(Rng* rng, double low, double high) {
    if (high <= low) {
        return low;
    }
    return low + (high - low) * rng_double(rng);
}

/// A random boolean.
bool rng_bool(Rng* rng) => (rng_next(rng) & 1) == 1;

/// A random result from a die with `sides` faces, in [1, sides].
int rng_roll(Rng* rng, int sides) {
    if (sides <= 0) {
        return 1;
    }
    return rng_range(rng, 1, sides + 1);
}

/// Shuffle an array or slice in place with Fisher-Yates.
void rng_shuffle<T>(T[] values, Rng* rng) {
    if (rng == nullptr) {
        return;
    }
    for (int index = values.length - 1; index > 0; index = index - 1) {
        int other = rng_range(rng, 0, index + 1);
        T temporary = values[index];
        values[index] = values[other];
        values[other] = temporary;
    }
}

Rng random_rng(ulong seed) => make_rng(seed);
int random_int(Rng* rng, int low, int high) => rng_range(rng, low, high);
double random_double(Rng* rng) => rng_double(rng);
bool random_bool(Rng* rng) => rng_bool(rng);
