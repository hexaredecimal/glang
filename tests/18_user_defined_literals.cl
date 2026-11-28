// Feature Test 18: User-Defined Literal Suffixes

struct Seconds {
  double val;
}

struct Meters {
  double val;
}

[user_literal] Seconds s(double v) => Seconds{v}
[user_literal] Meters m(double v) => Meters{v}
[user_literal] uint u(int v) => v as uint;

void main() {
  Seconds sec = 5.5s;
  Meters dist = 100.0m;
  uint uval = 42u;

  double s_val = sec.val;
  double m_val = dist.val;
}
