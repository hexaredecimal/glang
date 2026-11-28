

[[core]]
struct Box<T> {}

[[private, extern]]
Box<T> __new_box<T>();

[[private, extern]]
Box<T> __new_box_with_deleter<T>(void (*deleter)(T*));

[[private, extern]]
Box<T> __box_from<T>(T value);

[[private, extern]]
Box<T> __adopt_box<T>(T* pointer, void (*deleter)(T*));

[[private, extern]]
Box<T> __new_box_array<T>(ulong count);

[[private, extern]]
long __box_use_count<T>(Box<T>* box);

/// Create a box containing a default-initialized value.
Box<T> Box<T>::new() => __new_box<T>();

/// Create a box containing a default-initialized value that is released with
/// `deleter` when the last box copy is destroyed. The deleter receives the
/// pointer produced by the box allocation.
Box<T> Box<T>::new(void (*deleter)(T*)) => __new_box_with_deleter<T>(deleter);

/// Take ownership of an existing pointer. `deleter` is invoked with `pointer`
/// when the last box copy is destroyed. The pointer must not be released
/// separately afterwards.
Box<T> Box<T>::adopt(T* pointer, void (*deleter)(T*)) =>
    __adopt_box<T>(pointer, deleter);

/// Create a box owning a value-initialized array of `count` elements. The
/// elements are constructed on allocation and destroyed when the last box
/// copy is dropped.
Box<T> Box<T>::array(ulong count) => __new_box_array<T>(count);

/// Copy `value` into a newly allocated box.
Box<T> Box<T>::from(T value) => __box_from<T>(value);

/// Number of boxes sharing the same allocation. A null box reports zero.
long Box<T>::use_count(Box<T>* box) => __box_use_count<T>(box);

/// Copy a value into a box. This is the free-function form of `Box<T>::from`.
Box<T> to_box<T>(T value) => Box<T>::from(value);
Box<T> into_box<T>(T* value, void (*deleter)(T*)) => Box<T>::adopt(value, deleter);

T deref<T>(Box<T> box) => *box;

/// Raw pointer to the boxed value. Returns null when the box is empty. The
/// pointer is valid for as long as at least one copy of the box is alive.
T* ptr<T>(Box<T> box) {
    if (box == nullptr) {
        return nullptr;
    }
    return &(*box);
}

/// Alias for `ptr`.
T* get_ptr<T>(Box<T> box) => ptr(box);

T unwrap<T>(Box<T> box) => deref(box);

bool is_null<T>(Box<T> box) => box == nullptr;

/// Free-function form of `Box<T>::use_count`.
long use_count<T>(Box<T>* box) => __box_use_count<T>(box);

