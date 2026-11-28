// FigCraft Right Inspector Panel: Clean ArtCraft FigCraft UI3 Design / Prototype / Dev Inspectors & Color Tool.
// Zero presets: exposes full Font, Blend, Constraint, Stroke, Shape, and unlinked Effects options.

import std.gui;
import std.pipe;
import std.cui;
import std.string;
import examples.cui.figcraft.palette;
import examples.cui.figcraft.model;
import examples.cui.figcraft.geometry;
import examples.cui.figcraft.actions;

char[12] shapeSidesLabel;
bool inspectorOptsReady = false;

char*[8] blendModeOpts;
char*[4] constraintHOpts;
char*[4] constraintVOpts;
char*[8] fontFamilyOpts;
char*[7] fontWeightOpts;
char*[3] textDecorOpts;
char*[4] textCaseOpts;
char*[3] strokeAlignOpts;
char*[2] strokeStyleOpts;
char*[3] arrowCapOpts;
char*[4] chartSeriesOpts;

void initInspectorOptions() {
  if (inspectorOptsReady) { return; }
  inspectorOptsReady = true;

  blendModeOpts[0] = "Normal";
  blendModeOpts[1] = "Darken";
  blendModeOpts[2] = "Multiply";
  blendModeOpts[3] = "Color Burn";
  blendModeOpts[4] = "Lighten";
  blendModeOpts[5] = "Screen";
  blendModeOpts[6] = "Overlay";
  blendModeOpts[7] = "Soft Light";

  constraintHOpts[0] = "Left";
  constraintHOpts[1] = "Center";
  constraintHOpts[2] = "Right";
  constraintHOpts[3] = "Scale";

  constraintVOpts[0] = "Top";
  constraintVOpts[1] = "Middle";
  constraintVOpts[2] = "Bottom";
  constraintVOpts[3] = "Scale";

  fontFamilyOpts[0] = "Inter Sans";
  fontFamilyOpts[1] = "Inter Medium";
  fontFamilyOpts[2] = "Grotesk Display";
  fontFamilyOpts[3] = "JetBrains Mono";
  fontFamilyOpts[4] = "Editorial Serif";
  fontFamilyOpts[5] = "Condensed UI";
  fontFamilyOpts[6] = "Geometric Sans";
  fontFamilyOpts[7] = "Rounded UI";

  fontWeightOpts[0] = "Thin (200)";
  fontWeightOpts[1] = "Light (300)";
  fontWeightOpts[2] = "Regular (400)";
  fontWeightOpts[3] = "Medium (500)";
  fontWeightOpts[4] = "SemiBold (600)";
  fontWeightOpts[5] = "Bold (700)";
  fontWeightOpts[6] = "Black (900)";

  textDecorOpts[0] = "None";
  textDecorOpts[1] = "Underline";
  textDecorOpts[2] = "Strikethrough";

  textCaseOpts[0] = "Original";
  textCaseOpts[1] = "UPPERCASE";
  textCaseOpts[2] = "lowercase";
  textCaseOpts[3] = "Title Case";

  strokeAlignOpts[0] = "Inside";
  strokeAlignOpts[1] = "Center";
  strokeAlignOpts[2] = "Outside";

  strokeStyleOpts[0] = "Solid";
  strokeStyleOpts[1] = "Dashed";

  arrowCapOpts[0] = "None";
  arrowCapOpts[1] = "Arrowhead";
  arrowCapOpts[2] = "Dot";

  chartSeriesOpts[0] = "Baseline";
  chartSeriesOpts[1] = "Growth";
  chartSeriesOpts[2] = "Conservative";
  chartSeriesOpts[3] = "Volatile";
}

Color paletteSwatchAt(int k) {
  if (k == 0) { return gui::rgb(255, 255, 255); }
  if (k == 1) { return gui::rgb(245, 248, 246); }
  if (k == 2) { return gui::rgb(226, 232, 240); }
  if (k == 3) { return gui::rgb(148, 163, 184); }
  if (k == 4) { return gui::rgb(71, 85, 105); }
  if (k == 5) { return gui::rgb(30, 41, 59); }
  if (k == 6) { return gui::rgb(15, 23, 38); }
  if (k == 7) { return gui::rgb(0, 0, 0); }
  if (k == 8) { return gui::rgb(209, 250, 229); }
  if (k == 9) { return gui::rgb(110, 231, 183); }
  if (k == 10) { return gui::rgb(10, 207, 131); }
  if (k == 11) { return gui::rgb(5, 150, 105); }
  if (k == 12) { return gui::rgb(59, 130, 246); }
  if (k == 13) { return gui::rgb(14, 165, 233); }
  if (k == 14) { return gui::rgb(99, 102, 241); }
  if (k == 15) { return gui::rgb(139, 92, 246); }
  if (k == 16) { return gui::rgb(244, 63, 94); }
  if (k == 17) { return gui::rgb(239, 68, 68); }
  if (k == 18) { return gui::rgb(249, 115, 22); }
  if (k == 19) { return gui::rgb(245, 158, 11); }
  if (k == 20) { return gui::rgba(15, 23, 38, 48); }
  if (k == 21) { return gui::rgba(15, 23, 38, 96); }
  if (k == 22) { return gui::rgba(10, 207, 131, 128); }
  return gui::rgba(59, 130, 246, 128);
}

void handleInspectorChipAction(int code) {
  int grp = code / 16;
  int val = code % 16;
  if (grp == 1) {
    setNodeTextAlign(&ed, val);
  } else if (grp == 2) {
    setNodeTextVAlign(&ed, val);
  } else if (grp == 3) {
    toggleNodeItalic(&ed);
  } else if (grp == 5) {
    if (ed.selected >= 0 && ed.selected < ed.count) {
      int delta = if (val == 0) -1 else 1;
      int next = ed.nodes[ed.selected].shapeSides + delta;
      if (next < 3) { next = 3; }
      if (next > 12) { next = 12; }
      ed.nodes[ed.selected].shapeSides = next;
      markDirty(&ed);
    }
  } else if (grp == 9) {
    if (ed.selected >= 0 && ed.selected < ed.count) {
      if (val == 0) { toggleDropShadow(&ed, true); }
      else if (val == 1) { toggleInnerShadow(&ed, true); }
      else if (val == 2) { toggleLayerBlur(&ed, true); }
      else if (val == 3) { toggleBgBlur(&ed, true); }
      ed.showAddEffectMenu = false;
    }
  } else if (grp == 11) {
    if (val == 0) { ed.constrainRatio = !ed.constrainRatio; }
    else if (val == 2) { toggleIndependentCorners(&ed); }
  } else if (grp == 17) {
    loadPickerFromTarget(&ed, val);
  } else if (grp == 18) {
    if (ed.selected >= 0 && ed.selected < ed.count) {
      reparentNode(&ed, ed.selected, -1);
    }
  }
}

// ---------------------------------------------------------------------------
// Shared Clean UI Helpers
// ---------------------------------------------------------------------------

Widget* inspIconBtn(const char* wid, const char* glyph, const char* tip, bool active, int actionTag, bool dark) {
  auto btn = BBox::new()
    |> set_size(26px, 26px)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_bg(pickColor(active, fcGreenSoft(dark), gui::clear()))
    |> set_hover_bg(fcField(dark))
    |> set_radius(5.0)
    |> set_tooltip(tip)
    |> on_click_tag(actionTag) {
      -> int a = gui::clickTag();
         if (a == 0) {
           if (ed.selected >= 0 && ed.selected < ed.count) {
             ed.nodes[ed.selected].rotation = 0.0;
             markDirty(&ed);
             refreshInspectorLabels(&ed);
           }
         } else if (a == 1) { duplicateSelectedNode(&ed); }
         else if (a == 2) { stepZoom(&ed, 0); }
         else if (a == 5) {
           if (ed.selected >= 0 && ed.selected < ed.count) {
             ed.nodes[ed.selected].visible = !ed.nodes[ed.selected].visible;
             markDirty(&ed);
           }
         } else if (a == 6) {
           if (ed.selected >= 0 && ed.selected < ed.count) {
             ed.nodes[ed.selected].locked = !ed.nodes[ed.selected].locked;
             markDirty(&ed);
           }
         } else if (a == 7) { deleteSelectedNode(&ed); }
         else if (a == 8) { moveLayerOrder(&ed, ed.selected, 1); }
         else if (a == 9) { moveLayerOrder(&ed, ed.selected, -1); }
         return;
    };
  if (wid != nullptr) { btn.set_id(wid); }
  btn.add(Icon::new()
    |> set_icon(glyph)
    |> set_text_size(12.5)
    |> set_text_color(pickColor(active, fcGreenDark(), fcSecondaryText(dark))));
  return btn;
}

