// Feature Test 16: nullptr and Implicit Pointer Conversions

struct Node {
  int data;
  Node* next;
}

void process(void* ptr) {}

void main() {
  int* p1 = nullptr;
  void* vp = p1; // Pointer to void* implicit cast
  int* p2 = vp;  // void* to int* implicit cast

  Node* n = nullptr;
  n = &Node{10, nullptr};

  process(nullptr);
  process(n);
}
