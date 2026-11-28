// VisualNob Visual Scripting Node Editor built with Glang std.gui and CUI.
//
// Features:
// - Interactive Bezier node graph with typed Exec & Data sockets
// - Live drag-to-connect, compatibility validation, and wire selection
// - Right-click context menus (Canvas, Node, Port, Wire)
// - Docked Node Palette & Tab/Cursor Quick-Add Node Picker
// - Live visual scripting interpreter (Run / Step Tick / Output Console)
//
// Build with:
//   ./nob --visualnob
//   or examples\cui\build.cmd -VisualNob

import std.gui;
import std.pipe;
import examples.cui.visualnob.palette;
import examples.cui.visualnob.model;
import examples.cui.visualnob.graph;
import examples.cui.visualnob.runtime;
import examples.cui.visualnob.app;

int main() {
  resetEditorDefaults(&vn);
  loadPresetThreshold(&vn);
  runFullScript(&vn);

  auto window = Window::new()
    |> set_size(1440px, 900px)
    |> set_min_size(1160.0, 720.0)
    |> set_title("VisualNob - Visual Scripting Node Editor")
    |> set_bg(vnChrome(true));

  window.on_build() {
    -> gui::setTheme(vn.darkTheme);
       buildVisualNobUi(window);
       return;
  };

  return gui::run(window);
}
