// FigCraft Right Inspector Panel: Header, Zoom, Design / Prototype / Dev Mode Inspectors.

import std.gui;
import std.pipe;
import std.cui;
import examples.cui.figcraft.palette;
import examples.cui.figcraft.model;
import examples.cui.figcraft.geometry;
import examples.cui.figcraft.actions;

Widget* inspIconBtn(const char* glyph, const char* tip, bool active, int actionTag, bool dark) {
  auto btn = Box::new()
    |> set_size(24px, 24px)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_bg(pickColor(active, fcGreenSoft(dark), gui::clear()))
    |> set_hover_bg(fcField(dark))
    |> set_radius(5.0)
    |> set_tooltip(tip)
    |> on_click_tag(actionTag) {
      -> int a = gui::clickTag();
         if (a == 0) { if (ed.selected >= 0 && ed.selected < ed.count) { ed.nodes[ed.selected].rotation = 0.0; } }
         else if (a == 1) { duplicateSelectedNode(&ed); }
         else if (a == 2) { ed.bottomMode = if (ed.bottomMode == 2) 0 else 2; }
         else if (a == 3) { ed.showGrid = !ed.showGrid; }
         else if (a == 4) { ed.outlineMode = !ed.outlineMode; }
         else if (a == 5) { if (ed.selected >= 0 && ed.selected < ed.count) { ed.nodes[ed.selected].visible = !ed.nodes[ed.selected].visible; } }
         else if (a == 6) { if (ed.selected >= 0 && ed.selected < ed.count) { ed.nodes[ed.selected].locked = !ed.nodes[ed.selected].locked; } }
         else if (a == 7) { deleteSelectedNode(&ed); }
         else if (a == 8) { moveLayerOrder(&ed, ed.selected, 1); }
         else if (a == 9) { moveLayerOrder(&ed, ed.selected, -1); }
         return;
    };
  btn.add(Icon::new()
    |> set_icon(glyph)
    |> set_text_size(12.5)
    |> set_text_color(pickColor(active, fcGreenDark(), fcSecondaryText(dark))));
  return btn;
}

Widget* alignBtn(const char* glyph, int mode, const char* tip, bool dark) {
  auto btn = Box::new()
    |> set_size(30px, 27px)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_bg(fcField(dark))
    |> set_hover_bg(fcGreenSoft(dark))
    |> set_radius(5.0)
    |> set_tooltip(tip)
    |> on_click_tag(mode) { -> alignSelectedNode(&ed, gui::clickTag()); return; };
  btn.add(Icon::new() |> set_icon(glyph) |> set_text_size(12.5) |> set_text_color(fcSecondaryText(dark)));
  return btn;
}

Widget* inspSectionHeader(const char* title, bool dark) {
  auto row = Row::new() |> set_size(fill(), 24px) |> set_align(GuiAlign::GuiAlignCenter);
  row.add(Text::new() |> set_text(title) |> set_text_size(10.5) |> set_text_color(fcText(dark)) |> set_font(gui::medium()));
  row.add(Spacer::new() |> set_size(fill(), 1px));
  return row;
}

Widget* colorSwatchBtn(Color c, int varIdx, bool dark) {
  auto btn = Box::new()
    |> set_size(20px, 20px)
    |> set_bg(c)
    |> set_border(1.0, fcBorder(dark))
    |> set_radius(4.0)
    |> set_tooltip("Apply color")
    |> on_click_tag(varIdx) { -> applyColorVar(&ed, gui::clickTag()); return; };
  return btn;
}

