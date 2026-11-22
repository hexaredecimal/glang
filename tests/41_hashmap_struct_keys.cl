struct Key {
  int id;
  int[2] coordinates;
}

struct NestedKey {
  Key key;
  int category;
}

struct NameKey {
  const char* name;
}

void main() {
  int[Key] byKey = [:];
  byKey[Key{7, [2, 3]}] = 100;
  auto (fromKey, keyFound) = byKey[Key{7, [2, 3]}];
  if (!keyFound) {
    return;
  }
  if (fromKey != 100) {
    return;
  }

  int[NestedKey] byNestedKey = [:];
  byNestedKey[NestedKey{Key{9, [4, 5]}, 1}] = 200;
  auto (fromNestedKey, nestedFound) =
      byNestedKey[NestedKey{Key{9, [4, 5]}, 1}];
  if (!nestedFound) {
    return;
  }
  if (fromNestedKey != 200) {
    return;
  }

  int[NameKey] byName = [:];
  byName[NameKey{"same"}] = 300;
  auto (fromName, nameFound) = byName[NameKey{"same"}];
  if (!nameFound || fromName != 300) {
    return;
  }
}
