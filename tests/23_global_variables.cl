// Feature Test 23: Global Variables and Functions

int g_counter = 100;
double g_factor = 2.5;
bool g_flag = true;

struct Config {
  int maxConnections;
  bool verbose;
}

Config g_config = Config{10, true};

void incrementCounter(int delta) {
  g_counter = g_counter + delta;
}

int getCounter() => g_counter;

void main() {
  int initial = getCounter();
  incrementCounter(50);
  int updated = getCounter();

  g_config.maxConnections = 20;
  bool isVerbose = g_config.verbose;
}
