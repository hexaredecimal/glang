void cleanup() {
}

void nested(bool condition) {
  defer cleanup();
  if (condition) {
    defer cleanup();
    return;
  }
  while (condition) {
    defer cleanup();
    break;
  }
}

void normal_exit() {
  defer cleanup();
  defer cleanup();
}

void main() {
  nested(true);
  normal_exit();
}
