import std.algo.prelude;

/// Index of the first matching value, or -1.
int find_index<T>(T[] elements, T value) {
    for (int i = 0; i < elements.length; ++i) {
        if (elements[i] == value) {
            return i;
        }
    }
    return -1;
}

/// Index of the last matching value, or -1.
int find_last_index<T>(T[] elements, T value) {
    for (int i = elements.length - 1; i >= 0; --i) {
        if (elements[i] == value) {
            return i;
        }
    }
    return -1;
}

/// First element matching the predicate. The flag is false when none match.
(T, bool) find_first<T>(T[] elements, bool (*predicate)(T)) {
    for (int i = 0; i < elements.length; ++i) {
        if (predicate(elements[i])) {
            return (elements[i], true);
        }
    }
    T empty;
    return (empty, false);
}

/// Last element matching the predicate. The flag is false when none match.
(T, bool) find_last<T>(T[] elements, bool (*predicate)(T)) {
    for (int i = elements.length - 1; i >= 0; --i) {
        if (predicate(elements[i])) {
            return (elements[i], true);
        }
    }
    T empty;
    return (empty, false);
}

int find_index_if<T>(T[] elements, bool (*predicate)(T)) {
    for (int i = 0; i < elements.length; ++i) {
        if (predicate(elements[i])) {
            return i;
        }
    }
    return -1;
}

int find_last_index_if<T>(T[] elements, bool (*predicate)(T)) {
    for (int i = elements.length - 1; i >= 0; --i) {
        if (predicate(elements[i])) {
            return i;
        }
    }
    return -1;
}

/// First position whose value is not less than `value` in a sorted array.
int lower_bound<T>(T[] elements, T value) {
    int low = 0;
    int high = elements.length;
    while (low < high) {
        int middle = low + (high - low) / 2;
        if (elements[middle] < value) {
            low = middle + 1;
        } else {
            high = middle;
        }
    }
    return low;
}

/// First position whose value is greater than `value` in a sorted array.
int upper_bound<T>(T[] elements, T value) {
    int low = 0;
    int high = elements.length;
    while (low < high) {
        int middle = low + (high - low) / 2;
        if (elements[middle] <= value) {
            low = middle + 1;
        } else {
            high = middle;
        }
    }
    return low;
}

/// Index of `value` in a sorted array, or -1.
int binary_search<T>(T[] elements, T value) {
    int position = lower_bound(elements, value);
    if (position < elements.length && elements[position] == value) {
        return position;
    }
    return -1;
}
