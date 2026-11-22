import std.result;
import std.string.owned;
import std.string.dup;
import std.memory.owned;

Result<int> failedInt() {
  return std::error("expected failure");
}

void main() {
  auto failure = failedInt();
  if (!failure.isErr()) {
    return;
  }

  auto ownedResult = "Glang".toOwned();
  if (ownedResult.isErr()) {
    return;
  }

  auto ownedString = ownedResult.unwrap();
  if (ownedString.ptr == nullptr || ownedString.count != 6 ||
      ownedString.ptr[0] != 'G' || ownedString.ptr[4] != 'g' ||
      ownedString.ptr[5] != '\0') {
    return;
  }
  std::memory::release(&ownedString);
  if (ownedString.ptr != nullptr || ownedString.count != 0) {
    return;
  }

  auto allocated = std::memory::fromValue(7);
  if (allocated.isErr()) {
    return;
  }

  auto ownedInt = allocated.unwrap();
  if (*ownedInt.ptr != 7) {
    return;
  }
  std::memory::release(&ownedInt);

  auto ownedArrayResult = std::memory::allocateOwned<int>(2);
  if (ownedArrayResult.isErr()) {
    return;
  }
  auto ownedArray = ownedArrayResult.unwrap();
  ownedArray.ptr[0] = 3;
  ownedArray.ptr[1] = 4;
  if (ownedArray.count != 2 || ownedArray.ptr[0] != 3 ||
      ownedArray.ptr[1] != 4) {
    std::memory::release(&ownedArray);
    return;
  }
  std::memory::release(&ownedArray);

  auto (raw, rawOk) = std::memory::allocate<char>(4);
  if (!rawOk) {
    return;
  }
  raw[0] = 'a';
  auto adoptedResult = std::memory::fromPtr(raw, 4);
  if (adoptedResult.isErr()) {
    free(raw as void*);
    return;
  }
  auto adopted = adoptedResult.unwrap();
  if (adopted.ptr[0] != 'a' || adopted.count != 4) {
    std::memory::release(&adopted);
    return;
  }
  std::memory::release(&adopted);

  auto duplicateResult = std::string::dup("copy");
  if (duplicateResult.isErr()) {
    return;
  }
  auto duplicate = duplicateResult.unwrap();
  if (duplicate.ptr[0] != 'c' || duplicate.ptr[3] != 'y' ||
      duplicate.ptr[4] != '\0') {
    std::memory::release(&duplicate);
    return;
  }
  std::memory::release(&duplicate);
}
