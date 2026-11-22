import std.math.prelude;

enum Ordering {
    Greaterthan, 
    Lessthan, 
    Equal
}

Ordering std::math::compare<T>(T a, T b) {
    return if (a < b) 
        yield Ordering::Lessthan; 
    else if (a > b) 
        yield Ordering::Greaterthan;
    else
        yield Ordering::Equal;
}

Ordering compare<T>(T a, T b) => std::math::compare(a, b);