Widget* alignBtn(const char* glyph, int mode, const char* tip, bool dark) {
  auto btn = BBox::new()
    |> set_size(fill(), 26px)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_bg(fcField(dark))
    |> set_hover_bg(fcGreenSoft(dark))
    |> set_radius(5.0)
    |> set_tooltip(tip)
    |> on_click_tag(mode) { -> alignSelectedNode(&ed, gui::clickTag()); return; };
  btn.add(Icon::new() |> set_icon(glyph) |> set_text_size(12.0) |> set_text_color(fcSecondaryText(dark)));
  return btn;
}

bool isAccordionOpen(int idx) {
  if (idx == 0) { return ed.accPositionOpen; }
  if (idx == 1) { return ed.accLayoutOpen; }
  if (idx == 2) { return ed.accAppearanceOpen; }
  if (idx == 3) { return ed.accTypographyOpen; }
  if (idx == 4) { return ed.accShapeOpen; }
  if (idx == 5) { return ed.accFillOpen; }
  if (idx == 6) { return ed.accStrokeOpen; }
  return ed.accEffectsOpen;
}

void toggleInspectorAccordion(int idx) {
  if (idx == 0) { ed.accPositionOpen = !ed.accPositionOpen; }
  else if (idx == 1) { ed.accLayoutOpen = !ed.accLayoutOpen; }
  else if (idx == 2) { ed.accAppearanceOpen = !ed.accAppearanceOpen; }
  else if (idx == 3) { ed.accTypographyOpen = !ed.accTypographyOpen; }
  else if (idx == 4) { ed.accShapeOpen = !ed.accShapeOpen; }
  else if (idx == 5) { ed.accFillOpen = !ed.accFillOpen; }
  else if (idx == 6) { ed.accStrokeOpen = !ed.accStrokeOpen; }
  else if (idx == 7) { ed.accEffectsOpen = !ed.accEffectsOpen; }
}

