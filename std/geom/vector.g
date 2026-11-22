import std.prelude;
import std.math;

/// Two-dimensional vector with double-precision components.
struct Vec2 {
    double x;
    double y;
}

/// Three-dimensional vector with double-precision components.
struct Vec3 {
    double x;
    double y;
    double z;
}

Vec2 vec2(double x, double y) => Vec2{x, y};
Vec3 vec3(double x, double y, double z) => Vec3{x, y, z};
Vec2 zero2() => Vec2{0.0, 0.0};
Vec3 zero3() => Vec3{0.0, 0.0, 0.0};

// Vec2 arithmetic.

[[infix_operator]]
Vec2 `+`(Vec2 left, Vec2 right) =>
    Vec2{left.x + right.x, left.y + right.y};

[[infix_operator]]
Vec2 `-`(Vec2 left, Vec2 right) =>
    Vec2{left.x - right.x, left.y - right.y};

[[prefix_operator]]
Vec2 `-`(Vec2 value) => Vec2{-value.x, -value.y};

[[infix_operator]]
Vec2 `*`(Vec2 value, double scalar) =>
    Vec2{value.x * scalar, value.y * scalar};

[[infix_operator]]
Vec2 `*`(double scalar, Vec2 value) =>
    Vec2{value.x * scalar, value.y * scalar};

[[infix_operator]]
Vec2 `/`(Vec2 value, double scalar) =>
    Vec2{value.x / scalar, value.y / scalar};

/// Dot product. Overloading `*` for two vectors makes `a * b` a scalar.
[[infix_operator]]
double `*`(Vec2 left, Vec2 right) =>
    left.x * right.x + left.y * right.y;

double dot(Vec2 left, Vec2 right) => left.x * right.x + left.y * right.y;
double magnitude_squared(Vec2 value) => value.x * value.x + value.y * value.y;
double magnitude(Vec2 value) => std::math::sqrt(magnitude_squared(value));
double distance(Vec2 left, Vec2 right) =>
    magnitude(Vec2{left.x - right.x, left.y - right.y});

Vec2 normalized(Vec2 value) {
    double length = magnitude(value);
    if (length == 0.0) {
        return Vec2{0.0, 0.0};
    }
    return value / length;
}

Vec2 lerp(Vec2 start, Vec2 end, double amount) =>
    Vec2{start.x + (end.x - start.x) * amount,
         start.y + (end.y - start.y) * amount};

// Vec3 arithmetic.

[[infix_operator]]
Vec3 `+`(Vec3 left, Vec3 right) =>
    Vec3{left.x + right.x, left.y + right.y, left.z + right.z};

[[infix_operator]]
Vec3 `-`(Vec3 left, Vec3 right) =>
    Vec3{left.x - right.x, left.y - right.y, left.z - right.z};

[[prefix_operator]]
Vec3 `-`(Vec3 value) => Vec3{-value.x, -value.y, -value.z};

[[infix_operator]]
Vec3 `*`(Vec3 value, double scalar) =>
    Vec3{value.x * scalar, value.y * scalar, value.z * scalar};

[[infix_operator]]
Vec3 `*`(double scalar, Vec3 value) =>
    Vec3{value.x * scalar, value.y * scalar, value.z * scalar};

[[infix_operator]]
Vec3 `/`(Vec3 value, double scalar) =>
    Vec3{value.x / scalar, value.y / scalar, value.z / scalar};

[[infix_operator]]
double `*`(Vec3 left, Vec3 right) =>
    left.x * right.x + left.y * right.y + left.z * right.z;

[[infix_operator]]
Vec3 `%`(Vec3 left, Vec3 right) =>
    Vec3{left.y * right.z - left.z * right.y,
         left.z * right.x - left.x * right.z,
         left.x * right.y - left.y * right.x};

Vec3 cross(Vec3 left, Vec3 right) => left % right;
double dot(Vec3 left, Vec3 right) =>
    left.x * right.x + left.y * right.y + left.z * right.z;
double magnitude_squared(Vec3 value) =>
    value.x * value.x + value.y * value.y + value.z * value.z;
double magnitude(Vec3 value) => std::math::sqrt(magnitude_squared(value));
double distance(Vec3 left, Vec3 right) =>
    magnitude(Vec3{left.x - right.x, left.y - right.y, left.z - right.z});

Vec3 normalized(Vec3 value) {
    double length = magnitude(value);
    if (length == 0.0) {
        return Vec3{0.0, 0.0, 0.0};
    }
    return value / length;
}

Vec3 lerp(Vec3 start, Vec3 end, double amount) =>
    Vec3{start.x + (end.x - start.x) * amount,
         start.y + (end.y - start.y) * amount,
         start.z + (end.z - start.z) * amount};
