/*
 * Ported and adapted from Raven's workspace example.
 * Original: Copyright 2026 Oscar Soirey.
 * Changes: translated to Glang and bound to Raven's C API.
 * Licensed under Apache-2.0; see LICENSE-APACHE-2.0 and NOTICE.
 * Source: https://github.com/oscar-soirey/Raven/tree/main/examples/workspace
 */

import examples.workspace.raven;

[[extern, c_abi]]
int strcmp(const char* left, const char* right);

[[extern, c_abi]]
size_t strlen(const char* text);

[[extern, c_abi]]
void* malloc(size_t size);

[[extern, c_abi]]
void free(void* memory);

[[extern, c_abi]]
int puts(const char* text);

const uint raven::invalid_id = -1 as uint;
const int raven::backend_vulkan = 1;
const int raven::true_value = 1;
const int raven::false_value = 0;
const int raven::theme_dark = 224;
const int raven::theme_light = 225;
const int raven::theme_glass_dark = 226;
const int raven::theme_glass_light = 227;
const int raven::material_solid = 736;
const int raven::material_glass = 737;
const int raven::material_frosted_glass = 738;
const int raven::material_tinted_glass = 739;
const int raven::material_default = 740;
const int raven::dock_tab = 868;

struct WorkspaceApp {
  uint window;
  uint dock;
  uint welcome;
  uint files;
  uint log;
  uint island;
  uint look;
  char* saved_layout;
  int notes;
}

WorkspaceApp app;

void copy_text(char* destination, int capacity, const char* source) {
  int index = 0;
  while (index + 1 < capacity && source[index] != '\0') {
    destination[index] = source[index];
    index += 1;
  }
  destination[index] = '\0';
}

void append_text(char* destination, int capacity, const char* source) {
  int destination_index = 0;
  while (destination_index + 1 < capacity &&
         destination[destination_index] != '\0') {
    destination_index += 1;
  }
  int source_index = 0;
  while (destination_index + 1 < capacity && source[source_index] != '\0') {
    destination[destination_index] = source[source_index];
    destination_index += 1;
    source_index += 1;
  }
  destination[destination_index] = '\0';
}

void append_char(char* destination, int capacity, char value) {
  int index = 0;
  while (index + 1 < capacity && destination[index] != '\0') {
    index += 1;
  }
  if (index + 1 < capacity) {
    destination[index] = value;
    destination[index + 1] = '\0';
  }
}

const char* last_path_separator(const char* path) {
  const char* result = nullptr;
  int index = 0;
  while (path[index] != '\0') {
    if (path[index] == '/' || path[index] == '\\') {
      result = path + index;
    }
    index += 1;
  }
  return result;
}

void format_note(char* destination, int capacity, int note) {
  char[16] digits;
  int count = 0;
  copy_text(destination, capacity, "Note ");
  do {
    digits[count] = '0' + note % 10;
    count += 1;
    note = note / 10;
  } while (note > 0 && count < 16);
  while (count > 0) {
    count -= 1;
    append_char(destination, capacity, digits[count]);
  }
}

void say(const char* title, const char* detail) {
  char[600] line;
  copy_text(&line[0], 600, title);
  append_text(&line[0], 600, ": ");
  append_text(&line[0], 600, detail);
  raven::list_view_add_item(app.log, &line[0]);
  raven::list_view_scroll_to_item(
      app.log, raven::list_view_get_item_count(app.log) - 1);
  raven::label_set_text(raven::widget_find(app.window, "island.text"), title);
  raven::label_set_text(raven::widget_find(app.window, "island.title"), title);
  raven::label_set_text(raven::widget_find(app.window, "island.detail"), detail);
  raven::island_expand_for(app.island, 2.0);
}

void on_raven_error(int code, int severity, const char* detail) {
  char[600] message;
  copy_text(&message[0], 600, "[Raven] ");
  append_text(&message[0], 600, raven::error_to_string(code));
  append_text(&message[0], 600, " (");
  append_text(&message[0], 600, raven::severity_to_string(severity));
  append_text(&message[0], 600, "): ");
  append_text(&message[0], 600, detail);
  puts(&message[0]);
}

uint add_editor_panel(const char* title, const char* text,
                      const char* language) {
  uint editor = raven::text_editor_create(text);
  raven::text_editor_set_line_numbers(editor, raven::true_value);
  raven::text_editor_set_language(editor, language);
  uint relative = raven::invalid_id;
  if (raven::widget_is_valid(app.welcome)) {
    relative = app.welcome;
  }
  raven::dock_area_add_panel(app.dock, editor, title, raven::dock_tab, relative,
                             0.0);
  raven::dock_area_show_panel(app.dock, editor);
  return editor;
}

void on_file_accepted(uint browser, const char* path, void* user_data) {
  size_t size = 0;
  char* text = raven::file_read(path, &size);
  const char* name = last_path_separator(path);
  if (name) {
    name = name + 1;
  } else {
    name = path;
  }
  if (!text) {
    say("Cannot open", path);
    return;
  }
  if (size > 2 * 1024 * 1024) {
    say("Too large to show", name);
  } else {
    add_editor_panel(name, text, raven::language_for_file(path));
    say("Opened", name);
  }
  raven::memory_free(text);
}

int on_panel_close(uint area, uint panel, void* user_data) {
  if (panel == app.welcome) {
    app.welcome = raven::invalid_id;
  }
  return raven::true_value;
}

void on_dock_changed(uint area, void* user_data) {
  raven::label_set_text(raven::widget_find(app.window, "layout.text"),
                        raven::dock_area_save_layout(area));
}

