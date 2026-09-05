// Feature Test 08: Generic Structs and Generic Functions

struct Pair<T> {
  T first;
  T second;
}

T identity<T>(T value) => value

T add_gen<T>(T a, T b) => a + b

void main() {
  auto p = Pair<int>{10, 20};
  int first_elem = p.first;

  auto p_inferred = Pair{100, 200};
  int second_elem = p_inferred.second;

  int x = identity<int>(42);
  int y = add_gen(10, 20);
}
