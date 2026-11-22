
import std.math.prelude; 
import std.math.random;

double std::math::E           = 2.7182818284590452354;
double std::math::LOG2E	      =	1.4426950408889634074;
double std::math::LOG10E      = 0.43429448190325182765;
double std::math::LN2	      =	0.69314718055994530942;
double std::math::LN10	      =	2.30258509299404568402;
double std::math::PI		  = 3.14159265358979323846;
double std::math::PI_2	      =	1.57079632679489661923;
double std::math::PI_4	      =	0.78539816339744830962;
double std::math::SQRT2	      =	1.41421356237309504880;
double std::math::SQRT1_2     =	0.70710678118654752440;


[[extern, c_abi]]
int std::math::abs(int a);

// cos
[[extern, c_abi]]
double std::math::cos(double a);

[[extern, c_abi]]
float std::math::cosf(float a);

[[extern, c_abi]]
double std::math::cosh(double a);

[[extern, c_abi]]
float std::math::coshf(float a);

[[extern, c_abi]]
double std::math::cospi(double a);

[[extern, c_abi]]
float std::math::cospif(float a);

// acos
[[extern, c_abi]]
double std::math::acos(double a);

[[extern, c_abi]]
float std::math::acosf(float a);

[[extern, c_abi]]
double std::math::acosh(double a);

[[extern, c_abi]]
float std::math::acoshf(float a);

[[extern, c_abi]]
double std::math::acospi(double a);

[[extern, c_abi]]
float std::math::acospif(float a);

// sin 

[[extern, c_abi]]
double std::math::sin(double a);

[[extern, c_abi]]
float std::math::sinf(float a);

[[extern, c_abi]]
double std::math::sinh(double a);

[[extern, c_abi]]
float std::math::sinhf(float a);

[[extern, c_abi]]
double std::math::sinpi(double a);

[[extern, c_abi]]
float std::math::sinpif(float a);

// asin 

[[extern, c_abi]]
double std::math::asin(double a);

[[extern, c_abi]]
float std::math::asinf(float a);

[[extern, c_abi]]
double std::math::asinh(double a);

[[extern, c_abi]]
float std::math::asinhf(float a);

[[extern, c_abi]]
double std::math::asinpi(double a);

[[extern, c_abi]]
float std::math::asinpif(float a);

// tan

[[extern, c_abi]]
double std::math::tan(double a);

[[extern, c_abi]]
float std::math::tanf(float a);

[[extern, c_abi]]
double std::math::tanh(double a);

[[extern, c_abi]]
float std::math::tanhf(float a);

[[extern, c_abi]]
double std::math::tanpi(double a);

[[extern, c_abi]]
float std::math::tanpif(float a);

 
// atan
[[extern, c_abi]]
double std::math::atan(double a);

[[extern, c_abi]]
double std::math::atan2(double a, double b);

[[extern, c_abi]]
float std::math::atan2f(float a, float b);

[[extern, c_abi]]
double std::math::atan2pi(double a, double b);

[[extern, c_abi]]
float std::math::atan2fpi(float a, float b);

// sqrt
[[extern, c_abi]]
double sqrt(double a);
[[extern, c_abi]]
float sqrtf(float a);
double std::math::sqrt(double a) => sqrt(a);
float std::math::sqrtf(float a) => sqrtf(a);

// pow
[[extern, c_abi]]
double pow(double base, double exp);
[[extern, c_abi]]
float powf(float base, float exp);
double std::math::pow(double base, double exp) => pow(base, exp);
float std::math::powf(float base, float exp) => powf(base, exp);

// floor & ceil & round
[[extern, c_abi]]
double floor(double a);
[[extern, c_abi]]
float floorf(float a);
double std::math::floor(double a) => floor(a);
float std::math::floorf(float a) => floorf(a);

[[extern, c_abi]]
double ceil(double a);
[[extern, c_abi]]
float ceilf(float a);
double std::math::ceil(double a) => ceil(a);
float std::math::ceilf(float a) => ceilf(a);

[[extern, c_abi]]
double round(double a);
[[extern, c_abi]]
float roundf(float a);
double std::math::round(double a) => round(a);
float std::math::roundf(float a) => roundf(a);

// exp & log
[[extern, c_abi]]
double exp(double a);
[[extern, c_abi]]
float expf(float a);
double std::math::exp(double a) => exp(a);
float std::math::expf(float a) => expf(a);

[[extern, c_abi]]
double log(double a);
[[extern, c_abi]]
float logf(float a);
double std::math::log(double a) => log(a);
float std::math::logf(float a) => logf(a);

[[extern, c_abi]]
double log10(double a);
[[extern, c_abi]]
float log10f(float a);
double std::math::log10(double a) => log10(a);
float std::math::log10f(float a) => log10f(a);

