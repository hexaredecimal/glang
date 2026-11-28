// FigCraft Start Page (Home Screen).
// 1:1 FigCraft workspace hub with Recents, Drafts, Templates, Design Systems,
// search filter, Grid/List toggle, open files, and 8 interactive starter templates.

import std.gui;
import std.pipe;
import std.cui;
import std.string;
import examples.cui.figcraft.palette;
import examples.cui.figcraft.model;
import examples.cui.figcraft.actions;

const char* templateTitleOf(int idx) {
  if (idx == 0) { return "Dashboard"; }
  if (idx == 1) { return "Mobile App"; }
  if (idx == 2) { return "Landing Page"; }
  if (idx == 3) { return "Design System"; }
  if (idx == 4) { return "Wireframe Kit"; }
  if (idx == 5) { return "Social Post Sizes"; }
  if (idx == 6) { return "Presentation Slides"; }
  return "Icon Set Starter";
}

const char* templateSubtitleOf(int idx) {
  if (idx == 0) { return "Analytics & KPIs · 1440x960"; }
  if (idx == 1) { return "iPhone 16 Pro · 390x844"; }
  if (idx == 2) { return "Hero & Feature Cards · 1440x960"; }
  if (idx == 3) { return "Tokens & UI Kit · 1440x960"; }
  if (idx == 4) { return "Low-fi Skeleton · 1440x960"; }
  if (idx == 5) { return "IG, Story & Banner Frames"; }
  if (idx == 6) { return "16:9 Q4 Deck · 1280x720"; }
  return "24px Vector Primitives · 1200x800";
}

const char* templateGlyphOf(int idx) {
  if (idx == 0) { return std::cui::icons::chartBar(); }
  if (idx == 1) { return std::cui::icons::compass(); }
  if (idx == 2) { return std::cui::icons::sparkles(); }
  if (idx == 3) { return std::cui::icons::sliders(); }
  if (idx == 4) { return std::cui::icons::grid(); }
  if (idx == 5) { return std::cui::icons::star(); }
  if (idx == 6) { return std::cui::icons::play(); }
  return std::cui::icons::pencil();
}

Color templateAccentOf(int idx, bool dark) {
  if (idx == 0) { return fcGreenSoft(dark); }
  if (idx == 1) { return fcNavy(); }
  if (idx == 2) { return fcBlueSoft(dark); }
  if (idx == 3) { return fcGreenSoft(dark); }
  if (idx == 4) { return fcField(dark); }
  if (idx == 5) { return fcWarningSoft(dark); }
  if (idx == 6) { return fcPurpleSoft(dark); }
  return fcGreenSoft(dark);
}

Color templateIconColorOf(int idx) {
  if (idx == 0) { return fcGreenDark(); }
  if (idx == 1) { return fcGreen(); }
  if (idx == 2) { return fcChartBlue(); }
  if (idx == 3) { return fcChartGreen(); }
  if (idx == 4) { return fcTitleMuted(); }
  if (idx == 5) { return fcWarning(); }
  if (idx == 6) { return fcPurple(); }
  return fcGreenDark();
}

