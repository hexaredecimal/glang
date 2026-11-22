
import std.prelude;
import std.panic;

struct std::list {}     // Module struct kept for std.container.list compatibility

[[core]]
struct List<T> {}


[[private, extern]]
void __list_push<T>(List<T>* self, T value);

[[private, extern]]
int __list_length<T>(List<T>* self);

void std::list::push_back<T>(List<T>* self, T value) => __list_push(self, value);

int std::list::size<T>(List<T>* self) => __list_length(self);

void push_back<T>(List<T>* self, T value) => std::list::push_back(self, value);

int size<T>(List<T>* self) => std::list::size(self);

List<T> std::to_list<T>(T[] elements) => to_list(elements);

List<T> to_list<T>(T[] elements) {
    auto result = List<T>{};
    for (int i = 0; i < elements.length; ++i) {
        result.push_back(elements[i]);
    }
    return result;
}

List<T> to_list<T>(List<T> elements) {
    auto result = List<T>{};
    for (int i = 0; i < elements.length; ++i) {
        result.push_back(elements[i]);
    }
    return result;
}

void for_each<T>(List<T> list, void (*fn)(T)) {
    for (int i = 0; i < list.length; ++i) {
        fn(list[i]);
    }
}

bool std::list::is_empty<T>(List<T>* self) => self.size() == 0;
bool is_empty<T>(List<T>* self) => self.size() == 0;

bool contains<T>(List<T> list, T item) {
    for (int i = 0; i < list.length; ++i) {
        if (list[i] == item) {
            return true;
        }
    }
    return false;
}

int index_of<T>(List<T> list, T item) {
    for (int i = 0; i < list.length; ++i) {
        if (list[i] == item) {
            return i;
        }
    }
    return -1;
}

T* front<T>(List<T> list) {
    if (list.length == 0) {
        std::panic("Attempt to access front of an empty list");
    }
    return &list[0];
}

T* back<T>(List<T> list) {
    if (list.length == 0) {
        std::panic("Attempt to access back of an empty list");
    }
    return &list[list.length - 1];
}