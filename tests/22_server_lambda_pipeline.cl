// Feature Test 22: Https Server Builder Pipeline with Lambdas and Function Pointers

struct Https {
  uint port;
}

struct Response {
  uint handle;
}

void send(Response self, const char* message) {
}

void status(Response self, uint status) {
}

Https Https::server(uint port) => Https{port}
Https get(Https self, const char* path, int (*callback)(Response)) => self
Https post(Https self, const char* path, int (*callback)(Response)) => self

void start(Https self) {
}

int indexHandler(Response r) {
  r.status(200);
  r.send("OK");
  return 0;
}

void test_fn_ptr(int (*fn)(Response)) {
  Response resp = Response{1};
  fn(resp);
}

void main() {
  auto server = Https::server(8080);
  server
    .get("/") { Response r -> 0 }
    .post("/post") { Response r -> 0 }
    .start();

  // Test passing normal function to function pointer
  test_fn_ptr(indexHandler);

  // Test passing closure to function pointer
  test_fn_ptr({ Response r ->
    r.status(204);
    return 0;
  });
}
