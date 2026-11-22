// Regression Test 83: std.encoding hex/Base64 and std.hash.
//
// Verifies length helpers, encode/decode round-trips, uppercase hex, invalid
// input rejection, buffer-too-small handling, and known hash values.
//
// Run:
//   gcli build tests\83_stdlib_encoding_hash.g --cpp -o build\test83.cpp
//   g++ -std=c++26 build\test83.cpp -o build\test83.exe
//   build\test83.exe

import std.encoding;
import std.hash;
import std.string;
import std.lib;

void main() {
  char[64] encoded;
  char[64] decoded;
  char[8] small;

  // Hexadecimal encoding.
  if (hex_encoded_length("Hello") != 10) std::exit(1);
  if (hex_encode("Hello", &encoded[0], 64) != 10) std::exit(2);
  if (compare_strings(&encoded[0], "48656c6c6f") != 0) std::exit(3);
  if (hex_encode_upper("xyz", &encoded[0], 64) != 6) std::exit(4);
  if (compare_strings(&encoded[0], "78797A") != 0) std::exit(5);
  if (hex_digit(10, false) != 'a' || hex_digit(15, true) != 'F') std::exit(6);
  if (hex_digit_value('f') != 15 || hex_digit_value('G') != -1) std::exit(7);
  if (hex_encoded_length("") != 0) std::exit(8);

  // Hexadecimal decoding and validation.
  if (hex_decode("48656c6c6f", &decoded[0], 64) != 5) std::exit(9);
  if (compare_strings(&decoded[0], "Hello") != 0) std::exit(10);
  if (hex_decode("414243", &decoded[0], 64) != 3) std::exit(11);
  if (compare_strings(&decoded[0], "ABC") != 0) std::exit(12);
  if (hex_decoded_length("414243") != 3) std::exit(13);
  if (hex_decoded_length("abc") != -1) std::exit(14);
  if (!hex_valid("0aFF") || hex_valid("0aF") || hex_valid("0G")) std::exit(15);
  if (hex_decode("abc", &decoded[0], 64) != -1) std::exit(16);
  if (hex_decode("zz", &decoded[0], 64) != -1) std::exit(17);
  if (hex_encode("Hello", &small[0], 8) != -1) std::exit(18);
  if (hex_encode("", &encoded[0], 64) != 0) std::exit(19);
  if (encoded[0] != '\0') std::exit(20);

  // Base64 encoding.
  if (base64_encoded_length("hello world") != 16) std::exit(21);
  if (base64_encode("hello world", &encoded[0], 64) != 16) std::exit(22);
  if (compare_strings(&encoded[0], "aGVsbG8gd29ybGQ=") != 0) std::exit(23);
  if (base64_encode("Man", &encoded[0], 64) != 4) std::exit(24);
  if (compare_strings(&encoded[0], "TWFu") != 0) std::exit(25);
  if (base64_encode("Ma", &encoded[0], 64) != 4) std::exit(26);
  if (compare_strings(&encoded[0], "TWE=") != 0) std::exit(27);
  if (base64_encode("M", &encoded[0], 64) != 4) std::exit(28);
  if (compare_strings(&encoded[0], "TQ==") != 0) std::exit(29);
  if (base64_encode("", &encoded[0], 64) != 0) std::exit(30);
  if (encoded[0] != '\0') std::exit(31);
  if (base64_digit(0) != 'A' || base64_digit(25) != 'Z') std::exit(32);
  if (base64_digit(52) != '0' || base64_digit(62) != '+') std::exit(33);
  if (base64_value('A') != 0 || base64_value('9') != 61) std::exit(34);
  if (base64_value('/') != 63 || base64_value('!') != -1) std::exit(35);

  // Base64 decoding and validation.
  if (base64_decoded_length("aGVsbG8gd29ybGQ=") != 11) std::exit(36);
  if (base64_decode("aGVsbG8gd29ybGQ=", &decoded[0], 64) != 11) std::exit(37);
  if (compare_strings(&decoded[0], "hello world") != 0) std::exit(38);
  if (base64_decode("TWFu", &decoded[0], 64) != 3) std::exit(39);
  if (compare_strings(&decoded[0], "Man") != 0) std::exit(40);
  if (base64_decode("TWE=", &decoded[0], 64) != 2) std::exit(41);
  if (decoded[0] != 'M' || decoded[1] != 'a') std::exit(42);
  if (base64_decode("", &decoded[0], 64) != 0) std::exit(43);
  if (!base64_valid("TWFu") || !base64_valid("TQ==") || !base64_valid("")) {
    std::exit(44);
  }
  if (base64_valid("TWF") || base64_valid("TW!u") || base64_valid("T===")) {
    std::exit(45);
  }
  if (base64_decode("TWF", &decoded[0], 64) != -1) std::exit(46);
  if (base64_decode("!!!!", &decoded[0], 64) != -1) std::exit(47);
  if (base64_decode("TQ===", &decoded[0], 64) != -1) std::exit(48);
  if (base64_decode("TWFu", &small[0], 2) != -1) std::exit(49);
  if (base64_encode("hello world", &small[0], 8) != -1) std::exit(50);

  // Binary round-trip through both encodings.
  char[4] binary = [(200 as char), (255 as char), 'A', '\0'];
  if (hex_encode(&binary[0], &encoded[0], 64) != 6) std::exit(51);
  if (hex_decode(&encoded[0], &binary[0], 4) != 3) std::exit(52);
  if (((binary[0] as uchar) as int) != 200) std::exit(53);
  char[4] original = [(200 as char), (255 as char), 'A', '\0'];
  if (base64_encode(&original[0], &encoded[0], 64) != 4) std::exit(54);
  if (base64_decode(&encoded[0], &binary[0], 4) != 3) std::exit(55);
  if (((binary[0] as uchar) as int) != 200) std::exit(56);
  if (((binary[1] as uchar) as int) != 255) std::exit(57);
  if (binary[2] != 'A') std::exit(58);

  // FNV-1a 32-bit hashing.
  ulong emptyHash = 2166136261 as ulong;
  ulong aHash = 3826002220 as ulong;
  ulong abcHash = 440920331 as ulong;
  if ((hash_string("") as ulong) != emptyHash) std::exit(59);
  if ((hash_string("a") as ulong) != aHash) std::exit(60);
  if ((hash_string("abc") as ulong) != abcHash) std::exit(61);
  if (hash_bytes("abc", 3) != hash_string("abc")) std::exit(62);
  if (hash_string("abc") == hash_string("abd")) std::exit(63);
  if (hash_string("abc\0def") != hash_string("abc")) std::exit(64);
  if (hash_bytes("abc\0def", 7) == hash_bytes("abc", 3)) std::exit(65);
  if (hash_string(nullptr) != hash_string("")) std::exit(66);
  if (hash_bytes(nullptr, 10) != hash_string("")) std::exit(67);
  if (hash_bytes("abc", 0) != hash_string("")) std::exit(79);

  // djb2 64-bit hashing.
  if (hash_string64("") != 5381) std::exit(68);
  if (hash_string64("a") != 177670) std::exit(69);
  if (hash_string64("abc") != 193485963) std::exit(70);
  if (hash_bytes64("abc", 3) != hash_string64("abc")) std::exit(71);
  if (hash_string64(nullptr) != 5381) std::exit(72);
  if (hash_bytes64(nullptr, 4) != 5381) std::exit(80);
  if (hash_string64("abc") == hash_string64("abd")) std::exit(73);

  // Integer hashing and combination.
  if (hash_int(0) != 0) std::exit(74);
  if (hash_int(1) == hash_int(2)) std::exit(75);
  if (hash_int(1) != hash_int(1)) std::exit(76);
  if (hash_combine(7, 11) == hash_combine(7, 12)) std::exit(77);
  if (hash_combine(7, 11) != hash_combine(7, 11)) std::exit(78);
}
