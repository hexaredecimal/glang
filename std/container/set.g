import std.prelude;
import std.container.list;

struct std::set {} // Module namespace

/// A set backed by the managed `List` container. Values must support `==`.
/// Removing a value marks its slot inactive; re-adding reactivates the slot.
struct Set<T> {
    List<T> values;
    List<uchar> active;
    int count;
}

Set<T> std::set::make<T>() {
    Set<T> result;
    result.count = 0;
    return result;
}

Set<T> make_set<T>() => std::set::make<T>();

/// Insert a value. Returns true when the value was not already present.
bool std::set::insert<T>(Set<T>* set, T value) {
    for (int index = 0; index < set.values.length; index = index + 1) {
        if (set.values[index] == value) {
            if (set.active[index] == 1) {
                return false;
            }
            set.active[index] = 1;
            set.count = set.count + 1;
            return true;
        }
    }
    set.values.push_back(value);
    set.active.push_back(1);
    set.count = set.count + 1;
    return true;
}

bool insert<T>(Set<T>* set, T value) => std::set::insert(set, value);

/// Alias for insert.
bool std::set::add<T>(Set<T>* set, T value) => std::set::insert(set, value);
bool add<T>(Set<T>* set, T value) => std::set::add(set, value);

bool std::set::contains<T>(Set<T> set, T value) {
    for (int index = 0; index < set.values.length; index = index + 1) {
        if (set.active[index] == 1 && set.values[index] == value) {
            return true;
        }
    }
    return false;
}

bool contains<T>(Set<T> set, T value) => std::set::contains(set, value);
bool has<T>(Set<T> set, T value) => std::set::contains(set, value);

/// Remove a value. Returns true when the value was present.
bool std::set::remove<T>(Set<T>* set, T value) {
    for (int index = 0; index < set.values.length; index = index + 1) {
        if (set.active[index] == 1 && set.values[index] == value) {
            set.active[index] = 0;
            set.count = set.count - 1;
            return true;
        }
    }
    return false;
}

bool remove<T>(Set<T>* set, T value) => std::set::remove(set, value);
bool erase<T>(Set<T>* set, T value) => std::set::remove(set, value);

int std::set::len<T>(Set<T> set) => set.count;
int len<T>(Set<T> set) => std::set::len(set);
int size<T>(Set<T> set) => std::set::len(set);

bool std::set::is_empty<T>(Set<T> set) => set.count == 0;
bool is_empty<T>(Set<T> set) => std::set::is_empty(set);

void std::set::clear<T>(Set<T>* set) {
    set.values = List<T>{};
    set.active = List<uchar>{};
    set.count = 0;
}

void clear<T>(Set<T>* set) => std::set::clear(set);
