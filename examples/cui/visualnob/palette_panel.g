// VisualNob Left Node Palette Drawer & Floating Quick-Add Picker.
// Provides categorized node browsing, live search filtering, one-click spawning,
// and quick variable creation matching FigCraft's clean editorial panel styling.

import std.gui;
import std.pipe;
import std.cui;
import examples.cui.visualnob.palette;
import examples.cui.visualnob.model;
import examples.cui.visualnob.geometry;
import examples.cui.visualnob.graph;

void spawnNodeAtCanvasCenter(int kind) {
  float cx = vn.canvasRect.x + vn.canvasRect.w * 0.48;
  float cy = vn.canvasRect.y + vn.canvasRect.h * 0.44;
  float wx = screenToWorldX(&vn, cx);
  float wy = screenToWorldY(&vn, cy);
  int idx = createScriptNode(&vn, kind, wx - 80.0, wy - 40.0);
  if (idx >= 0) {
    vn.selectedNode = idx;
    vn.selectedWire = -1;
  }
}

void spawnNodeFromQuickAdd(int kind) {
  int idx = createScriptNode(&vn, kind, vn.quickAddWorldX - 80.0, vn.quickAddWorldY - 24.0);
  if (idx >= 0) {
    vn.selectedNode = idx;
    vn.selectedWire = -1;
  }
  vn.showQuickAdd = false;
}

