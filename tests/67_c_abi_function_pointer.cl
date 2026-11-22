type Callback = void (*fn)(int);

[[extern, c_abi]]
void register_callback(Callback callback);

void handler(int value) {
}

int main() {
  register_callback(handler);
  return 0;
}
