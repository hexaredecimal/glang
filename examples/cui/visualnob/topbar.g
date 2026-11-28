// VisualNob Top Bar Chrome:
// Brand identity, preset script switcher, Run/Tick interpreter buttons,
// Auto-layout, Grid/Snap controls, Zoom bar, Theme switcher, and Help toggle.

import std.gui;
import std.pipe;
import std.cui;
import examples.cui.visualnob.palette;
import examples.cui.visualnob.model;
import examples.cui.visualnob.graph;
import examples.cui.visualnob.runtime;

Widget* topPresetBtn(int idx, const char* label, bool dark) {
  bool active = vn.activePreset == idx;
  auto btn = Box::new()
    |> set_size(fit(), 26px)
    |> set_padding_xy(9.0, 0.0)
    |> set_radius(6.0)
    |> set_bg(vnPickColor(active, vnField(dark), gui::clear()))
    |> set_hover_bg(vnHover(dark))
    |> set_border(1.0, vnPickColor(active, vnBorder(dark), gui::clear()))
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> on_click_tag(idx) {
      -> int p = gui::clickTag();
         if (p == 0) { loadPresetThreshold(&vn); }
         else if (p == 1) { loadPresetLoop(&vn); }
         else { loadPresetGreeter(&vn); }
         runFullScript(&vn);
         return;
    };
  btn.add(Text::new()
    |> set_text(label)
    |> set_text_size(10.5)
    |> set_font(if (active) gui::medium() else gui::body())
    |> set_text_color(vnPickColor(active, vnText(dark), vnSecondaryText(dark))));
  return btn;
}

Widget* topIconToggle(const char* icon, const char* tip, bool active, int tag, bool dark) {
  auto btn = Box::new()
    |> set_size(28px, 28px)
    |> set_radius(6.0)
    |> set_bg(vnPickColor(active, vnMintSoft(dark), gui::clear()))
    |> set_hover_bg(vnHover(dark))
    |> set_border(1.0, vnPickColor(active, vnMintDark(), gui::clear()))
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_tooltip(tip)
    |> on_click_tag(tag) {
      -> int t = gui::clickTag();
         if (t == 1) { autoArrangeGraph(&vn); }
         else if (t == 2) { vn.snapToGrid = !vn.snapToGrid; }
         else if (t == 3) { vn.showGrid = !vn.showGrid; }
         else if (t == 4) { stepZoomGraph(&vn, -1); }
         else if (t == 5) { stepZoomGraph(&vn, 1); }
         else if (t == 6) { stepZoomGraph(&vn, 0); }
         else if (t == 7) {
           vn.darkTheme = !vn.darkTheme;
           gui::setTheme(vn.darkTheme);
         } else if (t == 8) {
           vn.showHelp = !vn.showHelp;
         }
         return;
    };
  btn.add(Icon::new()
    |> set_icon(icon)
    |> set_text_size(13.0)
    |> set_text_color(vnPickColor(active, vnMint(), vnSecondaryText(dark))));
  return btn;
}

