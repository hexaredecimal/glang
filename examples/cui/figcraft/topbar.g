// FigCraft Top Chrome Bar: Home button, Multi-Tab Document Strip,
// Light/Dark Theme Toggle, and Window Controls.

import std.gui;
import std.pipe;
import std.cui;
import examples.cui.figcraft.palette;
import examples.cui.figcraft.model;
import examples.cui.figcraft.actions;

Widget* buildDocTab(int idx, bool dark) {
  bool active = ed.activeTab == idx;
  Color bg = pickColor(active, fcCard(dark), gui::clear());
  Color bdr = pickColor(active, fcDivider(dark), gui::clear());
  float bw = pickFloat(active, 1.0, 0.0);

  auto tab = Row::new()
    |> set_size(236px, fill())
    |> set_padding_each(0.0, 8.0, 0.0, 12.0)
    |> set_gap(7.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_bg(bg)
    |> set_border(bw, bdr)
    |> set_corners(7.0, 7.0, 0.0, 0.0)
    |> on_click_tag(idx) { -> switchDocTab(&ed, gui::clickTag()); return; };

  tab.add(Icon::new()
    |> set_icon(std::cui::icons::layers())
    |> set_text_size(14.0)
    |> set_text_color(pickColor(active, fcGreenDark(), fcMutedText(dark))));

  tab.add(Text::new()
    |> set_text(&ed.tabs[idx].title[0])
    |> set_text_size(11.5)
    |> set_text_color(pickColor(active, fcText(dark), fcSecondaryText(dark))));

  tab.add(Spacer::new() |> set_size(fill(), 1px));

  auto closeTab = Box::new()
    |> set_size(20px, 20px)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_radius(5.0)
    |> set_hover_bg(fcField(dark))
    |> set_tooltip("Close tab")
    |> on_click_tag(idx) { -> closeDocTab(&ed, gui::clickTag()); return; };
  closeTab.add(Icon::new()
    |> set_icon(std::cui::icons::x())
    |> set_text_size(12.0)
    |> set_text_color(fcMutedText(dark)));
  tab.add(closeTab);

  return tab;
}

Widget* buildTopBar() {
  bool dark = ed.darkTheme;
  auto bar = Row::new()
    |> set_size(fill(), 50px)
    |> set_bg(fcChrome(dark))
    |> set_align(GuiAlign::GuiAlignCenter);

  // Home button above left rail
  auto homeBtn = Box::new()
    |> set_size(52px, fill())
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_hover_bg(fcField(dark))
    |> set_tooltip("Dashboard home")
    |> on_click() {
      -> switchDocTab(&ed, 0);
         switchPage(&ed, 0);
         gui::toast("Home", "Returned to Ridgeline Studio dashboard.");
         return;
    };
  homeBtn.add(Icon::new()
    |> set_icon(std::cui::icons::home())
    |> set_text_size(17.0)
    |> set_text_color(fcText(dark)));
  bar.add(homeBtn);

  // Document tabs
  for (int i = 0; i < ed.tabCount; i = i + 1) {
    bar.add(buildDocTab(i, dark));
  }

  // New tab '+' button
  auto newTab = Box::new()
    |> set_id("fc-new-tab")
    |> set_size(34px, fill())
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_hover_bg(fcField(dark))
    |> set_tooltip("New design file")
    |> on_click() { -> addNewDocTab(&ed); return; };
  newTab.add(Icon::new()
    |> set_icon(std::cui::icons::plus())
    |> set_text_size(15.0)
    |> set_text_color(fcSecondaryText(dark)));
  bar.add(newTab);

  bar.add(Spacer::new() |> set_size(fill(), 1px));

  // Theme toggle + Window controls
  auto winTools = Row::new()
    |> set_size(fit(), fill())
    |> set_padding_xy(8.0, 0.0)
    |> set_gap(4.0)
    |> set_align(GuiAlign::GuiAlignCenter);

  auto themeBtn = Box::new()
    |> set_id("fc-theme-btn")
    |> set_size(28px, 28px)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_radius(6.0)
    |> set_hover_bg(fcField(dark))
    |> set_tooltip(pickText(dark, "Switch to Light theme", "Switch to Dark theme"))
    |> on_click() { -> toggleThemeMode(&ed); return; };
  themeBtn.add(Icon::new()
    |> set_icon(std::cui::icons::sun())
    |> set_text_size(15.0)
    |> set_text_color(pickColor(dark, fcGreen(), fcSecondaryText(dark))));
  winTools.add(themeBtn);

  auto minBtn = Box::new()
    |> set_size(28px, 28px)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_radius(6.0)
    |> set_hover_bg(fcField(dark))
    |> set_tooltip("Minimize")
    |> on_click() { -> gui::minimize(); return; };
  minBtn.add(Icon::new()
    |> set_icon(std::cui::icons::minus())
    |> set_text_size(15.0)
    |> set_text_color(fcSecondaryText(dark)));
  winTools.add(minBtn);

  auto maxBtn = Box::new()
    |> set_size(28px, 28px)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_radius(6.0)
    |> set_hover_bg(fcField(dark))
    |> set_tooltip("Maximize")
    |> on_click() { -> gui::toggleMaximize(); return; };
  maxBtn.add(Icon::new()
    |> set_icon(std::cui::icons::maximize())
    |> set_text_size(14.0)
    |> set_text_color(fcSecondaryText(dark)));
  winTools.add(maxBtn);

  auto closeBtn = Box::new()
    |> set_size(28px, 28px)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_radius(6.0)
    |> set_hover_bg(fcDangerSoft(dark))
    |> set_tooltip("Close")
    |> on_click() { -> gui::quit(); return; };
  closeBtn.add(Icon::new()
    |> set_icon(std::cui::icons::x())
    |> set_text_size(15.0)
    |> set_text_color(fcSecondaryText(dark)));
  winTools.add(closeBtn);

  bar.add(winTools);
  return bar;
}
