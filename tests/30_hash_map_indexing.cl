void main() {
  int[const char*] map = [:];
  const char* hello = "Hello";
  map[hello] = 200;
  auto (c, found) = map["Hello"];
  if (!found) {
    return;
  }

  int[const char*] initialized = ["seed": 100];
  initialized["seed"] = c;
  auto (fromLiteral, seedFound) = initialized["seed"];
  if (!seedFound) {
    return;
  }

  auto (missingValue, missingFound) = map["world"];
  if (missingFound || missingValue != 0) {
    return;
  }
}
