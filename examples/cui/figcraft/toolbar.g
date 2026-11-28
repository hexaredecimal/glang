// FigCraft Floating Bottom Toolbar & Quick Actions Strip.
// Exact UI3 proportions: 7 tools with flyout chevrons, vertical divider,
// and working Draw / Layout / Dev mode segmented pill.

import std.gui;
import std.pipe;
import std.cui;
import examples.cui.figcraft.palette;
import examples.cui.figcraft.model;
import examples.cui.figcraft.actions;

Widget* toolBtn(const char* glyph, int toolIdx, const char* tip, bool dark) {
  bool active = ed.tool == toolIdx;
  auto btn = BBox::new()
    |> set_size(27px, 27px)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_bg(pickColor(active, fcGreen(), gui::clear()))
    |> set_hover_bg(pickColor(active, fcGreen(), fcField(dark)))
    |> set_radius(6.0)
    |> set_tooltip(tip)
    |> on_click_tag(toolIdx) { -> selectTool(&ed, gui::clickTag()); return; };

  btn.add(Icon::new()
    |> set_icon(glyph)
    |> set_text_size(14.0)
    |> set_text_color(pickColor(active, fcNavy(), fcSecondaryText(dark))));
  return btn;
}

Widget* toolGroupBtn(int groupIdx, bool dark) {
  int curTool = ed.groupTool[groupIdx];
  bool active = toolGroupOf(ed.tool) == groupIdx;
  auto btn = BBox::new()
    |> set_size(27px, 27px)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_bg(pickColor(active, fcGreen(), gui::clear()))
    |> set_hover_bg(pickColor(active, fcGreen(), fcField(dark)))
    |> set_radius(6.0)
    |> set_tooltip(toolTipOf(curTool))
    |> on_click_tag(curTool) { -> selectTool(&ed, gui::clickTag()); return; };

  btn.add(Icon::new()
    |> set_icon(toolGlyphOf(curTool))
    |> set_text_size(14.0)
    |> set_text_color(pickColor(active, fcNavy(), fcSecondaryText(dark))));
  return btn;
}

Widget* flyoutChevron(const char* wid, int groupIdx, bool dark) {
  bool open = ed.openFlyout == groupIdx;
  auto mark = BBox::new()
    |> set_id(wid)
    |> set_size(15px, 27px)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_bg(pickColor(open, fcGreenSoft(dark), gui::clear()))
    |> set_hover_bg(fcField(dark))
    |> set_radius(4.0)
    |> set_tooltip("More tools")
    |> on_click_tag(groupIdx) { -> toggleToolFlyout(&ed, gui::clickTag()); return; };
  mark.add(Icon::new()
    |> set_icon(std::cui::icons::chevronDown())
    |> set_text_size(9.5)
    |> set_text_color(pickColor(open, fcGreenDark(), fcMutedText(dark))));
  return mark;
}

Widget* modeBtn(const char* wid, const char* glyph, int modeIdx, const char* tip, bool dark) {
  bool active = ed.bottomMode == modeIdx;
  auto btn = BBox::new()
    |> set_id(wid)
    |> set_size(28px, 26px)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_bg(pickColor(active, fcCard(dark), gui::clear()))
    |> set_border(pickFloat(active, 1.0, 0.0), fcDivider(dark))
    |> set_radius(6.0)
    |> set_tooltip(tip)
    |> on_click_tag(modeIdx) { -> setBottomMode(&ed, gui::clickTag()); return; };

  btn.add(Icon::new()
    |> set_icon(glyph)
    |> set_text_size(13.0)
    |> set_text_color(pickColor(active, fcGreenDark(), fcSecondaryText(dark))));
  return btn;
}

Widget* flyoutMenuItem(int toolIdx, bool dark) {
  bool active = ed.tool == toolIdx;
  auto row = Row::new()
    |> set_size(fill(), 30px)
    |> set_padding_xy(8.0, 0.0)
    |> set_gap(8.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_bg(pickColor(active, fcGreenSoft(dark), gui::clear()))
    |> set_hover_bg(fcField(dark))
    |> set_radius(6.0)
    |> on_click_tag(toolIdx) { -> selectTool(&ed, gui::clickTag()); return; };

  auto checkSlot = BBox::new()
    |> set_size(12px, 12px)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter);
  if (active) {
    checkSlot.add(Icon::new()
      |> set_icon(std::cui::icons::check())
      |> set_text_size(11.0)
      |> set_text_color(fcGreenDark()));
  }
  row.add(checkSlot);

  row.add(Icon::new()
    |> set_icon(toolGlyphOf(toolIdx))
    |> set_text_size(13.5)
    |> set_text_color(pickColor(active, fcGreenDark(), fcText(dark))));

  row.add(Text::new()
    |> set_text(toolLabelOf(toolIdx))
    |> set_text_size(11.0)
    |> set_text_color(pickColor(active, fcText(dark), fcSecondaryText(dark))));

  row.add(Spacer::new() |> set_size(fill(), 1px));

  const char* sc = toolShortcutOf(toolIdx);
  if (sc[0] != '\0') {
    row.add(Text::new()
      |> set_text(sc)
      |> set_text_size(9.5)
      |> set_text_color(fcMutedText(dark))
      |> set_font(gui::mono()));
  }
  return row;
}

