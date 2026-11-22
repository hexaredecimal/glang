// FigCraft Left Navigation Rail: Brand Badge, File / Assets / Variables Switcher, and Help.

import std.gui;
import std.pipe;
import std.cui;
import examples.cui.figcraft.palette;
import examples.cui.figcraft.model;

Widget* railItem(const char* wid, const char* label, const char* glyph, int tabIndex, bool dark) {
  bool selected = ed.leftTab == tabIndex && !ed.leftCollapsed;
  auto item = Column::new()
    |> set_id(wid)
    |> set_size(fill(), 50px)
    |> set_gap(3.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_radius(6.0)
    |> set_bg(pickColor(selected, fcGreenSoft(dark), gui::clear()))
    |> set_hover_bg(fcField(dark))
    |> set_tooltip(label)
    |> on_click_tag(tabIndex) {
      -> int t = gui::clickTag();
         if (ed.leftTab == t && !ed.leftCollapsed) {
           ed.leftCollapsed = true;
         } else {
           ed.leftTab = t;
           ed.leftCollapsed = false;
         }
         return;
    };

  Color iconCol = pickColor(selected, fcGreenDark(), fcSecondaryText(dark));
  Color textCol = pickColor(selected, fcText(dark), fcSecondaryText(dark));
  item.add(Icon::new() |> set_icon(glyph) |> set_text_size(16.0) |> set_text_color(iconCol));
  item.add(Text::new() |> set_text(label) |> set_text_size(10.0) |> set_text_color(textCol));
  return item;
}

Widget* buildRail() {
  bool dark = ed.darkTheme;
  auto rail = Column::new()
    |> set_size(52px, fill())
    |> set_padding_each(9.0, 4.0, 8.0, 4.0)
    |> set_gap(4.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_bg(fcPanel(dark))
    |> set_border(1.0, fcDivider(dark));

  // Top FigCraft brand mark + subtle divider
  auto logo = Box::new()
    |> set_size(27px, 27px)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_bg(fcGreenSoft(dark))
    |> set_radius(8.0)
    |> set_tooltip("FigCraft Studio");
  logo.add(Icon::new() |> set_icon(std::cui::icons::star()) |> set_text_size(14.0) |> set_text_color(fcGreenDark()));
  rail.add(logo);

  auto logoGap = Column::new()
    |> set_size(fill(), 8px)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter);
  logoGap.add(Divider::new() |> set_size(22px, 1px) |> set_bg(fcDivider(dark)));
  rail.add(logoGap);

  rail.add(railItem("fc-rail-file", "File", std::cui::icons::file(), 0, dark));
  rail.add(railItem("fc-rail-assets", "Assets", std::cui::icons::grid(), 1, dark));
  rail.add(railItem("fc-rail-vars", "Variables", std::cui::icons::sliders(), 2, dark));

  rail.add(Spacer::new() |> set_size(fill(), fill()));

  auto helpBtn = Box::new()
    |> set_id("fc-rail-help")
    |> set_size(32px, 32px)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_radius(6.0)
    |> set_bg(pickColor(ed.showHelp, fcGreenSoft(dark), gui::clear()))
    |> set_hover_bg(fcField(dark))
    |> set_tooltip("Shortcuts & Help")
    |> on_click() { -> ed.showHelp = !ed.showHelp; return; };
  helpBtn.add(Icon::new()
    |> set_icon(std::cui::icons::help())
    |> set_text_size(15.0)
    |> set_text_color(pickColor(ed.showHelp, fcGreenDark(), fcMutedText(dark))));
  rail.add(helpBtn);

  return rail;
}
