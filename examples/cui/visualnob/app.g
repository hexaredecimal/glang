// VisualNob Application Shell Composition.
// Connects TopBar, Collapsible Node Palette, Full-Bleed Node Canvas Stack
// (+ Right-Click Context Menu + Cursor Quick-Add Picker + Shortcuts Card), and Right Inspector/Console.

import std.gui;
import std.pipe;
import std.cui;
import examples.cui.visualnob.palette;
import examples.cui.visualnob.model;
import examples.cui.visualnob.canvas;
import examples.cui.visualnob.topbar;
import examples.cui.visualnob.palette_panel;
import examples.cui.visualnob.context_menu;
import examples.cui.visualnob.inspector;

Widget* vnShortcutRow(const char* keys, const char* desc, bool dark) {
  auto row = Row::new() |> set_size(fill(), 22px) |> set_align(GuiAlign::GuiAlignCenter);
  row.add(Text::new() |> set_text(desc) |> set_text_size(10.0) |> set_text_color(vnSecondaryText(dark)));
  row.add(Spacer::new() |> set_size(fill(), 1px));
  auto badge = Box::new()
    |> set_size(fit(), 18px)
    |> set_padding_xy(6.0, 0.0)
    |> set_bg(vnField(dark))
    |> set_border(1.0, vnBorder(dark))
    |> set_radius(4.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter);
  badge.add(Text::new() |> set_text(keys) |> set_text_size(9.0) |> set_font(gui::mono()) |> set_text_color(vnText(dark)));
  row.add(badge);
  return row;
}

Widget* buildVnHelpCard(bool dark) {
  auto card = Column::new()
    |> set_id("vn-help-card")
    |> set_size(270px, fit())
    |> set_padding(12.0)
    |> set_gap(5.0)
    |> set_bg(vnCard(dark))
    |> set_border(1.0, vnBorder(dark))
    |> set_radius(10.0)
    |> set_elevation(GuiElevation::GuiElevationFloating);

  auto head = Row::new() |> set_size(fill(), 22px) |> set_align(GuiAlign::GuiAlignCenter);
  head.add(Text::new() |> set_text("VisualNob Controls") |> set_text_size(11.0) |> set_font(gui::medium()) |> set_text_color(vnText(dark)));
  head.add(Spacer::new() |> set_size(fill(), 1px));
  auto closeBtn = Box::new()
    |> set_size(20px, 20px)
    |> set_radius(4.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> on_click() { -> vn.showHelp = false; return; };
  closeBtn.add(Icon::new() |> set_icon(std::cui::icons::x()) |> set_text_size(11.0) |> set_text_color(vnMutedText(dark)));
  head.add(closeBtn);
  card.add(head);
  card.add(Divider::new() |> set_size(fill(), 1px) |> set_bg(vnDivider(dark)));
  card.add(vnShortcutRow("Drag Port", "Connect Typed Wire", dark));
  card.add(vnShortcutRow("Right-Click", "Context Menu", dark));
  card.add(vnShortcutRow("Tab", "Quick-Add Node", dark));
  card.add(vnShortcutRow("R / T", "Run / Step Tick", dark));
  card.add(vnShortcutRow("D / Del", "Duplicate / Delete", dark));
  card.add(vnShortcutRow("A / 0", "Auto-Layout / Fit", dark));
  card.add(vnShortcutRow("Space+Drag", "Pan Canvas", dark));
  return card;
}

Widget* buildNodeCanvasStack() {
  bool dark = vn.darkTheme;
  auto stack = Stack::new()
    |> set_size(fill(), fill())
    |> set_bg(vnCanvasBg(dark));

  stack.add(Canvas::new()
    |> set_id("vn-canvas")
    |> set_size(fill(), fill())
    |> on_paint() { -> paintNodeCanvas(); return; });

  // Top-left floating chip (re-open palette) & help overlay
  auto topLeft = Column::new()
    |> set_size(fill(), fill())
    |> set_padding(12.0)
    |> set_gap(8.0)
    |> set_align(GuiAlign::GuiAlignStart)
    |> set_justify(GuiJustify::GuiJustifyStart);

  if (vn.leftCollapsed) {
    auto expandChip = Row::new()
      |> set_id("vn-expand-left")
      |> set_size(fit(), 30px)
      |> set_padding_xy(10.0, 0.0)
      |> set_gap(6.0)
      |> set_radius(8.0)
      |> set_bg(vnCard(dark))
      |> set_border(1.0, vnBorder(dark))
      |> set_elevation(GuiElevation::GuiElevationRaised)
      |> set_align(GuiAlign::GuiAlignCenter)
      |> on_click() { -> vn.leftCollapsed = false; return; };
    expandChip.add(Icon::new() |> set_icon(std::cui::icons::panelLeft()) |> set_text_size(12.5) |> set_text_color(vnMint()));
    expandChip.add(Text::new() |> set_text("Node Palette") |> set_text_size(10.5) |> set_text_color(vnText(dark)));
    topLeft.add(expandChip);
  }

  if (vn.showHelp) {
    topLeft.add(buildVnHelpCard(dark));
  }
  stack.add(topLeft);

  if (vn.showQuickAdd) {
    stack.add(buildQuickAddPicker());
  }

  if (vn.contextKind != (ContextKind::CtxNone as int)) {
    stack.add(buildContextMenuOverlay());
  }

  return stack;
}

void buildVisualNobUi(Widget* window) {
  handleNodeCanvasInput();
  window.clear();

  bool dark = vn.darkTheme;
  window.set_bg(vnChrome(dark));

  auto root = Column::new()
    |> set_size(fill(), fill())
    |> set_gap(0.0)
    |> set_bg(vnChrome(dark));

  root.add(buildTopBar());

  auto body = Row::new()
    |> set_size(fill(), fill())
    |> set_gap(0.0);

  if (!vn.leftCollapsed) {
    body.add(buildPalettePanel());
  }
  body.add(buildNodeCanvasStack());
  body.add(buildRightInspector());

  root.add(body);
  window.add(root);
}
