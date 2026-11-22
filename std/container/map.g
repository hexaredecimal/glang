import std.option;

struct std::map {} // Module 
 
std::Option<ValueType> std::map::get<KeyType, ValueType>(ValueType[KeyType] map, KeyType key) {
    auto (value, isOk) = map[key];
    if (!isOk) {
        return std::none();
    }
    return std::some(value);
}

bool std::map::contains<KeyType, ValueType>(ValueType[KeyType] map, KeyType key) {
    auto (value, isOk) = map[key];
    return isOk;
}

std::Option<ValueType> get_value<KeyType, ValueType>(ValueType[KeyType] map, KeyType key) => std::map::get(map, key);
bool contains_key<KeyType, ValueType>(ValueType[KeyType] map, KeyType key) => std::map::contains(map, key);
