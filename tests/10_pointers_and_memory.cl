// Feature Test 10: Pointers, Address-Of, and Dereferencing

void double_value(int* ptr) {
  *ptr = *ptr * 2;
}

void main() {
  int x = 50;
  int* p = &x;
  int deref = *p;

  double_value(&x);
}
