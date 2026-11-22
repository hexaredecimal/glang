import std.result;

struct Wrapped<T> {
  T value;
}

struct Factory {}

Result<int> globalFailure = std::error("global failure");

Result<int> failInt() {
  return std::error("expected failure");
}

Result<T> makeError<T>(const char* message) {
  return std::error(message);
}

Result<T> Factory::makeError<T>() {
  return std::error("static failure");
}

Result<int> failUfcs() {
  return "ufcs failure".makeError();
}

Result<double> failStatic() {
  return Factory::makeError();
}

Result<int> chooseResult(bool succeed) {
  return if (succeed) {
    yield std::ok(42);
  } else {
    yield std::error("expected failure");
  };
}

Wrapped<Result<double>> wrapError() {
  return Wrapped{std::error("nested failure")};
}

int main() {
  if (!globalFailure.isErr()) {
    return 1;
  }

  auto failure = failInt();
  if (!failure.isErr()) {
    return 2;
  }

  auto ufcsFailure = failUfcs();
  auto staticFailure = failStatic();
  if (!ufcsFailure.isErr() || !staticFailure.isErr()) {
    return 3;
  }

  auto success = chooseResult(true);
  if (!success.isOk() || success.unwrap() != 42) {
    return 4;
  }

  auto wrapped = wrapError();
  if (!wrapped.value.isErr()) {
    return 5;
  }

  return 0;
}
