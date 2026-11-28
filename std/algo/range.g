import std.algo.prelude; 
import std.container.list;

List<T> std::algorithm::map<T>(List<T> list, T (*fn)(T)) {
    auto result = list.clone();
    for (int i = 0; i < result.length; ++i) {
        result[i] = fn(result[i]);
    }
    return result;
}

List<T> std::algorithm::filter<T>(List<T> list, bool (*fn)(T)) {
    auto result = List<T>{};
    for (int i = 0; i < list.length; ++i) {
        if (fn(list[i])) {
            result.push_back(list[i]);
        }
    }
    return result;
}

T std::algorithm::reduce<T>(List<T> list, T (*fn)(T, T)) {
    T acc; 
    for (int i = 0; i < list.length; ++i) {
        acc = fn(acc, list[i]);
    }
    return acc;
}

bool contains<T>(T[] elements, T item) {
    for (int i = 0; i < elements.length; ++i) {
        if (elements[i] == item) {
            return true;
        }
    }
    return false;
}

int index_of<T>(T[] elements, T item) {
    for (int i = 0; i < elements.length; ++i) {
        if (elements[i] == item) {
            return i;
        }
    }
    return -1;
}

bool any<T>(T[] elements, bool (*fn)(T)) {
    for (int i = 0; i < elements.length; ++i) {
        if (fn(elements[i])) {
            return true;
        }
    }
    return false;
}

bool all<T>(T[] elements, bool (*fn)(T)) {
    for (int i = 0; i < elements.length; ++i) {
        if (!fn(elements[i])) {
            return false;
        }
    }
    return true;
}

int count<T>(T[] elements, bool (*fn)(T)) {
    int total = 0;
    for (int i = 0; i < elements.length; ++i) {
        if (fn(elements[i])) {
            total = total + 1;
        }
    }
    return total;
}

void reverse<T>(T[] elements) {
    int left = 0;
    int right = elements.length - 1;
    while (left < right) {
        T temp = elements[left];
        elements[left] = elements[right];
        elements[right] = temp;
        left = left + 1;
        right = right - 1;
    }
}

List<T> to_mapped<T>(List<T> list, T (*fn)(T)) => std::algorithm::map(list, fn); 
List<T> to_filtered<T>(List<T> list, bool (*fn)(T)) => std::algorithm::filter(list, fn); 
List<T> to_reduced<T>(List<T> list, T (*fn)(T, T)) => std::algorithm::reduce<T>(list, fn); 
