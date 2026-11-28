
import std.prelude;
import std.container.list;

/// Heap module namespace.
struct std::heap {}

/// A binary min-heap backed by `List<T>`. Values must support `<`. The heap
/// keeps its own count so popping does not need to shrink the backing list;
/// stale slots are reused by later pushes.
struct Heap<T> {
    List<T> items;
    int count;
}

Heap<T> Heap<T>::new() => Heap<T>{List<T>{}, 0};

int size<T>(Heap<T>* heap) {
    if (heap == nullptr) {
        return 0;
    }
    return heap.count;
}

bool is_empty<T>(Heap<T>* heap) => size(heap) == 0;

void clear<T>(Heap<T>* heap) {
    if (heap == nullptr) {
        return;
    }
    heap.items = List<T>{};
    heap.count = 0;
}

void swap<T>(Heap<T>* heap, int left, int right) {
    T temporary = heap.items[left];
    heap.items[left] = heap.items[right];
    heap.items[right] = temporary;
}

void sift_up<T>(Heap<T>* heap, int index) {
    int current = index;
    while (current > 0) {
        int parent = (current - 1) / 2;
        if (!(heap.items[current] < heap.items[parent])) {
            break;
        }
        swap(heap, current, parent);
        current = parent;
    }
}

void sift_down<T>(Heap<T>* heap, int index) {
    int current = index;
    while (true) {
        int left = current * 2 + 1;
        if (left >= heap.count) {
            break;
        }
        int smallest = left;
        int right = left + 1;
        if (right < heap.count && heap.items[right] < heap.items[left]) {
            smallest = right;
        }
        if (!(heap.items[smallest] < heap.items[current])) {
            break;
        }
        swap(heap, current, smallest);
        current = smallest;
    }
}

/// Insert a value.
void push<T>(Heap<T>* heap, T value) {
    if (heap == nullptr) {
        return;
    }
    if (heap.count < heap.items.length) {
        heap.items[heap.count] = value;
    } else {
        heap.items.push_back(value);
    }
    heap.count = heap.count + 1;
    sift_up(heap, heap.count - 1);
}

/// Remove and return the smallest value. The flag is false when empty.
(T, bool) pop<T>(Heap<T>* heap) {
    if (heap == nullptr || heap.count == 0) {
        T empty;
        return (empty, false);
    }
    T result = heap.items[0];
    heap.count = heap.count - 1;
    if (heap.count > 0) {
        heap.items[0] = heap.items[heap.count];
        sift_down(heap, 0);
    }
    return (result, true);
}

/// Read the smallest value without removing it. The flag is false when empty.
(T, bool) peek<T>(Heap<T>* heap) {
    if (heap == nullptr || heap.count == 0) {
        T empty;
        return (empty, false);
    }
    return (heap.items[0], true);
}

/// Insert every element of an array or slice.
void push_all<T>(Heap<T>* heap, T[] values) {
    for (int index = 0; index < values.length; index = index + 1) {
        push(heap, values[index]);
    }
}

/// Build a heap from an array or slice.
Heap<T> from<T>(T[] values) {
    Heap<T> result = make_heap<T>();
    push_all(&result, values);
    return result;
}
