struct Key {
  int value;
}

void fill(int count) {
  int[count] values;
  int[count + 1] larger;
  int[5] fixedValues;
  int[] slice;

  values[0] = count;
  larger[0] = values[0];

  int[const char*] byName = [:];
  byName["runtime"] = larger[0];
  int[Key] byKey = [:];
}

void main() {
  fill(3);
}
