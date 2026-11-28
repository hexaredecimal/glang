import std.memory.rc;
import std.io.print : printf;

struct LinkedList<T> {
    T value;
    Box<LinkedList<T>> next;
}

Box<LinkedList<T>> LinkedList<T>::new(T value) {
    auto node = Box<LinkedList<T>>::new();
    node.value = value;
    node.next = nullptr;
    return node;
}

Box<LinkedList<T>> append<T>(Box<LinkedList<T>> tail, T value) {
    auto node = Box<LinkedList<T>>::new();
    node.value = value;
    node.next = nullptr;
    tail.next = node;
    return node;
}

int main() {
    auto head = LinkedList<int>::new(10);
    auto tail = append(head, 20);
    tail = append(tail, 30);

    int sum = 0;
    auto currentNode = head;
    while (currentNode != nullptr) {
        sum += currentNode.value;
        if (currentNode.next != nullptr) {
            printf("%d -> ", currentNode.value);
        } else {
            printf("%d.\n", currentNode.value);
        }
        currentNode = currentNode.next;
    }

    printf("Linked-list sum: %d\n", sum);

    if (sum != 60) {
        return 2;
    }
    return 0;
}
