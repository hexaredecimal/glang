import std.algo.prelude;

/// Smallest element. The flag is false for an empty array.
(T, bool) min_element<T>(T[] elements) {
    if (elements.length == 0) {
        T empty;
        return (empty, false);
    }
    T best = elements[0];
    for (int i = 1; i < elements.length; ++i) {
        if (elements[i] < best) {
            best = elements[i];
        }
    }
    return (best, true);
}

/// Largest element. The flag is false for an empty array.
(T, bool) max_element<T>(T[] elements) {
    if (elements.length == 0) {
        T empty;
        return (empty, false);
    }
    T best = elements[0];
    for (int i = 1; i < elements.length; ++i) {
        if (elements[i] > best) {
            best = elements[i];
        }
    }
    return (best, true);
}

/// Sum of a non-empty numeric array.
T sum<T>(T[] elements) {
    T total = elements[0];
    for (int i = 1; i < elements.length; ++i) {
        total = total + elements[i];
    }
    return total;
}

/// Sum with an empty-array flag.
(T, bool) try_sum<T>(T[] elements) {
    if (elements.length == 0) {
        T empty;
        return (empty, false);
    }
    return (sum(elements), true);
}

/// Product of a non-empty numeric array.
T product<T>(T[] elements) {
    T total = elements[0];
    for (int i = 1; i < elements.length; ++i) {
        total = total * elements[i];
    }
    return total;
}

/// Product with an empty-array flag.
(T, bool) try_product<T>(T[] elements) {
    if (elements.length == 0) {
        T empty;
        return (empty, false);
    }
    return (product(elements), true);
}

int count_value<T>(T[] elements, T value) {
    int total = 0;
    for (int i = 0; i < elements.length; ++i) {
        if (elements[i] == value) {
            total = total + 1;
        }
    }
    return total;
}

bool is_sorted<T>(T[] elements) {
    for (int i = 1; i < elements.length; ++i) {
        if (elements[i] < elements[i - 1]) {
            return false;
        }
    }
    return true;
}

bool all_equal<T>(T[] elements) {
    for (int i = 1; i < elements.length; ++i) {
        if (elements[i] != elements[0]) {
            return false;
        }
    }
    return true;
}

void fill<T>(T[] elements, T value) {
    for (int i = 0; i < elements.length; ++i) {
        elements[i] = value;
    }
}