[[extern, c_abi]]
double log2(double a);
[[extern, c_abi]]
float log2f(float a);
double std::math::log2(double a) => log2(a);
float std::math::log2f(float a) => log2f(a);

// fabs & fmod
[[extern, c_abi]]
double fabs(double a);
[[extern, c_abi]]
float fabsf(float a);
double std::math::fabs(double a) => fabs(a);
float std::math::fabsf(float a) => fabsf(a);

[[extern, c_abi]]
double fmod(double x, double y);
[[extern, c_abi]]
float fmodf(float x, float y);
double std::math::fmod(double x, double y) => fmod(x, y);
float std::math::fmodf(float x, float y) => fmodf(x, y);

// trunc
[[extern, c_abi]]
double trunc(double a);
[[extern, c_abi]]
float truncf(float a);
double std::math::trunc(double a) => trunc(a);
float std::math::truncf(float a) => truncf(a);

// cbrt
[[extern, c_abi]]
double cbrt(double a);
[[extern, c_abi]]
float cbrtf(float a);
double std::math::cbrt(double a) => cbrt(a);
float std::math::cbrtf(float a) => cbrtf(a);

// hypot
[[extern, c_abi]]
double hypot(double a, double b);
[[extern, c_abi]]
float hypotf(float a, float b);
double std::math::hypot(double a, double b) => hypot(a, b);
float std::math::hypotf(float a, float b) => hypotf(a, b);

// copysign
[[extern, c_abi]]
double copysign(double magnitude, double sign);
[[extern, c_abi]]
float copysignf(float magnitude, float sign);
double std::math::copysign(double magnitude, double sign) => copysign(magnitude, sign);
float std::math::copysignf(float magnitude, float sign) => copysignf(magnitude, sign);

// fmin & fmax
[[extern, c_abi]]
double fmin(double a, double b);
[[extern, c_abi]]
float fminf(float a, float b);
double std::math::fmin(double a, double b) => fmin(a, b);
float std::math::fminf(float a, float b) => fminf(a, b);

[[extern, c_abi]]
double fmax(double a, double b);
[[extern, c_abi]]
float fmaxf(float a, float b);
double std::math::fmax(double a, double b) => fmax(a, b);
float std::math::fmaxf(float a, float b) => fmaxf(a, b);

// remainder
[[extern, c_abi]]
double remainder(double a, double b);
[[extern, c_abi]]
float remainderf(float a, float b);
double std::math::remainder(double a, double b) => remainder(a, b);
float std::math::remainderf(float a, float b) => remainderf(a, b);

// expm1 & log1p
[[extern, c_abi]]
double expm1(double a);
[[extern, c_abi]]
float expm1f(float a);
double std::math::expm1(double a) => expm1(a);
float std::math::expm1f(float a) => expm1f(a);

[[extern, c_abi]]
double log1p(double a);
[[extern, c_abi]]
float log1pf(float a);
double std::math::log1p(double a) => log1p(a);
float std::math::log1pf(float a) => log1pf(a);

bool std::math::is_nan(double value) => !(value == value);
bool std::math::is_finite(double value) =>
    value == value && (value - value) == 0.0;
bool std::math::is_infinite(double value) =>
    value == value && !((value - value) == 0.0);

double std::math::lerp(double start, double end, double amount) =>
    start + (end - start) * amount;
double std::math::radians(double degrees) => degrees * (std::math::PI / 180.0);
double std::math::degrees(double radians) => radians * (180.0 / std::math::PI);
T std::math::square<T>(T value) => value * value;
T std::math::cube<T>(T value) => value * value * value;
int std::math::sign<T>(T value) {
    if (value < 0) {
        return -1;
    }
    if (value > 0) {
        return 1;
    }
    return 0;
}

T std::math::min<T>(T a, T b) {
    return if (a < b) 
        yield a;
    else
        yield b;
}

T std::math::max<T>(T a, T b) {
    return if (a > b) 
        yield a;
    else
        yield b;
}

T std::math::clamp<T>(T val, T low, T high) => std::math::min(std::math::max(val, low), high);

T min<T>(T a, T b) => std::math::min(a, b);
T max<T>(T a, T b) => std::math::max(a, b);
T clamp<T>(T val, T low, T high) => std::math::clamp(val, low, high);

double abs(double value) => fabs(value);
float abs(float value) => fabsf(value);
double lerp(double start, double end, double amount) => std::math::lerp(start, end, amount);
double radians(double degrees) => std::math::radians(degrees);
double degrees(double radians) => std::math::degrees(radians);
T square<T>(T value) => std::math::square(value);
T cube<T>(T value) => std::math::cube(value);
int sign<T>(T value) => std::math::sign(value);
bool is_nan(double value) => std::math::is_nan(value);
bool is_finite(double value) => std::math::is_finite(value);
bool is_infinite(double value) => std::math::is_infinite(value);




