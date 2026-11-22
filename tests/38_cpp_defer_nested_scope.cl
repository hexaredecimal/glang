void a() {}
void b() {}

void main() {
  defer a();

  {
    defer b();
    return;
  }
}
