// Feature Test 05: Scoped Constants and Struct Static Variables

struct Config {}

int Config::DEFAULT_PORT = 8080;
int int::SIZE = sizeof(int);
const int int::MAX = 2147483647;
const int int::MIN = -2147483648;

void main() {
  auto port = Config::DEFAULT_PORT;
  auto size = int::SIZE;
  auto maxVal = int::MAX;
  auto minVal = int::MIN;
}
