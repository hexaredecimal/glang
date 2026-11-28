import std.prelude;
import std.container.pair;
import std.container.list;
import std.string.string;

struct std::sequence {} // Module struct

/// A single-pass, pull-based lazy sequence. Values are produced only when
/// a terminal operation (`to_list`, `fold`, `count`, `for_each`, ...)
/// consumes them. Copies of a `Lazy<T>` share progression state.
[[core]]
struct Lazy<T> {}

[[private, extern]]
Lazy<T> __lazy_from_span<T>(T[] values);

[[private, extern]]
Lazy<char> __lazy_from_cstr(const char* text);

[[private, extern]]
Lazy<int> __lazy_range(int end);

[[private, extern]]
Lazy<int> __lazy_range_step(int start, int end, int step);

[[private, extern]]
Lazy<U> __lazy_map<T, U>(Lazy<T> source, U (*fn)(T));

[[private, extern]]
Lazy<T> __lazy_filter<T>(Lazy<T> source, bool (*keep)(T));

[[private, extern]]
Lazy<T> __lazy_take<T>(Lazy<T> source, int count);

[[private, extern]]
Lazy<T> __lazy_drop<T>(Lazy<T> source, int count);

[[private, extern]]
Lazy<T> __lazy_take_while<T>(Lazy<T> source, bool (*keep)(T));

[[private, extern]]
Lazy<T> __lazy_drop_while<T>(Lazy<T> source, bool (*keep)(T));

[[private, extern]]
Lazy<T> __lazy_stride<T>(Lazy<T> source, int step);

[[private, extern]]
Lazy<T> __lazy_inspect<T>(Lazy<T> source, void (*fn)(T));

[[private, extern]]
Lazy<U> __lazy_flat_map<T, U>(Lazy<T> source, Lazy<U> (*fn)(T));

[[private, extern]]
Lazy<(int, T)> __lazy_enumerate<T>(Lazy<T> source);

[[private, extern]]
Lazy<(A, B)> __lazy_zip<A, B>(Lazy<A> left, Lazy<B> right);

[[private, extern]]
Lazy<T> __lazy_chain<T>(Lazy<T> first, Lazy<T> second);

[[private, extern]]
(T*, int) __lazy_to_buffer<T>(Lazy<T> source);

[[private, extern]]
U __lazy_fold<T, U>(Lazy<T> source, U initial, U (*fn)(U, T));

[[private, extern]]
T __lazy_reduce<T>(Lazy<T> source, T (*fn)(T, T));

[[private, extern]]
int __lazy_count<T>(Lazy<T> source);

[[private, extern]]
int __lazy_count_if<T>(Lazy<T> source, bool (*predicate)(T));

[[private, extern]]
bool __lazy_any<T>(Lazy<T> source, bool (*predicate)(T));

[[private, extern]]
bool __lazy_all<T>(Lazy<T> source, bool (*predicate)(T));

[[private, extern]]
T __lazy_sum<T>(Lazy<T> source);

[[private, extern]]
(T, bool) __lazy_first<T>(Lazy<T> source);

[[private, extern]]
T __lazy_first_or<T>(Lazy<T> source, T fallback);

[[private, extern]]
T __lazy_last_or<T>(Lazy<T> source, T fallback);

[[private, extern]]
(T, bool) __lazy_nth<T>(Lazy<T> source, int index);

[[private, extern]]
void __lazy_for_each<T>(Lazy<T> source, void (*fn)(T));

/// Wrap an array, fixed array, or slice as a lazy sequence. The elements
/// are copied into owned storage, so temporary array literals are safe.
Lazy<T> to_lazy<T>(T[] elements) => __lazy_from_span(elements);

/// Wrap a `List<T>` as a lazy sequence. The elements are copied.
Lazy<T> to_lazy<T>(List<T> elements) => __lazy_from_span(elements.as_slice());

/// Iterate the bytes of a C string lazily.
Lazy<char> to_lazy(const char* text) => __lazy_from_cstr(text);

/// Iterate the bytes of a String lazily.
Lazy<char> to_lazy(String* text) => text.c_str().to_lazy();

/// A lazy sequence is already lazy.
Lazy<T> to_lazy<T>(Lazy<T> source) => source;

/// Half-open integer range: `range(end)` or `range(start, end)`.
Lazy<int> range(int end) => __lazy_range(end);

Lazy<int> range(int start, int end) => __lazy_range_step(start, end, 1);

/// Half-open integer range with an explicit step.
Lazy<int> range(int start, int end, int step) => __lazy_range_step(start, end, step);

Lazy<U> map<T, U>(Lazy<T> source, U (*fn)(T)) => __lazy_map(source, fn);

Lazy<T> filter<T>(Lazy<T> source, bool (*keep)(T)) => __lazy_filter(source, keep);

Lazy<T> take<T>(Lazy<T> source, int count) => __lazy_take(source, count);

Lazy<T> drop<T>(Lazy<T> source, int count) => __lazy_drop(source, count);

Lazy<T> take_while<T>(Lazy<T> source, bool (*keep)(T)) => __lazy_take_while(source, keep);

Lazy<T> drop_while<T>(Lazy<T> source, bool (*keep)(T)) => __lazy_drop_while(source, keep);

Lazy<T> stride<T>(Lazy<T> source, int step) => __lazy_stride(source, step);

Lazy<T> step_by<T>(Lazy<T> source, int step) => __lazy_stride(source, step);

Lazy<T> inspect<T>(Lazy<T> source, void (*fn)(T)) => __lazy_inspect(source, fn);

Lazy<U> flat_map<T, U>(Lazy<T> source, Lazy<U> (*fn)(T)) => __lazy_flat_map(source, fn);

Lazy<(int, T)> enumerate<T>(Lazy<T> source) => __lazy_enumerate(source);

Lazy<(A, B)> zip<A, B>(Lazy<A> left, Lazy<B> right) => __lazy_zip(left, right);

Lazy<T> chain<T>(Lazy<T> first, Lazy<T> second) => __lazy_chain(first, second);

/// Consume `source` into a new `List<T>`.
List<T> to_list<T>(Lazy<T> source) {
    auto (buffer, count) = __lazy_to_buffer(source);
    return List<T>::from_buffer(buffer, count);
}

List<T> collect<T>(Lazy<T> source) => source.to_list();

U fold<T, U>(Lazy<T> source, U initial, U (*fn)(U, T)) => __lazy_fold(source, initial, fn);

T reduce<T>(Lazy<T> source, T (*fn)(T, T)) => __lazy_reduce(source, fn);

int count<T>(Lazy<T> source) => __lazy_count(source);

int count_if<T>(Lazy<T> source, bool (*predicate)(T)) => __lazy_count_if(source, predicate);

bool any<T>(Lazy<T> source, bool (*predicate)(T)) => __lazy_any(source, predicate);

bool all<T>(Lazy<T> source, bool (*predicate)(T)) => __lazy_all(source, predicate);

T sum<T>(Lazy<T> source) => __lazy_sum(source);

(T, bool) first<T>(Lazy<T> source) => __lazy_first(source);

T first_or<T>(Lazy<T> source, T fallback) => __lazy_first_or(source, fallback);

T last_or<T>(Lazy<T> source, T fallback) => __lazy_last_or(source, fallback);

(T, bool) nth<T>(Lazy<T> source, int index) => __lazy_nth(source, index);

void for_each<T>(Lazy<T> source, void (*fn)(T)) => __lazy_for_each(source, fn);
