// Feature Test 21: Tuples, Slices, and Defer Statements

void test_tuples() {
    (int, double) t = (42, 3.14);
    int a = t.0;
    double b = t.1;
}

void test_slices_and_arrays() {
    int[5] arr = [10, 20, 30, 40, 50];
    int l = arr.length;

    int[] s = arr[1..4];
    int slen = s.length;
    int first = s[0];
}

void test_defer() {
    int status = 0;
    defer status = 1;
    int current = status;
}

void main() {
    test_tuples();
    test_slices_and_arrays();
    test_defer();
}
