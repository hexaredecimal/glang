
import std.prelude;

/// An axis-aligned rectangle with double-precision bounds. `width` and
/// `height` are expected to be non-negative; `rect_from_points` normalizes
/// corners for you.
struct Rect {
    double x;
    double y;
    double width;
    double height;
}

Rect make_rect(double x, double y, double width, double height) =>
    Rect{x, y, width, height};

/// Build a rectangle from two opposite corners in any order.
Rect rect_from_points(double x1, double y1, double x2, double y2) {
    double minimumX = x1;
    double maximumX = x1;
    double minimumY = y1;
    double maximumY = y1;
    if (x2 < minimumX) {
        minimumX = x2;
    } else {
        maximumX = x2;
    }
    if (y2 < minimumY) {
        minimumY = y2;
    } else {
        maximumY = y2;
    }
    return make_rect(minimumX, minimumY, maximumX - minimumX,
                     maximumY - minimumY);
}

double rect_left(Rect rect) => rect.x;
double rect_right(Rect rect) => rect.x + rect.width;
double rect_top(Rect rect) => rect.y;
double rect_bottom(Rect rect) => rect.y + rect.height;
double rect_center_x(Rect rect) => rect.x + rect.width / 2.0;
double rect_center_y(Rect rect) => rect.y + rect.height / 2.0;
double rect_area(Rect rect) => rect.width * rect.height;
double rect_perimeter(Rect rect) => 2.0 * (rect.width + rect.height);

bool rect_is_empty(Rect rect) => rect.width <= 0.0 || rect.height <= 0.0;

/// True when the point lies inside or on the rectangle boundary.
bool rect_contains(Rect rect, double x, double y) =>
    x >= rect.x && x <= rect.x + rect.width && y >= rect.y &&
    y <= rect.y + rect.height;

/// True when `inner` lies entirely inside `outer`.
bool rect_contains_rect(Rect outer, Rect inner) {
    if (rect_is_empty(inner)) {
        return true;
    }
    return rect_contains(outer, inner.x, inner.y) &&
           rect_contains(outer, inner.x + inner.width,
                         inner.y + inner.height);
}

/// True when the rectangles overlap with positive area. Touching edges do not
/// count as an intersection.
bool rect_intersects(Rect left, Rect right) {
    if (rect_is_empty(left) || rect_is_empty(right)) {
        return false;
    }
    return left.x < right.x + right.width &&
           right.x < left.x + left.width &&
           left.y < right.y + right.height &&
           right.y < left.y + left.height;
}

/// Overlap of two rectangles. The flag is false when they do not intersect.
(Rect, bool) rect_intersection(Rect left, Rect right) {
    if (!rect_intersects(left, right)) {
        return (Rect{0.0, 0.0, 0.0, 0.0}, false);
    }
    double minimumX = left.x;
    if (right.x > minimumX) {
        minimumX = right.x;
    }
    double minimumY = left.y;
    if (right.y > minimumY) {
        minimumY = right.y;
    }
    double maximumX = left.x + left.width;
    if (right.x + right.width < maximumX) {
        maximumX = right.x + right.width;
    }
    double maximumY = left.y + left.height;
    if (right.y + right.height < maximumY) {
        maximumY = right.y + right.height;
    }
    return (make_rect(minimumX, minimumY, maximumX - minimumX,
                      maximumY - minimumY),
            true);
}

/// Smallest rectangle containing both inputs. Empty inputs are ignored.
Rect rect_union(Rect left, Rect right) {
    if (rect_is_empty(left)) {
        return right;
    }
    if (rect_is_empty(right)) {
        return left;
    }
    double minimumX = left.x;
    if (right.x < minimumX) {
        minimumX = right.x;
    }
    double minimumY = left.y;
    if (right.y < minimumY) {
        minimumY = right.y;
    }
    double maximumX = left.x + left.width;
    if (right.x + right.width > maximumX) {
        maximumX = right.x + right.width;
    }
    double maximumY = left.y + left.height;
    if (right.y + right.height > maximumY) {
        maximumY = right.y + right.height;
    }
    return make_rect(minimumX, minimumY, maximumX - minimumX,
                     maximumY - minimumY);
}

/// Grow the rectangle by `amount` on every side. Negative amounts shrink it.
Rect rect_inflate(Rect rect, double amount) =>
    make_rect(rect.x - amount, rect.y - amount, rect.width + amount * 2.0,
              rect.height + amount * 2.0);

Rect rect_translate(Rect rect, double x, double y) =>
    make_rect(rect.x + x, rect.y + y, rect.width, rect.height);

Rect rect_scale(Rect rect, double factor) =>
    make_rect(rect.x * factor, rect.y * factor, rect.width * factor,
              rect.height * factor);

/// Union of two rectangles.
[[infix_operator]]
Rect `+`(Rect left, Rect right) => rect_union(left, right);

/// Scale a rectangle about the origin.
[[infix_operator]]
Rect `*`(Rect rect, double factor) => rect_scale(rect, factor);

/// Order rectangles by area.
[[infix_operator]]
bool `<`(Rect left, Rect right) => rect_area(left) < rect_area(right);
