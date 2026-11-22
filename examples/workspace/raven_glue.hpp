#ifndef GLANG_RAVEN_GLUE_HPP
#define GLANG_RAVEN_GLUE_HPP

#include <cstdint>
#include <functional>
#include <memory>
#include <string>
#include <unordered_map>
#include <utility>

using RavenRid = std::uint32_t;

extern "C" {
void Rerror_set_callback(void (*callback)(int, int, const char*));
void Raction_bind(const char* name,
                  void (*callback)(RavenRid, const char*, void*),
                  void* user_data);
void Rdock_area_set_close_callback(
    RavenRid area, int (*callback)(RavenRid, RavenRid, void*),
    void* user_data);
void Rdock_area_set_changed_callback(
    RavenRid area, void (*callback)(RavenRid, void*), void* user_data);
void Rfile_browser_set_accepted_callback(
    RavenRid browser, void (*callback)(RavenRid, const char*, void*),
    void* user_data);
}

namespace glang_raven_detail {

using ErrorCallback = std::function<void(int, int, const char*)>;
using ActionCallback = std::function<void(RavenRid, const char*)>;
using FileCallback = std::function<void(RavenRid, const char*)>;
using DockCloseCallback = std::function<int(RavenRid, RavenRid)>;
using DockChangedCallback = std::function<void(RavenRid)>;

inline ErrorCallback& error_callback() {
  static ErrorCallback callback;
  return callback;
}

template <typename Key, typename Callback>
using CallbackStore =
    std::unordered_map<Key, std::shared_ptr<Callback>>;

template <typename Key, typename Callback>
CallbackStore<Key, Callback>& callback_store() {
  static CallbackStore<Key, Callback> callbacks;
  return callbacks;
}

inline void error_trampoline(int code, int severity, const char* detail) {
  if (error_callback()) error_callback()(code, severity, detail);
}

inline void action_trampoline(RavenRid sender, const char* action,
                              void* context) {
  auto* callback = static_cast<ActionCallback*>(context);
  if (callback && *callback) (*callback)(sender, action);
}

inline void file_trampoline(RavenRid browser, const char* path, void* context) {
  auto* callback = static_cast<FileCallback*>(context);
  if (callback && *callback) (*callback)(browser, path);
}

inline int dock_close_trampoline(RavenRid area, RavenRid panel,
                                 void* context) {
  auto* callback = static_cast<DockCloseCallback*>(context);
  return callback && *callback ? (*callback)(area, panel) : 0;
}

inline void dock_changed_trampoline(RavenRid area, void* context) {
  auto* callback = static_cast<DockChangedCallback*>(context);
  if (callback && *callback) (*callback)(area);
}

}  // namespace glang_raven_detail

extern "C" inline void glang_raven_error_set_callback(
    glang_raven_detail::ErrorCallback callback) {
  glang_raven_detail::error_callback() = std::move(callback);
  Rerror_set_callback(glang_raven_detail::error_trampoline);
}

extern "C" inline void glang_raven_action_bind(
    const char* name, glang_raven_detail::ActionCallback callback) {
  auto kept = std::make_shared<glang_raven_detail::ActionCallback>(
      std::move(callback));
  const std::string key = name ? name : "";
  Raction_bind(name, glang_raven_detail::action_trampoline, kept.get());
  glang_raven_detail::callback_store<std::string,
                                     glang_raven_detail::ActionCallback>()
      .insert_or_assign(key, std::move(kept));
}

extern "C" inline void glang_raven_dock_area_set_close_callback(
    RavenRid area, glang_raven_detail::DockCloseCallback callback) {
  auto kept = std::make_shared<glang_raven_detail::DockCloseCallback>(
      std::move(callback));
  Rdock_area_set_close_callback(
      area, glang_raven_detail::dock_close_trampoline, kept.get());
  glang_raven_detail::callback_store<RavenRid,
                                     glang_raven_detail::DockCloseCallback>()
      .insert_or_assign(area, std::move(kept));
}

extern "C" inline void glang_raven_dock_area_set_changed_callback(
    RavenRid area, glang_raven_detail::DockChangedCallback callback) {
  auto kept = std::make_shared<glang_raven_detail::DockChangedCallback>(
      std::move(callback));
  Rdock_area_set_changed_callback(
      area, glang_raven_detail::dock_changed_trampoline, kept.get());
  glang_raven_detail::callback_store<
      RavenRid, glang_raven_detail::DockChangedCallback>()
      .insert_or_assign(area, std::move(kept));
}

extern "C" inline void glang_raven_file_browser_set_accepted_callback(
    RavenRid browser, glang_raven_detail::FileCallback callback) {
  auto kept =
      std::make_shared<glang_raven_detail::FileCallback>(std::move(callback));
  Rfile_browser_set_accepted_callback(
      browser, glang_raven_detail::file_trampoline, kept.get());
  glang_raven_detail::callback_store<RavenRid,
                                     glang_raven_detail::FileCallback>()
      .insert_or_assign(browser, std::move(kept));
}

#endif
