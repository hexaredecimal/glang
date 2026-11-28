// FigCraft Left Panel: File (Pages + Filterable Layer Tree), Assets (Component Library),
// and Variables (Theme Color & Number Tokens).

import std.gui;
import std.pipe;
import std.cui;
import std.string;
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

  auto collapseBtn = BBox::new()
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

  auto addPageBtn = BBox::new()
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

  auto searchToggle = BBox::new()
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

  buildLayerTreeCache(&ed);

  auto scroll = Scroll::new()
    |> set_id("fc-layers-scroll")
    |> set_size(fill(), fill())
    |> set_padding_xy(8.0, 2.0)
    |> set_gap(2.0);

  // Root frame row
  bool rootSel = ed.selected < 0;
  bool rootDrop = ed.layerDragActive && ed.layerDropTargetIdx == -1;
  auto rootRow = Row::new()
    |> set_id("fc-layer-root")
    |> set_size(fill(), 28px)
    |> set_padding_xy(8.0, 0.0)
    |> set_gap(5.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_bg(pickColor(rootDrop, fcGreenSoft(dark), pickColor(rootSel, fcGreenSoft(dark), fcPanel(dark))))
    |> set_border(pickFloat(rootDrop, 1.5, 0.0), fcGreen())
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

  // Hierarchical layer tree rows (top to bottom)
  for (int t = 0; t < ed.layerTreeCount; t = t + 1) {
    if (scroll.childCount >= 188) { break; }
    int i = ed.layerTreeOrder[t];
    int depth = ed.layerTreeDepth[t];
    bool hasKids = ed.layerTreeHasKids[t];
    bool isContainer = isNodeContainerKind(ed.nodes[i].kind);

    if (!std::string::contains_ignore_case(&ed.nodes[i].name[0], &ed.layerFilter[0])) { continue; }
    bool isSel = ed.selected == i;
    bool vis = ed.nodes[i].visible;
    bool isDropTarget = ed.layerDragActive && ed.layerDropTargetIdx == i;
    bool isDropAbove = isDropTarget && ed.layerDropMode == 0;
    bool isDropInside = isDropTarget && ed.layerDropMode == 1;
    bool isDropBelow = isDropTarget && ed.layerDropMode == 2;
    bool isDragSrc = ed.layerDragActive && ed.layerDragNodeIdx == i;

    if (isDropAbove && scroll.childCount < 188) {
      scroll.add(BBox::new() |> set_size(fill(), 2px) |> set_bg(fcGreen()) |> set_radius(1.0));
    }
    if (scroll.childCount >= 188) { break; }

    float leftPad = 8.0 + (depth as float) * 14.0;
    auto nodeRow = Row::new()
      |> set_id(&ed.nodes[i].rowId[0])
      |> set_size(fill(), 26px)
      |> set_padding_each(0.0, 6.0, 0.0, leftPad)
      |> set_gap(4.0)
      |> set_align(GuiAlign::GuiAlignCenter)
      |> set_bg(pickColor(isSel || isDropInside, fcGreenSoft(dark), fcPanel(dark)))
      |> set_border(pickFloat(isDropInside, 1.5, pickFloat(isDragSrc, 1.0, 0.0)), pickColor(isDropInside, fcGreen(), fcBorder(dark)))
      |> set_radius(6.0)
      |> on_click_tag(i) { -> ed.selected = gui::clickTag(); refreshInspectorLabels(&ed); return; };

    if (hasKids || isContainer) {
      auto expBtn = BBox::new()
        |> set_size(14px, 18px)
        |> set_align(GuiAlign::GuiAlignCenter)
        |> set_justify(GuiJustify::GuiJustifyCenter)
        |> set_radius(3.0)
        |> set_hover_bg(fcField(dark))
        |> on_click_tag(i) {
          -> int ni = gui::clickTag();
             if (ni >= 0 && ni < ed.count) { ed.nodes[ni].expanded = !ed.nodes[ni].expanded; }
             return;
        };
      expBtn.add(Icon::new()
        |> set_icon(pickText(ed.nodes[i].expanded, std::cui::icons::chevronDown(), std::cui::icons::chevronRight()))
        |> set_text_size(9.5)
        |> set_text_color(fcMutedText(dark)));
      nodeRow.add(expBtn);
    } else {
      nodeRow.add(BBox::new() |> set_size(14px, 14px));
    }

    nodeRow.add(Icon::new()
      |> set_icon(nodeGlyph(ed.nodes[i].kind))
      |> set_text_size(11.0)
      |> set_text_color(pickColor(isSel || isDropInside, fcGreenDark(), fcSecondaryText(dark))));

    nodeRow.add(Text::new()
      |> set_text(&ed.nodes[i].name[0])
      |> set_text_size(10.5)
      |> set_text_color(pickColor(vis, pickColor(isSel, fcText(dark), fcSecondaryText(dark)), fcMutedText(dark))));

    nodeRow.add(Spacer::new() |> set_size(fill(), 1px));

    auto visBtn = BBox::new()
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

    if (isDropBelow && scroll.childCount < 188) {
      scroll.add(BBox::new() |> set_size(fill(), 2px) |> set_bg(fcGreen()) |> set_radius(1.0));
    }
  }

  col.add(scroll);
  return col;
}

