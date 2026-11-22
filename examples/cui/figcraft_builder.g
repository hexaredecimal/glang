// FigCraft UI Builder built with Glang std.gui and CUI.
//
// A 1:1 recreation of ArtCraft FigCraft's UI3 workspace built with modular Glang
// packages under examples/cui/figcraft/ using the std.gui builder pattern.
//
// Build with: examples\cui\build.cmd -Builder. Set CUI_SMOKE=1 for a hidden run.

import std.gui;
import std.pipe;
import examples.cui.figcraft.palette;
import examples.cui.figcraft.model;
import examples.cui.figcraft.geometry;
import examples.cui.figcraft.scene;
import examples.cui.figcraft.app;

int main() {
  initDefaultWorkspace(&ed);
  refreshInspectorLabels(&ed);

  auto window = Window::new()
    |> set_size(1440px, 900px)
    |> set_min_size(1180.0, 760.0)
    |> set_title("FigCraft - Ridgeline Studio")
    |> set_bg(fcChrome(false));

  window.on_build() {
    -> buildFigcraftUi(window);
    return;
  };

  return gui::run(window);
}
