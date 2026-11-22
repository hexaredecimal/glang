// Regression Test 84: std.container BitSet and Heap, std.math.random.
//
// Verifies bitset growth and queries, min-heap ordering, deterministic
// pseudo-random sequences, range bounds, and in-place shuffling.
//
// Run:
//   gcli build tests\84_stdlib_bitset_heap_random.g --cpp -o build\test84.cpp
//   g++ -std=c++26 build\test84.cpp -o build\test84.exe
//   build\test84.exe

import std.container;
import std.string;
import std.math;
import std.lib;

void main() {
  // BitSet basics.
  BitSet set = make_bitset(40);
  if (bitset_size(&set) != 40) std::exit(1);
  if (bitset_capacity(&set) != 64) std::exit(2);
  if (bitset_test(&set, 0)) std::exit(3);
  if (!bitset_set(&set, 0)) std::exit(4);
  if (!bitset_set(&set, 31)) std::exit(5);
  if (!bitset_set(&set, 32)) std::exit(6);
  if (!bitset_set(&set, 39)) std::exit(7);
  if (!bitset_test(&set, 31) || !bitset_test(&set, 32)) std::exit(8);
  if (bitset_set(&set, 40)) std::exit(9);
  if (bitset_set(&set, -1)) std::exit(10);
  if (bitset_test(&set, 40) || bitset_test(&set, -1)) std::exit(11);
  if (bitset_count(&set) != 4) std::exit(12);
  if (bitset_first_set(&set) != 0) std::exit(13);
  if (!bitset_any(&set) || bitset_none(&set)) std::exit(14);

  if (!bitset_toggle(&set, 5)) std::exit(15);
  if (!bitset_test(&set, 5)) std::exit(16);
  if (bitset_toggle(&set, 5)) std::exit(17);
  if (bitset_test(&set, 5)) std::exit(18);
  if (!bitset_reset(&set, 31)) std::exit(19);
  if (bitset_test(&set, 31)) std::exit(20);
  if (!bitset_reset(&set, 31)) std::exit(21);
  if (bitset_reset(&set, 99)) std::exit(73);

  bitset_set_all(&set);
  if (bitset_count(&set) != 40) std::exit(22);
  if (!bitset_all(&set)) std::exit(23);
  bitset_clear_all(&set);
  if (bitset_count(&set) != 0) std::exit(24);
  if (bitset_first_set(&set) != -1) std::exit(25);
  if (!bitset_none(&set)) std::exit(26);

  // BitSet resize: grow, shrink, and grow again.
  bitset_resize(&set, 70);
  if (bitset_size(&set) != 70) std::exit(27);
  if (bitset_capacity(&set) != 96) std::exit(28);
  if (bitset_test(&set, 65)) std::exit(29);
  if (!bitset_set(&set, 65) || !bitset_set(&set, 69)) std::exit(30);
  if (bitset_first_set(&set) != 65) std::exit(31);
  bitset_resize(&set, 10);
  if (bitset_size(&set) != 10) std::exit(32);
  if (bitset_test(&set, 65)) std::exit(33);
  if (bitset_count(&set) != 0) std::exit(34);
  bitset_resize(&set, 70);
  if (bitset_test(&set, 65)) std::exit(35);
  bitset_resize(&set, 0);
  if (bitset_size(&set) != 0 || bitset_any(&set)) std::exit(36);
  bitset_resize(&set, -8);
  if (bitset_size(&set) != 0) std::exit(37);

  // BitSet rendering.
  BitSet patternSet = make_bitset(8);
  bitset_set(&patternSet, 0);
  bitset_set(&patternSet, 3);
  char[16] patternBuffer;
  if (bitset_to_chars(&patternSet, &patternBuffer[0], 16) != 8) std::exit(38);
  if (compare_strings(&patternBuffer[0], "00001001") != 0) std::exit(39);
  BitSet emptySet = make_bitset(0);
  char[4] emptyPattern;
  if (bitset_to_chars(&emptySet, &emptyPattern[0], 4) != 0) std::exit(74);
  if (compare_strings(&emptyPattern[0], "") != 0) std::exit(75);
  if (bitset_to_chars(&patternSet, &patternBuffer[0], 8) != -1) std::exit(76);
  if (bitset_to_chars(nullptr, &patternBuffer[0], 16) != -1) std::exit(77);

  // Min-heap ordering.
  Heap<int> heap = make_heap<int>();
  if (!heap_is_empty(&heap) || heap_size(&heap) != 0) std::exit(40);
  heap_push(&heap, 5);
  heap_push(&heap, 3);
  heap_push(&heap, 8);
  heap_push(&heap, 1);
  heap_push(&heap, 9);
  heap_push(&heap, 2);
  if (heap_size(&heap) != 6 || heap_is_empty(&heap)) std::exit(41);

  auto (peeked, peekOk) = heap_peek(&heap);
  if (!peekOk || peeked != 1) std::exit(42);

  int[6] expected = [1, 2, 3, 5, 8, 9];
  for (int index = 0; index < 6; index = index + 1) {
    auto (value, ok) = heap_pop(&heap);
    if (!ok || value != expected[index]) std::exit(43);
  }
  auto (drained, drainedOk) = heap_pop(&heap);
  if (drainedOk) std::exit(44);
  auto (missing, missingOk) = heap_peek(&heap);
  if (missingOk) std::exit(45);

  // Reused slots after draining.
  heap_push(&heap, 7);
  heap_push(&heap, 4);
  auto (firstReuse, firstReuseOk) = heap_pop(&heap);
  auto (secondReuse, secondReuseOk) = heap_pop(&heap);
  if (!firstReuseOk || firstReuse != 4) std::exit(46);
  if (!secondReuseOk || secondReuse != 7) std::exit(47);

  // Bulk insertion.
  int[5] bulk = [5, 0, 3, 9, 1];
  heap_push_all(&heap, bulk);
  if (heap_size(&heap) != 5) std::exit(48);
  int[5] bulkExpected = [0, 1, 3, 5, 9];
  for (int index = 0; index < 5; index = index + 1) {
    auto (value, ok) = heap_pop(&heap);
    if (!ok || value != bulkExpected[index]) std::exit(49);
  }

  // Heap construction from a slice.
  int[4] raw = [4, 2, 7, 1];
  Heap<int> built = heap_from(raw);
  if (heap_size(&built) != 4) std::exit(50);
  int[4] builtExpected = [1, 2, 4, 7];
  for (int index = 0; index < 4; index = index + 1) {
    auto (value, ok) = heap_pop(&built);
    if (!ok || value != builtExpected[index]) std::exit(51);
  }
  heap_push(&built, 12);
  heap_clear(&built);
  if (!heap_is_empty(&built) || heap_size(&built) != 0) std::exit(52);

  // Deterministic xorshift64 sequence.
  Rng firstGenerator = make_rng(1);
  Rng secondGenerator = make_rng(1);
  ulong firstValue = rng_next(&firstGenerator);
  ulong secondValue = rng_next(&secondGenerator);
  if (firstValue != secondValue) std::exit(53);
  ulong expectedFirst = 1082269761 as ulong;
  if (firstValue != expectedFirst) std::exit(54);
  Rng zeroSeed = make_rng(0);
  if (zeroSeed.state == 0) std::exit(55);
  if (rng_next(&zeroSeed) == 0) std::exit(56);

  Rng reseeded = make_rng(99);
  rng_reseed(&reseeded, 1);
  if (rng_next(&reseeded) != expectedFirst) std::exit(57);

  // Random ranges and helpers.
  Rng rng = make_rng(2024);
  for (int index = 0; index < 200; index = index + 1) {
    int value = rng_range(&rng, 5, 10);
    if (value < 5 || value >= 10) std::exit(58);
    int roll = rng_roll(&rng, 6);
    if (roll < 1 || roll > 6) std::exit(59);
    double fraction = rng_double(&rng);
    if (fraction < 0.0 || fraction >= 1.0) std::exit(60);
    double ranged = rng_range_double(&rng, -1.0, 1.0);
    if (ranged < -1.0 || ranged >= 1.0) std::exit(61);
    bool coin = rng_bool(&rng);
    if (coin != true && coin != false) std::exit(62);
    if (rng_next_int(&rng) < 0) std::exit(63);
  }
  if (rng_range(&rng, 7, 7) != 7) std::exit(64);
  if (rng_range(&rng, 10, 5) != 10) std::exit(65);
  if (rng_roll(&rng, 0) != 1) std::exit(66);
  if (rng_range_double(&rng, 2.0, 2.0) != 2.0) std::exit(67);

  // Shuffle preserves the multiset.
  int[8] cards = [1, 2, 3, 4, 5, 6, 7, 8];
  rng_shuffle(cards, &rng);
  int[9] seen = [0, 0, 0, 0, 0, 0, 0, 0, 0];
  for (int index = 0; index < 8; index = index + 1) {
    if (cards[index] < 1 || cards[index] > 8) std::exit(68);
    seen[cards[index]] = seen[cards[index]] + 1;
  }
  for (int value = 1; value <= 8; value = value + 1) {
    if (seen[value] != 1) std::exit(69);
  }

  // Aliases share the same implementation.
  Rng aliasGenerator = random_rng(7);
  int aliasValue = random_int(&aliasGenerator, 3, 4);
  if (aliasValue != 3) std::exit(70);
  double aliasDouble = random_double(&aliasGenerator);
  if (aliasDouble < 0.0 || aliasDouble >= 1.0) std::exit(71);
  bool aliasBool = random_bool(&aliasGenerator);
  if (aliasBool != true && aliasBool != false) std::exit(72);
}
