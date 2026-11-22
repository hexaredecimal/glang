int invoke_callback((const int) -> int callback) {
  return callback(42);
}

int main() {
  return invoke_callback({ const int value ->
    return value;
  });
}
