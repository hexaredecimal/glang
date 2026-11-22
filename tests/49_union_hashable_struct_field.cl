import std.container.map;

union IntOrText {
  int number;
  const char* text;
}

struct Key {
  int tag;
  IntOrText value;
}

void main() {
  int[Key] values = [:];

  Key first;
  first.tag = 0;
  first.value.number = 42;
  values[first] = 100;

  auto (foundValue, found) = values[first];
  if (!found || foundValue != 100) {
    return;
  }
}