Widget* homeNavItem(const char* wid, const char* label, const char* glyph, int tabIdx, bool dark) {
  bool sel = ed.homeTab == tabIdx;
  auto row = Row::new()
    |> set_id(wid)
    |> set_size(fill(), 34px)
    |> set_padding_xy(10.0, 0.0)
    |> set_gap(9.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_bg(pickColor(sel, fcGreenSoft(dark), gui::clear()))
    |> set_hover_bg(fcField(dark))
    |> set_radius(7.0)
    |> on_click_tag(tabIdx) { -> ed.homeTab = gui::clickTag(); return; };

  row.add(Icon::new()
    |> set_icon(glyph)
    |> set_text_size(14.0)
    |> set_text_color(pickColor(sel, fcGreenDark(), fcSecondaryText(dark))));
  row.add(Text::new()
    |> set_text(label)
    |> set_text_size(11.5)
    |> set_text_color(pickColor(sel, fcText(dark), fcSecondaryText(dark))));
  return row;
}

Widget* openFileCardGrid(int idx, bool dark) {
  bool cur = ed.activeTab == idx;
  bool dirty = ed.tabs[idx].dirty;
  const char* wid = if (idx == 0) "fc-home-file-0" else if (idx == 1) "fc-home-file-1" else if (idx == 2) "fc-home-file-2" else if (idx == 3) "fc-home-file-3" else if (idx == 4) "fc-home-file-4" else "fc-home-file-5";

  auto card = Column::new()
    |> set_id(wid)
    |> set_size(252px, 168px)
    |> set_bg(fcCard(dark))
    |> set_hover_bg(fcField(dark))
    |> set_border(pickFloat(cur, 1.5, 1.0), pickColor(cur, fcGreen(), fcDivider(dark)))
    |> set_radius(10.0)
    |> set_clip(true)
    |> on_click_tag(idx) { -> openTabFromHome(&ed, gui::clickTag()); return; };

  auto preview = Column::new()
    |> set_size(fill(), 104px)
    |> set_padding(12.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_bg(pickColor(idx % 2 == 0, fcGreenSoft(dark), fcBlueSoft(dark)));
  preview.add(Icon::new()
    |> set_icon(std::cui::icons::layers())
    |> set_text_size(24.0)
    |> set_text_color(pickColor(idx % 2 == 0, fcGreenDark(), fcChartBlue())));
  card.add(preview);

  auto meta = Column::new()
    |> set_size(fill(), fill())
    |> set_padding_xy(12.0, 8.0)
    |> set_gap(4.0)
    |> set_justify(GuiJustify::GuiJustifyCenter);

  auto titleRow = Row::new() |> set_size(fill(), fit()) |> set_gap(6.0) |> set_align(GuiAlign::GuiAlignCenter);
  titleRow.add(Text::new() |> set_text(&ed.tabs[idx].title[0]) |> set_text_size(11.5) |> set_text_color(fcText(dark)) |> set_font(gui::medium()));
  titleRow.add(Spacer::new() |> set_size(fill(), 1px));
  if (dirty) {
    titleRow.add(BBox::new() |> set_size(7px, 7px) |> set_bg(fcWarning()) |> set_radius(4.0));
  }
  meta.add(titleRow);

  const char* statusTxt = pickText(dirty, "Unsaved edits", pickText(cur, "Active tab · Saved", "Open tab · Saved"));
  meta.add(Text::new() |> set_text(statusTxt) |> set_text_size(9.5) |> set_text_color(fcMutedText(dark)));
  card.add(meta);

  return card;
}

Widget* openFileCardList(int idx, bool dark) {
  bool cur = ed.activeTab == idx;
  bool dirty = ed.tabs[idx].dirty;
  const char* wid = if (idx == 0) "fc-home-lfile-0" else if (idx == 1) "fc-home-lfile-1" else if (idx == 2) "fc-home-lfile-2" else if (idx == 3) "fc-home-lfile-3" else if (idx == 4) "fc-home-lfile-4" else "fc-home-lfile-5";

  auto row = Row::new()
    |> set_id(wid)
    |> set_size(fill(), 44px)
    |> set_padding_xy(12.0, 0.0)
    |> set_gap(10.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_bg(fcCard(dark))
    |> set_hover_bg(fcField(dark))
    |> set_border(1.0, pickColor(cur, fcGreen(), fcDivider(dark)))
    |> set_radius(8.0)
    |> on_click_tag(idx) { -> openTabFromHome(&ed, gui::clickTag()); return; };

  row.add(Icon::new() |> set_icon(std::cui::icons::layers()) |> set_text_size(14.0) |> set_text_color(fcGreenDark()));
  row.add(Text::new() |> set_text(&ed.tabs[idx].title[0]) |> set_text_size(11.5) |> set_text_color(fcText(dark)) |> set_font(gui::medium()));
  row.add(Spacer::new() |> set_size(fill(), 1px));
  row.add(Text::new() |> set_text(pickText(dirty, "Unsaved", "Saved")) |> set_text_size(10.0) |> set_text_color(pickColor(dirty, fcWarning(), fcGreenDark())));
  return row;
}

Widget* templateCardGrid(int idx, bool dark) {
  const char* wid = if (idx == 0) "fc-tmpl-0" else if (idx == 1) "fc-tmpl-1" else if (idx == 2) "fc-tmpl-2" else if (idx == 3) "fc-tmpl-3" else if (idx == 4) "fc-tmpl-4" else if (idx == 5) "fc-tmpl-5" else if (idx == 6) "fc-tmpl-6" else "fc-tmpl-7";

  auto card = Column::new()
    |> set_id(wid)
    |> set_size(252px, 162px)
    |> set_bg(fcCard(dark))
    |> set_hover_bg(fcField(dark))
    |> set_border(1.0, fcDivider(dark))
    |> set_radius(10.0)
    |> set_clip(true)
    |> on_click_tag(idx) {
      -> int t = gui::clickTag();
         openTemplateFile(&ed, t, templateTitleOf(t));
         return;
    };

  auto thumb = Column::new()
    |> set_size(fill(), 98px)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_bg(templateAccentOf(idx, dark));
  thumb.add(Icon::new()
    |> set_icon(templateGlyphOf(idx))
    |> set_text_size(26.0)
    |> set_text_color(templateIconColorOf(idx)));
  card.add(thumb);

  auto info = Column::new()
    |> set_size(fill(), fill())
    |> set_padding_xy(12.0, 8.0)
    |> set_gap(3.0)
    |> set_justify(GuiJustify::GuiJustifyCenter);
  info.add(Text::new() |> set_text(templateTitleOf(idx)) |> set_text_size(11.5) |> set_text_color(fcText(dark)) |> set_font(gui::medium()));
  info.add(Text::new() |> set_text(templateSubtitleOf(idx)) |> set_text_size(9.5) |> set_text_color(fcMutedText(dark)));
  card.add(info);

  return card;
}

Widget* templateCardList(int idx, bool dark) {
  const char* wid = if (idx == 0) "fc-ltmpl-0" else if (idx == 1) "fc-ltmpl-1" else if (idx == 2) "fc-ltmpl-2" else if (idx == 3) "fc-ltmpl-3" else if (idx == 4) "fc-ltmpl-4" else if (idx == 5) "fc-ltmpl-5" else if (idx == 6) "fc-ltmpl-6" else "fc-ltmpl-7";

  auto row = Row::new()
    |> set_id(wid)
    |> set_size(fill(), 44px)
    |> set_padding_xy(12.0, 0.0)
    |> set_gap(10.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_bg(fcCard(dark))
    |> set_hover_bg(fcField(dark))
    |> set_border(1.0, fcDivider(dark))
    |> set_radius(8.0)
    |> on_click_tag(idx) {
      -> int t = gui::clickTag();
         openTemplateFile(&ed, t, templateTitleOf(t));
         return;
    };

  auto dot = BBox::new()
    |> set_size(24px, 24px)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_bg(templateAccentOf(idx, dark))
    |> set_radius(6.0);
  dot.add(Icon::new() |> set_icon(templateGlyphOf(idx)) |> set_text_size(12.5) |> set_text_color(templateIconColorOf(idx)));
  row.add(dot);

  row.add(Text::new() |> set_text(templateTitleOf(idx)) |> set_text_size(11.5) |> set_text_color(fcText(dark)) |> set_font(gui::medium()));
  row.add(Spacer::new() |> set_size(fill(), 1px));
  row.add(Text::new() |> set_text(templateSubtitleOf(idx)) |> set_text_size(9.5) |> set_text_color(fcMutedText(dark)));
  return row;
}

Widget* buildHomePage(bool dark) {
  auto shell = Row::new()
    |> set_size(fill(), fill())
    |> set_gap(0.0)
    |> set_bg(fcCanvas(dark));

  // Left Workspace Sidebar
  auto sidebar = Column::new()
    |> set_size(232px, fill())
    |> set_padding(14.0)
    |> set_gap(8.0)
    |> set_bg(fcPanel(dark))
    |> set_border(1.0, fcDivider(dark));

  auto brandRow = Row::new()
    |> set_id("fc-rail-logo")
    |> set_size(fill(), 40px)
    |> set_padding_xy(6.0, 0.0)
    |> set_gap(10.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_hover_bg(fcField(dark))
    |> set_radius(8.0)
    |> set_tooltip("FigCraft menu")
    |> on_click() { -> ed.showMainMenu = !ed.showMainMenu; return; };

  auto starBadge = BBox::new()
    |> set_size(28px, 28px)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_bg(pickColor(ed.showMainMenu, fcGreen(), fcGreenSoft(dark)))
    |> set_radius(8.0);
  starBadge.add(Icon::new()
    |> set_icon(std::cui::icons::star())
    |> set_text_size(14.0)
    |> set_text_color(pickColor(ed.showMainMenu, fcNavy(), fcGreenDark())));
  brandRow.add(starBadge);

  auto brandTexts = Column::new() |> set_size(fill(), fit()) |> set_gap(1.0);
  brandTexts.add(Text::new() |> set_text("FigCraft") |> set_text_size(12.5) |> set_text_color(fcText(dark)) |> set_font(gui::medium()));
  brandTexts.add(Text::new() |> set_text("ArtCraft Studio") |> set_text_size(9.5) |> set_text_color(fcMutedText(dark)));
  brandRow.add(brandTexts);
  brandRow.add(Icon::new() |> set_icon(std::cui::icons::chevronDown()) |> set_text_size(11.0) |> set_text_color(fcMutedText(dark)));
  sidebar.add(brandRow);

  sidebar.add(Divider::new() |> set_size(fill(), 1px) |> set_bg(fcDivider(dark)));

  sidebar.add(homeNavItem("fc-home-nav-0", "Recents", std::cui::icons::clock(), 0, dark));
  sidebar.add(homeNavItem("fc-home-nav-1", "Drafts", std::cui::icons::file(), 1, dark));
  sidebar.add(homeNavItem("fc-home-nav-2", "Templates", std::cui::icons::layers(), 2, dark));
  sidebar.add(homeNavItem("fc-home-nav-3", "Design Systems", std::cui::icons::sliders(), 3, dark));

  sidebar.add(Divider::new() |> set_size(fill(), 1px) |> set_bg(fcDivider(dark)));

  auto newBtn = Row::new()
    |> set_id("fc-home-new-file")
    |> set_size(fill(), 34px)
    |> set_gap(6.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_bg(fcGreen())
    |> set_hover_bg(fcGreenDark())
    |> set_radius(8.0)
    |> on_click() { -> openNewDesignFile(&ed); return; };
  newBtn.add(Icon::new() |> set_icon(std::cui::icons::plus()) |> set_text_size(13.5) |> set_text_color(fcNavy()));
  newBtn.add(Text::new() |> set_text("New design file") |> set_text_size(11.5) |> set_text_color(fcNavy()) |> set_font(gui::medium()));
  sidebar.add(newBtn);

  auto tmplBtn = Row::new()
    |> set_id("fc-home-browse-tmpl")
    |> set_size(fill(), 32px)
    |> set_gap(6.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_bg(fcField(dark))
    |> set_hover_bg(fcDivider(dark))
    |> set_radius(8.0)
    |> on_click() { -> ed.homeTab = 2; return; };
  tmplBtn.add(Icon::new() |> set_icon(std::cui::icons::layers()) |> set_text_size(13.0) |> set_text_color(fcText(dark)));
  tmplBtn.add(Text::new() |> set_text("Browse templates") |> set_text_size(11.0) |> set_text_color(fcText(dark)));
  sidebar.add(tmplBtn);

  sidebar.add(Spacer::new() |> set_size(fill(), fill()));

  auto footer = Row::new()
    |> set_size(fill(), 30px)
    |> set_padding_xy(8.0, 0.0)
    |> set_gap(7.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_bg(fcField(dark))
    |> set_radius(7.0);
  footer.add(BBox::new() |> set_size(8px, 8px) |> set_bg(fcGreen()) |> set_radius(4.0));
  footer.add(Text::new() |> set_text("Local workspace ready") |> set_text_size(10.0) |> set_text_color(fcSecondaryText(dark)));
  sidebar.add(footer);

  shell.add(sidebar);

  // Main Content Pane
  auto main = Column::new()
    |> set_size(fill(), fill())
    |> set_padding(22.0)
    |> set_gap(16.0);

  // Header + search + grid/list toggle
  auto topRow = Row::new() |> set_size(fill(), 36px) |> set_gap(10.0) |> set_align(GuiAlign::GuiAlignCenter);
  const char* heading = if (ed.homeTab == 0) "Recents" else if (ed.homeTab == 1) "Drafts" else if (ed.homeTab == 2) "Starter Templates" else "Design Systems";
  topRow.add(Text::new() |> set_text(heading) |> set_text_size(17.0) |> set_text_color(fcText(dark)) |> set_font(gui::medium()));
  topRow.add(Spacer::new() |> set_size(fill(), 1px));

  topRow.add(Input::new()
    |> set_id("fc-home-search")
    |> set_placeholder("Search files and templates...")
    |> set_buffer(&ed.homeSearch[0], 64)
    |> set_size(240px, 30px));

  auto viewPill = Row::new()
    |> set_size(fit(), 30px)
    |> set_padding(2.0)
    |> set_gap(2.0)
    |> set_bg(fcCard(dark))
    |> set_border(1.0, fcDivider(dark))
    |> set_radius(7.0);

  auto gridBtn = BBox::new()
    |> set_id("fc-home-grid")
    |> set_size(28px, 24px)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_bg(pickColor(ed.homeGridView, fcGreenSoft(dark), gui::clear()))
    |> set_radius(5.0)
    |> set_tooltip("Grid view")
    |> on_click() { -> ed.homeGridView = true; return; };
  gridBtn.add(Icon::new() |> set_icon(std::cui::icons::grid()) |> set_text_size(13.0) |> set_text_color(pickColor(ed.homeGridView, fcGreenDark(), fcMutedText(dark))));
  viewPill.add(gridBtn);

  auto listBtn = BBox::new()
    |> set_id("fc-home-list")
    |> set_size(28px, 24px)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_bg(pickColor(!ed.homeGridView, fcGreenSoft(dark), gui::clear()))
    |> set_radius(5.0)
    |> set_tooltip("List view")
    |> on_click() { -> ed.homeGridView = false; return; };
  listBtn.add(Icon::new() |> set_icon(std::cui::icons::layers()) |> set_text_size(13.0) |> set_text_color(pickColor(!ed.homeGridView, fcGreenDark(), fcMutedText(dark))));
  viewPill.add(listBtn);

  topRow.add(viewPill);
  main.add(topRow);

  auto scroll = Scroll::new()
    |> set_id("fc-home-scroll")
    |> set_size(fill(), fill())
    |> set_gap(18.0);

  if (ed.homeTab == 0 || ed.homeTab == 1) {
    scroll.add(Text::new() |> set_text("Open design files") |> set_text_size(11.5) |> set_text_color(fcSecondaryText(dark)) |> set_font(gui::medium()));
    if (ed.homeGridView) {
      auto fileRow = Row::new() |> set_size(fill(), fit()) |> set_gap(14.0) |> set_wrap(true);
      for (int i = 0; i < ed.tabCount; i = i + 1) {
        if (std::string::contains_ignore_case(&ed.tabs[i].title[0], &ed.homeSearch[0])) {
          fileRow.add(openFileCardGrid(i, dark));
        }
      }
      scroll.add(fileRow);
    } else {
      auto fileCol = Column::new() |> set_size(fill(), fit()) |> set_gap(6.0);
      for (int i = 0; i < ed.tabCount; i = i + 1) {
        if (std::string::contains_ignore_case(&ed.tabs[i].title[0], &ed.homeSearch[0])) {
          fileCol.add(openFileCardList(i, dark));
        }
      }
      scroll.add(fileCol);
    }
  }

  if (ed.homeTab != 1) {
    const char* tmplHeading = if (ed.homeTab == 3) "Design System & UI Kits" else "Start from a template";
    scroll.add(Text::new() |> set_text(tmplHeading) |> set_text_size(11.5) |> set_text_color(fcSecondaryText(dark)) |> set_font(gui::medium()));

    if (ed.homeGridView) {
      auto tmplGrid = Row::new() |> set_size(fill(), fit()) |> set_gap(14.0) |> set_wrap(true);
      for (int t = 0; t < 8; t = t + 1) {
        if (ed.homeTab == 3 && t != 3 && t != 4 && t != 7 && t != 0) { continue; }
        if (std::string::contains_ignore_case(templateTitleOf(t), &ed.homeSearch[0]) || std::string::contains_ignore_case(templateSubtitleOf(t), &ed.homeSearch[0])) {
          tmplGrid.add(templateCardGrid(t, dark));
        }
      }
      scroll.add(tmplGrid);
    } else {
      auto tmplList = Column::new() |> set_size(fill(), fit()) |> set_gap(6.0);
      for (int t = 0; t < 8; t = t + 1) {
        if (ed.homeTab == 3 && t != 3 && t != 4 && t != 7 && t != 0) { continue; }
        if (std::string::contains_ignore_case(templateTitleOf(t), &ed.homeSearch[0]) || std::string::contains_ignore_case(templateSubtitleOf(t), &ed.homeSearch[0])) {
          tmplList.add(templateCardList(t, dark));
        }
      }
      scroll.add(tmplList);
    }
  }

  main.add(scroll);
  shell.add(main);
  return shell;
}