Widget* catFilterBtn(int cat, const char* label, bool dark) {
  bool active = vn.paletteCategory == cat;
  auto btn = Box::new()
    |> set_size(fit(), 22px)
    |> set_padding_xy(8.0, 0.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_bg(vnPickColor(active, vnMintSoft(dark), vnField(dark)))
    |> set_border(1.0, vnPickColor(active, vnMintDark(), vnDivider(dark)))
    |> set_radius(5.0)
    |> on_click_tag(cat) { -> vn.paletteCategory = gui::clickTag(); return; };
  btn.add(Text::new()
    |> set_text(label)
    |> set_text_size(9.5)
    |> set_font(gui::medium())
    |> set_text_color(vnPickColor(active, vnMint(), vnSecondaryText(dark))));
  return btn;
}

Widget* paletteTemplateItem(int kind, bool dark) {
  int cat = nodeKindCategory(kind);
  Color accent = categoryHeaderColor(cat, dark);

  auto row = Row::new()
    |> set_size(fill(), 40px)
    |> set_padding_xy(9.0, 5.0)
    |> set_gap(9.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_bg(vnCard(dark))
    |> set_hover_bg(vnHover(dark))
    |> set_border(1.0, vnDivider(dark))
    |> set_radius(7.0)
    |> on_click_tag(kind) { -> spawnNodeAtCanvasCenter(gui::clickTag()); return; };

  auto badge = Box::new()
    |> set_size(24px, 24px)
    |> set_radius(5.0)
    |> set_bg(gui::fade(accent, 38))
    |> set_border(1.0, gui::fade(accent, 110))
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter);
  badge.add(Icon::new() |> set_icon(nodeKindIcon(kind)) |> set_text_size(12.0) |> set_text_color(accent));
  row.add(badge);

  auto txtCol = Column::new() |> set_size(fill(), fit()) |> set_gap(1.0);
  txtCol.add(Text::new()
    |> set_text(nodeKindDefaultTitle(kind))
    |> set_text_size(10.5)
    |> set_font(gui::medium())
    |> set_text_color(vnText(dark)));
  txtCol.add(Text::new()
    |> set_text(nodeKindDescription(kind))
    |> set_text_size(9.0)
    |> set_text_color(vnMutedText(dark)));
  row.add(txtCol);

  row.add(Icon::new()
    |> set_icon(std::cui::icons::plus())
    |> set_text_size(11.0)
    |> set_text_color(vnMutedText(dark)));
  return row;
}

Widget* buildPalettePanel() {
  bool dark = vn.darkTheme;
  auto panel = Column::new()
    |> set_id("vn-left-panel")
    |> set_size(260px, fill())
    |> set_bg(vnPanel(dark))
    |> set_border(1.0, vnBorder(dark))
    |> set_gap(0.0);

  // Header
  auto header = Row::new()
    |> set_size(fill(), 44px)
    |> set_padding_each(0.0, 10.0, 0.0, 14.0)
    |> set_gap(6.0)
    |> set_align(GuiAlign::GuiAlignCenter);
  header.add(Icon::new() |> set_icon(std::cui::icons::layers()) |> set_text_size(13.0) |> set_text_color(vnMint()));
  header.add(Text::new() |> set_text("Node Palette") |> set_text_size(11.5) |> set_font(gui::medium()) |> set_text_color(vnText(dark)));
  header.add(Spacer::new() |> set_size(fill(), 1px));

  auto collapseBtn = Box::new()
    |> set_size(24px, 24px)
    |> set_radius(5.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_hover_bg(vnHover(dark))
    |> set_tooltip("Collapse palette")
    |> on_click() { -> vn.leftCollapsed = true; return; };
  collapseBtn.add(Icon::new() |> set_icon(std::cui::icons::panelLeft()) |> set_text_size(13.0) |> set_text_color(vnSecondaryText(dark)));
  header.add(collapseBtn);
  panel.add(header);
  panel.add(Divider::new() |> set_size(fill(), 1px) |> set_bg(vnDivider(dark)));

  // Search box + category filters
  auto filterBox = Column::new()
    |> set_size(fill(), fit())
    |> set_padding(10.0)
    |> set_gap(8.0);
  filterBox.add(Input::new()
    |> set_id("vn-palette-search")
    |> set_placeholder("Search nodes...")
    |> set_buffer(&vn.paletteFilter[0], 48)
    |> set_size(fill(), 28px));

  auto catRow1 = Row::new() |> set_size(fill(), fit()) |> set_gap(4.0);
  catRow1.add(catFilterBtn(NodeCat::CatAll as int, "All", dark));
  catRow1.add(catFilterBtn(NodeCat::CatEvents as int, "Event", dark));
  catRow1.add(catFilterBtn(NodeCat::CatValues as int, "Value", dark));
  catRow1.add(catFilterBtn(NodeCat::CatVariables as int, "Var", dark));
  filterBox.add(catRow1);

  auto catRow2 = Row::new() |> set_size(fill(), fit()) |> set_gap(4.0);
  catRow2.add(catFilterBtn(NodeCat::CatLogic as int, "Logic", dark));
  catRow2.add(catFilterBtn(NodeCat::CatFlow as int, "Flow", dark));
  catRow2.add(catFilterBtn(NodeCat::CatActions as int, "Action", dark));
  filterBox.add(catRow2);
  panel.add(filterBox);

  panel.add(Divider::new() |> set_size(fill(), 1px) |> set_bg(vnDivider(dark)));

  // Scrollable Node Catalog
  auto listScroll = Scroll::new()
    |> set_id("vn-palette-scroll")
    |> set_size(fill(), fill())
    |> set_padding(10.0)
    |> set_gap(5.0);

  for (int k = 0; k <= (VnNodeKind::VnComment as int); k = k + 1) {
    int cat = nodeKindCategory(k);
    if (vn.paletteCategory != (NodeCat::CatAll as int) && vn.paletteCategory != cat) {
      continue;
    }
    if (!vnContainsFold(nodeKindDefaultTitle(k), &vn.paletteFilter[0]) &&
        !vnContainsFold(nodeKindDescription(k), &vn.paletteFilter[0])) {
      continue;
    }
    listScroll.add(paletteTemplateItem(k, dark));
  }
  panel.add(listScroll);

  panel.add(Divider::new() |> set_size(fill(), 1px) |> set_bg(vnDivider(dark)));

  // Script Variables Footer
  auto varSec = Column::new()
    |> set_size(fill(), fit())
    |> set_padding(10.0)
    |> set_gap(6.0);
  auto varHead = Row::new() |> set_size(fill(), 22px) |> set_align(GuiAlign::GuiAlignCenter);
  varHead.add(Text::new() |> set_text("Variables") |> set_text_size(10.5) |> set_font(gui::medium()) |> set_text_color(vnText(dark)));
  varHead.add(Spacer::new() |> set_size(fill(), 1px));
  auto addVarBtn = Box::new()
    |> set_size(fit(), 20px)
    |> set_padding_xy(6.0, 0.0)
    |> set_bg(vnCyanSoft(dark))
    |> set_radius(4.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> on_click() {
      -> if (vn.newVarName[0] != '\0') {
           addScriptVar(&vn, &vn.newVarName[0], PinType::PinNumber as int, 0.0, "", false);
         }
         return;
    };
  addVarBtn.add(Text::new() |> set_text("+ Var") |> set_text_size(9.5) |> set_font(gui::medium()) |> set_text_color(vnCyan()));
  varHead.add(addVarBtn);
  varSec.add(varHead);

  for (int v = 0; v < vn.varCount; v = v + 1) {
    if (v >= 4) { break; }
    char[24] vBuf;
    vnFormatNum(&vBuf[0], vn.vars[v].runtimeNum, 24);
    auto vRow = Row::new()
      |> set_size(fill(), 24px)
      |> set_padding_xy(8.0, 0.0)
      |> set_bg(vnField(dark))
      |> set_radius(4.0)
      |> set_align(GuiAlign::GuiAlignCenter)
      |> set_tooltip("Click to spawn Get Var node")
      |> on_click_tag(v) {
        -> int vi = gui::clickTag();
           if (vi >= 0 && vi < vn.varCount) {
             spawnNodeAtCanvasCenter(VnNodeKind::VnGetVar as int);
             if (vn.selectedNode >= 0) {
               vnCopyStr(&vn.nodes[vn.selectedNode].strValue[0], &vn.vars[vi].name[0], 64);
             }
           }
           return;
      };
    vRow.add(Text::new() |> set_text("$") |> set_text_size(10.0) |> set_font(gui::mono()) |> set_text_color(vnCyan()));
    vRow.add(Text::new() |> set_text(&vn.vars[v].name[0]) |> set_text_size(10.0) |> set_text_color(vnText(dark)));
    vRow.add(Spacer::new() |> set_size(fill(), 1px));
    vRow.add(Text::new() |> set_text(&vBuf[0]) |> set_text_size(9.5) |> set_font(gui::mono()) |> set_text_color(vnMint()));
    varSec.add(vRow);
  }
  panel.add(varSec);

  return panel;
}

Widget* buildQuickAddPicker() {
  bool dark = vn.darkTheme;
  auto wrap = Column::new()
    |> set_size(fill(), fill())
    |> set_padding_each(vn.quickAddScreenY, 0.0, 0.0, vn.quickAddScreenX)
    |> set_align(GuiAlign::GuiAlignStart)
    |> set_justify(GuiJustify::GuiJustifyStart);

  auto card = Column::new()
    |> set_id("vn-quick-add")
    |> set_size(240px, 310px)
    |> set_padding(10.0)
    |> set_gap(7.0)
    |> set_bg(vnCard(dark))
    |> set_border(1.0, vnMint())
    |> set_radius(10.0)
    |> set_elevation(GuiElevation::GuiElevationFloating);

  auto head = Row::new() |> set_size(fill(), 22px) |> set_align(GuiAlign::GuiAlignCenter);
  head.add(Icon::new() |> set_icon(std::cui::icons::zap()) |> set_text_size(12.0) |> set_text_color(vnMint()));
  head.add(Box::new() |> set_size(6px, 1px));
  head.add(Text::new() |> set_text("Quick Add Node") |> set_text_size(11.0) |> set_font(gui::medium()) |> set_text_color(vnText(dark)));
  head.add(Spacer::new() |> set_size(fill(), 1px));
  auto closeBtn = Box::new()
    |> set_size(20px, 20px)
    |> set_radius(4.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_hover_bg(vnHover(dark))
    |> on_click() { -> vn.showQuickAdd = false; return; };
  closeBtn.add(Icon::new() |> set_icon(std::cui::icons::x()) |> set_text_size(11.0) |> set_text_color(vnMutedText(dark)));
  head.add(closeBtn);
  card.add(head);

  card.add(Input::new()
    |> set_id("vn-quick-search")
    |> set_placeholder("Type node name...")
    |> set_buffer(&vn.quickAddFilter[0], 48)
    |> set_size(fill(), 28px));

  auto scroll = Scroll::new()
    |> set_id("vn-quick-scroll")
    |> set_size(fill(), fill())
    |> set_padding(2.0)
    |> set_gap(3.0);

  for (int k = 0; k <= (VnNodeKind::VnComment as int); k = k + 1) {
    if (!vnContainsFold(nodeKindDefaultTitle(k), &vn.quickAddFilter[0]) &&
        !vnContainsFold(categoryLabel(nodeKindCategory(k)), &vn.quickAddFilter[0])) {
      continue;
    }
    Color accent = categoryHeaderColor(nodeKindCategory(k), dark);
    auto item = Row::new()
      |> set_size(fill(), 28px)
      |> set_padding_xy(8.0, 0.0)
      |> set_gap(7.0)
      |> set_radius(5.0)
      |> set_align(GuiAlign::GuiAlignCenter)
      |> set_hover_bg(vnHover(dark))
      |> on_click_tag(k) { -> spawnNodeFromQuickAdd(gui::clickTag()); return; };
    item.add(Icon::new() |> set_icon(nodeKindIcon(k)) |> set_text_size(11.5) |> set_text_color(accent));
    item.add(Text::new() |> set_text(nodeKindDefaultTitle(k)) |> set_text_size(10.5) |> set_text_color(vnText(dark)));
    item.add(Spacer::new() |> set_size(fill(), 1px));
    item.add(Text::new() |> set_text(categoryLabel(nodeKindCategory(k))) |> set_text_size(9.0) |> set_text_color(vnMutedText(dark)));
    scroll.add(item);
  }
  card.add(scroll);
  wrap.add(card);
  return wrap;
}
