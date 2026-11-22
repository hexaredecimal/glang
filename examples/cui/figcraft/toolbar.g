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
  auto btn = Box::new()
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

Widget* flyoutChevron(bool dark) {
  auto mark = Box::new()
    |> set_size(14px, 27px)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter);
  mark.add(Icon::new()
    |> set_icon(std::cui::icons::chevronDown())
    |> set_text_size(9.5)
    |> set_text_color(fcMutedText(dark)));
  return mark;
}

Widget* modeBtn(const char* wid, const char* glyph, int modeIdx, const char* tip, bool dark) {
  bool active = ed.bottomMode == modeIdx;
  auto btn = Box::new()
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

  toolbar.add(toolBtn(std::cui::icons::move(), ToolKind::ToolMove as int, "Move (V)", dark));
  toolbar.add(flyoutChevron(dark));
  toolbar.add(toolBtn(std::cui::icons::grid(), ToolKind::ToolFrame as int, "Frame (F)", dark));
  toolbar.add(flyoutChevron(dark));
  toolbar.add(toolBtn(std::cui::icons::square(), ToolKind::ToolRect as int, "Rectangle (R)", dark));
  toolbar.add(flyoutChevron(dark));
  toolbar.add(toolBtn(std::cui::icons::pencil(), ToolKind::ToolPen as int, "Pen (P)", dark));
  toolbar.add(flyoutChevron(dark));
  toolbar.add(toolBtn(std::cui::icons::textTool(), ToolKind::ToolText as int, "Text (T)", dark));
  toolbar.add(flyoutChevron(dark));
  toolbar.add(toolBtn(std::cui::icons::message(), ToolKind::ToolComment as int, "Comment (C)", dark));
  toolbar.add(toolBtn(std::cui::icons::zap(), ToolKind::ToolActions as int, "Actions (K)", dark));

  toolbar.add(Box::new() |> set_size(5px, 1px));
  toolbar.add(Divider::new() |> set_size(1px, 23px) |> set_bg(fcDivider(dark)));
  toolbar.add(Box::new() |> set_size(6px, 1px));

  auto modes = Row::new()
    |> set_size(fit(), 31px)
    |> set_padding(2.0)
    |> set_gap(2.0)
    |> set_bg(fcField(dark))
    |> set_radius(8.0)
    |> set_align(GuiAlign::GuiAlignCenter);
  modes.add(modeBtn("fc-mode-draw", std::cui::icons::pencil(), BottomMode::ModeDraw as int, "Draw", dark));
  modes.add(modeBtn("fc-mode-layout", std::cui::icons::grid(), BottomMode::ModeLayout as int, "Layout Grid (L)", dark));
  modes.add(modeBtn("fc-mode-dev", std::cui::icons::code(), BottomMode::ModeDev as int, "Dev mode", dark));
  toolbar.add(modes);

  return toolbar;
}

Widget* actionChip(const char* label, int actionId, bool dark) {
  auto chip = Box::new()
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
  bar.add(actionChip("Wireframe", 3, dark));
  bar.add(actionChip("Duplicate", 4, dark));
  bar.add(actionChip("Reset View", 5, dark));

  auto closeBtn = Box::new()
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