Widget* sectionPreviewCard(const char* wid, const char* name, int sectionKind, bool dark) {
  auto card = Column::new()
    |> set_id(wid)
    |> set_size(fill(), 86px)
    |> set_padding(7.0)
    |> set_gap(5.0)
    |> set_bg(fcCard(dark))
    |> set_hover_bg(fcGreenSoft(dark))
    |> set_border(1.0, fcDivider(dark))
    |> set_radius(7.0)
    |> set_tooltip("Drag onto canvas or click to add");

  auto preview = Column::new()
    |> set_size(fill(), 48px)
    |> set_padding(5.0)
    |> set_gap(3.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_bg(pickColor(sectionKind == 1 || sectionKind == 5, fcNavy(), fcField(dark)))
    |> set_radius(5.0);

  if (sectionKind == 0) {
    // Navbar miniature
    auto bar = Row::new() |> set_size(fill(), 14px) |> set_padding_xy(4.0, 0.0) |> set_gap(4.0) |> set_align(GuiAlign::GuiAlignCenter) |> set_bg(fcCard(dark)) |> set_radius(3.0);
    bar.add(BBox::new() |> set_size(6px, 6px) |> set_bg(fcGreen()) |> set_radius(3.0));
    bar.add(Spacer::new() |> set_size(fill(), 1px));
    bar.add(BBox::new() |> set_size(14px, 5px) |> set_bg(fcGreen()) |> set_radius(2.5));
    preview.add(bar);
  } else if (sectionKind == 1) {
    // Hero miniature
    preview.add(BBox::new() |> set_size(48px, 5px) |> set_bg(fcWhite()) |> set_radius(2.0));
    preview.add(BBox::new() |> set_size(62px, 3px) |> set_bg(fcChartMint()) |> set_radius(1.5));
    preview.add(BBox::new() |> set_size(24px, 8px) |> set_bg(fcGreen()) |> set_radius(4.0));
  } else if (sectionKind == 2) {
    // 3-Column Feature Cards miniature
    auto cols = Row::new() |> set_size(fill(), 26px) |> set_gap(4.0) |> set_align(GuiAlign::GuiAlignCenter);
    cols.add(BBox::new() |> set_size(fill(), 24px) |> set_bg(fcCard(dark)) |> set_border(1.0, fcBorder(dark)) |> set_radius(3.0));
    cols.add(BBox::new() |> set_size(fill(), 24px) |> set_bg(fcCard(dark)) |> set_border(1.0, fcBorder(dark)) |> set_radius(3.0));
    cols.add(BBox::new() |> set_size(fill(), 24px) |> set_bg(fcCard(dark)) |> set_border(1.0, fcBorder(dark)) |> set_radius(3.0));
    preview.add(cols);
  } else if (sectionKind == 3) {
    // Login form miniature
    auto box = Column::new() |> set_size(46px, 36px) |> set_padding(4.0) |> set_gap(3.0) |> set_bg(fcCard(dark)) |> set_border(1.0, fcBorder(dark)) |> set_radius(3.0);
    box.add(BBox::new() |> set_size(fill(), 6px) |> set_bg(fcField(dark)) |> set_radius(2.0));
    box.add(BBox::new() |> set_size(fill(), 6px) |> set_bg(fcField(dark)) |> set_radius(2.0));
    box.add(BBox::new() |> set_size(fill(), 7px) |> set_bg(fcGreen()) |> set_radius(2.5));
    preview.add(box);
  } else if (sectionKind == 4) {
    // KPI Analytics miniature
    preview.add(Row::new() |> set_size(fill(), 8px) |> set_gap(4.0) |> set_align(GuiAlign::GuiAlignCenter));
    preview.add(BBox::new() |> set_size(52px, 6px) |> set_bg(fcNavy()) |> set_radius(2.0));
    preview.add(BBox::new() |> set_size(64px, 12px) |> set_bg(fcGreenSoft(dark)) |> set_border(1.0, fcChartGreen()) |> set_radius(3.0));
  } else {
    // Footer miniature
    auto row = Row::new() |> set_size(fill(), 12px) |> set_padding_xy(4.0, 0.0) |> set_gap(4.0) |> set_align(GuiAlign::GuiAlignCenter);
    row.add(BBox::new() |> set_size(6px, 6px) |> set_bg(fcGreen()) |> set_radius(3.0));
    row.add(Spacer::new() |> set_size(fill(), 1px));
    row.add(BBox::new() |> set_size(12px, 3px) |> set_bg(fcChartMint()) |> set_radius(1.0));
    row.add(BBox::new() |> set_size(12px, 3px) |> set_bg(fcChartMint()) |> set_radius(1.0));
    preview.add(row);
  }

  card.add(preview);
  card.add(Text::new() |> set_text(name) |> set_text_size(9.5) |> set_text_color(fcSecondaryText(dark)));
  return card;
}

Widget* assetPreviewCard(const char* wid, const char* name, int assetKind, bool dark) {
  auto card = Column::new()
    |> set_id(wid)
    |> set_size(fill(), 82px)
    |> set_padding(7.0)
    |> set_gap(5.0)
    |> set_bg(fcCard(dark))
    |> set_hover_bg(fcGreenSoft(dark))
    |> set_border(1.0, fcDivider(dark))
    |> set_radius(7.0)
    |> set_tooltip("Drag onto canvas or click to add");

  auto preview = BBox::new()
    |> set_size(fill(), 44px)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_bg(fcField(dark))
    |> set_radius(5.0);

  if (assetKind == 0) {
    auto pill = BBox::new() |> set_size(58px, 18px) |> set_align(GuiAlign::GuiAlignCenter) |> set_justify(GuiJustify::GuiJustifyCenter) |> set_bg(fcGreen()) |> set_radius(9.0);
    pill.add(Text::new() |> set_text("Button") |> set_text_size(7.5) |> set_text_color(fcNavy()) |> set_font(gui::medium()));
    preview.add(pill);
  } else if (assetKind == 1) {
    auto pill = BBox::new() |> set_size(58px, 18px) |> set_align(GuiAlign::GuiAlignCenter) |> set_justify(GuiJustify::GuiJustifyCenter) |> set_bg(fcCard(dark)) |> set_border(1.0, fcBorder(dark)) |> set_radius(9.0);
    pill.add(Text::new() |> set_text("Outline") |> set_text_size(7.5) |> set_text_color(fcText(dark)));
    preview.add(pill);
  } else if (assetKind == 2) {
    auto miniCard = Column::new() |> set_size(56px, 28px) |> set_padding(4.0) |> set_gap(3.0) |> set_bg(fcCard(dark)) |> set_border(1.0, fcBorder(dark)) |> set_radius(4.0);
    miniCard.add(BBox::new() |> set_size(32px, 3px) |> set_bg(fcBorder(dark)) |> set_radius(1.0));
    miniCard.add(BBox::new() |> set_size(22px, 3px) |> set_bg(fcDivider(dark)) |> set_radius(1.0));
    preview.add(miniCard);
  } else if (assetKind == 3) {
    auto inp = BBox::new() |> set_size(64px, 18px) |> set_padding_xy(5.0, 0.0) |> set_align(GuiAlign::GuiAlignStart) |> set_justify(GuiJustify::GuiJustifyCenter) |> set_bg(fcCard(dark)) |> set_border(1.0, fcBorder(dark)) |> set_radius(4.0);
    inp.add(Text::new() |> set_text("Input...") |> set_text_size(7.5) |> set_text_color(fcMutedText(dark)));
    preview.add(inp);
  } else if (assetKind == 4) {
    auto tag = BBox::new() |> set_size(48px, 15px) |> set_align(GuiAlign::GuiAlignCenter) |> set_justify(GuiJustify::GuiJustifyCenter) |> set_bg(fcGreenSoft(dark)) |> set_radius(8.0);
    tag.add(Text::new() |> set_text("Active") |> set_text_size(7.0) |> set_text_color(fcGreenDark()) |> set_font(gui::medium()));
    preview.add(tag);
  } else if (assetKind == 5) {
    auto bars = Row::new() |> set_size(fit(), 26px) |> set_gap(3.0) |> set_align(GuiAlign::GuiAlignEnd);
    bars.add(BBox::new() |> set_size(5px, 12px) |> set_bg(fcChartGreen()) |> set_radius(1.0));
    bars.add(BBox::new() |> set_size(5px, 21px) |> set_bg(fcChartMint()) |> set_radius(1.0));
    bars.add(BBox::new() |> set_size(5px, 16px) |> set_bg(fcChartGreen()) |> set_radius(1.0));
    bars.add(BBox::new() |> set_size(5px, 24px) |> set_bg(fcChartBlue()) |> set_radius(1.0));
    preview.add(bars);
  } else if (assetKind == 6) {
    preview.add(Icon::new() |> set_icon(std::cui::icons::activity()) |> set_text_size(18.0) |> set_text_color(fcChartGreen()));
  } else if (assetKind == 7) {
    preview.add(BBox::new() |> set_size(24px, 24px) |> set_border(4.0, fcGreen()) |> set_radius(12.0));
  } else if (assetKind == 8) {
    auto av = BBox::new() |> set_size(24px, 24px) |> set_align(GuiAlign::GuiAlignCenter) |> set_justify(GuiJustify::GuiJustifyCenter) |> set_bg(fcNavy()) |> set_radius(12.0);
    av.add(Icon::new() |> set_icon(std::cui::icons::user()) |> set_text_size(12.0) |> set_text_color(fcWhite()));
    preview.add(av);
  } else if (assetKind == 9) {
    auto sw = Row::new() |> set_size(32px, 16px) |> set_padding(2.0) |> set_align(GuiAlign::GuiAlignCenter) |> set_justify(GuiJustify::GuiJustifyEnd) |> set_bg(fcGreen()) |> set_radius(8.0);
    sw.add(BBox::new() |> set_size(12px, 12px) |> set_bg(fcWhite()) |> set_radius(6.0));
    preview.add(sw);
  } else if (assetKind == 10) {
    preview.add(Icon::new() |> set_icon(std::cui::icons::sparkles()) |> set_text_size(16.0) |> set_text_color(fcChartBlue()));
  } else {
    preview.add(Icon::new() |> set_icon(std::cui::icons::message()) |> set_text_size(16.0) |> set_text_color(fcGreenDark()));
  }

  card.add(preview);
  card.add(Text::new() |> set_text(name) |> set_text_size(9.5) |> set_text_color(fcSecondaryText(dark)));
  return card;
}

Widget* buildAssetsTab(bool dark) {
  auto col = Column::new() |> set_size(fill(), fill()) |> set_gap(0.0);
  col.add(leftPanelHeader("Assets", "Sections & components", dark));
  col.add(Divider::new() |> set_size(fill(), 1px) |> set_bg(fcDivider(dark)));

  auto scroll = Scroll::new()
    |> set_id("fc-assets-scroll")
    |> set_size(fill(), fill())
    |> set_padding(12.0)
    |> set_gap(10.0);

  auto secRow = Row::new() |> set_size(fill(), 22px) |> set_align(GuiAlign::GuiAlignCenter);
  secRow.add(Text::new() |> set_text("Prebuilt Sections") |> set_text_size(10.5) |> set_text_color(fcText(dark)) |> set_font(gui::medium()));
  secRow.add(Spacer::new() |> set_size(fill(), 1px));
  secRow.add(Text::new() |> set_text("Drag or click") |> set_text_size(9.0) |> set_text_color(fcMutedText(dark)));
  scroll.add(secRow);

  auto secGrid = Grid::new() |> set_size(fill(), fit()) |> set_columns(2) |> set_gap(8.0);
  secGrid.add(sectionPreviewCard("fc-sec-navbar", "Navbar", 0, dark));
  secGrid.add(sectionPreviewCard("fc-sec-hero", "Hero Banner", 1, dark));
  secGrid.add(sectionPreviewCard("fc-sec-cards", "3-Col Cards", 2, dark));
  secGrid.add(sectionPreviewCard("fc-sec-login", "Login Card", 3, dark));
  secGrid.add(sectionPreviewCard("fc-sec-kpi", "KPI Stat", 4, dark));
  secGrid.add(sectionPreviewCard("fc-sec-footer", "Footer Bar", 5, dark));
  scroll.add(secGrid);

  scroll.add(Divider::new() |> set_size(fill(), 1px) |> set_bg(fcDivider(dark)));

  auto compRow = Row::new() |> set_size(fill(), 22px) |> set_align(GuiAlign::GuiAlignCenter);
  compRow.add(Text::new() |> set_text("Basic Components") |> set_text_size(10.5) |> set_text_color(fcText(dark)) |> set_font(gui::medium()));
  compRow.add(Spacer::new() |> set_size(fill(), 1px));
  compRow.add(Text::new() |> set_text("12 items") |> set_text_size(9.0) |> set_text_color(fcMutedText(dark)));
  scroll.add(compRow);

  auto grid = Grid::new() |> set_size(fill(), fit()) |> set_columns(2) |> set_gap(8.0);
  grid.add(assetPreviewCard("fc-asset-button", "Button", 0, dark));
  grid.add(assetPreviewCard("fc-asset-outline", "Outline Btn", 1, dark));
  grid.add(assetPreviewCard("fc-asset-card", "Card", 2, dark));
  grid.add(assetPreviewCard("fc-asset-input", "Input Field", 3, dark));
  grid.add(assetPreviewCard("fc-asset-badge", "Status Badge", 4, dark));
  grid.add(assetPreviewCard("fc-asset-chart", "Bar Chart", 5, dark));
  grid.add(assetPreviewCard("fc-asset-spark", "Sparkline", 6, dark));
  grid.add(assetPreviewCard("fc-asset-donut", "Donut Ring", 7, dark));
  grid.add(assetPreviewCard("fc-asset-avatar", "Avatar", 8, dark));
  grid.add(assetPreviewCard("fc-asset-toggle", "Toggle", 9, dark));
  grid.add(assetPreviewCard("fc-asset-image", "Image Frame", 10, dark));
  grid.add(assetPreviewCard("fc-asset-comment", "Comment Pin", 11, dark));
  scroll.add(grid);

  auto note = Column::new()
    |> set_size(fill(), fit())
    |> set_padding_xy(2.0, 4.0)
    |> set_gap(4.0);
  note.add(Text::new() |> set_text("Styles") |> set_text_size(10.5) |> set_text_color(fcSecondaryText(dark)) |> set_font(gui::medium()));
  note.add(Text::new()
    |> set_text("Colour, text, effect and grid styles drive both light and dark modes.")
    |> set_text_size(9.5)
    |> set_text_color(fcMutedText(dark))
    |> set_text_wrap(true)
    |> set_width(fill()));
  scroll.add(note);

  col.add(scroll);
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
    row.add(BBox::new()
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
    row.add(BBox::new()
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
