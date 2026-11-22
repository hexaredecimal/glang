import std.memory.rc : Box;

struct Data {
  int value;
}

[[extern]]
void print(void* value);

T zero<T>() => 0 as T;

T zeroWithArg<T>(T) => 0 as T;

void inspect(Box<Data> box) {
  int value = box.value;
}

void arrays(int count) {
  int[count] runtime;
  int[count + 1] larger;
  int[5] fixed;
  int[] slice;
  int[int] map = [:];
  runtime[0] = count;
  larger[0] = runtime[0];
  map[1] = zero<int>();
}

void main() {
  auto amount = zero<int>();
  auto fromArg = zeroWithArg<int>(amount);
  auto box = Box<int>::new();
  arrays(fromArg + 4);
}
