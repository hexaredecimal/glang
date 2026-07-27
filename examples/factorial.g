import std.io : println;

int fact(int n) {
  if (n <= 1) 
    return 1; 
  else 
    return n * fact(n - 1);
}

void main() {
 auto n = 5;
 auto result = n.fact();
 println("result: %s\n", result);
}