Widget* inspVarRow(const char* name, Color c, const char* group, const char* val, int applyIdx, bool dark) {
  auto row = Row::new()
    |> set_size(fill(), 28px)
    |> set_gap(7.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_hover_bg(fcField(dark))
    |> set_radius(5.0)
    |> on_click_tag(applyIdx) { -> applyColorVar(&ed, gui::clickTag()); return; };
  row.add(Box::new() |> set_size(14px, 14px) |> set_bg(c) |> set_border(1.0, fcBorder(dark)) |> set_radius(3.0));
  row.add(Text::new() |> set_text(name) |> set_text_size(10.0) |> set_text_color(fcText(dark)));
  row.add(Spacer::new() |> set_size(fill(), 1px));
  row.add(Text::new() |> set_text(group) |> set_text_size(9.5) |> set_text_color(fcMutedText(dark)));
  row.add(Text::new() |> set_text(val) |> set_text_size(9.5) |> set_text_color(fcSecondaryText(dark)));
  return row;
}

Widget* buildDesignBody(bool dark) {
  auto scroll = Scroll::new()
    |> set_id("fc-inspector-scroll")
    |> set_size(fill(), fill())
    |> set_padding(14.0)
    |> set_gap(9.0);

  bool hasSel = ed.selected >= 0 && ed.selected < ed.count;

  // Type header + quick actions
  auto typeRow = Row::new() |> set_size(fill(), 26px) |> set_align(GuiAlign::GuiAlignCenter) |> set_gap(4.0);
  const char* kindTxt = if (hasSel) nodeKindLabel(ed.nodes[ed.selected].kind) else "Frame";
  typeRow.add(Text::new() |> set_text(kindTxt) |> set_text_size(11.5) |> set_text_color(fcText(dark)) |> set_font(gui::medium()));
  typeRow.add(Icon::new() |> set_icon(std::cui::icons::chevronDown()) |> set_text_size(10.5) |> set_text_color(fcSecondaryText(dark)));
  typeRow.add(Spacer::new() |> set_size(fill(), 1px));
  typeRow.add(inspIconBtn(std::cui::icons::rotateCcw(), "Reset rotation", false, 0, dark));
  typeRow.add(inspIconBtn(std::cui::icons::copy(), "Duplicate (D)", false, 1, dark));
  typeRow.add(inspIconBtn(std::cui::icons::code(), "Dev mode", ed.bottomMode == 2, 2, dark));
  typeRow.add(inspIconBtn(std::cui::icons::grid(), "Layout grid (G)", ed.showGrid, 3, dark));
  typeRow.add(inspIconBtn(std::cui::icons::square(), "Outline wireframe", ed.outlineMode, 4, dark));
  scroll.add(typeRow);

  // Layer / Frame editable name
  if (hasSel) {
    scroll.add(Input::new()
      |> set_id("fc-sel-name")
      |> set_placeholder("Layer name")
      |> set_buffer(&ed.nodes[ed.selected].name[0], 64)
      |> set_size(fill(), 28px));
  } else {
    scroll.add(Input::new()
      |> set_id("fc-frame-name")
      |> set_placeholder("Frame name")
      |> set_buffer(&ed.stageName[0], 48)
      |> set_size(fill(), 28px));
  }

  // Alignment bar
  scroll.add(Text::new() |> set_text("Position") |> set_text_size(10.0) |> set_text_color(fcSecondaryText(dark)));
  auto alignRow = Row::new() |> set_size(fill(), fit()) |> set_gap(5.0) |> set_align(GuiAlign::GuiAlignCenter);
  alignRow.add(alignBtn(std::cui::icons::alignLeft(), 0, "Align left", dark));
  alignRow.add(alignBtn(std::cui::icons::layers(), 1, "Align horizontal centers", dark));
  alignRow.add(alignBtn(std::cui::icons::grid(), 2, "Align right", dark));
  alignRow.add(Box::new() |> set_size(6px, 1px));
  alignRow.add(alignBtn(std::cui::icons::arrowLeft(), 3, "Align top", dark));
  alignRow.add(alignBtn(std::cui::icons::sliders(), 4, "Align vertical centers", dark));
  alignRow.add(alignBtn(std::cui::icons::arrowRight(), 5, "Align bottom", dark));
  scroll.add(alignRow);

  // X / Y Position scrubs
  auto posRow = Row::new() |> set_size(fill(), fit()) |> set_gap(8.0);
  if (hasSel) {
    posRow.add(Scrub::new() |> set_text("X") |> set_value(&ed.nodes[ed.selected].x, -4000.0, 4000.0) |> set_width(126px));
    posRow.add(Scrub::new() |> set_text("Y") |> set_value(&ed.nodes[ed.selected].y, -4000.0, 4000.0) |> set_width(126px));
  } else {
    posRow.add(Scrub::new() |> set_text("X") |> set_value(&ed.offsetX, -4000.0, 4000.0) |> set_width(126px));
    posRow.add(Scrub::new() |> set_text("Y") |> set_value(&ed.offsetY, -4000.0, 4000.0) |> set_width(126px));
  }
  scroll.add(posRow);

  // Rotation / Layer order row
  if (hasSel) {
    auto rotRow = Row::new() |> set_size(fill(), fit()) |> set_gap(6.0) |> set_align(GuiAlign::GuiAlignCenter);
    rotRow.add(Scrub::new() |> set_text("Deg") |> set_value(&ed.nodes[ed.selected].rotation, -360.0, 360.0) |> set_width(126px));
    rotRow.add(inspIconBtn(std::cui::icons::upload(), "Bring forward", false, 8, dark));
    rotRow.add(inspIconBtn(std::cui::icons::download(), "Send backward", false, 9, dark));
    rotRow.add(inspIconBtn(std::cui::icons::trash(), "Delete layer", false, 7, dark));
    scroll.add(rotRow);
  }

  scroll.add(Divider::new() |> set_size(fill(), 1px) |> set_bg(fcDivider(dark)));

  // Layout Dimensions
  scroll.add(inspSectionHeader("Layout", dark));
  auto dimRow = Row::new() |> set_size(fill(), fit()) |> set_gap(8.0);
  if (hasSel) {
    dimRow.add(Scrub::new() |> set_text("W") |> set_value(&ed.nodes[ed.selected].w, 8.0, 5000.0) |> set_width(126px));
    dimRow.add(Scrub::new() |> set_text("H") |> set_value(&ed.nodes[ed.selected].h, 8.0, 5000.0) |> set_width(126px));
  } else {
    dimRow.add(Scrub::new() |> set_text("W") |> set_value(&ed.stageW, 320.0, 3840.0) |> set_width(126px));
    dimRow.add(Scrub::new() |> set_text("H") |> set_value(&ed.stageH, 240.0, 2400.0) |> set_width(126px));
  }
  scroll.add(dimRow);
  scroll.add(Checkbox::new() |> set_text("Clip content") |> set_checked(&ed.clipContent));

  scroll.add(Divider::new() |> set_size(fill(), 1px) |> set_bg(fcDivider(dark)));

  // Appearance (Opacity + Corner radius + Visibility/Lock)
  auto appHead = inspSectionHeader("Appearance", dark);
  if (hasSel) {
    appHead.add(inspIconBtn(
      pickText(ed.nodes[ed.selected].visible, std::cui::icons::eye(), std::cui::icons::eyeOff()),
      "Toggle visibility", !ed.nodes[ed.selected].visible, 5, dark));
    appHead.add(inspIconBtn(
      std::cui::icons::shield(),
      pickText(ed.nodes[ed.selected].locked, "Unlock layer", "Lock layer"),
      ed.nodes[ed.selected].locked, 6, dark));
  }
  scroll.add(appHead);

  if (hasSel) {
    auto appRow = Row::new() |> set_size(fill(), fit()) |> set_gap(8.0);
    appRow.add(Scrub::new() |> set_text("Op") |> set_value(&ed.nodes[ed.selected].opacity, 0.1, 1.0) |> set_step(0.05) |> set_width(126px));
    appRow.add(Scrub::new() |> set_text("R") |> set_value(&ed.nodes[ed.selected].radius, 0.0, 200.0) |> set_width(126px));
    scroll.add(appRow);
  } else {
    auto appRow = Row::new() |> set_size(fill(), fit()) |> set_gap(8.0);
    appRow.add(Text::new() |> set_text("Opacity: 100%") |> set_text_size(10.0) |> set_text_color(fcSecondaryText(dark)));
    appRow.add(Spacer::new() |> set_size(fill(), 1px));
    appRow.add(Text::new() |> set_text("Radius: 2") |> set_text_size(10.0) |> set_text_color(fcSecondaryText(dark)));
    scroll.add(appRow);
  }

  scroll.add(Divider::new() |> set_size(fill(), 1px) |> set_bg(fcDivider(dark)));

  // Fill section + clickable swatches
  auto fillHead = inspSectionHeader("Fill", dark);
  auto eyeBtn = Box::new()
    |> set_size(24px, 24px)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_radius(4.0)
    |> set_hover_bg(fcField(dark))
    |> on_click() { -> ed.fillVisible = !ed.fillVisible; return; };
  eyeBtn.add(Icon::new()
    |> set_icon(pickText(ed.fillVisible, std::cui::icons::eye(), std::cui::icons::eyeOff()))
    |> set_text_size(12.0)
    |> set_text_color(fcMutedText(dark)));
  fillHead.add(eyeBtn);
  scroll.add(fillHead);

  Color activeSwatch = ed.stageBg;
  if (hasSel) {
    activeSwatch = if (ed.nodes[ed.selected].kind == (NodeKind::NodeText as int)) ed.nodes[ed.selected].ink else ed.nodes[ed.selected].fill;
  }
  auto fillRow = Row::new() |> set_size(fill(), 26px) |> set_align(GuiAlign::GuiAlignCenter) |> set_gap(7.0);
  fillRow.add(Box::new() |> set_size(16px, 16px) |> set_bg(activeSwatch) |> set_border(1.0, fcBorder(dark)) |> set_radius(3.0));
  fillRow.add(Text::new() |> set_text(&ed.hexLabel[0]) |> set_text_size(10.0) |> set_text_color(fcText(dark)) |> set_font(gui::mono()));
  fillRow.add(Spacer::new() |> set_size(fill(), 1px));
  fillRow.add(Text::new() |> set_text(&ed.opacityLabel[0]) |> set_text_size(9.5) |> set_text_color(fcSecondaryText(dark)));
  scroll.add(fillRow);

  auto swatchBar = Row::new() |> set_size(fill(), 26px) |> set_gap(6.0) |> set_align(GuiAlign::GuiAlignCenter);
  for (int v = 0; v < ed.colorVarCount && v < 6; v = v + 1) {
    swatchBar.add(colorSwatchBtn(ed.colorVars[v].color, v, dark));
  }
  scroll.add(swatchBar);

  // Stroke section
  if (hasSel) {
    scroll.add(Divider::new() |> set_size(fill(), 1px) |> set_bg(fcDivider(dark)));
    scroll.add(inspSectionHeader("Stroke", dark));
    auto strokeRow = Row::new() |> set_size(fill(), fit()) |> set_gap(8.0) |> set_align(GuiAlign::GuiAlignCenter);
    strokeRow.add(Scrub::new() |> set_text("W") |> set_value(&ed.nodes[ed.selected].border, 0.0, 24.0) |> set_step(0.5) |> set_width(126px));
    strokeRow.add(Text::new() |> set_text("Inside") |> set_text_size(10.0) |> set_text_color(fcMutedText(dark)));
    scroll.add(strokeRow);
  }

  scroll.add(Divider::new() |> set_size(fill(), 1px) |> set_bg(fcDivider(dark)));
  scroll.add(inspSectionHeader("Selection colors", dark));
  scroll.add(inspVarRow("Surface/Canvas", fcDesignBg(false), "Selected", "100%", 0, dark));
  scroll.add(inspVarRow("0F1726", fcNavy(), "Ink", "100%", 1, dark));
  scroll.add(inspVarRow("Accent", fcGreen(), "Accent", "100%", 2, dark));

  return scroll;
}

Widget* buildPrototypeBody(bool dark) {
  auto scroll = Scroll::new()
    |> set_id("fc-proto-scroll")
    |> set_size(fill(), fill())
    |> set_padding(16.0)
    |> set_gap(10.0);

  scroll.add(Text::new() |> set_text("Interactions") |> set_text_size(11.0) |> set_text_color(fcText(dark)) |> set_font(gui::medium()));

  for (int i = 0; i < ed.interactionCount; i = i + 1) {
    auto card = Column::new()
      |> set_size(fill(), fit())
      |> set_padding(10.0)
      |> set_gap(5.0)
      |> set_bg(fcField(dark))
      |> set_radius(7.0);

    auto top = Row::new() |> set_size(fill(), fit()) |> set_align(GuiAlign::GuiAlignCenter);
    top.add(Text::new() |> set_text(&ed.interactions[i].trigger[0]) |> set_text_size(9.5) |> set_text_color(fcMutedText(dark)));
    top.add(Spacer::new() |> set_size(fill(), 1px));
    auto del = Box::new()
      |> set_size(18px, 18px)
      |> set_align(GuiAlign::GuiAlignCenter)
      |> set_justify(GuiJustify::GuiJustifyCenter)
      |> set_radius(4.0)
      |> on_click_tag(i) { -> removeInteractionAt(&ed, gui::clickTag()); return; };
    del.add(Icon::new() |> set_icon(std::cui::icons::x()) |> set_text_size(10.5) |> set_text_color(fcMutedText(dark)));
    top.add(del);
    card.add(top);

    card.add(Text::new() |> set_text(&ed.interactions[i].action[0]) |> set_text_size(10.5) |> set_text_color(fcText(dark)) |> set_font(gui::medium()));

    auto animRow = Row::new() |> set_size(fill(), 22px) |> set_align(GuiAlign::GuiAlignCenter) |> set_gap(6.0);
    animRow.add(Text::new() |> set_text(&ed.interactions[i].animation[0]) |> set_text_size(9.0) |> set_text_color(fcSecondaryText(dark)));
    animRow.add(Spacer::new() |> set_size(fill(), 1px));
    animRow.add(Text::new() |> set_text("300 ms") |> set_text_size(9.0) |> set_text_color(fcSecondaryText(dark)));
    card.add(animRow);

    scroll.add(card);
  }

  auto addBtn = Box::new()
    |> set_size(fill(), 30px)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_border(1.0, fcBorder(dark))
    |> set_hover_bg(fcField(dark))
    |> set_radius(6.0)
    |> on_click() { -> addDefaultInteraction(&ed); return; };
  addBtn.add(Text::new() |> set_text("+ Add interaction") |> set_text_size(10.0) |> set_text_color(fcSecondaryText(dark)));
  scroll.add(addBtn);

  scroll.add(Divider::new() |> set_size(fill(), 1px) |> set_bg(fcDivider(dark)));
  scroll.add(Text::new() |> set_text("Flow starting points") |> set_text_size(10.5) |> set_text_color(fcText(dark)) |> set_font(gui::medium()));
  scroll.add(Text::new()
    |> set_text("Present from the current frame to preview navigation and interactive hotspots.")
    |> set_text_size(9.5)
    |> set_text_color(fcMutedText(dark))
    |> set_text_wrap(true)
    |> set_width(fill()));

  auto presentBtn = Box::new()
    |> set_size(fill(), 32px)
    |> set_bg(fcGreen())
    |> set_radius(6.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> on_click() { -> ed.presentMode = true; return; };
  presentBtn.add(Text::new() |> set_text("Present") |> set_text_size(10.5) |> set_text_color(fcNavy()) |> set_font(gui::medium()));
  scroll.add(presentBtn);

  return scroll;
}

Widget* buildDevBody(bool dark) {
  auto scroll = Scroll::new()
    |> set_id("fc-dev-scroll")
    |> set_size(fill(), fill())
    |> set_padding(16.0)
    |> set_gap(10.0);

  bool hasSel = ed.selected >= 0 && ed.selected < ed.count;
  const char* selTitle = if (hasSel) &ed.nodes[ed.selected].name[0] else &ed.stageName[0];

  auto badge = Row::new()
    |> set_size(fill(), 26px)
    |> set_padding_xy(8.0, 0.0)
    |> set_gap(6.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_bg(fcGreenSoft(dark))
    |> set_radius(6.0);
  badge.add(Icon::new() |> set_icon(std::cui::icons::code()) |> set_text_size(12.0) |> set_text_color(fcGreenDark()));
  badge.add(Text::new() |> set_text("Dev Mode Spec") |> set_text_size(10.5) |> set_text_color(fcGreenDark()) |> set_font(gui::medium()));
  scroll.add(badge);

  scroll.add(Text::new() |> set_text(selTitle) |> set_text_size(12.0) |> set_text_color(fcText(dark)) |> set_font(gui::medium()));

  auto specCard = Column::new()
    |> set_size(fill(), fit())
    |> set_padding(10.0)
    |> set_gap(6.0)
    |> set_bg(fcField(dark))
    |> set_radius(7.0);
  specCard.add(Text::new() |> set_text("Dimensions") |> set_text_size(9.5) |> set_text_color(fcMutedText(dark)));
  specCard.add(Text::new() |> set_text(&ed.dimLabel[0]) |> set_text_size(11.0) |> set_text_color(fcText(dark)) |> set_font(gui::mono()));
  specCard.add(Text::new() |> set_text("Fill Hex") |> set_text_size(9.5) |> set_text_color(fcMutedText(dark)));
  specCard.add(Text::new() |> set_text(&ed.hexLabel[0]) |> set_text_size(11.0) |> set_text_color(fcText(dark)) |> set_font(gui::mono()));
  scroll.add(specCard);

  scroll.add(Text::new() |> set_text("Glang std.gui Snippet") |> set_text_size(10.5) |> set_text_color(fcText(dark)) |> set_font(gui::medium()));
  auto codeCard = Column::new()
    |> set_size(fill(), fit())
    |> set_padding(10.0)
    |> set_gap(3.0)
    |> set_bg(fcNavy())
    |> set_radius(7.0);
  codeCard.add(Text::new() |> set_text("auto node = Box::new()") |> set_text_size(9.5) |> set_text_color(fcChartMint()) |> set_font(gui::mono()));
  codeCard.add(Text::new() |> set_text("  |> set_size(fill(), fit())") |> set_text_size(9.5) |> set_text_color(fcWhite()) |> set_font(gui::mono()));
  codeCard.add(Text::new() |> set_text("  |> set_bg(fcCard(dark))") |> set_text_size(9.5) |> set_text_color(fcWhite()) |> set_font(gui::mono()));
  codeCard.add(Text::new() |> set_text("  |> set_radius(9.0);") |> set_text_size(9.5) |> set_text_color(fcWhite()) |> set_font(gui::mono()));
  scroll.add(codeCard);

  auto copyBtn = Box::new()
    |> set_size(fill(), 30px)
    |> set_bg(fcGreen())
    |> set_radius(6.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> on_click() { -> gui::toast("Code copied", "Glang std.gui layout snippet ready."); return; };
  copyBtn.add(Text::new() |> set_text("Copy Glang Spec") |> set_text_size(10.0) |> set_text_color(fcNavy()) |> set_font(gui::medium()));
  scroll.add(copyBtn);

  return scroll;
}

Widget* buildRightPanel() {
  bool dark = ed.darkTheme;
  auto panel = Column::new()
    |> set_size(300px, fill())
    |> set_bg(fcCard(dark))
    |> set_border(1.0, fcDivider(dark));

  // Header: avatar, Present button, Share CTA
  auto head = Row::new()
    |> set_size(fill(), 52px)
    |> set_padding_xy(14.0, 0.0)
    |> set_gap(8.0)
    |> set_align(GuiAlign::GuiAlignCenter);

  auto avatar = Box::new()
    |> set_size(26px, 26px)
    |> set_bg(fcNavy())
    |> set_radius(13.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter);
  avatar.add(Text::new() |> set_text("MC") |> set_text_size(7.5) |> set_text_color(fcWhite()) |> set_font(gui::medium()));
  head.add(avatar);
  head.add(Icon::new() |> set_icon(std::cui::icons::chevronDown()) |> set_text_size(11.0) |> set_text_color(fcSecondaryText(dark)));
  head.add(Spacer::new() |> set_size(fill(), 1px));

  auto playBtn = Box::new()
    |> set_id("fc-present-btn")
    |> set_size(28px, 28px)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_radius(6.0)
    |> set_hover_bg(fcField(dark))
    |> set_tooltip("Present prototype")
    |> on_click() { -> ed.presentMode = !ed.presentMode; return; };
  playBtn.add(Icon::new() |> set_icon(std::cui::icons::play()) |> set_text_size(14.0) |> set_text_color(fcText(dark)));
  head.add(playBtn);

  auto shareBtn = Box::new()
    |> set_size(74px, 32px)
    |> set_bg(fcGreen())
    |> set_radius(8.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> on_click() { -> gui::toast("Share link copied", "Anyone with the link can view this file."); return; };
  shareBtn.add(Text::new() |> set_text("Share") |> set_text_size(11.0) |> set_text_color(fcNavy()) |> set_font(gui::medium()));
  head.add(shareBtn);
  panel.add(head);

  // Design / Prototype tabs + interactive Zoom control
  auto tabs = Row::new()
    |> set_size(fill(), 42px)
    |> set_padding_xy(14.0, 0.0)
    |> set_gap(4.0)
    |> set_align(GuiAlign::GuiAlignCenter);

  bool designActive = ed.rightTab == (RightTab::TabDesign as int);
  auto dTab = Box::new()
    |> set_id("fc-design-tab")
    |> set_size(68px, 27px)
    |> set_bg(pickColor(designActive, fcCard(dark), gui::clear()))
    |> set_border(pickFloat(designActive, 1.0, 0.0), fcBorder(dark))
    |> set_radius(6.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> on_click() { -> ed.rightTab = RightTab::TabDesign as int; if (ed.bottomMode == 2) { ed.bottomMode = 0; } return; };
  dTab.add(Text::new() |> set_text("Design") |> set_text_size(10.5) |> set_text_color(pickColor(designActive, fcText(dark), fcMutedText(dark))));
  tabs.add(dTab);

  auto pTab = Box::new()
    |> set_id("fc-proto-tab")
    |> set_size(76px, 27px)
    |> set_bg(pickColor(!designActive, fcCard(dark), gui::clear()))
    |> set_border(pickFloat(!designActive, 1.0, 0.0), fcBorder(dark))
    |> set_radius(6.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> on_click() { -> ed.rightTab = RightTab::TabPrototype as int; if (ed.bottomMode == 2) { ed.bottomMode = 0; } return; };
  pTab.add(Text::new() |> set_text("Prototype") |> set_text_size(10.5) |> set_text_color(pickColor(!designActive, fcText(dark), fcMutedText(dark))));
  tabs.add(pTab);

  tabs.add(Spacer::new() |> set_size(fill(), 1px));

  auto zoomOutBtn = Box::new()
    |> set_size(20px, 22px)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_hover_bg(fcField(dark))
    |> set_radius(4.0)
    |> set_tooltip("Zoom out (-)")
    |> on_click() { -> stepZoom(&ed, -1); return; };
  zoomOutBtn.add(Icon::new() |> set_icon(std::cui::icons::minus()) |> set_text_size(10.5) |> set_text_color(fcSecondaryText(dark)));
  tabs.add(zoomOutBtn);

  auto zoomResetBtn = Box::new()
    |> set_size(fit(), 22px)
    |> set_padding_xy(4.0, 0.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_hover_bg(fcField(dark))
    |> set_radius(4.0)
    |> set_tooltip("Reset zoom (0)")
    |> on_click() { -> stepZoom(&ed, 0); return; };
  zoomResetBtn.add(Text::new() |> set_text(&ed.zoomLabel[0]) |> set_text_size(10.0) |> set_text_color(fcSecondaryText(dark)));
  tabs.add(zoomResetBtn);

  auto zoomInBtn = Box::new()
    |> set_size(20px, 22px)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_hover_bg(fcField(dark))
    |> set_radius(4.0)
    |> set_tooltip("Zoom in (+)")
    |> on_click() { -> stepZoom(&ed, 1); return; };
  zoomInBtn.add(Icon::new() |> set_icon(std::cui::icons::plus()) |> set_text_size(10.5) |> set_text_color(fcSecondaryText(dark)));
  tabs.add(zoomInBtn);

  panel.add(tabs);
  panel.add(Divider::new() |> set_size(fill(), 1px) |> set_bg(fcDivider(dark)));

  if (ed.bottomMode == (BottomMode::ModeDev as int)) {
    panel.add(buildDevBody(dark));
  } else if (ed.rightTab == (RightTab::TabDesign as int)) {
    panel.add(buildDesignBody(dark));
  } else {
    panel.add(buildPrototypeBody(dark));
  }

  return panel;
}
