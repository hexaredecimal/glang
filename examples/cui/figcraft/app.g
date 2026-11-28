// FigCraft Application Shell Composition.
// Connects TopBar, LeftRail, LeftPanel, Full-Bleed Interactive Canvas Stack,
// Help/Actions/Present overlays, Floating Bottom Toolbar, and RightInspector.

import std.gui;
import std.pipe;
import std.cui;
import examples.cui.figcraft.palette;
import examples.cui.figcraft.model;
import examples.cui.figcraft.geometry;
import examples.cui.figcraft.canvas;
import examples.cui.figcraft.topbar;
import examples.cui.figcraft.rail;
import examples.cui.figcraft.left_panel;
import examples.cui.figcraft.toolbar;
import examples.cui.figcraft.inspector;
import examples.cui.figcraft.home;
import examples.cui.figcraft.menu;

Widget* shortcutRow(const char* keyLabel, const char* desc, bool dark) {
  auto row = Row::new() |> set_size(fill(), 24px) |> set_align(GuiAlign::GuiAlignCenter);
  row.add(Text::new() |> set_text(desc) |> set_text_size(10.5) |> set_text_color(fcSecondaryText(dark)));
  row.add(Spacer::new() |> set_size(fill(), 1px));
  auto badge = BBox::new()
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
  auto closeBtn = BBox::new()
    |> set_size(20px, 20px)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_radius(4.0)
    |> on_click() { -> ed.showHelp = false; return; };
  closeBtn.add(Icon::new() |> set_icon(std::cui::icons::x()) |> set_text_size(11.5) |> set_text_color(fcMutedText(dark)));
  head.add(closeBtn);
  card.add(head);

  card.add(Divider::new() |> set_size(fill(), 1px) |> set_bg(fcDivider(dark)));
  card.add(shortcutRow("V / H", "Move / Hand pan", dark));
  card.add(shortcutRow("F / S", "Frame / Slice", dark));
  card.add(shortcutRow("R / L / O", "Rect / Line / Ellipse", dark));
  card.add(shortcutRow("P / T / C", "Pen / Text / Comment", dark));
  card.add(shortcutRow("G / K", "Grid / Quick Actions", dark));
  card.add(shortcutRow("N", "Toggle smart snapping", dark));
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

  auto exitBtn = BBox::new()
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

  // Layer 1b: Top-right overlay (re-expand chip when right properties panel collapsed)
  if (ed.rightCollapsed && !ed.presentMode) {
    auto topRightOverlay = Column::new()
      |> set_size(fill(), fill())
      |> set_padding(12.0)
      |> set_gap(8.0)
      |> set_align(GuiAlign::GuiAlignEnd)
      |> set_justify(GuiJustify::GuiJustifyStart);

    auto expandRight = Row::new()
      |> set_id("fc-expand-right")
      |> set_size(fit(), 30px)
      |> set_padding_xy(10.0, 0.0)
      |> set_gap(6.0)
      |> set_align(GuiAlign::GuiAlignCenter)
      |> set_bg(fcCard(dark))
      |> set_border(1.0, fcDivider(dark))
      |> set_radius(8.0)
      |> set_elevation(GuiElevation::GuiElevationRaised)
      |> on_click() { -> ed.rightCollapsed = false; return; };
    expandRight.add(Icon::new() |> set_icon(std::cui::icons::sliders()) |> set_text_size(12.5) |> set_text_color(fcSecondaryText(dark)));
    expandRight.add(Text::new() |> set_text("Show Properties") |> set_text_size(10.5) |> set_text_color(fcText(dark)));
    topRightOverlay.add(expandRight);
    center.add(topRightOverlay);
  }

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
    if (ed.openFlyout >= 0) {
      bottomOverlay.add(buildToolFlyoutBar(dark));
    }
    bottomOverlay.add(buildBottomToolbar());
  }
  center.add(bottomOverlay);

  return center;
}

