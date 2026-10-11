// Feature Test 04: Struct Methods, Pointer Returns, and Method Chaining

struct Builder {}

Builder* Builder::new() => &Builder{}

Builder* build_dir(Builder* self, const char* path) => self

Builder* sources(Builder* self, const char* path) => self

void main() {
  auto build = Builder::new();
  build
   .build_dir("build")
   .sources("src");
}