Widget* buildToolFlyoutBar(bool dark) {
  int g = ed.openFlyout;
  auto card = Column::new()
    |> set_id("fc-tool-flyout")
    |> set_size(214px, fit())
    |> set_padding(6.0)
    |> set_gap(2.0)
    |> set_bg(fcCard(dark))
    |> set_border(1.0, fcDivider(dark))
    |> set_radius(10.0)
    |> set_elevation(GuiElevation::GuiElevationFloating);

  if (g == 0) {
    card.add(flyoutMenuItem(ToolKind::ToolMove as int, dark));
    card.add(flyoutMenuItem(ToolKind::ToolHand as int, dark));
    card.add(flyoutMenuItem(ToolKind::ToolScale as int, dark));
  } else if (g == 1) {
    card.add(flyoutMenuItem(ToolKind::ToolFrame as int, dark));
    card.add(flyoutMenuItem(ToolKind::ToolSection as int, dark));
    card.add(flyoutMenuItem(ToolKind::ToolSlice as int, dark));
  } else if (g == 2) {
    card.add(flyoutMenuItem(ToolKind::ToolRect as int, dark));
    card.add(flyoutMenuItem(ToolKind::ToolLine as int, dark));
    card.add(flyoutMenuItem(ToolKind::ToolArrow as int, dark));
    card.add(flyoutMenuItem(ToolKind::ToolEllipse as int, dark));
    card.add(flyoutMenuItem(ToolKind::ToolPolygon as int, dark));
    card.add(flyoutMenuItem(ToolKind::ToolStar as int, dark));
    card.add(Divider::new() |> set_size(fill(), 1px) |> set_bg(fcDivider(dark)));
    card.add(flyoutMenuItem(ToolKind::ToolImage as int, dark));
  } else if (g == 3) {
    card.add(flyoutMenuItem(ToolKind::ToolPen as int, dark));
    card.add(flyoutMenuItem(ToolKind::ToolPencil as int, dark));
  } else {
    card.add(flyoutMenuItem(ToolKind::ToolText as int, dark));
    card.add(flyoutMenuItem(ToolKind::ToolBodyText as int, dark));
    card.add(flyoutMenuItem(ToolKind::ToolBadge as int, dark));
  }

  // Position the flyout roughly above the active chevron group relative to the centered toolbar
  float leftOffset = 0.0;
  float rightOffset = 0.0;
  if (g == 0) { rightOffset = 158.0; }
  else if (g == 1) { rightOffset = 74.0; }
  else if (g == 2) { leftOffset = 10.0; }
  else if (g == 3) { leftOffset = 94.0; }
  else { leftOffset = 178.0; }

  auto wrap = Row::new()
    |> set_size(fit(), fit())
    |> set_padding_each(0.0, rightOffset, 0.0, leftOffset)
    |> set_align(GuiAlign::GuiAlignEnd)
    |> set_justify(GuiJustify::GuiJustifyCenter);
  wrap.add(card);
  return wrap;
}

