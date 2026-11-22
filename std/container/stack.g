import std.prelude;
import std.container.list;

struct std::stack {} // Module struct

/// LIFO stack backed by the managed `List<T>` container.
struct Stack<T> {
    List<T> items;
    int count;
}

Stack<T> std::stack::make<T>() => Stack<T>{List<T>{}, 0};
Stack<T> make_stack<T>() => std::stack::make<T>();

void std::stack::push<T>(Stack<T>* stack, T value) {
    stack.items.push_back(value);
    stack.count = stack.count + 1;
}

/// Pop the top value. The flag is false when the stack is empty.
(T, bool) std::stack::pop<T>(Stack<T>* stack) {
    if (stack.count == 0) {
        T empty;
        return (empty, false);
    }
    T value = stack.items[stack.count - 1];
    stack.count = stack.count - 1;
    return (value, true);
}

/// Read the top value without removing it.
(T, bool) std::stack::peek<T>(Stack<T> stack) {
    if (stack.count == 0) {
        T empty;
        return (empty, false);
    }
    T value = stack.items[stack.count - 1];
    return (value, true);
}

int std::stack::len<T>(Stack<T> stack) => stack.count;

bool std::stack::is_empty<T>(Stack<T> stack) => stack.count == 0;

void std::stack::clear<T>(Stack<T>* stack) {
    stack.items = List<T>{};
    stack.count = 0;
}

void push<T>(Stack<T>* stack, T value) => std::stack::push(stack, value);
(T, bool) pop<T>(Stack<T>* stack) => std::stack::pop(stack);
(T, bool) peek<T>(Stack<T> stack) => std::stack::peek(stack);
int len<T>(Stack<T> stack) => std::stack::len(stack);
bool is_empty<T>(Stack<T> stack) => std::stack::is_empty(stack);
void clear<T>(Stack<T>* stack) => std::stack::clear(stack);