Widget* buildDragGhostOverlay() {
  float winW = if (gui::windowWidth() > 240) gui::windowWidth() as float else 1440.0;
  float winH = if (gui::windowHeight() > 120) gui::windowHeight() as float else 900.0;
  float gx = gui::clampf(gui::mouseX() + 14.0, 8.0, winW - 210.0);
  float gy = gui::clampf(gui::mouseY() + 14.0, 8.0, winH - 42.0);

  auto overlay = Column::new()
    |> set_size(fill(), fill())
    |> set_padding_each(gy, 0.0, 0.0, gx)
    |> set_align(GuiAlign::GuiAlignStart)
    |> set_justify(GuiJustify::GuiJustifyStart);

  auto pill = Row::new()
    |> set_id("fc-drag-ghost")
    |> set_size(fit(), 28px)
    |> set_padding_xy(10.0, 0.0)
    |> set_gap(6.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_bg(fcNavy())
    |> set_border(1.5, fcGreen())
    |> set_radius(8.0)
    |> set_elevation(GuiElevation::GuiElevationFloating);

  if (ed.assetDragActive) {
    pill.add(Icon::new() |> set_icon(std::cui::icons::plus()) |> set_text_size(11.0) |> set_text_color(fcGreen()));
    pill.add(Text::new() |> set_text("Drop:") |> set_text_size(10.0) |> set_text_color(fcChartMint()));
    pill.add(Text::new()
      |> set_text(if (ed.assetDragIsSection) sectionLabelOf(ed.assetDragKind) else assetLabelOf(ed.assetDragKind))
      |> set_text_size(10.0)
      |> set_text_color(fcWhite())
      |> set_font(gui::medium()));
  } else if (ed.layerDragNodeIdx >= 0 && ed.layerDragNodeIdx < ed.count) {
    pill.add(Icon::new() |> set_icon(nodeGlyph(ed.nodes[ed.layerDragNodeIdx].kind)) |> set_text_size(11.0) |> set_text_color(fcGreen()));
    pill.add(Text::new() |> set_text("Move:") |> set_text_size(10.0) |> set_text_color(fcChartMint()));
    pill.add(Text::new()
      |> set_text(&ed.nodes[ed.layerDragNodeIdx].name[0])
      |> set_text_size(10.0)
      |> set_text_color(fcWhite())
      |> set_font(gui::medium()));
  }

  overlay.add(pill);
  return overlay;
}

void buildFigcraftUi(Widget* window) {
  handleCanvasInput();
  window.clear();

  bool dark = ed.darkTheme;
  window.set_bg(fcChrome(dark));

  auto shellStack = Stack::new()
    |> set_size(fill(), fill())
    |> set_bg(fcChrome(dark));

  auto root = Column::new()
    |> set_size(fill(), fill())
    |> set_gap(0.0)
    |> set_bg(fcChrome(dark));

  root.add(buildTopBar());

  if (ed.showHome) {
    root.add(buildHomePage(dark));
  } else {
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

    if (!ed.presentMode && !ed.rightCollapsed) {
      workspace.add(buildRightPanel());
    }

    root.add(workspace);
  }

  shellStack.add(root);

  if (ed.showColorPicker && !ed.showHome && !ed.presentMode && !ed.rightCollapsed) {
    shellStack.add(buildColorPickerPopover(dark));
  }
  if (ed.showMainMenu) {
    shellStack.add(buildMainMenuPopup(dark));
  }
  if (ed.assetDragActive || ed.layerDragActive) {
    shellStack.add(buildDragGhostOverlay());
  }
  if (ed.showExitPrompt) {
    shellStack.add(buildExitModal(dark));
  } else if (ed.showSaveAsModal) {
    shellStack.add(buildSaveAsModal(dark));
  } else if (ed.showExportModal) {
    shellStack.add(buildExportModal(dark));
  }

  window.add(shellStack);
}
