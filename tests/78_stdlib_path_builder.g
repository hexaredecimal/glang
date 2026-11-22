// Regression Test 78: std.fs Path and std.string StringBuilder.
//
// Verifies Path composition through the custom `/` operator, path queries,
// normalization, extension replacement, and StringBuilder append operators.
//
// Run:
//   gcli build tests\78_stdlib_path_builder.g --cpp -o build\test78.cpp
//   g++ -std=c++26 build\test78.cpp -o build\test78.exe
//   build\test78.exe

import std.fs;
import std.string;
import std.lib;

void main() {
  auto path = "C:" / "Users" / "mfana" / "Downlods";
  if (compare_strings(path.to_string(), "C:/Users/mfana/Downlods") != 0) {
    std::exit(1);
  }
  if (path.len() != 23 || path.is_empty()) std::exit(2);

  auto parent = path.parent();
  if (compare_strings(parent.to_string(), "C:/Users/mfana") != 0) std::exit(3);

  auto root = "/" / "root" / "file.txt";
  if (compare_strings(root.to_string(), "/root/file.txt") != 0) std::exit(4);
  if (compare_strings(root.file_name(), "file.txt") != 0) std::exit(5);
  if (compare_strings(root.extension(), ".txt") != 0) std::exit(6);
  if (!root.has_extension(".txt")) std::exit(7);
  if (!root.is_absolute()) std::exit(8);
  if (make_path("relative/file").is_absolute()) std::exit(9);

  auto changed = root.with_extension("md");
  if (compare_strings(changed.to_string(), "/root/file.md") != 0) std::exit(10);

  auto suffix = path + ".bak";
  if (compare_strings(suffix.to_string(), "C:/Users/mfana/Downlods.bak") != 0) {
    std::exit(11);
  }

  auto joined = path / (make_path("archive") + ".zip");
  if (compare_strings(joined.to_string(),
                      "C:/Users/mfana/Downlods/archive.zip") != 0) {
    std::exit(12);
  }

  auto messy = make_path("C:\\\\Users\\mfana\\\\file.txt");
  auto clean = messy.normalize();
  if (compare_strings(clean.to_string(), "C:/Users/mfana/file.txt") != 0) {
    std::exit(13);
  }

  auto builder = builder();
  builder = builder << "value=" << 42 << "," << 2.5 << "," << true << "!";
  if (compare_strings(builder.to_string(), "value=42,2.500000,true!") != 0) {
    std::exit(14);
  }
  if (builder.len() != 23 || builder.is_empty()) std::exit(15);

  builder.clear();
  if (!builder.is_empty()) std::exit(16);

  auto text = builder_from("abc");
  text = text.append("def");
  text = text.append('g');
  text = text.append(7);
  if (compare_strings(text.to_string(), "abcdefg7") != 0) std::exit(17);
}
