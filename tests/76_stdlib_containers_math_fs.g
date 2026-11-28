// Regression Test 76: Expanded containers, math, filesystem, and I/O helpers.
//
// Exercises Stack<T>, Queue<T>, std.math additions, std.fs.path,
// std.fs.write, std.fs.read, std.io.error, and the extended std.io.print
// overloads.
//
// Run:
//   gcli build tests\76_stdlib_containers_math_fs.g --cpp -o build\test76.cpp
//   g++ -std=c++26 build\test76.cpp -o build\test76.exe
//   build\test76.exe

import std.container.stack;
import std.container.queue;
import std.math;
import std.string.compare;
import std.fs.path;
import std.fs.write;
import std.fs.read;
import std.string.owned;
import std.io.print;
import std.io.error;
import std.lib;

void main() {
  auto stack = make_stack<int>();
  stack.push(10);
  stack.push(20);
  stack.push(30);
  if (stack.len() != 3 || stack.is_empty()) std::exit(1);

  auto (top, hasTop) = stack.peek();
  if (!hasTop || top != 30) std::exit(2);

  auto (popped, hasPopped) = stack.pop();
  if (!hasPopped || popped != 30 || stack.len() != 2) std::exit(3);

  stack.clear();
  if (!stack.is_empty() || stack.len() != 0) std::exit(4);
  auto (emptyPop, emptyPopOk) = stack.pop();
  if (emptyPopOk || emptyPop != 0) std::exit(5);

  auto queue = make_queue<int>();
  queue.enqueue(1);
  queue.enqueue(2);
  queue.enqueue(3);
  if (queue.len() != 3 || queue.is_empty()) std::exit(6);

  auto (frontValue, hasFront) = queue.front();
  if (!hasFront || frontValue != 1) std::exit(7);
  auto (dequeued, hasDequeued) = queue.dequeue();
  if (!hasDequeued || dequeued != 1 || queue.len() != 2) std::exit(8);

  queue.clear();
  if (!queue.is_empty()) std::exit(9);
  queue.enqueue(9);
  auto (lastValue, lastOk) = queue.dequeue();
  if (!lastOk || lastValue != 9) std::exit(10);

  if (fabs(-2.5) != 2.5) std::exit(11);
  if (trunc(2.9) != 2.0) std::exit(12);
  if (cbrt(27.0) != 3.0) std::exit(13);
  if (hypot(3.0, 4.0) != 5.0) std::exit(14);
  if (copysign(2.0, -1.0) != -2.0) std::exit(15);
  if (fmin(3.0, 5.0) != 3.0 || fmax(3.0, 5.0) != 5.0) std::exit(16);
  if (remainder(5.0, 2.0) != 1.0) std::exit(17);
  if (expm1(0.0) != 0.0 || log1p(0.0) != 0.0) std::exit(18);
  if (is_nan(1.0) || !is_finite(1.0) || is_infinite(1.0)) std::exit(19);
  if (lerp(0.0, 10.0, 0.5) != 5.0) std::exit(20);
  if (square(4) != 16 || cube(2) != 8 || sign(-3) != -1) std::exit(21);
  double piFromDegrees = radians(180.0);
  if (piFromDegrees < 3.14159 || piFromDegrees > 3.1416) std::exit(22);
  double degreesFromPi = degrees(3.141592653589793);
  if (degreesFromPi < 179.999 || degreesFromPi > 180.001) std::exit(23);

  if (compare_strings(file_name("std/string/trim.g"), "trim.g") != 0) std::exit(24);
  if (compare_strings(file_name("plain"), "plain") != 0) std::exit(25);
  if (compare_strings(extension("std/string/trim.g"), ".g") != 0) std::exit(26);
  if (!is_empty_string(extension("plain"))) std::exit(27);
  if (!has_extension("archive.tar.gz", ".gz")) std::exit(28);
  if (has_extension("archive.tar.gz", ".tar")) std::exit(29);

  auto writeResult = std::fs::write_string("build/stdlib_expansion_test.txt", "hello");
  if (writeResult.is_err()) {
    eprintln("write_string failed");
    std::exit(30);
  }
  auto appendResult = std::fs::append_string("build/stdlib_expansion_test.txt", " world");
  if (appendResult.is_err()) {
    eprintln("append_string failed");
    std::exit(31);
  }

  auto contentsResult = std::fs::read_to_string("build/stdlib_expansion_test.txt");
  if (contentsResult.is_err()) {
    eprintln("read_to_string failed");
    std::exit(32);
  }
  auto contents = contentsResult.unwrap();
  const char* contentsText = contents.c_str();
  if (contentsText[0] != 'h' || contentsText[5] != ' ' ||
      contentsText[10] != 'd') {
    std::exit(33);
  }

  const char* bytes = "abc";
  auto bytesResult = std::fs::write_bytes("build/stdlib_expansion_bytes_test.bin", bytes, 3);
  if (bytesResult.is_err()) std::exit(34);

  // Exercise the print overloads; output is intentionally minimal.
  print('G');
  print(7 as uchar);
  print(1 as uint);
  print(2 as ulong);
  print(1.5 as float);
  println();
}

