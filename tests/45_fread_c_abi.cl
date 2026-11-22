import std.fs.file;
import std.fs.read;
import std.memory.owned;

int main() {
  File* file = fopen("tests/fread_input.txt", "rb");
  if (file == nullptr) {
    return 1;
  }

  auto (buffer, allocated) = std::memory::allocate<char>(6);
  if (!allocated) {
    fclose(file);
    return 2;
  }

  size_t itemsRead = fread(buffer, 2, 3, file);
  int closeResult = fclose(file);
  if (itemsRead != 3 || closeResult != 0 ||
      buffer[0] != 'G' || buffer[1] != 'l' ||
      buffer[2] != 'a' || buffer[3] != 'n' ||
      buffer[4] != 'g' || buffer[5] != '!') {
    free(buffer as void*);
    return 3;
  }

  free(buffer as void*);

  auto contentsResult = std::fs::read_to_string("tests/fread_input.txt");
  if (contentsResult.isErr()) {
    return 4;
  }

  auto contents = contentsResult.unwrap();
  if (contents.ptr == nullptr ||
      contents.ptr[0] != 'G' || contents.ptr[1] != 'l' ||
      contents.ptr[2] != 'a' || contents.ptr[3] != 'n' ||
      contents.ptr[4] != 'g' || contents.ptr[5] != '!') {
    std::memory::release(&contents);
    return 5;
  }

  std::memory::release(&contents);

  auto missingContents =
      std::fs::read_to_string("tests/this_file_does_not_exist.gl");
  if (!missingContents.isErr()) {
    auto unexpectedContents = missingContents.unwrap();
    std::memory::release(&unexpectedContents);
    return 6;
  }

  return 0;
}