void action_layout(uint sender, const char* action, void* user_data) {
  if (strcmp(action, "layout.save") == 0) {
    const char* layout = raven::dock_area_save_layout(app.dock);
    if (app.saved_layout) {
      free(app.saved_layout as void*);
    }
    app.saved_layout = malloc(strlen(layout) + 1) as char*;
    if (!app.saved_layout) {
      say("Cannot save layout", "Out of memory.");
      return;
    }
    copy_text(app.saved_layout, strlen(layout) + 1, layout);
    say("Layout saved", layout);
  } else if (strcmp(action, "layout.restore") == 0) {
    if (!app.saved_layout) {
      say("Nothing saved yet", "Use \"Save layout\" first.");
    } else if (raven::dock_area_load_layout(app.dock, app.saved_layout)) {
      say("Layout restored", "The panels fly back to where they were.");
    }
  } else {
    char[32] title;
    app.notes += 1;
    format_note(&title[0], 32, app.notes);
    add_editor_panel(&title[0], "", nullptr);
    say("New panel", &title[0]);
  }
}

void action_look(uint sender, const char* action, void* user_data) {
  int[4] themes = [raven::theme_dark, raven::theme_light,
                   raven::theme_glass_dark, raven::theme_glass_light];
  int[5] materials = [raven::material_default, raven::material_solid,
                      raven::material_glass, raven::material_frosted_glass,
                      raven::material_tinted_glass];
  int index = raven::combo_box_get_selected(sender);
  if (index < 0) {
    return;
  }
  if (strcmp(action, "look.theme") == 0) {
    raven::theme_apply(themes[index]);
    raven::combo_box_set_selected(raven::widget_find(app.window, "material"),
                                  0);
    say("Theme", raven::combo_box_get_item_text(sender, index));
  } else if (strcmp(action, "look.material") == 0) {
    if (index == 0) {
      int theme_index = raven::combo_box_get_selected(
          raven::widget_find(app.window, "theme"));
      raven::theme_apply(themes[theme_index]);
    } else {
      raven::theme_set_material(materials[index]);
    }
    say("Material of everything",
        raven::combo_box_get_item_text(sender, index));
  } else {
    raven::widget_set_material(app.look, materials[index]);
    say("Material of the panel", raven::combo_box_get_item_text(sender, index));
  }
}

int main() {
  const char* welcome_text =
      "/*\n"
      " * Drag the tab of a panel:\n"
      " *   - onto a tab bar, to put it with the tabs that are there;\n"
      " *   - onto the left, right, top or bottom of a panel, to split it;\n"
      " *   - onto an edge of the window, to take the whole side.\n"
      " * Drag the line between two panels to resize them.\n"
      " * Double click a file on the left to open it in a new panel.\n"
      " */\n"
      "int main(void) {\n"
      "\treturn 0;\n"
      "}\n";

  int actionCount = 0;
  raven::error_set_callback({ int code, int severity, const char* detail ->
    on_raven_error(code, severity, detail);
    return;
  });
  if (!raven::init(raven::backend_vulkan)) {
    puts("workspace: Raven initialization failed (Vulkan may be unavailable).");
    return 1;
  }
  raven::theme_apply(raven::theme_glass_dark);

  raven::action_bind("layout.save", { uint sender, const char* action ->
    actionCount += 1;
    action_layout(sender, action, nullptr);
    return;
  });
  raven::action_bind("layout.restore", { uint sender, const char* action ->
    actionCount += 1;
    action_layout(sender, action, nullptr);
    return;
  });
  raven::action_bind("note.new", { uint sender, const char* action ->
    actionCount += 1;
    action_layout(sender, action, nullptr);
    return;
  });
  raven::action_bind("look.theme", { uint sender, const char* action ->
    actionCount += 1;
    action_look(sender, action, nullptr);
    return;
  });
  raven::action_bind("look.material", { uint sender, const char* action ->
    actionCount += 1;
    action_look(sender, action, nullptr);
    return;
  });
  raven::action_bind("look.panel", { uint sender, const char* action ->
    actionCount += 1;
    action_look(sender, action, nullptr);
    return;
  });

  app.window = raven::window_create_from_xml_file(
      "examples/workspace/workspace.xml");
  if (app.window == raven::invalid_id) {
    puts("workspace: could not load examples/workspace/workspace.xml.");
    raven::shutdown();
    return 1;
  }
  app.dock = raven::widget_find(app.window, "dock");
  app.welcome = raven::widget_find(app.window, "welcome");
  app.files = raven::widget_find(app.window, "files");
  app.log = raven::widget_find(app.window, "log");
  app.island = raven::widget_find(app.window, "island");
  app.look = raven::widget_find(app.window, "look");

  raven::text_editor_set_text(app.welcome, welcome_text);
  raven::file_browser_set_directory(app.files, "examples");
  raven::file_browser_set_accepted_callback(
      app.files, { uint browser, const char* path ->
        on_file_accepted(browser, path, nullptr);
        return;
      });
  raven::dock_area_set_close_callback(
      app.dock, { uint area, uint panel ->
        return on_panel_close(area, panel, nullptr);
      });
  raven::dock_area_set_changed_callback(
      app.dock, { uint area ->
        on_dock_changed(area, nullptr);
        return;
      });
  on_dock_changed(app.dock, nullptr);
  raven::list_view_add_item(app.log, "Ready.");

  while (raven::wait_frame(-1.0)) {
  }
  if (app.saved_layout) {
    free(app.saved_layout as void*);
  }
  raven::shutdown();
  return 0;
}
