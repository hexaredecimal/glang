[[extern, c_abi, link_name("glang_accept_callback")]]
void accept_callback((int) -> int callback);

int main() {
  int total = 0;
  accept_callback({ int value ->
    total += value;
    return total;
  });
  return total;
}
