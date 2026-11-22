
import std.algo.prelude;
import std.container.list; 

import std.math;

List<(A, B)> std::algorithm::zip<A, B>(A[] a, B[] b) {
    auto size = std::math::min(a.length, b.length);
    List<(A, B)> list;
    for (int i = 0; i < size; ++i) {
        A value_a = a[i];
        B value_b = b[i];
        list.push_back((value_a, value_b));
    }
    return list;
} 

List<(A, B)> std::algorithm::zip<A, B>(List<A> a, List<B> b) {
    auto size = std::math::min(a.size(), b.size());
    List<(A, B)> list;
    for (int i = 0; i < size; ++i) {
        A value_a = a[i];
        B value_b = b[i];
        list.push_back((value_a, value_b));
    }
    return list;
} 

List<(A, B)> zip_with<A, B>(A[] a, B[] b) => std::algorithm::zip(a, b); 
List<(A, B)> zip_with<A, B>(List<A> a, List<B> b) => std::algorithm::zip(a, b); 