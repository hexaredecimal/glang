// Feature Test 11: Control Flow (if/else, block expressions, while, for loops)

void main() {
  int x = 10;

  if (x > 5) {
    x = x + 1;
  } else {
    x = 0;
  }

  bool flag = if (x > 5) { yield true; } else false;

  int count = 0;
  while (count < 5) {
    count = count + 1;
  }

  int sum = 0;
  for (int i = 0; i < 5; i = i + 1) {
    sum = sum + i;
  }
}