Widget* buildBottomToolbar() {
  bool dark = ed.darkTheme;
  auto toolbar = Row::new()
    |> set_id("fc-toolbar")
    |> set_size(fit(), 45px)
    |> set_padding_xy(8.0, 0.0)
    |> set_gap(1.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_bg(fcCard(dark))
    |> set_border(1.0, fcDivider(dark))
    |> set_radius(13.0)
    |> set_elevation(GuiElevation::GuiElevationFloating);

  toolbar.add(toolGroupBtn(0, dark));
  toolbar.add(flyoutChevron("fc-fly-0", 0, dark));
  toolbar.add(toolGroupBtn(1, dark));
  toolbar.add(flyoutChevron("fc-fly-1", 1, dark));
  toolbar.add(toolGroupBtn(2, dark));
  toolbar.add(flyoutChevron("fc-fly-2", 2, dark));
  toolbar.add(toolGroupBtn(3, dark));
  toolbar.add(flyoutChevron("fc-fly-3", 3, dark));
  toolbar.add(toolGroupBtn(4, dark));
  toolbar.add(flyoutChevron("fc-fly-4", 4, dark));
  toolbar.add(toolBtn(std::cui::icons::message(), ToolKind::ToolComment as int, "Comment (C)", dark));
  toolbar.add(toolBtn(std::cui::icons::zap(), ToolKind::ToolActions as int, "Actions (K)", dark));

  toolbar.add(BBox::new() |> set_size(4px, 1px));
  auto snapBtn = BBox::new()
    |> set_id("fc-snap-toggle")
    |> set_size(27px, 27px)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_bg(pickColor(ed.snapEnabled, fcGreenSoft(dark), gui::clear()))
    |> set_border(pickFloat(ed.snapEnabled, 1.0, 0.0), fcGreen())
    |> set_hover_bg(fcField(dark))
    |> set_radius(6.0)
    |> set_tooltip("Smart Snapping (N)")
    |> on_click() { -> toggleSnapping(&ed); return; };
  snapBtn.add(Icon::new()
    |> set_icon(std::cui::icons::target())
    |> set_text_size(13.5)
    |> set_text_color(pickColor(ed.snapEnabled, fcGreenDark(), fcMutedText(dark))));
  toolbar.add(snapBtn);

  toolbar.add(BBox::new() |> set_size(5px, 1px));
  toolbar.add(Divider::new() |> set_size(1px, 23px) |> set_bg(fcDivider(dark)));
  toolbar.add(BBox::new() |> set_size(6px, 1px));

  auto modes = Row::new()
    |> set_size(fit(), 31px)
    |> set_padding(2.0)
    |> set_gap(2.0)
    |> set_bg(fcField(dark))
    |> set_radius(8.0)
    |> set_align(GuiAlign::GuiAlignCenter);
  modes.add(modeBtn("fc-mode-draw", std::cui::icons::pencil(), BottomMode::ModeDraw as int, "Draw", dark));
  modes.add(modeBtn("fc-mode-layout", std::cui::icons::grid(), BottomMode::ModeLayout as int, "Layout Grid (G)", dark));
  modes.add(modeBtn("fc-mode-dev", std::cui::icons::code(), BottomMode::ModeDev as int, "Dev mode", dark));
  toolbar.add(modes);

  return toolbar;
}

Widget* actionChip(const char* label, int actionId, bool dark) {
  auto chip = BBox::new()
    |> set_size(fit(), 26px)
    |> set_padding_xy(9.0, 0.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_bg(fcField(dark))
    |> set_hover_bg(fcGreenSoft(dark))
    |> set_radius(6.0)
    |> on_click_tag(actionId) {
      -> int a = gui::clickTag();
         if (a == 0) { insertComponentAsset(&ed, 0); }
         else if (a == 1) { insertComponentAsset(&ed, 1); }
         else if (a == 2) { ed.showGrid = !ed.showGrid; }
         else if (a == 3) { ed.outlineMode = !ed.outlineMode; }
         else if (a == 4) { duplicateSelectedNode(&ed); }
         else if (a == 5) { stepZoom(&ed, 0); }
         else if (a == 6) { toggleSnapping(&ed); }
         ed.showActions = false;
         return;
    };
  chip.add(Text::new() |> set_text(label) |> set_text_size(10.0) |> set_text_color(fcText(dark)));
  return chip;
}

Widget* buildQuickActionsBar() {
  bool dark = ed.darkTheme;
  auto bar = Row::new()
    |> set_id("fc-actions-bar")
    |> set_size(fit(), 38px)
    |> set_padding_xy(10.0, 0.0)
    |> set_gap(6.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_bg(fcCard(dark))
    |> set_border(1.0, fcGreen())
    |> set_radius(10.0)
    |> set_elevation(GuiElevation::GuiElevationFloating);

  bar.add(Icon::new() |> set_icon(std::cui::icons::zap()) |> set_text_size(13.0) |> set_text_color(fcGreenDark()));
  bar.add(actionChip("+ Button", 0, dark));
  bar.add(actionChip("+ Card", 1, dark));
  bar.add(actionChip("Toggle Grid", 2, dark));
  bar.add(actionChip("Toggle Snap", 6, dark));
  bar.add(actionChip("Wireframe", 3, dark));
  bar.add(actionChip("Duplicate", 4, dark));
  bar.add(actionChip("Reset View", 5, dark));

  auto closeBtn = BBox::new()
    |> set_size(22px, 22px)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_radius(4.0)
    |> set_hover_bg(fcField(dark))
    |> on_click() { -> ed.showActions = false; return; };
  closeBtn.add(Icon::new() |> set_icon(std::cui::icons::x()) |> set_text_size(12.0) |> set_text_color(fcMutedText(dark)));
  bar.add(closeBtn);
  return bar;
}
