// FigCraft Application Shell Composition.
// Connects TopBar, LeftRail, LeftPanel, Full-Bleed Interactive Canvas Stack,
// Help/Actions/Present overlays, Floating Bottom Toolbar, and RightInspector.

import std.gui;
import std.pipe;
import std.cui;
import examples.cui.figcraft.palette;
import examples.cui.figcraft.model;
import examples.cui.figcraft.canvas;
import examples.cui.figcraft.topbar;
import examples.cui.figcraft.rail;
import examples.cui.figcraft.left_panel;
import examples.cui.figcraft.toolbar;
import examples.cui.figcraft.inspector;

Widget* shortcutRow(const char* keyLabel, const char* desc, bool dark) {
  auto row = Row::new() |> set_size(fill(), 24px) |> set_align(GuiAlign::GuiAlignCenter);
  row.add(Text::new() |> set_text(desc) |> set_text_size(10.5) |> set_text_color(fcSecondaryText(dark)));
  row.add(Spacer::new() |> set_size(fill(), 1px));
  auto badge = Box::new()
    |> set_size(fit(), 20px)
    |> set_padding_xy(7.0, 0.0)
    |> set_bg(fcField(dark))
    |> set_border(1.0, fcBorder(dark))
    |> set_radius(4.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter);
  badge.add(Text::new() |> set_text(keyLabel) |> set_text_size(9.5) |> set_text_color(fcText(dark)) |> set_font(gui::mono()));
  row.add(badge);
  return row;
}

Widget* buildHelpOverlay(bool dark) {
  auto card = Column::new()
    |> set_id("fc-help-card")
    |> set_size(270px, fit())
    |> set_padding(14.0)
    |> set_gap(6.0)
    |> set_bg(fcCard(dark))
    |> set_border(1.0, fcDivider(dark))
    |> set_radius(10.0)
    |> set_elevation(GuiElevation::GuiElevationFloating);

  auto head = Row::new() |> set_size(fill(), 24px) |> set_align(GuiAlign::GuiAlignCenter);
  head.add(Text::new() |> set_text("Keyboard Shortcuts") |> set_text_size(11.5) |> set_text_color(fcText(dark)) |> set_font(gui::medium()));
  head.add(Spacer::new() |> set_size(fill(), 1px));
  auto closeBtn = Box::new()
    |> set_size(20px, 20px)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_radius(4.0)
    |> on_click() { -> ed.showHelp = false; return; };
  closeBtn.add(Icon::new() |> set_icon(std::cui::icons::x()) |> set_text_size(11.5) |> set_text_color(fcMutedText(dark)));
  head.add(closeBtn);
  card.add(head);

  card.add(Divider::new() |> set_size(fill(), 1px) |> set_bg(fcDivider(dark)));
  card.add(shortcutRow("V / F / R", "Move / Frame / Rect", dark));
  card.add(shortcutRow("P / T / C", "Pen / Text / Comment", dark));
  card.add(shortcutRow("G / L", "Layout Grid / Mode", dark));
  card.add(shortcutRow("D / Del", "Duplicate / Delete", dark));
  card.add(shortcutRow("Arrows", "Nudge 4px", dark));
  card.add(shortcutRow("+ / - / 0", "Zoom In / Out / Reset", dark));
  card.add(shortcutRow("Space+Drag", "Pan Canvas", dark));
  return card;
}

