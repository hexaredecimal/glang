import std.algo.prelude; 
import std.math.ord;
import std.container.list;

type SortCallback<T> = bool (*fn)(T, T);

void std::algorithm::to_sorted<T>(T[] elements, SortCallback<T> fn) {
    for (int i = 0; i < elements.length; ++i) {
        for (int j = 0; j < i; j++) {
            T a = elements[i];
            T b = elements[j];

            if (fn(a, b)) {
                elements[i] = b;
                elements[j] = a;
            }
        }    
    }
}

void std::algorithm::to_sorted<T>(T[] elements) => elements.to_sorted() { T a, T b -> return a < b; }

void std::algorithm::to_sorted<T>(T[] elements, Ordering ord) {
    auto callback = switch (ord) {
        case Ordering::Lessthan -> { T a, T b -> return a < b; }
        case Ordering::Greaterthan -> { T a, T b -> return a > b; }
        case Ordering::Equal -> { T a, T b -> return a == b; }
    };
    std::algorithm::to_sorted(elements, callback);
}



List<T> std::algorithm::to_sorted<T>(List<T> elements, SortCallback<T> fn) {
    auto result = elements.clone();
    for (int i = 0; i < result.length; ++i) {
        for (int j = 0; j < i; j++) {
            T a = result[i];
            T b = result[j];

            if (fn(a, b)) {
                result[i] = b;
                result[j] = a;
            }
        }    
    }
    return result;
}

List<T> std::algorithm::to_sorted<T>(List<T> elements) => elements.to_sorted() { T a, T b -> return a < b; }

List<T> std::algorithm::to_sorted<T>(List<T> elements, Ordering ord) {
    auto callback = switch (ord) {
        case Ordering::Lessthan -> { T a, T b -> return a < b; }
        case Ordering::Greaterthan -> { T a, T b -> return a > b; }
        case Ordering::Equal -> { T a, T b -> return a == b; }
    };
    return std::algorithm::to_sorted(elements, callback);
}

List<T> to_sorted<T>(List<T> elements, SortCallback<T> fn) => std::algorithm::to_sorted<T>(elements, fn);
List<T> to_sorted<T>(List<T> elements) => std::algorithm::to_sorted<T>(elements);
List<T> to_sorted<T>(List<T> elements, Ordering ord) => std::algorithm::to_sorted<T>(elements, ord);