Widget* buildTopBar() {
  bool dark = vn.darkTheme;
  auto bar = Row::new()
    |> set_id("vn-topbar")
    |> set_size(fill(), 46px)
    |> set_padding_xy(12.0, 0.0)
    |> set_gap(6.0)
    |> set_bg(vnChrome(dark))
    |> set_border(1.0, vnBorder(dark))
    |> set_align(GuiAlign::GuiAlignCenter);

  // Brand pill
  auto brand = Box::new()
    |> set_size(26px, 26px)
    |> set_radius(6.0)
    |> set_bg(vnMint())
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter);
  brand.add(Icon::new() |> set_icon(std::cui::icons::gitBranch()) |> set_text_size(13.5) |> set_text_color(vnNavy()));
  bar.add(brand);

  bar.add(Text::new() |> set_text("VisualNob") |> set_text_size(12.5) |> set_font(gui::medium()) |> set_text_color(vnText(dark)));
  bar.add(Text::new() |> set_text("/") |> set_text_size(11.0) |> set_text_color(vnMutedText(dark)));
  bar.add(Text::new() |> set_text(&vn.scriptName[0]) |> set_text_size(11.0) |> set_text_color(vnSecondaryText(dark)));

  bar.add(Box::new() |> set_size(12px, 1px));
  bar.add(topPresetBtn(0, "Threshold", dark));
  bar.add(topPresetBtn(1, "Loop", dark));
  bar.add(topPresetBtn(2, "Sequence", dark));

  bar.add(Spacer::new() |> set_size(fill(), 1px));

  // Primary Execution Buttons
  auto runBtn = Row::new()
    |> set_id("vn-run-btn")
    |> set_size(fit(), 28px)
    |> set_padding_xy(12.0, 0.0)
    |> set_gap(5.0)
    |> set_radius(6.0)
    |> set_bg(vnMint())
    |> set_hover_bg(vnMintDark())
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_tooltip("Run OnStart visual script (R)")
    |> on_click() { -> runFullScript(&vn); return; };
  runBtn.add(Icon::new() |> set_icon(std::cui::icons::play()) |> set_text_size(12.0) |> set_text_color(vnNavy()));
  runBtn.add(Text::new() |> set_text("Run") |> set_text_size(10.8) |> set_font(gui::medium()) |> set_text_color(vnNavy()));
  bar.add(runBtn);

  auto tickBtn = Row::new()
    |> set_id("vn-tick-btn")
    |> set_size(fit(), 28px)
    |> set_padding_xy(10.0, 0.0)
    |> set_gap(5.0)
    |> set_radius(6.0)
    |> set_bg(vnField(dark))
    |> set_hover_bg(vnHover(dark))
    |> set_border(1.0, vnBorder(dark))
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_tooltip("Step OnTick event (T)")
    |> on_click() { -> triggerTick(&vn); return; };
  tickBtn.add(Icon::new() |> set_icon(std::cui::icons::clock()) |> set_text_size(12.0) |> set_text_color(vnBlue()));
  tickBtn.add(Text::new() |> set_text("Step Tick") |> set_text_size(10.5) |> set_font(gui::medium()) |> set_text_color(vnText(dark)));
  bar.add(tickBtn);

  bar.add(Box::new() |> set_size(6px, 1px));
  bar.add(topIconToggle(std::cui::icons::sliders(), "Auto-Layout Graph (A)", false, 1, dark));
  bar.add(topIconToggle(std::cui::icons::target(), "Snap to Grid (G)", vn.snapToGrid, 2, dark));
  bar.add(topIconToggle(std::cui::icons::grid(), "Toggle Grid Lines", vn.showGrid, 3, dark));

  // Zoom controls
  bar.add(topIconToggle(std::cui::icons::zoomOut(), "Zoom Out (-)", false, 4, dark));
  auto zoomBtn = Box::new()
    |> set_size(46px, 26px)
    |> set_radius(5.0)
    |> set_bg(vnField(dark))
    |> set_hover_bg(vnHover(dark))
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_tooltip("Fit graph in view (0)")
    |> on_click() { -> fitGraphInView(&vn); return; };
  zoomBtn.add(Text::new() |> set_text(&vn.zoomLabel[0]) |> set_text_size(10.0) |> set_font(gui::mono()) |> set_text_color(vnText(dark)));
  bar.add(zoomBtn);
  bar.add(topIconToggle(std::cui::icons::zoomIn(), "Zoom In (+)", false, 5, dark));

  bar.add(topIconToggle(std::cui::icons::sun(), "Toggle Light/Dark Theme", false, 7, dark));
  bar.add(topIconToggle(std::cui::icons::help(), "Keyboard Shortcuts", vn.showHelp, 8, dark));

  return bar;
}
