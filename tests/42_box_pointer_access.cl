import std.memory.rc : Box, unwrap;

struct Item {
  int value;
}

void main() {
  Box<int> number = Box<int>::new();
  *number = 42;
  int copied = *number;
  int unwrapped = unwrap(number);
  if (unwrapped != copied) {
    return;
  }

  Box<Item> item = Box<Item>::new();
  item.value = copied;
  int field = item.value;
  if (field != copied) {
    return;
  }

  if (*number != 42 || item->value != 42) {
    return;
  }
}
