import std.prelude;
import std.container.list;

struct std::queue {} // Module struct

/// FIFO queue backed by the managed `List<T>` container. The list storage is
/// reset when the queue becomes empty, so repeated fills do not grow it
/// without bound.
struct Queue<T> {
    List<T> items;
    int head;
    int count;
}

Queue<T> std::queue::make<T>() => Queue<T>{List<T>{}, 0, 0};
Queue<T> make_queue<T>() => std::queue::make<T>();

void std::queue::enqueue<T>(Queue<T>* queue, T value) {
    queue.items.push_back(value);
    queue.count = queue.count + 1;
}

/// Remove the front value. The flag is false when the queue is empty.
(T, bool) std::queue::dequeue<T>(Queue<T>* queue) {
    if (queue.count == 0) {
        T empty;
        return (empty, false);
    }
    T value = queue.items[queue.head];
    queue.head = queue.head + 1;
    queue.count = queue.count - 1;
    if (queue.count == 0) {
        queue.items = List<T>{};
        queue.head = 0;
    }
    return (value, true);
}

/// Read the front value without removing it.
(T, bool) std::queue::front<T>(Queue<T> queue) {
    if (queue.count == 0) {
        T empty;
        return (empty, false);
    }
    T value = queue.items[queue.head];
    return (value, true);
}

int std::queue::len<T>(Queue<T> queue) => queue.count;

bool std::queue::is_empty<T>(Queue<T> queue) => queue.count == 0;

void std::queue::clear<T>(Queue<T>* queue) {
    queue.items = List<T>{};
    queue.head = 0;
    queue.count = 0;
}

void enqueue<T>(Queue<T>* queue, T value) => std::queue::enqueue(queue, value);
(T, bool) dequeue<T>(Queue<T>* queue) => std::queue::dequeue(queue);
(T, bool) front<T>(Queue<T> queue) => std::queue::front(queue);
int len<T>(Queue<T> queue) => std::queue::len(queue);
bool is_empty<T>(Queue<T> queue) => std::queue::is_empty(queue);
void clear<T>(Queue<T>* queue) => std::queue::clear(queue);
