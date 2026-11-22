// FigCraft Left Panel: File (Pages + Filterable Layer Tree), Assets (Component Library),
// and Variables (Theme Color & Number Tokens).

import std.gui;
import std.pipe;
import std.cui;
import examples.cui.figcraft.palette;
import examples.cui.figcraft.model;
import examples.cui.figcraft.geometry;
import examples.cui.figcraft.actions;

Widget* leftPanelHeader(const char* title, const char* subtitle, bool dark) {
  auto header = Row::new()
    |> set_size(fill(), 52px)
    |> set_padding_each(0.0, 10.0, 0.0, 16.0)
    |> set_gap(6.0)
    |> set_align(GuiAlign::GuiAlignCenter);

  auto titles = Column::new() |> set_size(fill(), fit()) |> set_gap(1.0);
  titles.add(Text::new() |> set_text(title) |> set_text_size(12.0) |> set_text_color(fcText(dark)) |> set_font(gui::medium()));
  if (subtitle != nullptr) {
    titles.add(Text::new() |> set_text(subtitle) |> set_text_size(10.0) |> set_text_color(fcMutedText(dark)));
  }
  header.add(titles);

  auto collapseBtn = Box::new()
    |> set_id("fc-collapse-left")
    |> set_size(24px, 24px)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_radius(5.0)
    |> set_hover_bg(fcField(dark))
    |> set_tooltip("Collapse panel")
    |> on_click() { -> ed.leftCollapsed = true; return; };
  collapseBtn.add(Icon::new() |> set_icon(std::cui::icons::panelLeft()) |> set_text_size(14.0) |> set_text_color(fcSecondaryText(dark)));
  header.add(collapseBtn);

  return header;
}

