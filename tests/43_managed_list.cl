import std.container.list : List;

struct Item {
  int value;
}

void main() {
  List<int> values = List<int>{};
  values.push(10);
  values.append(20);
  values.push(30);

  if (values.length != 3 || values[0] != 10 ||
      values[1] != 20 || values[2] != 30) {
    return;
  }

  values[1] = 25;
  if (values[1] != 25 || values.length() != 3) {
    return;
  }

  List<Item> items = List<Item>{};
  items.push(Item{42});
  if (items.length != 1 || items[0].value != 42) {
    return;
  }
}
