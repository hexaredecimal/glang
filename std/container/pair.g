
import std.prelude;

struct std::pair {} // Module struct

struct std::pair::Pair<T, U> {
  T first;
  U second;
}

type Pair<T, U> = std::pair::Pair<T, U>;

Pair<T, U> Pair<T, U>::new(T a, U b) => Pair{a, b};

Pair <T, U> std::pair::make_pair<T, U>(T first, U second) {
  return Pair<T, U>{first, second};
}

Pair <T, U> std::make_pair<T, U>(T first, U second) => std::pair::make_pair(first, second)

Pair<T, U> to_pair<T, U>(T first, U second) => std::pair::make_pair(first, second)
Pair<T, U> to_pair<T, U>((T, U) tuple) => std::pair::make_pair(tuple.0, tuple.1)
Pair<T, U> to_pair<T>(T[] arr) => std::pair::make_pair(arr[0], arr[1])

(T, U) to_tuple<T, U>(Pair<T, U> pair) => (pair.first, pair.second);

ulong get_size<T, U>(Pair<T, U> pair) => sizeof(T) + sizeof(U);

[[infix_operator]]
Pair<A, B> to<A, B>(A left, B right) => std::make_pair(left, right);