Widget* buildFileTab(bool dark) {
  auto col = Column::new() |> set_size(fill(), fill()) |> set_gap(0.0);
  col.add(leftPanelHeader(&ed.tabs[ed.activeTab].title[0], "Drafts", dark));
  col.add(Divider::new() |> set_size(fill(), 1px) |> set_bg(fcDivider(dark)));

  // Pages section header
  auto pagesHead = Row::new()
    |> set_size(fill(), 34px)
    |> set_padding_each(0.0, 10.0, 0.0, 16.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_gap(4.0);
  pagesHead.add(Text::new() |> set_text("Pages") |> set_text_size(10.5) |> set_text_color(fcSecondaryText(dark)) |> set_font(gui::medium()));
  pagesHead.add(Spacer::new() |> set_size(fill(), 1px));

  auto addPageBtn = Box::new()
    |> set_id("fc-add-page")
    |> set_size(24px, 24px)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_radius(5.0)
    |> set_hover_bg(fcField(dark))
    |> set_tooltip("Add page")
    |> on_click() { -> addNewPage(&ed); return; };
  addPageBtn.add(Icon::new() |> set_icon(std::cui::icons::plus()) |> set_text_size(13.5) |> set_text_color(fcMutedText(dark)));
  pagesHead.add(addPageBtn);
  col.add(pagesHead);

  // Page list
  auto pagesBox = Column::new()
    |> set_size(fill(), fit())
    |> set_padding_each(0.0, 8.0, 6.0, 8.0)
    |> set_gap(2.0);
  for (int p = 0; p < ed.pageCount; p = p + 1) {
    bool activeP = ed.activePage == p;
    auto pageRow = Row::new()
      |> set_size(fill(), 28px)
      |> set_padding_xy(10.0, 0.0)
      |> set_gap(6.0)
      |> set_align(GuiAlign::GuiAlignCenter)
      |> set_bg(pickColor(activeP, fcPageSelected(dark), gui::clear()))
      |> set_radius(6.0)
      |> on_click_tag(p) { -> switchPage(&ed, gui::clickTag()); return; };
    pageRow.add(Icon::new()
      |> set_icon(std::cui::icons::fileText())
      |> set_text_size(11.5)
      |> set_text_color(pickColor(activeP, fcGreenDark(), fcMutedText(dark))));
    pageRow.add(Text::new()
      |> set_text(&ed.pages[p].title[0])
      |> set_text_size(11.0)
      |> set_text_color(pickColor(activeP, fcText(dark), fcSecondaryText(dark))));
    pagesBox.add(pageRow);
  }
  col.add(pagesBox);
  col.add(Divider::new() |> set_size(fill(), 1px) |> set_bg(fcDivider(dark)));

  // Layers header + filter toggle
  auto layersHead = Row::new()
    |> set_size(fill(), 34px)
    |> set_padding_each(0.0, 10.0, 0.0, 16.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_gap(4.0);
  layersHead.add(Text::new() |> set_text("Layers") |> set_text_size(10.5) |> set_text_color(fcSecondaryText(dark)) |> set_font(gui::medium()));
  layersHead.add(Text::new() |> set_text(&ed.layerCountLabel[0]) |> set_text_size(9.5) |> set_text_color(fcMutedText(dark)));
  layersHead.add(Spacer::new() |> set_size(fill(), 1px));

  auto searchToggle = Box::new()
    |> set_size(24px, 24px)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_radius(5.0)
    |> set_bg(pickColor(ed.showLayerSearch, fcGreenSoft(dark), gui::clear()))
    |> set_hover_bg(fcField(dark))
    |> set_tooltip("Filter layers")
    |> on_click() {
      -> ed.showLayerSearch = !ed.showLayerSearch;
         if (!ed.showLayerSearch) { ed.layerFilter[0] = '\0'; }
         return;
    };
  searchToggle.add(Icon::new()
    |> set_icon(std::cui::icons::search())
    |> set_text_size(12.5)
    |> set_text_color(pickColor(ed.showLayerSearch, fcGreenDark(), fcMutedText(dark))));
  layersHead.add(searchToggle);
  col.add(layersHead);

  if (ed.showLayerSearch) {
    auto filterWrap = Row::new()
      |> set_size(fill(), 34px)
      |> set_padding_each(0.0, 10.0, 4.0, 10.0)
      |> set_align(GuiAlign::GuiAlignCenter);
    filterWrap.add(Input::new()
      |> set_id("fc-layer-filter")
      |> set_placeholder("Filter layers...")
      |> set_buffer(&ed.layerFilter[0], 64)
      |> set_size(fill(), 26px));
    col.add(filterWrap);
  }

  auto scroll = Scroll::new()
    |> set_id("fc-layers-scroll")
    |> set_size(fill(), fill())
    |> set_padding_xy(8.0, 2.0)
    |> set_gap(2.0);

  // Root frame row
  bool rootSel = ed.selected < 0;
  auto rootRow = Row::new()
    |> set_size(fill(), 28px)
    |> set_padding_xy(8.0, 0.0)
    |> set_gap(5.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_bg(pickColor(rootSel, fcGreenSoft(dark), fcPanel(dark)))
    |> set_radius(6.0)
    |> on_click() { -> ed.selected = -1; refreshInspectorLabels(&ed); return; };
  rootRow.add(Icon::new()
    |> set_icon(std::cui::icons::chevronDown())
    |> set_text_size(10.5)
    |> set_text_color(pickColor(rootSel, fcGreenDark(), fcMutedText(dark))));
  rootRow.add(Icon::new()
    |> set_icon(std::cui::icons::layers())
    |> set_text_size(12.0)
    |> set_text_color(pickColor(rootSel, fcGreenDark(), fcSecondaryText(dark))));
  rootRow.add(Text::new()
    |> set_text(&ed.stageName[0])
    |> set_text_size(11.0)
    |> set_text_color(pickColor(rootSel, fcText(dark), fcSecondaryText(dark))));
  scroll.add(rootRow);

  // Filtered layer rows (top to bottom)
  for (int i = ed.count - 1; i >= 0; i = i - 1) {
    if (scroll.childCount >= 188) { break; }
    if (!strContainsFold(&ed.nodes[i].name[0], &ed.layerFilter[0])) { continue; }
    bool isSel = ed.selected == i;
    bool vis = ed.nodes[i].visible;

    auto nodeRow = Row::new()
      |> set_size(fill(), 26px)
      |> set_padding_each(0.0, 6.0, 0.0, 18.0)
      |> set_gap(5.0)
      |> set_align(GuiAlign::GuiAlignCenter)
      |> set_bg(pickColor(isSel, fcGreenSoft(dark), fcPanel(dark)))
      |> set_radius(6.0)
      |> on_click_tag(i) { -> ed.selected = gui::clickTag(); refreshInspectorLabels(&ed); return; };

    nodeRow.add(Icon::new()
      |> set_icon(nodeGlyph(ed.nodes[i].kind))
      |> set_text_size(11.0)
      |> set_text_color(pickColor(isSel, fcGreenDark(), fcSecondaryText(dark))));

    nodeRow.add(Text::new()
      |> set_text(&ed.nodes[i].name[0])
      |> set_text_size(10.5)
      |> set_text_color(pickColor(vis, pickColor(isSel, fcText(dark), fcSecondaryText(dark)), fcMutedText(dark))));

    nodeRow.add(Spacer::new() |> set_size(fill(), 1px));

    auto visBtn = Box::new()
      |> set_size(20px, 20px)
      |> set_align(GuiAlign::GuiAlignCenter)
      |> set_justify(GuiJustify::GuiJustifyCenter)
      |> set_radius(4.0)
      |> on_click_tag(i) { -> toggleNodeVisibility(&ed, gui::clickTag()); return; };
    visBtn.add(Icon::new()
      |> set_icon(pickText(vis, std::cui::icons::eye(), std::cui::icons::eyeOff()))
      |> set_text_size(10.5)
      |> set_text_color(pickColor(vis, fcMutedText(dark), fcDanger())));
    nodeRow.add(visBtn);

    scroll.add(nodeRow);
  }

  col.add(scroll);
  return col;
}

Widget* assetPreviewCard(const char* wid, const char* name, int assetKind, bool dark) {
  auto card = Column::new()
    |> set_id(wid)
    |> set_size(fill(), 94px)
    |> set_padding(8.0)
    |> set_gap(6.0)
    |> set_bg(fcCard(dark))
    |> set_border(1.0, fcDivider(dark))
    |> set_radius(7.0)
    |> set_tooltip("Click to insert onto canvas")
    |> on_click_tag(assetKind) { -> insertComponentAsset(&ed, gui::clickTag()); return; };

  auto preview = Box::new()
    |> set_size(fill(), 54px)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_bg(fcField(dark))
    |> set_radius(5.0);

  if (assetKind == 0) {
    auto pill = Box::new()
      |> set_size(60px, 20px)
      |> set_align(GuiAlign::GuiAlignCenter)
      |> set_justify(GuiJustify::GuiJustifyCenter)
      |> set_bg(fcGreen())
      |> set_radius(10.0);
    pill.add(Text::new() |> set_text("Button") |> set_text_size(7.5) |> set_text_color(fcNavy()) |> set_font(gui::medium()));
    preview.add(pill);
  } else if (assetKind == 1) {
    auto miniCard = Column::new()
      |> set_size(58px, 32px)
      |> set_padding(5.0)
      |> set_gap(4.0)
      |> set_bg(fcCard(dark))
      |> set_border(1.0, fcBorder(dark))
      |> set_radius(4.0);
    miniCard.add(Box::new() |> set_size(34px, 3px) |> set_bg(fcBorder(dark)) |> set_radius(1.0));
    miniCard.add(Box::new() |> set_size(24px, 3px) |> set_bg(fcDivider(dark)) |> set_radius(1.0));
    preview.add(miniCard);
  } else if (assetKind == 2) {
    auto bars = Row::new()
      |> set_size(fit(), 32px)
      |> set_gap(3.0)
      |> set_align(GuiAlign::GuiAlignEnd);
    bars.add(Box::new() |> set_size(6px, 14px) |> set_bg(fcChartGreen()) |> set_radius(1.0));
    bars.add(Box::new() |> set_size(6px, 25px) |> set_bg(fcChartMint()) |> set_radius(1.0));
    bars.add(Box::new() |> set_size(6px, 19px) |> set_bg(fcChartGreen()) |> set_radius(1.0));
    bars.add(Box::new() |> set_size(6px, 29px) |> set_bg(fcChartBlue()) |> set_radius(1.0));
    preview.add(bars);
  } else {
    auto av = Box::new()
      |> set_size(28px, 28px)
      |> set_align(GuiAlign::GuiAlignCenter)
      |> set_justify(GuiJustify::GuiJustifyCenter)
      |> set_bg(fcNavy())
      |> set_radius(14.0);
    av.add(Icon::new() |> set_icon(std::cui::icons::user()) |> set_text_size(14.0) |> set_text_color(fcWhite()));
    preview.add(av);
  }

  card.add(preview);
  card.add(Text::new() |> set_text(name) |> set_text_size(9.5) |> set_text_color(fcSecondaryText(dark)));
  return card;
}

Widget* buildAssetsTab(bool dark) {
  auto col = Column::new() |> set_size(fill(), fill()) |> set_gap(0.0);
  col.add(leftPanelHeader("Assets", "Local components", dark));
  col.add(Divider::new() |> set_size(fill(), 1px) |> set_bg(fcDivider(dark)));

  auto titleRow = Row::new()
    |> set_size(fill(), 36px)
    |> set_padding_xy(16.0, 0.0)
    |> set_align(GuiAlign::GuiAlignCenter);
  titleRow.add(Text::new() |> set_text("Components") |> set_text_size(10.5) |> set_text_color(fcSecondaryText(dark)));
  titleRow.add(Spacer::new() |> set_size(fill(), 1px));
  titleRow.add(Text::new() |> set_text("Click to add") |> set_text_size(9.0) |> set_text_color(fcMutedText(dark)));
  col.add(titleRow);

  auto grid = Grid::new()
    |> set_size(fill(), fit())
    |> set_columns(2)
    |> set_padding_xy(12.0, 0.0)
    |> set_gap(8.0);
  grid.add(assetPreviewCard("fc-asset-button", "Button", 0, dark));
  grid.add(assetPreviewCard("fc-asset-card", "Card", 1, dark));
  grid.add(assetPreviewCard("fc-asset-chart", "Chart", 2, dark));
  grid.add(assetPreviewCard("fc-asset-avatar", "Avatar", 3, dark));
  col.add(grid);

  auto note = Column::new()
    |> set_size(fill(), fit())
    |> set_padding(14.0)
    |> set_gap(4.0);
  note.add(Text::new() |> set_text("Styles") |> set_text_size(10.5) |> set_text_color(fcSecondaryText(dark)) |> set_font(gui::medium()));
  note.add(Text::new()
    |> set_text("Colour, text, effect and grid styles drive both light and dark modes.")
    |> set_text_size(9.5)
    |> set_text_color(fcMutedText(dark))
    |> set_text_wrap(true)
    |> set_width(fill()));
  col.add(note);
  col.add(Spacer::new() |> set_size(fill(), fill()));
  return col;
}

Widget* buildVariablesTab(bool dark) {
  auto col = Column::new() |> set_size(fill(), fill()) |> set_gap(0.0);
  col.add(leftPanelHeader("Variables", "Theme modes", dark));
  col.add(Divider::new() |> set_size(fill(), 1px) |> set_bg(fcDivider(dark)));

  auto cHead = Row::new() |> set_size(fill(), 34px) |> set_padding_xy(14.0, 0.0) |> set_align(GuiAlign::GuiAlignCenter);
  cHead.add(Text::new() |> set_text("Colour") |> set_text_size(10.5) |> set_text_color(fcSecondaryText(dark)));
  cHead.add(Spacer::new() |> set_size(fill(), 1px));
  cHead.add(Text::new() |> set_text("Apply fill") |> set_text_size(9.0) |> set_text_color(fcMutedText(dark)));
  col.add(cHead);

  for (int i = 0; i < ed.colorVarCount; i = i + 1) {
    auto row = Row::new()
      |> set_size(fill(), 34px)
      |> set_padding_xy(12.0, 0.0)
      |> set_gap(7.0)
      |> set_align(GuiAlign::GuiAlignCenter)
      |> set_hover_bg(fcField(dark))
      |> set_radius(5.0)
      |> on_click_tag(i) { -> applyColorVar(&ed, gui::clickTag()); return; };
    row.add(Box::new()
      |> set_size(16px, 16px)
      |> set_bg(ed.colorVars[i].color)
      |> set_border(1.0, fcBorder(dark))
      |> set_radius(4.0));
    row.add(Text::new() |> set_text(&ed.colorVars[i].token[0]) |> set_text_size(10.0) |> set_text_color(fcText(dark)));
    row.add(Spacer::new() |> set_size(fill(), 1px));
    row.add(Text::new() |> set_text(&ed.colorVars[i].group[0]) |> set_text_size(9.5) |> set_text_color(fcMutedText(dark)));
    row.add(Text::new() |> set_text(&ed.colorVars[i].hex[0]) |> set_text_size(9.5) |> set_text_color(fcSecondaryText(dark)) |> set_font(gui::mono()));
    col.add(row);
  }

  col.add(Divider::new() |> set_size(fill(), 1px) |> set_bg(fcDivider(dark)));

  auto nHead = Row::new() |> set_size(fill(), 34px) |> set_padding_xy(14.0, 0.0) |> set_align(GuiAlign::GuiAlignCenter);
  nHead.add(Text::new() |> set_text("Numbers") |> set_text_size(10.5) |> set_text_color(fcSecondaryText(dark)));
  nHead.add(Spacer::new() |> set_size(fill(), 1px));
  nHead.add(Text::new() |> set_text("Apply radius") |> set_text_size(9.0) |> set_text_color(fcMutedText(dark)));
  col.add(nHead);

  for (int i = 0; i < ed.numberVarCount; i = i + 1) {
    auto row = Row::new()
      |> set_size(fill(), 34px)
      |> set_padding_xy(12.0, 0.0)
      |> set_gap(7.0)
      |> set_align(GuiAlign::GuiAlignCenter)
      |> set_hover_bg(fcField(dark))
      |> set_radius(5.0)
      |> on_click_tag(i) { -> applyNumberVar(&ed, gui::clickTag()); return; };
    row.add(Box::new()
      |> set_size(16px, 16px)
      |> set_bg(fcField(dark))
      |> set_border(1.0, fcBorder(dark))
      |> set_radius(4.0));
    row.add(Text::new() |> set_text(&ed.numberVars[i].token[0]) |> set_text_size(10.0) |> set_text_color(fcText(dark)));
    row.add(Spacer::new() |> set_size(fill(), 1px));
    row.add(Text::new() |> set_text(&ed.numberVars[i].label[0]) |> set_text_size(9.5) |> set_text_color(fcMutedText(dark)));
    row.add(Text::new() |> set_text(&ed.numberVars[i].display[0]) |> set_text_size(9.5) |> set_text_color(fcSecondaryText(dark)));
    col.add(row);
  }

  col.add(Spacer::new() |> set_size(fill(), fill()));
  return col;
}

Widget* buildLeftPanel() {
  bool dark = ed.darkTheme;
  auto panel = Column::new()
    |> set_size(248px, fill())
    |> set_bg(fcPanel(dark))
    |> set_border(1.0, fcDivider(dark));

  if (ed.leftTab == (LeftTab::TabFile as int)) {
    panel.add(buildFileTab(dark));
  } else if (ed.leftTab == (LeftTab::TabAssets as int)) {
    panel.add(buildAssetsTab(dark));
  } else {
    panel.add(buildVariablesTab(dark));
  }
  return panel;
}
