import std.memory.rc : Box, isNull;

void main() {
  Box<int> empty = nullptr;
  if (!isNull(empty)) {
    return;
  }
  if (empty == nullptr) {
    empty = Box<int>::new();
  }
  if (isNull(empty)) {
    return;
  }
  if (empty != nullptr) {
    empty = nullptr;
  }
  if (!isNull(empty)) {
    return;
  }
}