Widget* inspAccordionHeader(const char* title, int accIdx, bool dark) {
  bool open = isAccordionOpen(accIdx);
  auto row = Row::new()
    |> set_size(fill(), 26px)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_gap(4.0);

  auto toggleBtn = Row::new()
    |> set_size(fill(), 26px)
    |> set_padding_xy(2.0, 0.0)
    |> set_gap(6.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_hover_bg(fcField(dark))
    |> set_radius(5.0)
    |> set_tooltip(pickText(open, "Collapse section", "Expand section"))
    |> on_click_tag(accIdx) { -> toggleInspectorAccordion(gui::clickTag()); return; };

  toggleBtn.add(Icon::new()
    |> set_icon(pickText(open, std::cui::icons::chevronDown(), std::cui::icons::chevronRight()))
    |> set_text_size(10.5)
    |> set_text_color(fcMutedText(dark)));
  toggleBtn.add(Text::new()
    |> set_text(title)
    |> set_text_size(11.0)
    |> set_text_color(fcText(dark))
    |> set_font(gui::medium()));
  toggleBtn.add(Spacer::new() |> set_size(fill(), 1px));

  row.add(toggleBtn);
  return row;
}

Widget* inspSubLabel(const char* text, bool dark) {
  return Text::new()
    |> set_text(text)
    |> set_text_size(9.5)
    |> set_text_color(fcMutedText(dark));
}

Widget* segChip(const char* label, bool active, int groupTag, int valueTag, bool dark) {
  int code = groupTag * 16 + valueTag;
  auto chip = BBox::new()
    |> set_size(fill(), 26px)
    |> set_bg(pickColor(active, fcGreenSoft(dark), fcField(dark)))
    |> set_border(pickFloat(active, 1.0, 0.0), fcGreen())
    |> set_hover_bg(fcGreenSoft(dark))
    |> set_radius(5.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> on_click_tag(code) { -> handleInspectorChipAction(gui::clickTag()); return; };
  chip.add(Text::new()
    |> set_text(label)
    |> set_text_size(10.0)
    |> set_text_color(pickColor(active, fcGreenDark(), fcSecondaryText(dark)))
    |> set_font(if (active) gui::medium() else gui::body()));
  return chip;
}

Widget* miniActionPill(const char* label, bool active, const char* tip, int groupTag, int valueTag, bool dark) {
  int code = groupTag * 16 + valueTag;
  auto pill = BBox::new()
    |> set_size(fit(), 22px)
    |> set_padding_xy(8.0, 0.0)
    |> set_bg(pickColor(active, fcGreenSoft(dark), fcField(dark)))
    |> set_border(1.0, pickColor(active, fcGreen(), fcBorder(dark)))
    |> set_hover_bg(fcGreenSoft(dark))
    |> set_radius(5.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_tooltip(tip)
    |> on_click_tag(code) { -> handleInspectorChipAction(gui::clickTag()); return; };
  pill.add(Text::new()
    |> set_text(label)
    |> set_text_size(9.5)
    |> set_text_color(pickColor(active, fcGreenDark(), fcSecondaryText(dark)))
    |> set_font(gui::medium()));
  return pill;
}

Widget* colorTriggerRow(Color swatch, const char* hexText, const char* subLabel, int target, bool enabled, bool dark) {
  auto row = Row::new()
    |> set_size(fill(), 30px)
    |> set_padding_xy(8.0, 0.0)
    |> set_gap(8.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_bg(fcField(dark))
    |> set_hover_bg(fcGreenSoft(dark))
    |> set_border(1.0, pickColor(ed.showColorPicker && ed.colorTarget == target, fcGreen(), fcBorder(dark)))
    |> set_radius(6.0)
    |> set_tooltip("Open Color Tool")
    |> on_click_tag(target) { -> openColorPicker(&ed, gui::clickTag()); return; };

  Color dotBg = if (enabled) swatch else gui::rgba(148, 163, 184, 60);
  row.add(BBox::new() |> set_size(16px, 16px) |> set_bg(dotBg) |> set_border(1.0, fcBorder(dark)) |> set_radius(4.0));
  row.add(Text::new() |> set_text(hexText) |> set_text_size(10.5) |> set_text_color(fcText(dark)) |> set_font(gui::mono()));
  row.add(Spacer::new() |> set_size(fill(), 1px));
  row.add(Text::new() |> set_text(subLabel) |> set_text_size(9.5) |> set_text_color(fcMutedText(dark)));
  return row;
}

// ---------------------------------------------------------------------------
// Node-Specific Sections: Full Typography, Geometry, Fill, Stroke, Effects
// ---------------------------------------------------------------------------

void appendTypographySection(Widget* scroll, DesignNode* n, bool dark) {
  scroll.add(Divider::new() |> set_size(fill(), 1px) |> set_bg(fcDivider(dark)));
  scroll.add(inspAccordionHeader("Typography", 3, dark));
  if (!ed.accTypographyOpen) { return; }

  if (n.kind == (NodeKind::NodeComment as int)) {
    scroll.add(Input::new()
      |> set_id("fc-sel-body")
      |> set_placeholder("Comment note")
      |> set_buffer(&n.body[0], 128)
      |> set_size(fill(), 28px));
  } else {
    scroll.add(Input::new()
      |> set_id("fc-sel-body")
      |> set_placeholder("Text content")
      |> set_buffer(&n.name[0], 64)
      |> set_size(fill(), 28px));
  }

  // Full Font Family Select (searchable, 8 families)
  scroll.add(Select::new()
    |> set_id("fc-font-fam")
    |> set_label("Family")
    |> set_options(&fontFamilyOpts[0], 8, &n.font)
    |> set_searchable(true)
    |> set_width(fill()));

  // Weight Select + Italic Toggle
  auto wtRow = Row::new() |> set_size(fill(), fit()) |> set_gap(8.0) |> set_align(GuiAlign::GuiAlignEnd);
  wtRow.add(Select::new()
    |> set_id("fc-font-wt")
    |> set_label("Weight")
    |> set_options(&fontWeightOpts[0], 7, &n.fontWeight)
    |> set_width(204px));
  wtRow.add(BBox::new()
    |> set_id("fc-font-italic")
    |> set_size(fill(), 30px)
    |> set_bg(pickColor(n.fontItalic, fcGreenSoft(dark), fcField(dark)))
    |> set_border(1.0, pickColor(n.fontItalic, fcGreen(), fcBorder(dark)))
    |> set_hover_bg(fcGreenSoft(dark))
    |> set_radius(6.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_tooltip("Toggle Italic")
    |> on_click_tag(3 * 16 + 0) { -> handleInspectorChipAction(gui::clickTag()); return; }
    |> add(Text::new()
      |> set_text("I")
      |> set_text_size(12.0)
      |> set_text_color(pickColor(n.fontItalic, fcGreenDark(), fcSecondaryText(dark)))
      |> set_font(gui::display())));
  scroll.add(wtRow);

  // Clean 2x2 Metrics Grid (Size, Line Height, Letter Spacing, Paragraph Spacing)
  auto mRow1 = Row::new() |> set_size(fill(), fit()) |> set_gap(8.0);
  mRow1.add(Scrub::new() |> set_id("fc-typ-sz") |> set_text("Size") |> set_value(&n.textSize, 6.0, 128.0) |> set_step(0.5) |> set_width(144px));
  mRow1.add(Scrub::new() |> set_id("fc-typ-lh") |> set_text("Line H") |> set_value(&n.lineHeight, 0.8, 3.0) |> set_step(0.05) |> set_width(144px));
  scroll.add(mRow1);

  auto mRow2 = Row::new() |> set_size(fill(), fit()) |> set_gap(8.0);
  mRow2.add(Scrub::new() |> set_id("fc-typ-ls") |> set_text("Track") |> set_value(&n.letterSpacing, -4.0, 24.0) |> set_step(0.25) |> set_width(144px));
  mRow2.add(Scrub::new() |> set_id("fc-typ-ps") |> set_text("Para") |> set_value(&n.paragraphSpacing, 0.0, 64.0) |> set_step(1.0) |> set_width(144px));
  scroll.add(mRow2);

  // Clean Alignment Controls: H-Align + V-Align
  auto alignGrid = Row::new() |> set_size(fill(), 26px) |> set_gap(6.0);
  auto hBox = Row::new() |> set_size(144px, 26px) |> set_gap(4.0);
  hBox.add(segChip("L", n.textAlign == 0, 1, 0, dark));
  hBox.add(segChip("C", n.textAlign == 1, 1, 1, dark));
  hBox.add(segChip("R", n.textAlign == 2, 1, 2, dark));
  alignGrid.add(hBox);

  auto vBox = Row::new() |> set_size(144px, 26px) |> set_gap(4.0);
  vBox.add(segChip("T", n.textVAlign == 0, 2, 0, dark));
  vBox.add(segChip("M", n.textVAlign == 1, 2, 1, dark));
  vBox.add(segChip("B", n.textVAlign == 2, 2, 2, dark));
  alignGrid.add(vBox);
  scroll.add(alignGrid);

  // Decoration & Case Selects (full options including Title Case)
  auto styleRow = Row::new() |> set_size(fill(), fit()) |> set_gap(8.0);
  styleRow.add(Select::new()
    |> set_id("fc-typ-dec")
    |> set_label("Decoration")
    |> set_options(&textDecorOpts[0], 3, &n.textDecoration)
    |> set_width(144px));
  styleRow.add(Select::new()
    |> set_id("fc-typ-case")
    |> set_label("Case")
    |> set_options(&textCaseOpts[0], 4, &n.textCase)
    |> set_width(144px));
  scroll.add(styleRow);
}

void appendShapeSpecificSection(Widget* scroll, DesignNode* n, bool dark) {
  if (nodeIsPolyOrStar(n.kind)) {
    scroll.add(Divider::new() |> set_size(fill(), 1px) |> set_bg(fcDivider(dark)));
    const char* title = if (n.kind == (NodeKind::NodeStar as int)) "Star Geometry" else "Polygon Geometry";
    scroll.add(inspAccordionHeader(title, 4, dark));
    if (!ed.accShapeOpen) { return; }

    auto sideRow = Row::new() |> set_size(fill(), 28px) |> set_gap(6.0) |> set_align(GuiAlign::GuiAlignCenter);
    sideRow.add(inspSubLabel(if (n.kind == (NodeKind::NodeStar as int)) "Points" else "Sides", dark));
    sideRow.add(Spacer::new() |> set_size(fill(), 1px));
    sideRow.add(miniActionPill("-", false, "Fewer sides", 5, 0, dark));
    std::string::format_int(&shapeSidesLabel[0], n.shapeSides, 12);
    sideRow.add(Text::new() |> set_text(&shapeSidesLabel[0]) |> set_text_size(10.5) |> set_text_color(fcText(dark)) |> set_font(gui::mono()));
    sideRow.add(miniActionPill("+", false, "More sides", 5, 1, dark));
    scroll.add(sideRow);

    if (n.kind == (NodeKind::NodeStar as int)) {
      scroll.add(Scrub::new() |> set_id("fc-shp-ratio") |> set_text("Inner Ratio") |> set_value(&n.shapeRatio, 0.18, 0.85) |> set_step(0.02) |> set_width(fill()));
    }
  } else if (n.kind == (NodeKind::NodeEllipse as int)) {
    scroll.add(Divider::new() |> set_size(fill(), 1px) |> set_bg(fcDivider(dark)));
    scroll.add(inspAccordionHeader("Ellipse Geometry", 4, dark));
    if (!ed.accShapeOpen) { return; }
    scroll.add(Scrub::new() |> set_id("fc-shp-hole") |> set_text("Ring Hole") |> set_value(&n.shapeRatio, 0.0, 0.85) |> set_step(0.02) |> set_width(fill()));
  } else if (nodeIsLineOrArrow(n.kind)) {
    scroll.add(Divider::new() |> set_size(fill(), 1px) |> set_bg(fcDivider(dark)));
    scroll.add(inspAccordionHeader("Endpoints", 4, dark));
    if (!ed.accShapeOpen) { return; }

    auto capRow = Row::new() |> set_size(fill(), fit()) |> set_gap(8.0);
    capRow.add(Select::new()
      |> set_id("fc-cap-start")
      |> set_label("Start Cap")
      |> set_options(&arrowCapOpts[0], 3, &n.arrowStartCap)
      |> set_width(144px));
    capRow.add(Select::new()
      |> set_id("fc-cap-end")
      |> set_label("End Cap")
      |> set_options(&arrowCapOpts[0], 3, &n.arrowEndCap)
      |> set_width(144px));
    scroll.add(capRow);
    scroll.add(Scrub::new() |> set_id("fc-shp-head") |> set_text("Cap Scale") |> set_value(&n.shapeRatio, 0.2, 0.9) |> set_step(0.02) |> set_width(fill()));
  } else if (nodeIsChart(n.kind)) {
    scroll.add(Divider::new() |> set_size(fill(), 1px) |> set_bg(fcDivider(dark)));
    scroll.add(inspAccordionHeader("Chart Data", 4, dark));
    if (!ed.accShapeOpen) { return; }
    auto chartCfg = Row::new() |> set_size(fill(), fit()) |> set_gap(8.0) |> set_align(GuiAlign::GuiAlignEnd);
    chartCfg.add(Select::new()
      |> set_id("fc-chart-series")
      |> set_label("Series")
      |> set_options(&chartSeriesOpts[0], 4, &n.font)
      |> set_width(148px));
    chartCfg.add(Scrub::new()
      |> set_id("fc-chart-amp")
      |> set_text("Scale")
      |> set_value(&n.shapeRatio, 0.0, 1.0)
      |> set_step(0.05)
      |> set_width(140px));
    scroll.add(chartCfg);
  }
}

Widget* addEffectRow(const char* label, int effKind, bool dark) {
  auto row = Row::new()
    |> set_size(fill(), 28px)
    |> set_padding_xy(8.0, 0.0)
    |> set_gap(8.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_hover_bg(fcGreenSoft(dark))
    |> set_radius(5.0)
    |> on_click_tag(9 * 16 + effKind) { -> handleInspectorChipAction(gui::clickTag()); return; };
  row.add(Icon::new() |> set_icon(std::cui::icons::plus()) |> set_text_size(11.0) |> set_text_color(fcGreenDark()));
  row.add(Text::new() |> set_text(label) |> set_text_size(10.5) |> set_text_color(fcText(dark)));
  return row;
}

void appendEffectsSection(Widget* scroll, DesignNode* n, bool dark) {
  scroll.add(Divider::new() |> set_size(fill(), 1px) |> set_bg(fcDivider(dark)));

  auto effHead = inspAccordionHeader("Effects", 7, dark);
  auto addEffBtn = BBox::new()
    |> set_id("fc-eff-add-btn")
    |> set_size(24px, 24px)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_bg(pickColor(ed.showAddEffectMenu, fcGreenSoft(dark), gui::clear()))
    |> set_hover_bg(fcField(dark))
    |> set_radius(5.0)
    |> set_tooltip("Add effect")
    |> on_click() { -> ed.showAddEffectMenu = !ed.showAddEffectMenu; ed.accEffectsOpen = true; return; };
  addEffBtn.add(Icon::new()
    |> set_icon(std::cui::icons::plus())
    |> set_text_size(12.5)
    |> set_text_color(pickColor(ed.showAddEffectMenu, fcGreenDark(), fcSecondaryText(dark))));
  effHead.add(addEffBtn);
  scroll.add(effHead);

  if (!ed.accEffectsOpen) { return; }

  if (ed.showAddEffectMenu) {
    auto addMenu = Column::new()
      |> set_id("fc-eff-add-menu")
      |> set_size(fill(), fit())
      |> set_padding(4.0)
      |> set_gap(2.0)
      |> set_bg(fcField(dark))
      |> set_border(1.0, fcGreenBorder(dark))
      |> set_radius(7.0);
    addMenu.add(addEffectRow("Drop shadow", 0, dark));
    addMenu.add(addEffectRow("Inner shadow", 1, dark));
    addMenu.add(addEffectRow("Layer blur", 2, dark));
    addMenu.add(addEffectRow("Background blur", 3, dark));
    scroll.add(addMenu);
  }

  bool anyEffect = n.dropShadowEnabled || n.innerShadowEnabled || n.layerBlurEnabled || n.bgBlurEnabled;
  if (!anyEffect && !ed.showAddEffectMenu) {
    scroll.add(Text::new()
      |> set_text("Click + to add Drop Shadow, Inner Shadow, Layer Blur, or Background Blur.")
      |> set_text_size(9.5)
      |> set_text_color(fcMutedText(dark))
      |> set_text_wrap(true)
      |> set_width(fill()));
    return;
  }

  // 1. Drop Shadow (unlinked X, Y, Blur, Spread, Color, Alpha%)
  if (n.dropShadowEnabled) {
    auto dropCard = Column::new()
      |> set_size(fill(), fit())
      |> set_padding(8.0)
      |> set_gap(7.0)
      |> set_bg(fcField(dark))
      |> set_border(1.0, fcBorder(dark))
      |> set_radius(7.0);

    auto top = Row::new() |> set_size(fill(), 22px) |> set_align(GuiAlign::GuiAlignCenter) |> set_gap(6.0);
    auto cfgBtn = BBox::new()
      |> set_id("fc-drop-expand")
      |> set_size(22px, 22px)
      |> set_align(GuiAlign::GuiAlignCenter)
      |> set_justify(GuiJustify::GuiJustifyCenter)
      |> set_bg(pickColor(ed.editDropOpen, fcGreenSoft(dark), fcCard(dark)))
      |> set_radius(4.0)
      |> set_tooltip("Effect settings")
      |> on_click() { -> ed.editDropOpen = !ed.editDropOpen; return; };
    cfgBtn.add(Icon::new() |> set_icon(std::cui::icons::sliders()) |> set_text_size(11.0) |> set_text_color(pickColor(ed.editDropOpen, fcGreenDark(), fcSecondaryText(dark))));
    top.add(cfgBtn);

    top.add(Text::new() |> set_text("Drop shadow") |> set_text_size(10.5) |> set_text_color(fcText(dark)) |> set_font(gui::medium()));
    top.add(Spacer::new() |> set_size(fill(), 1px));

    auto eyeDrop = BBox::new()
      |> set_id("fc-drop-vis")
      |> set_size(20px, 20px)
      |> set_align(GuiAlign::GuiAlignCenter)
      |> set_justify(GuiJustify::GuiJustifyCenter)
      |> set_radius(4.0)
      |> set_tooltip("Toggle Drop Shadow visibility")
      |> on_click() { -> toggleDropShadowVisible(&ed); return; };
    eyeDrop.add(Icon::new() |> set_icon(pickText(n.dropShadowVisible, std::cui::icons::eye(), std::cui::icons::eyeOff())) |> set_text_size(11.5) |> set_text_color(fcMutedText(dark)));
    top.add(eyeDrop);

    auto rmDrop = BBox::new()
      |> set_id("fc-drop-rm")
      |> set_size(20px, 20px)
      |> set_align(GuiAlign::GuiAlignCenter)
      |> set_justify(GuiJustify::GuiJustifyCenter)
      |> set_radius(4.0)
      |> set_tooltip("Remove Drop Shadow")
      |> on_click() { -> toggleDropShadow(&ed, false); return; };
    rmDrop.add(Icon::new() |> set_icon(std::cui::icons::minus()) |> set_text_size(11.5) |> set_text_color(fcMutedText(dark)));
    top.add(rmDrop);
    dropCard.add(top);

    if (ed.editDropOpen) {
      auto dxy = Row::new() |> set_size(fill(), fit()) |> set_gap(8.0);
      dxy.add(Scrub::new() |> set_id("fc-drop-x") |> set_text("X") |> set_value(&n.dropShadowX, -64.0, 64.0) |> set_step(1.0) |> set_width(136px));
      dxy.add(Scrub::new() |> set_id("fc-drop-y") |> set_text("Y") |> set_value(&n.dropShadowY, -64.0, 64.0) |> set_step(1.0) |> set_width(136px));
      dropCard.add(dxy);

      auto dbs = Row::new() |> set_size(fill(), fit()) |> set_gap(8.0);
      dbs.add(Scrub::new() |> set_id("fc-drop-blur") |> set_text("Blur") |> set_value(&n.dropShadowBlur, 0.0, 80.0) |> set_step(1.0) |> set_width(136px));
      dbs.add(Scrub::new() |> set_id("fc-drop-spread") |> set_text("Spread") |> set_value(&n.dropShadowSpread, -20.0, 32.0) |> set_step(0.5) |> set_width(136px));
      dropCard.add(dbs);

      dropCard.add(colorTriggerRow(n.dropShadowColor, &ed.dropHexLabel[0], &ed.dropAlphaLabel[0], ColorTarget::ColorTargetDropShadow as int, n.dropShadowVisible, dark));
    }
    scroll.add(dropCard);
  }

  // 2. Inner Shadow (unlinked X, Y, Blur, Spread, Color, Alpha%)
  if (n.innerShadowEnabled) {
    auto innerCard = Column::new()
      |> set_size(fill(), fit())
      |> set_padding(8.0)
      |> set_gap(7.0)
      |> set_bg(fcField(dark))
      |> set_border(1.0, fcBorder(dark))
      |> set_radius(7.0);

    auto top = Row::new() |> set_size(fill(), 22px) |> set_align(GuiAlign::GuiAlignCenter) |> set_gap(6.0);
    auto cfgBtn = BBox::new()
      |> set_id("fc-inner-expand")
      |> set_size(22px, 22px)
      |> set_align(GuiAlign::GuiAlignCenter)
      |> set_justify(GuiJustify::GuiJustifyCenter)
      |> set_bg(pickColor(ed.editInnerOpen, fcGreenSoft(dark), fcCard(dark)))
      |> set_radius(4.0)
      |> set_tooltip("Effect settings")
      |> on_click() { -> ed.editInnerOpen = !ed.editInnerOpen; return; };
    cfgBtn.add(Icon::new() |> set_icon(std::cui::icons::sliders()) |> set_text_size(11.0) |> set_text_color(pickColor(ed.editInnerOpen, fcGreenDark(), fcSecondaryText(dark))));
    top.add(cfgBtn);

    top.add(Text::new() |> set_text("Inner shadow") |> set_text_size(10.5) |> set_text_color(fcText(dark)) |> set_font(gui::medium()));
    top.add(Spacer::new() |> set_size(fill(), 1px));

    auto eyeInner = BBox::new()
      |> set_id("fc-inner-vis")
      |> set_size(20px, 20px)
      |> set_align(GuiAlign::GuiAlignCenter)
      |> set_justify(GuiJustify::GuiJustifyCenter)
      |> set_radius(4.0)
      |> set_tooltip("Toggle Inner Shadow visibility")
      |> on_click() { -> toggleInnerShadowVisible(&ed); return; };
    eyeInner.add(Icon::new() |> set_icon(pickText(n.innerShadowVisible, std::cui::icons::eye(), std::cui::icons::eyeOff())) |> set_text_size(11.5) |> set_text_color(fcMutedText(dark)));
    top.add(eyeInner);

    auto rmInner = BBox::new()
      |> set_id("fc-inner-rm")
      |> set_size(20px, 20px)
      |> set_align(GuiAlign::GuiAlignCenter)
      |> set_justify(GuiJustify::GuiJustifyCenter)
      |> set_radius(4.0)
      |> set_tooltip("Remove Inner Shadow")
      |> on_click() { -> toggleInnerShadow(&ed, false); return; };
    rmInner.add(Icon::new() |> set_icon(std::cui::icons::minus()) |> set_text_size(11.5) |> set_text_color(fcMutedText(dark)));
    top.add(rmInner);
    innerCard.add(top);

    if (ed.editInnerOpen) {
      auto ixy = Row::new() |> set_size(fill(), fit()) |> set_gap(8.0);
      ixy.add(Scrub::new() |> set_id("fc-inner-x") |> set_text("X") |> set_value(&n.innerShadowX, -64.0, 64.0) |> set_step(1.0) |> set_width(136px));
      ixy.add(Scrub::new() |> set_id("fc-inner-y") |> set_text("Y") |> set_value(&n.innerShadowY, -64.0, 64.0) |> set_step(1.0) |> set_width(136px));
      innerCard.add(ixy);

      auto ibs = Row::new() |> set_size(fill(), fit()) |> set_gap(8.0);
      ibs.add(Scrub::new() |> set_id("fc-inner-blur") |> set_text("Blur") |> set_value(&n.innerShadowBlur, 0.0, 80.0) |> set_step(1.0) |> set_width(136px));
      ibs.add(Scrub::new() |> set_id("fc-inner-spread") |> set_text("Spread") |> set_value(&n.innerShadowSpread, -12.0, 24.0) |> set_step(0.5) |> set_width(136px));
      innerCard.add(ibs);

      innerCard.add(colorTriggerRow(n.innerShadowColor, &ed.innerHexLabel[0], &ed.innerAlphaLabel[0], ColorTarget::ColorTargetInnerShadow as int, n.innerShadowVisible, dark));
    }
    scroll.add(innerCard);
  }

  // 3. Layer Blur
  if (n.layerBlurEnabled) {
    auto lbCard = Column::new()
      |> set_size(fill(), fit())
      |> set_padding(8.0)
      |> set_gap(6.0)
      |> set_bg(fcField(dark))
      |> set_border(1.0, fcBorder(dark))
      |> set_radius(7.0);

    auto top = Row::new() |> set_size(fill(), 22px) |> set_align(GuiAlign::GuiAlignCenter) |> set_gap(6.0);
    auto cfgBtn = BBox::new()
      |> set_size(22px, 22px)
      |> set_align(GuiAlign::GuiAlignCenter)
      |> set_justify(GuiJustify::GuiJustifyCenter)
      |> set_bg(pickColor(ed.editLayerBlurOpen, fcGreenSoft(dark), fcCard(dark)))
      |> set_radius(4.0)
      |> on_click() { -> ed.editLayerBlurOpen = !ed.editLayerBlurOpen; return; };
    cfgBtn.add(Icon::new() |> set_icon(std::cui::icons::sliders()) |> set_text_size(11.0) |> set_text_color(pickColor(ed.editLayerBlurOpen, fcGreenDark(), fcSecondaryText(dark))));
    top.add(cfgBtn);

    top.add(Text::new() |> set_text("Layer blur") |> set_text_size(10.5) |> set_text_color(fcText(dark)) |> set_font(gui::medium()));
    top.add(Spacer::new() |> set_size(fill(), 1px));

    auto eyeLb = BBox::new()
      |> set_id("fc-lblur-vis")
      |> set_size(20px, 20px)
      |> set_align(GuiAlign::GuiAlignCenter)
      |> set_justify(GuiJustify::GuiJustifyCenter)
      |> set_radius(4.0)
      |> on_click() { -> toggleLayerBlurVisible(&ed); return; };
    eyeLb.add(Icon::new() |> set_icon(pickText(n.layerBlurVisible, std::cui::icons::eye(), std::cui::icons::eyeOff())) |> set_text_size(11.5) |> set_text_color(fcMutedText(dark)));
    top.add(eyeLb);

    auto rmBlur = BBox::new()
      |> set_id("fc-lblur-rm")
      |> set_size(20px, 20px)
      |> set_align(GuiAlign::GuiAlignCenter)
      |> set_justify(GuiJustify::GuiJustifyCenter)
      |> set_radius(4.0)
      |> on_click() { -> toggleLayerBlur(&ed, false); return; };
    rmBlur.add(Icon::new() |> set_icon(std::cui::icons::minus()) |> set_text_size(11.5) |> set_text_color(fcMutedText(dark)));
    top.add(rmBlur);
    lbCard.add(top);

    if (ed.editLayerBlurOpen) {
      lbCard.add(Scrub::new() |> set_id("fc-layer-blur") |> set_text("Blur") |> set_value(&n.layerBlur, 0.0, 64.0) |> set_step(0.5) |> set_width(fill()));
    }
    scroll.add(lbCard);
  }

  // 4. Background Blur
  if (n.bgBlurEnabled) {
    auto bgCard = Column::new()
      |> set_size(fill(), fit())
      |> set_padding(8.0)
      |> set_gap(7.0)
      |> set_bg(fcField(dark))
      |> set_border(1.0, fcBorder(dark))
      |> set_radius(7.0);

    auto top = Row::new() |> set_size(fill(), 22px) |> set_align(GuiAlign::GuiAlignCenter) |> set_gap(6.0);
    auto cfgBtn = BBox::new()
      |> set_size(22px, 22px)
      |> set_align(GuiAlign::GuiAlignCenter)
      |> set_justify(GuiJustify::GuiJustifyCenter)
      |> set_bg(pickColor(ed.editBgBlurOpen, fcGreenSoft(dark), fcCard(dark)))
      |> set_radius(4.0)
      |> on_click() { -> ed.editBgBlurOpen = !ed.editBgBlurOpen; return; };
    cfgBtn.add(Icon::new() |> set_icon(std::cui::icons::sliders()) |> set_text_size(11.0) |> set_text_color(pickColor(ed.editBgBlurOpen, fcGreenDark(), fcSecondaryText(dark))));
    top.add(cfgBtn);

    top.add(Text::new() |> set_text("Background blur") |> set_text_size(10.5) |> set_text_color(fcText(dark)) |> set_font(gui::medium()));
    top.add(Spacer::new() |> set_size(fill(), 1px));

    auto eyeBg = BBox::new()
      |> set_id("fc-bgblur-vis")
      |> set_size(20px, 20px)
      |> set_align(GuiAlign::GuiAlignCenter)
      |> set_justify(GuiJustify::GuiJustifyCenter)
      |> set_radius(4.0)
      |> on_click() { -> toggleBgBlurVisible(&ed); return; };
    eyeBg.add(Icon::new() |> set_icon(pickText(n.bgBlurVisible, std::cui::icons::eye(), std::cui::icons::eyeOff())) |> set_text_size(11.5) |> set_text_color(fcMutedText(dark)));
    top.add(eyeBg);

    auto rmBg = BBox::new()
      |> set_id("fc-bgblur-rm")
      |> set_size(20px, 20px)
      |> set_align(GuiAlign::GuiAlignCenter)
      |> set_justify(GuiJustify::GuiJustifyCenter)
      |> set_radius(4.0)
      |> on_click() { -> toggleBgBlur(&ed, false); return; };
    rmBg.add(Icon::new() |> set_icon(std::cui::icons::minus()) |> set_text_size(11.5) |> set_text_color(fcMutedText(dark)));
    top.add(rmBg);
    bgCard.add(top);

    if (ed.editBgBlurOpen) {
      bgCard.add(Scrub::new() |> set_id("fc-bg-blur") |> set_text("Blur") |> set_value(&n.bgBlur, 0.0, 64.0) |> set_step(0.5) |> set_width(fill()));
      bgCard.add(colorTriggerRow(n.bgBlurColor, &ed.bgBlurHexLabel[0], &ed.bgBlurAlphaLabel[0], ColorTarget::ColorTargetBgBlur as int, n.bgBlurVisible, dark));
    }
    scroll.add(bgCard);
  }
}

// ---------------------------------------------------------------------------
// Main Design Inspector Body (Clean ArtCraft FigCraft Hierarchy)
// ---------------------------------------------------------------------------

Widget* buildDesignBody(bool dark) {
  initInspectorOptions();

  auto scroll = Scroll::new()
    |> set_id("fc-inspector-scroll")
    |> set_size(fill(), fill())
    |> set_padding(16.0)
    |> set_gap(10.0);

  bool hasSel = ed.selected >= 0 && ed.selected < ed.count;

  // Clean Selection Header: Kind + concise layer controls only
  auto typeRow = Row::new() |> set_size(fill(), 28px) |> set_align(GuiAlign::GuiAlignCenter) |> set_gap(6.0);
  const char* kindGlyph = if (hasSel) nodeGlyph(ed.nodes[ed.selected].kind) else std::cui::icons::grid();
  const char* kindTxt = if (hasSel) nodeKindLabel(ed.nodes[ed.selected].kind) else "Frame";
  typeRow.add(Icon::new() |> set_icon(kindGlyph) |> set_text_size(12.5) |> set_text_color(fcGreenDark()));
  typeRow.add(Text::new() |> set_text(kindTxt) |> set_text_size(12.0) |> set_text_color(fcText(dark)) |> set_font(gui::medium()));
  typeRow.add(Spacer::new() |> set_size(fill(), 1px));

  if (hasSel) {
    typeRow.add(inspIconBtn("fc-hdr-dup", std::cui::icons::copy(), "Duplicate (D)", false, 1, dark));
    typeRow.add(inspIconBtn("fc-hdr-vis", pickText(ed.nodes[ed.selected].visible, std::cui::icons::eye(), std::cui::icons::eyeOff()), "Toggle visibility", !ed.nodes[ed.selected].visible, 5, dark));
    typeRow.add(inspIconBtn("fc-hdr-lock", std::cui::icons::shield(), pickText(ed.nodes[ed.selected].locked, "Unlock", "Lock"), ed.nodes[ed.selected].locked, 6, dark));
    typeRow.add(inspIconBtn("fc-hdr-del", std::cui::icons::trash(), "Delete (Del)", false, 7, dark));
  } else {
    typeRow.add(inspIconBtn("fc-hdr-resetview", std::cui::icons::maximize(), "Reset viewport (0)", false, 2, dark));
  }
  scroll.add(typeRow);

  // Layer / Frame editable name
  if (hasSel) {
    scroll.add(Input::new()
      |> set_id("fc-sel-name")
      |> set_placeholder("Layer name")
      |> set_buffer(&ed.nodes[ed.selected].name[0], 64)
      |> set_size(fill(), 28px));

    int pIdx = findNodeIndexById(&ed, ed.nodes[ed.selected].parentId);
    if (pIdx >= 0) {
      auto parentRow = Row::new()
        |> set_size(fill(), 26px)
        |> set_padding_xy(8.0, 0.0)
        |> set_gap(6.0)
        |> set_align(GuiAlign::GuiAlignCenter)
        |> set_bg(fcGreenSoft(dark))
        |> set_radius(6.0);
      parentRow.add(Text::new() |> set_text("Inside") |> set_text_size(9.5) |> set_text_color(fcGreenDark()));
      parentRow.add(Text::new() |> set_text(&ed.nodes[pIdx].name[0]) |> set_text_size(10.0) |> set_text_color(fcText(dark)) |> set_font(gui::medium()));
      parentRow.add(Spacer::new() |> set_size(fill(), 1px));
      parentRow.add(miniActionPill("Detach", false, "Detach from parent container", 18, 0, dark));
      scroll.add(parentRow);
    }
  } else {
    scroll.add(Input::new()
      |> set_id("fc-frame-name")
      |> set_placeholder("Frame name")
      |> set_buffer(&ed.stageName[0], 48)
      |> set_size(fill(), 28px));
  }

  scroll.add(Divider::new() |> set_size(fill(), 1px) |> set_bg(fcDivider(dark)));

  // Position (Accordion 0)
  scroll.add(inspAccordionHeader("Position", 0, dark));
  if (ed.accPositionOpen) {
    if (hasSel) {
      auto alignRow = Row::new() |> set_size(fill(), 26px) |> set_gap(4.0) |> set_align(GuiAlign::GuiAlignCenter);
      alignRow.add(alignBtn(std::cui::icons::alignLeft(), 0, "Align left", dark));
      alignRow.add(alignBtn(std::cui::icons::layers(), 1, "Align horizontal centers", dark));
      alignRow.add(alignBtn(std::cui::icons::grid(), 2, "Align right", dark));
      alignRow.add(BBox::new() |> set_size(4px, 1px));
      alignRow.add(alignBtn(std::cui::icons::arrowLeft(), 3, "Align top", dark));
      alignRow.add(alignBtn(std::cui::icons::sliders(), 4, "Align vertical centers", dark));
      alignRow.add(alignBtn(std::cui::icons::arrowRight(), 5, "Align bottom", dark));
      scroll.add(alignRow);
    }

    auto posRow = Row::new() |> set_size(fill(), fit()) |> set_gap(8.0);
    if (hasSel) {
      posRow.add(Scrub::new() |> set_id("fc-pos-x") |> set_text("X") |> set_value(&ed.nodes[ed.selected].x, -4000.0, 4000.0) |> set_width(144px));
      posRow.add(Scrub::new() |> set_id("fc-pos-y") |> set_text("Y") |> set_value(&ed.nodes[ed.selected].y, -4000.0, 4000.0) |> set_width(144px));
    } else {
      posRow.add(Scrub::new() |> set_id("fc-pos-ox") |> set_text("Pan X") |> set_value(&ed.offsetX, -4000.0, 4000.0) |> set_width(144px));
      posRow.add(Scrub::new() |> set_id("fc-pos-oy") |> set_text("Pan Y") |> set_value(&ed.offsetY, -4000.0, 4000.0) |> set_width(144px));
    }
    scroll.add(posRow);

    if (hasSel) {
      auto rotRow = Row::new() |> set_size(fill(), fit()) |> set_gap(6.0) |> set_align(GuiAlign::GuiAlignCenter);
      rotRow.add(Scrub::new() |> set_id("fc-pos-deg") |> set_text("Rotation") |> set_value(&ed.nodes[ed.selected].rotation, -360.0, 360.0) |> set_step(1.0) |> set_width(144px));
      rotRow.add(inspIconBtn("fc-rot-reset", std::cui::icons::rotateCcw(), "Reset rotation", false, 0, dark));
      rotRow.add(Spacer::new() |> set_size(fill(), 1px));
      rotRow.add(inspIconBtn("fc-ord-up", std::cui::icons::upload(), "Bring forward", false, 8, dark));
      rotRow.add(inspIconBtn("fc-ord-dn", std::cui::icons::download(), "Send backward", false, 9, dark));
      scroll.add(rotRow);
    }
  }

  scroll.add(Divider::new() |> set_size(fill(), 1px) |> set_bg(fcDivider(dark)));

  // Layout (Accordion 1 - ZERO frame presets!)
  scroll.add(inspAccordionHeader("Layout", 1, dark));
  if (ed.accLayoutOpen) {
    auto dimRow = Row::new() |> set_size(fill(), fit()) |> set_gap(6.0) |> set_align(GuiAlign::GuiAlignCenter);
    if (hasSel) {
      dimRow.add(Scrub::new() |> set_id("fc-lay-w") |> set_text("W") |> set_value(&ed.nodes[ed.selected].w, 8.0, 5000.0) |> set_width(128px));
      auto lockBtn = BBox::new()
        |> set_id("fc-lay-lockratio")
        |> set_size(26px, 26px)
        |> set_align(GuiAlign::GuiAlignCenter)
        |> set_justify(GuiJustify::GuiJustifyCenter)
        |> set_bg(pickColor(ed.constrainRatio, fcGreenSoft(dark), fcField(dark)))
        |> set_border(pickFloat(ed.constrainRatio, 1.0, 0.0), fcGreen())
        |> set_radius(5.0)
        |> set_tooltip("Constrain proportions")
        |> on_click() { -> ed.constrainRatio = !ed.constrainRatio; return; };
      lockBtn.add(Icon::new()
        |> set_icon(std::cui::icons::link())
        |> set_text_size(11.5)
        |> set_text_color(pickColor(ed.constrainRatio, fcGreenDark(), fcMutedText(dark))));
      dimRow.add(lockBtn);
      dimRow.add(Scrub::new() |> set_id("fc-lay-h") |> set_text("H") |> set_value(&ed.nodes[ed.selected].h, 8.0, 5000.0) |> set_width(128px));
    } else {
      dimRow.add(Scrub::new() |> set_id("fc-stage-w") |> set_text("W") |> set_value(&ed.stageW, 200.0, 3840.0) |> set_width(144px));
      dimRow.add(Scrub::new() |> set_id("fc-stage-h") |> set_text("H") |> set_value(&ed.stageH, 200.0, 2400.0) |> set_width(144px));
    }
    scroll.add(dimRow);

    if (hasSel) {
      DesignNode* n = &ed.nodes[ed.selected];
      auto conRow = Row::new() |> set_size(fill(), fit()) |> set_gap(8.0);
      conRow.add(Select::new()
        |> set_id("fc-pin-h")
        |> set_label("H Constraint")
        |> set_options(&constraintHOpts[0], 4, &n.constraintH)
        |> set_width(144px));
      conRow.add(Select::new()
        |> set_id("fc-pin-v")
        |> set_label("V Constraint")
        |> set_options(&constraintVOpts[0], 4, &n.constraintV)
        |> set_width(144px));
      scroll.add(conRow);

      scroll.add(Switch::new() |> set_id("fc-sel-clip") |> set_text("Clip content") |> set_checked(&n.clipContent));
    } else {
      scroll.add(Switch::new() |> set_id("fc-stage-clip") |> set_text("Clip content") |> set_checked(&ed.clipContent));
    }
  }

  scroll.add(Divider::new() |> set_size(fill(), 1px) |> set_bg(fcDivider(dark)));

  // Appearance (Accordion 2: Opacity, Full Blend Modes Select, Radius + Independent Corners)
  auto appHead = inspAccordionHeader("Appearance", 2, dark);
  if (hasSel) {
    appHead.add(miniActionPill("Corners", ed.nodes[ed.selected].independentCorners, "Independent corner radii", 11, 2, dark));
  }
  scroll.add(appHead);

  if (ed.accAppearanceOpen) {
    if (hasSel) {
      DesignNode* n = &ed.nodes[ed.selected];
      auto opBlendRow = Row::new() |> set_size(fill(), fit()) |> set_gap(8.0) |> set_align(GuiAlign::GuiAlignEnd);
      opBlendRow.add(Scrub::new() |> set_id("fc-app-op") |> set_text("Opacity") |> set_value(&n.opacity, 0.05, 1.0) |> set_step(0.05) |> set_width(126px));
      opBlendRow.add(Select::new()
        |> set_id("fc-blend-sel")
        |> set_label("Blend")
        |> set_options(&blendModeOpts[0], 8, &n.blendMode)
        |> set_width(162px));
      scroll.add(opBlendRow);

      scroll.add(Scrub::new() |> set_id("fc-app-r") |> set_text("Corner radius") |> set_value(&n.radius, 0.0, 200.0) |> set_step(1.0) |> set_width(fill()));

      if (n.independentCorners) {
        auto cTop = Row::new() |> set_size(fill(), fit()) |> set_gap(8.0);
        cTop.add(Scrub::new() |> set_id("fc-app-tl") |> set_text("TL") |> set_value(&n.radiusTL, 0.0, 200.0) |> set_step(1.0) |> set_width(144px));
        cTop.add(Scrub::new() |> set_id("fc-app-tr") |> set_text("TR") |> set_value(&n.radiusTR, 0.0, 200.0) |> set_step(1.0) |> set_width(144px));
        scroll.add(cTop);
        auto cBot = Row::new() |> set_size(fill(), fit()) |> set_gap(8.0);
        cBot.add(Scrub::new() |> set_id("fc-app-bl") |> set_text("BL") |> set_value(&n.radiusBL, 0.0, 200.0) |> set_step(1.0) |> set_width(144px));
        cBot.add(Scrub::new() |> set_id("fc-app-br") |> set_text("BR") |> set_value(&n.radiusBR, 0.0, 200.0) |> set_step(1.0) |> set_width(144px));
        scroll.add(cBot);
      }
    } else {
      auto appRow = Row::new() |> set_size(fill(), fit()) |> set_gap(8.0);
      appRow.add(Scrub::new() |> set_id("fc-stage-op") |> set_text("Opacity") |> set_value(&ed.stageOpacity, 0.05, 1.0) |> set_step(0.05) |> set_width(144px));
      appRow.add(Scrub::new() |> set_id("fc-stage-r") |> set_text("Radius") |> set_value(&ed.stageRadius, 0.0, 80.0) |> set_step(1.0) |> set_width(144px));
      scroll.add(appRow);
    }
  }

  // Node-specific Typography & Geometry sections (Accordions 3 & 4)
  if (hasSel) {
    DesignNode* n = &ed.nodes[ed.selected];
    if (nodeHasTypography(n.kind)) {
      appendTypographySection(scroll, n, dark);
    }
    appendShapeSpecificSection(scroll, n, dark);
  }

  scroll.add(Divider::new() |> set_size(fill(), 1px) |> set_bg(fcDivider(dark)));

  // Fill Section (Accordion 5)
  auto fillHead = inspAccordionHeader("Fill", 5, dark);
  auto palBtn = BBox::new()
    |> set_size(24px, 24px)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_radius(4.0)
    |> set_hover_bg(fcField(dark))
    |> set_tooltip("Open Color Tool")
    |> on_click() { -> openColorPicker(&ed, ColorTarget::ColorTargetFill as int); return; };
  palBtn.add(Icon::new() |> set_icon(std::cui::icons::palette()) |> set_text_size(12.0) |> set_text_color(fcGreenDark()));
  fillHead.add(palBtn);

  bool curFillVis = if (hasSel) ed.nodes[ed.selected].fillVisible else ed.fillVisible;
  auto eyeBtn = BBox::new()
    |> set_size(24px, 24px)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_radius(4.0)
    |> set_hover_bg(fcField(dark))
    |> set_tooltip("Toggle Fill visibility")
    |> on_click() { -> toggleNodeFillVisible(&ed); return; };
  eyeBtn.add(Icon::new()
    |> set_icon(pickText(curFillVis, std::cui::icons::eye(), std::cui::icons::eyeOff()))
    |> set_text_size(12.0)
    |> set_text_color(fcMutedText(dark)));
  fillHead.add(eyeBtn);
  scroll.add(fillHead);

  if (ed.accFillOpen) {
    Color activeSwatch = ed.stageBg;
    if (hasSel) {
      activeSwatch = if (ed.nodes[ed.selected].kind == (NodeKind::NodeText as int)) ed.nodes[ed.selected].ink else ed.nodes[ed.selected].fill;
    }
    scroll.add(colorTriggerRow(activeSwatch, &ed.hexLabel[0], &ed.opacityLabel[0], ColorTarget::ColorTargetFill as int, curFillVis, dark));

    if (hasSel && nodeHasTypography(ed.nodes[ed.selected].kind) && ed.nodes[ed.selected].kind != (NodeKind::NodeText as int)) {
      scroll.add(colorTriggerRow(ed.nodes[ed.selected].ink, &ed.inkHexLabel[0], "Text Color", ColorTarget::ColorTargetInk as int, true, dark));
    }
  }

  // Stroke (Accordion 6) & Effects (Accordion 7)
  if (hasSel) {
    DesignNode* n = &ed.nodes[ed.selected];
    scroll.add(Divider::new() |> set_size(fill(), 1px) |> set_bg(fcDivider(dark)));

    auto strokeHead = inspAccordionHeader("Stroke", 6, dark);
    auto stEye = BBox::new()
      |> set_size(24px, 24px)
      |> set_align(GuiAlign::GuiAlignCenter)
      |> set_justify(GuiJustify::GuiJustifyCenter)
      |> set_radius(4.0)
      |> set_hover_bg(fcField(dark))
      |> set_tooltip("Toggle Stroke")
      |> on_click() { -> toggleNodeStrokeVisible(&ed); return; };
    stEye.add(Icon::new()
      |> set_icon(pickText(n.strokeVisible, std::cui::icons::eye(), std::cui::icons::eyeOff()))
      |> set_text_size(12.0)
      |> set_text_color(fcMutedText(dark)));
    strokeHead.add(stEye);
    scroll.add(strokeHead);

    if (ed.accStrokeOpen) {
      scroll.add(colorTriggerRow(n.stroke, &ed.strokeHexLabel[0], pickText(n.strokeVisible, "Stroke Color", "Hidden"), ColorTarget::ColorTargetStroke as int, n.strokeVisible, dark));

      auto strokeGrid = Row::new() |> set_size(fill(), fit()) |> set_gap(6.0) |> set_align(GuiAlign::GuiAlignEnd);
      strokeGrid.add(Scrub::new() |> set_id("fc-stroke-w") |> set_text("Weight") |> set_value(&n.border, 0.0, 24.0) |> set_step(0.5) |> set_width(86px));
      strokeGrid.add(Select::new()
        |> set_id("fc-stroke-align")
        |> set_label("Position")
        |> set_options(&strokeAlignOpts[0], 3, &n.strokeAlign)
        |> set_width(102px));
      strokeGrid.add(Select::new()
        |> set_id("fc-stroke-style")
        |> set_label("Style")
        |> set_options(&strokeStyleOpts[0], 2, &n.strokeStyle)
        |> set_width(96px));
      scroll.add(strokeGrid);
    }

    appendEffectsSection(scroll, n, dark);
  }

  return scroll;
}

// ---------------------------------------------------------------------------
// Floating Color Picker Popover Tool (Includes BG Blur target)
// ---------------------------------------------------------------------------

Widget* paletteCellBtn(Color c, int idx, bool dark) {
  auto cell = BBox::new()
    |> set_size(26px, 22px)
    |> set_bg(c)
    |> set_border(1.0, fcBorder(dark))
    |> set_radius(4.0)
    |> set_tooltip("Pick swatch color")
    |> on_click_tag(idx) {
      -> int k = gui::clickTag();
         if (k >= 0 && k < 24) {
           applySwatchToTarget(&ed, paletteSwatchAt(k), false);
         }
         return;
    };
  return cell;
}

Widget* buildColorPickerPopover(bool dark) {
  auto overlay = Column::new()
    |> set_size(fill(), fill())
    |> set_padding_each(92.0, 338.0, 0.0, 0.0)
    |> set_align(GuiAlign::GuiAlignEnd)
    |> set_justify(GuiJustify::GuiJustifyStart);

  auto card = Column::new()
    |> set_id("fc-color-picker")
    |> set_size(286px, fit())
    |> set_padding(12.0)
    |> set_gap(9.0)
    |> set_bg(fcCard(dark))
    |> set_border(1.0, fcBorder(dark))
    |> set_radius(10.0)
    |> set_elevation(GuiElevation::GuiElevationFloating);

  bool hasSel = ed.selected >= 0 && ed.selected < ed.count;
  Color preview = getActiveTargetColor(&ed, ed.colorTarget);

  auto head = Row::new() |> set_size(fill(), 24px) |> set_align(GuiAlign::GuiAlignCenter) |> set_gap(7.0);
  head.add(BBox::new() |> set_size(16px, 16px) |> set_bg(preview) |> set_border(1.0, fcBorder(dark)) |> set_radius(4.0));
  head.add(Text::new() |> set_text("Color Tool") |> set_text_size(11.0) |> set_text_color(fcText(dark)) |> set_font(gui::medium()));
  head.add(Spacer::new() |> set_size(fill(), 1px));
  auto closeBtn = BBox::new()
    |> set_size(20px, 20px)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_hover_bg(fcField(dark))
    |> set_radius(4.0)
    |> on_click() { -> ed.showColorPicker = false; return; };
  closeBtn.add(Icon::new() |> set_icon(std::cui::icons::x()) |> set_text_size(11.0) |> set_text_color(fcMutedText(dark)));
  head.add(closeBtn);
  card.add(head);

  if (hasSel) {
    auto targetRow = Row::new() |> set_size(fill(), 24px) |> set_gap(3.0);
    targetRow.add(segChip("Fill", ed.colorTarget == 0, 17, 0, dark));
    targetRow.add(segChip("Ink", ed.colorTarget == 1, 17, 1, dark));
    targetRow.add(segChip("Strk", ed.colorTarget == 2, 17, 2, dark));
    targetRow.add(segChip("Drop", ed.colorTarget == 3, 17, 3, dark));
    targetRow.add(segChip("Innr", ed.colorTarget == 4, 17, 4, dark));
    targetRow.add(segChip("Blur", ed.colorTarget == 5, 17, 5, dark));
    card.add(targetRow);
  }

  for (int rowIdx = 0; rowIdx < 3; rowIdx = rowIdx + 1) {
    auto pRow = Row::new() |> set_size(fill(), 22px) |> set_gap(5.0);
    for (int colIdx = 0; colIdx < 8; colIdx = colIdx + 1) {
      int k = rowIdx * 8 + colIdx;
      pRow.add(paletteCellBtn(paletteSwatchAt(k), k, dark));
    }
    card.add(pRow);
  }

  auto rgRow = Row::new() |> set_size(fill(), fit()) |> set_gap(8.0);
  rgRow.add(Scrub::new() |> set_id("fc-pick-r") |> set_text("Red") |> set_value(&ed.pickerR, 0.0, 255.0) |> set_step(1.0) |> set_width(126px));
  rgRow.add(Scrub::new() |> set_id("fc-pick-g") |> set_text("Grn") |> set_value(&ed.pickerG, 0.0, 255.0) |> set_step(1.0) |> set_width(126px));
  card.add(rgRow);

  auto baRow = Row::new() |> set_size(fill(), fit()) |> set_gap(8.0);
  baRow.add(Scrub::new() |> set_id("fc-pick-b") |> set_text("Blu") |> set_value(&ed.pickerB, 0.0, 255.0) |> set_step(1.0) |> set_width(126px));
  baRow.add(Scrub::new() |> set_id("fc-pick-a") |> set_text("A%") |> set_value(&ed.pickerA, 0.0, 100.0) |> set_step(1.0) |> set_width(126px));
  card.add(baRow);

  auto hexRow = Row::new() |> set_size(fill(), 28px) |> set_gap(6.0) |> set_align(GuiAlign::GuiAlignCenter);
  hexRow.add(Input::new()
    |> set_id("fc-picker-hex")
    |> set_placeholder("#RRGGBB")
    |> set_buffer(&ed.pickerHex[0], 16)
    |> set_size(fill(), 28px));
  auto applyHexBtn = BBox::new()
    |> set_size(58px, 28px)
    |> set_bg(fcGreen())
    |> set_radius(6.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> on_click() { -> applyPickerHexString(&ed); return; };
  applyHexBtn.add(Text::new() |> set_text("Apply") |> set_text_size(10.0) |> set_text_color(fcNavy()) |> set_font(gui::medium()));
  hexRow.add(applyHexBtn);
  card.add(hexRow);

  overlay.add(card);
  return overlay;
}

// ---------------------------------------------------------------------------
// Prototype & Dev Inspectors + Right Panel Shell
// ---------------------------------------------------------------------------

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
    auto del = BBox::new()
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

  auto addBtn = BBox::new()
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

  auto presentBtn = BBox::new()
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
  specCard.add(Text::new() |> set_text("Fill / Ink Hex") |> set_text_size(9.5) |> set_text_color(fcMutedText(dark)));
  specCard.add(Text::new() |> set_text(&ed.hexLabel[0]) |> set_text_size(11.0) |> set_text_color(fcText(dark)) |> set_font(gui::mono()));
  specCard.add(Text::new() |> set_text("Stroke Hex") |> set_text_size(9.5) |> set_text_color(fcMutedText(dark)));
  specCard.add(Text::new() |> set_text(&ed.strokeHexLabel[0]) |> set_text_size(11.0) |> set_text_color(fcText(dark)) |> set_font(gui::mono()));
  scroll.add(specCard);

  scroll.add(Text::new() |> set_text("Glang std.gui Snippet") |> set_text_size(10.5) |> set_text_color(fcText(dark)) |> set_font(gui::medium()));
  auto codeCard = Column::new()
    |> set_size(fill(), fit())
    |> set_padding(10.0)
    |> set_gap(3.0)
    |> set_bg(fcNavy())
    |> set_radius(7.0);
  codeCard.add(Text::new() |> set_text("auto node = BBox::new()") |> set_text_size(9.5) |> set_text_color(fcChartMint()) |> set_font(gui::mono()));
  codeCard.add(Text::new() |> set_text("  |> set_size(fill(), fit())") |> set_text_size(9.5) |> set_text_color(fcWhite()) |> set_font(gui::mono()));
  codeCard.add(Text::new() |> set_text("  |> set_bg(fcCard(dark))") |> set_text_size(9.5) |> set_text_color(fcWhite()) |> set_font(gui::mono()));
  codeCard.add(Text::new() |> set_text("  |> set_radius(9.0);") |> set_text_size(9.5) |> set_text_color(fcWhite()) |> set_font(gui::mono()));
  scroll.add(codeCard);

  auto copyBtn = BBox::new()
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
    |> set_size(328px, fill())
    |> set_bg(fcCard(dark))
    |> set_border(1.0, fcDivider(dark));

  // Header: collapse button, avatar, Present button, Share CTA
  auto head = Row::new()
    |> set_size(fill(), 52px)
    |> set_padding_xy(16.0, 0.0)
    |> set_gap(8.0)
    |> set_align(GuiAlign::GuiAlignCenter);

  auto collapseRight = BBox::new()
    |> set_id("fc-collapse-right")
    |> set_size(24px, 24px)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_radius(5.0)
    |> set_hover_bg(fcField(dark))
    |> set_tooltip("Collapse properties")
    |> on_click() { -> ed.rightCollapsed = true; ed.showColorPicker = false; return; };
  collapseRight.add(Icon::new() |> set_icon(std::cui::icons::panelLeft()) |> set_text_size(14.0) |> set_text_color(fcSecondaryText(dark)));
  head.add(collapseRight);

  auto avatar = BBox::new()
    |> set_size(26px, 26px)
    |> set_bg(fcNavy())
    |> set_radius(13.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter);
  avatar.add(Text::new() |> set_text("MC") |> set_text_size(7.5) |> set_text_color(fcWhite()) |> set_font(gui::medium()));
  head.add(avatar);
  head.add(Icon::new() |> set_icon(std::cui::icons::chevronDown()) |> set_text_size(11.0) |> set_text_color(fcSecondaryText(dark)));
  head.add(Spacer::new() |> set_size(fill(), 1px));

  auto playBtn = BBox::new()
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

  auto shareBtn = BBox::new()
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
    |> set_padding_xy(16.0, 0.0)
    |> set_gap(4.0)
    |> set_align(GuiAlign::GuiAlignCenter);

  bool designActive = ed.rightTab == (RightTab::TabDesign as int);
  auto dTab = BBox::new()
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

  auto pTab = BBox::new()
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

  auto zoomOutBtn = BBox::new()
    |> set_size(20px, 22px)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_hover_bg(fcField(dark))
    |> set_radius(4.0)
    |> set_tooltip("Zoom out (-)")
    |> on_click() { -> stepZoom(&ed, -1); return; };
  zoomOutBtn.add(Icon::new() |> set_icon(std::cui::icons::minus()) |> set_text_size(10.5) |> set_text_color(fcSecondaryText(dark)));
  tabs.add(zoomOutBtn);

  auto zoomResetBtn = BBox::new()
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

  auto zoomInBtn = BBox::new()
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
