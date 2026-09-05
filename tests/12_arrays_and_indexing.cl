// Feature Test 12: Fixed Size Arrays and Indexing

void main() {
  int[5] numbers = [10, 20, 30, 40, 50];
  int count = numbers.length;

  int first = numbers[0];
  int second = numbers[1];

  int[] sub = numbers[1..3];
  int subLen = sub.length;
}