Widget* buildPresentBanner() {
  auto bar = Row::new()
    |> set_id("fc-present-bar")
    |> set_size(fit(), 38px)
    |> set_padding_xy(14.0, 0.0)
    |> set_gap(10.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_bg(fcNavy())
    |> set_border(1.0, fcGreen())
    |> set_radius(10.0)
    |> set_elevation(GuiElevation::GuiElevationFloating);

  bar.add(Icon::new() |> set_icon(std::cui::icons::play()) |> set_text_size(13.0) |> set_text_color(fcGreen()));
  bar.add(Text::new() |> set_text("Presentation Preview (click hotspots or press Esc)") |> set_text_size(10.5) |> set_text_color(fcWhite()));

  auto exitBtn = Box::new()
    |> set_id("fc-present-exit")
    |> set_size(fit(), 24px)
    |> set_padding_xy(8.0, 0.0)
    |> set_bg(fcGreen())
    |> set_radius(6.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> on_click() { -> ed.presentMode = false; return; };
  exitBtn.add(Text::new() |> set_text("Exit") |> set_text_size(10.0) |> set_text_color(fcNavy()) |> set_font(gui::medium()));
  bar.add(exitBtn);
  return bar;
}

Widget* buildCanvasCenter(bool dark) {
  auto center = Stack::new()
    |> set_size(fill(), fill())
    |> set_bg(fcCanvas(dark));

  // Layer 0: Full-bleed Canvas surface
  center.add(Canvas::new()
    |> set_id("fc-canvas")
    |> set_size(fill(), fill())
    |> on_paint() { -> paintStage(); return; });

  // Layer 1: Top-left overlays (re-expand chip when left panel collapsed, or Help card)
  auto topLeftOverlay = Column::new()
    |> set_size(fill(), fill())
    |> set_padding(12.0)
    |> set_gap(8.0)
    |> set_align(GuiAlign::GuiAlignStart)
    |> set_justify(GuiJustify::GuiJustifyStart);

  if (ed.leftCollapsed && !ed.presentMode) {
    auto expandChip = Row::new()
      |> set_id("fc-expand-left")
      |> set_size(fit(), 30px)
      |> set_padding_xy(10.0, 0.0)
      |> set_gap(6.0)
      |> set_align(GuiAlign::GuiAlignCenter)
      |> set_bg(fcCard(dark))
      |> set_border(1.0, fcDivider(dark))
      |> set_radius(8.0)
      |> set_elevation(GuiElevation::GuiElevationRaised)
      |> on_click() { -> ed.leftCollapsed = false; return; };
    expandChip.add(Icon::new() |> set_icon(std::cui::icons::panelLeft()) |> set_text_size(13.0) |> set_text_color(fcSecondaryText(dark)));
    expandChip.add(Text::new() |> set_text("Show Layers") |> set_text_size(10.5) |> set_text_color(fcText(dark)));
    topLeftOverlay.add(expandChip);
  }

  if (ed.showHelp) {
    topLeftOverlay.add(buildHelpOverlay(dark));
  }
  center.add(topLeftOverlay);

  // Layer 2: Bottom-centered floating Toolbar / QuickActions / Present Banner
  auto bottomOverlay = Column::new()
    |> set_size(fill(), fill())
    |> set_padding(12.0)
    |> set_gap(8.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyEnd);

  if (ed.presentMode) {
    bottomOverlay.add(buildPresentBanner());
  } else {
    if (ed.showActions) {
      bottomOverlay.add(buildQuickActionsBar());
    }
    bottomOverlay.add(buildBottomToolbar());
  }
  center.add(bottomOverlay);

  return center;
}

void buildFigcraftUi(Widget* window) {
  handleCanvasInput();
  window.clear();

  bool dark = ed.darkTheme;
  window.set_bg(fcChrome(dark));

  auto root = Column::new()
    |> set_size(fill(), fill())
    |> set_gap(0.0)
    |> set_bg(fcChrome(dark));

  root.add(buildTopBar());

  auto workspace = Row::new()
    |> set_size(fill(), fill())
    |> set_gap(0.0);

  if (!ed.presentMode) {
    workspace.add(buildRail());
    if (!ed.leftCollapsed) {
      workspace.add(buildLeftPanel());
    }
  }

  workspace.add(buildCanvasCenter(dark));

  if (!ed.presentMode) {
    workspace.add(buildRightPanel());
  }

  root.add(workspace);
  window.add(root);
}
