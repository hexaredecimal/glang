#include "../examples/workspace/raven_glue.hpp"

#include <cassert>

namespace {

void (*error_callback)(int, int, const char*) = nullptr;
void (*action_callback)(RavenRid, const char*, void*) = nullptr;
void* action_context = nullptr;
void (*file_callback)(RavenRid, const char*, void*) = nullptr;
void* file_context = nullptr;
int (*dock_close_callback)(RavenRid, RavenRid, void*) = nullptr;
void* dock_close_context = nullptr;
void (*dock_changed_callback)(RavenRid, void*) = nullptr;
void* dock_changed_context = nullptr;

}  // namespace

extern "C" void Rerror_set_callback(void (*callback)(int, int, const char*)) {
  error_callback = callback;
}

extern "C" void Raction_bind(
    const char*, void (*callback)(RavenRid, const char*, void*), void* context) {
  action_callback = callback;
  action_context = context;
}

extern "C" void Rdock_area_set_close_callback(
    RavenRid, int (*callback)(RavenRid, RavenRid, void*), void* context) {
  dock_close_callback = callback;
  dock_close_context = context;
}

extern "C" void Rdock_area_set_changed_callback(
    RavenRid, void (*callback)(RavenRid, void*), void* context) {
  dock_changed_callback = callback;
  dock_changed_context = context;
}

extern "C" void Rfile_browser_set_accepted_callback(
    RavenRid, void (*callback)(RavenRid, const char*, void*), void* context) {
  file_callback = callback;
  file_context = context;
}

int main() {
  int total = 0;
  glang_raven_action_bind("save", [&](RavenRid sender, const char*) {
    total += static_cast<int>(sender);
  });
  action_callback(2, "save", action_context);
  assert(total == 2);

  glang_raven_action_bind("save", [&](RavenRid sender, const char*) {
    total += static_cast<int>(sender) * 10;
  });
  action_callback(3, "save", action_context);
  assert(total == 32);

  glang_raven_error_set_callback([&](int code, int severity, const char*) {
    total += code + severity;
  });
  error_callback(4, 5, "error");
  assert(total == 41);

  glang_raven_file_browser_set_accepted_callback(
      7, [&](RavenRid browser, const char*) {
        total += static_cast<int>(browser);
      });
  file_callback(7, "file.g", file_context);
  assert(total == 48);

  glang_raven_dock_area_set_close_callback(
      9, [&](RavenRid area, RavenRid panel) {
        total += static_cast<int>(area + panel);
        return 1;
      });
  assert(dock_close_callback(9, 2, dock_close_context) == 1);
  assert(total == 59);

  glang_raven_dock_area_set_changed_callback(
      9, [&](RavenRid area) { total += static_cast<int>(area); });
  dock_changed_callback(9, dock_changed_context);
  assert(total == 68);
}
