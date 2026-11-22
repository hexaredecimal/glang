import std.memory.owned;
import std.io.print : printf;

struct LinkedList<T> {
    T value;
    std::memory::Owned<LinkedList<T>> next;
}

Result<std::memory::Owned<LinkedList<T>>> LinkedList<T>::new(T value) {
    auto allocation = std::memory::make_owned<LinkedList<T>>();
    if (allocation.isErr()) {
        return std::error("LinkedList allocation failed");
    }

    auto node = allocation.unwrap();
    node.ptr.value = value;
    node.ptr.next.ptr = nullptr;
    node.ptr.next.count = 0;
    return std::ok(node);
}

LinkedList<T>* append<T>(LinkedList<T>* tail, T value) {
    auto allocation = std::memory::make_owned<LinkedList<T>>();
    if (allocation.isErr()) {
        return nullptr;
    }

    auto node = allocation.unwrap();
    node.ptr.value = value;
    node.ptr.next.ptr = nullptr;
    node.ptr.next.count = 0;

    LinkedList<T>* newTail = node.ptr;
    tail.next = node;
    node.ptr = nullptr;
    node.count = 0;
    return newTail;
}

int main() {
    auto headResult = LinkedList<int>::new(10);
    if (headResult.isErr()) {
        printf("Failed to allocate the linked-list head\n");
        return 1;
    }

    auto head = headResult.unwrap();
    LinkedList<int>* tail = head.ptr;
    tail = append(tail, 20);
    if (tail == nullptr) {
        std::memory::release(&head);
        printf("Failed to append a linked-list node\n");
        return 1;
    }
    tail = append(tail, 30);
    if (tail == nullptr) {
        auto current = head;
        head.ptr = nullptr;
        head.count = 0;
        while (current.ptr != nullptr) {
            auto next = current.ptr.next;
            current.ptr.next.ptr = nullptr;
            current.ptr.next.count = 0;
            std::memory::release(&current);
            current = next;
        }
        printf("Failed to append a linked-list node\n");
        return 1;
    }

    int sum = 0;
    LinkedList<int>* currentNode = head.ptr;
    while (currentNode != nullptr) {
        sum += currentNode.value;
        if (currentNode.next.ptr) {
            printf("%d -> ", currentNode.value);
        } else {
            printf("%d.\n", currentNode.value);
        }
        currentNode = currentNode.next.ptr;
    }

    printf("Linked-list sum: %d\n", sum);

    auto current = head;
    head.ptr = nullptr;
    head.count = 0;
    while (current.ptr != nullptr) {
        auto next = current.ptr.next;
        current.ptr.next.ptr = nullptr;
        current.ptr.next.count = 0;
        std::memory::release(&current);
        current = next;
    }

    if (sum != 60) {
        return 2;
    }
    return 0;
}
