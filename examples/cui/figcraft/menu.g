// FigCraft Star Icon Main Menu Popup and File Management / Exit Modals.
// Provides 1:1 ArtCraft FigCraft file management, workspace view toggles,
// Save Local Copy, Export, and Unsaved Changes Exit confirmation.

import std.gui;
import std.pipe;
import std.cui;
import examples.cui.figcraft.palette;
import examples.cui.figcraft.model;
import examples.cui.figcraft.actions;

Widget* menuRow(const char* wid, const char* glyph, const char* label,
                const char* shortcut, bool checked, bool danger,
                int actionTag, bool dark) {
  Color ink = pickColor(danger, fcDanger(), fcText(dark));
  Color iconInk = pickColor(danger, fcDanger(), pickColor(checked, fcGreenDark(), fcSecondaryText(dark)));
  Color hoverCol = pickColor(danger, fcDangerSoft(dark), fcField(dark));

  auto row = Row::new()
    |> set_id(wid)
    |> set_size(fill(), 30px)
    |> set_padding_xy(8.0, 0.0)
    |> set_gap(8.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_hover_bg(hoverCol)
    |> set_radius(6.0)
    |> on_click_tag(actionTag) {
      -> int act = gui::clickTag();
         if (act == 0) {
           goHome(&ed);
         } else if (act == 1) {
           ed.showMainMenu = false;
           if (!ed.showHome) { ed.showActions = !ed.showActions; }
         } else if (act == 2) {
           openNewDesignFile(&ed);
         } else if (act == 3) {
           goHome(&ed);
           ed.homeTab = 2;
         } else if (act == 4) {
           goHome(&ed);
           ed.homeTab = 0;
         } else if (act == 5) {
           saveActiveDocument(&ed);
         } else if (act == 6) {
           openSaveLocalCopyModal(&ed);
         } else if (act == 7) {
           ed.showMainMenu = false;
           ed.showExportModal = true;
         } else if (act == 8) {
           ed.showGrid = !ed.showGrid;
           ed.showMainMenu = false;
         } else if (act == 9) {
           ed.outlineMode = !ed.outlineMode;
           ed.showMainMenu = false;
         } else if (act == 10) {
           toggleThemeMode(&ed);
           ed.showMainMenu = false;
         } else if (act == 11) {
           ed.showHelp = !ed.showHelp;
           ed.showMainMenu = false;
         } else if (act == 12) {
           closeActiveTabOrHome(&ed);
         } else if (act == 13) {
           requestExitFigcraft(&ed);
         } else if (act == 14) {
           toggleSnapping(&ed);
           ed.showMainMenu = false;
         }
         return;
    };

  auto checkBox = BBox::new()
    |> set_size(14px, 14px)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter);
  if (checked) {
    checkBox.add(Icon::new()
      |> set_icon(std::cui::icons::check())
      |> set_text_size(11.0)
      |> set_text_color(fcGreenDark()));
  }
  row.add(checkBox);

  row.add(Icon::new()
    |> set_icon(glyph)
    |> set_text_size(13.5)
    |> set_text_color(iconInk));

  row.add(Text::new()
    |> set_text(label)
    |> set_text_size(11.0)
    |> set_text_color(ink));

  row.add(Spacer::new() |> set_size(fill(), 1px));

  if (shortcut[0] != '\0') {
    row.add(Text::new()
      |> set_text(shortcut)
      |> set_text_size(9.5)
      |> set_text_color(fcMutedText(dark))
      |> set_font(gui::mono()));
  }

  return row;
}

Widget* buildMainMenuPopup(bool dark) {
  bool unsaved = hasAnyUnsavedWork(&ed);
  const char* statusTxt = pickText(unsaved, "Unsaved", "Saved");
  Color statusBg = pickColor(unsaved, fcWarningSoft(dark), fcGreenSoft(dark));
  Color statusFg = pickColor(unsaved, fcWarning(), fcGreenDark());

  auto overlay = Column::new()
    |> set_size(fill(), fill())
    |> set_padding_each(54.0, 0.0, 0.0, 56.0)
    |> set_align(GuiAlign::GuiAlignStart)
    |> set_justify(GuiJustify::GuiJustifyStart);

  auto card = Column::new()
    |> set_id("fc-main-menu")
    |> set_size(258px, fit())
    |> set_padding(8.0)
    |> set_gap(2.0)
    |> set_bg(fcCard(dark))
    |> set_border(1.0, fcDivider(dark))
    |> set_radius(11.0)
    |> set_elevation(GuiElevation::GuiElevationFloating);

  // Header strip
  auto header = Row::new()
    |> set_size(fill(), 34px)
    |> set_padding_xy(8.0, 0.0)
    |> set_gap(8.0)
    |> set_align(GuiAlign::GuiAlignCenter);
  auto badge = BBox::new()
    |> set_size(22px, 22px)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_bg(fcGreenSoft(dark))
    |> set_radius(6.0);
  badge.add(Icon::new() |> set_icon(std::cui::icons::star()) |> set_text_size(12.0) |> set_text_color(fcGreenDark()));
  header.add(badge);
  header.add(Text::new() |> set_text("FigCraft Studio") |> set_text_size(11.5) |> set_text_color(fcText(dark)) |> set_font(gui::medium()));
  header.add(Spacer::new() |> set_size(fill(), 1px));

  auto pill = BBox::new()
    |> set_size(fit(), 18px)
    |> set_padding_xy(6.0, 0.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_bg(statusBg)
    |> set_radius(4.0);
  pill.add(Text::new() |> set_text(statusTxt) |> set_text_size(9.0) |> set_text_color(statusFg) |> set_font(gui::medium()));
  header.add(pill);
  card.add(header);

  card.add(Divider::new() |> set_size(fill(), 1px) |> set_bg(fcDivider(dark)));

  // Navigation
  card.add(menuRow("fc-mm-home", std::cui::icons::home(), "Back to files", "Esc", false, false, 0, dark));
  card.add(menuRow("fc-mm-actions", std::cui::icons::zap(), "Quick actions...", "K", false, false, 1, dark));

  card.add(Divider::new() |> set_size(fill(), 1px) |> set_bg(fcDivider(dark)));

  // File Management
  card.add(menuRow("fc-mm-new", std::cui::icons::plus(), "New design file", "Ctrl+N", false, false, 2, dark));
  card.add(menuRow("fc-mm-tmpl", std::cui::icons::layers(), "New from template...", "", false, false, 3, dark));
  card.add(menuRow("fc-mm-open", std::cui::icons::folderOpen(), "Open...", "Ctrl+O", false, false, 4, dark));
  card.add(menuRow("fc-mm-save", std::cui::icons::save(), "Save", "Ctrl+S", false, false, 5, dark));
  card.add(menuRow("fc-mm-saveas", std::cui::icons::copy(), "Save local copy...", "Shift+S", false, false, 6, dark));
  card.add(menuRow("fc-mm-export", std::cui::icons::download(), "Export...", "Ctrl+E", false, false, 7, dark));

  card.add(Divider::new() |> set_size(fill(), 1px) |> set_bg(fcDivider(dark)));

  // View & Preferences
  card.add(menuRow("fc-mm-grid", std::cui::icons::grid(), "Show layout grid", "G", ed.showGrid, false, 8, dark));
  card.add(menuRow("fc-mm-snap", std::cui::icons::target(), "Smart snapping & guides", "N", ed.snapEnabled, false, 14, dark));
  card.add(menuRow("fc-mm-wire", std::cui::icons::box(), "Wireframe outlines", "", ed.outlineMode, false, 9, dark));
  card.add(menuRow("fc-mm-theme", std::cui::icons::sun(), "Dark theme", "", ed.darkTheme, false, 10, dark));
  card.add(menuRow("fc-mm-help", std::cui::icons::help(), "Keyboard shortcuts", "?", ed.showHelp, false, 11, dark));

  card.add(Divider::new() |> set_size(fill(), 1px) |> set_bg(fcDivider(dark)));

  // Tab & Exit
  card.add(menuRow("fc-mm-closetab", std::cui::icons::fileText(), "Close tab", "Ctrl+W", false, false, 12, dark));
  card.add(menuRow("fc-mm-exit", std::cui::icons::x(), "Exit FigCraft", "Alt+F4", false, true, 13, dark));

  overlay.add(card);
  return overlay;
}

Widget* buildExitModal(bool dark) {
  auto backdrop = Column::new()
    |> set_size(fill(), fill())
    |> set_bg(gui::rgba(15, 23, 38, 125))
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter);

  auto modal = Column::new()
    |> set_id("fc-exit-modal")
    |> set_size(400px, fit())
    |> set_padding(18.0)
    |> set_gap(12.0)
    |> set_bg(fcCard(dark))
    |> set_border(1.0, fcDivider(dark))
    |> set_radius(12.0)
    |> set_elevation(GuiElevation::GuiElevationFloating);

  auto top = Row::new() |> set_size(fill(), fit()) |> set_gap(10.0) |> set_align(GuiAlign::GuiAlignCenter);
  auto warnBadge = BBox::new()
    |> set_size(34px, 34px)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_bg(fcWarningSoft(dark))
    |> set_radius(8.0);
  warnBadge.add(Icon::new() |> set_icon(std::cui::icons::save()) |> set_text_size(16.0) |> set_text_color(fcWarning()));
  top.add(warnBadge);

  auto titles = Column::new() |> set_size(fill(), fit()) |> set_gap(2.0);
  titles.add(Text::new() |> set_text("Unsaved changes in FigCraft") |> set_text_size(13.5) |> set_text_color(fcText(dark)) |> set_font(gui::medium()));
  titles.add(Text::new() |> set_text(&ed.tabs[ed.activeTab].title[0]) |> set_text_size(10.5) |> set_text_color(fcMutedText(dark)));
  top.add(titles);
  modal.add(top);

  modal.add(Text::new()
    |> set_text("You have edits that have not been saved. Save your workspace before closing FigCraft?")
    |> set_text_size(11.5)
    |> set_text_color(fcSecondaryText(dark))
    |> set_text_wrap(true)
    |> set_size(fill(), fit()));

  modal.add(Divider::new() |> set_size(fill(), 1px) |> set_bg(fcDivider(dark)));

  auto actions = Row::new() |> set_size(fill(), 34px) |> set_gap(8.0) |> set_align(GuiAlign::GuiAlignCenter);
  actions.add(Spacer::new() |> set_size(fill(), 1px));

  auto cancelBtn = BBox::new()
    |> set_id("fc-exit-cancel")
    |> set_size(fit(), 32px)
    |> set_padding_xy(12.0, 0.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_bg(fcField(dark))
    |> set_hover_bg(fcDivider(dark))
    |> set_radius(7.0)
    |> on_click() { -> ed.showExitPrompt = false; return; };
  cancelBtn.add(Text::new() |> set_text("Cancel") |> set_text_size(11.0) |> set_text_color(fcText(dark)));
  actions.add(cancelBtn);

  auto discardBtn = BBox::new()
    |> set_id("fc-exit-discard")
    |> set_size(fit(), 32px)
    |> set_padding_xy(12.0, 0.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_bg(fcDangerSoft(dark))
    |> set_hover_bg(fcDangerSoft(dark))
    |> set_radius(7.0)
    |> on_click() { -> ed.showExitPrompt = false; gui::quit(); return; };
  discardBtn.add(Text::new() |> set_text("Close without saving") |> set_text_size(11.0) |> set_text_color(fcDanger()) |> set_font(gui::medium()));
  actions.add(discardBtn);

  auto saveExitBtn = BBox::new()
    |> set_id("fc-exit-save")
    |> set_size(fit(), 32px)
    |> set_padding_xy(14.0, 0.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_bg(fcGreen())
    |> set_hover_bg(fcGreenDark())
    |> set_radius(7.0)
    |> on_click() {
      -> saveActiveDocument(&ed);
         ed.showExitPrompt = false;
         gui::quit();
         return;
    };
  saveExitBtn.add(Text::new() |> set_text("Save & Exit") |> set_text_size(11.0) |> set_text_color(fcNavy()) |> set_font(gui::medium()));
  actions.add(saveExitBtn);

  modal.add(actions);
  backdrop.add(modal);
  return backdrop;
}

Widget* buildSaveAsModal(bool dark) {
  auto backdrop = Column::new()
    |> set_size(fill(), fill())
    |> set_bg(gui::rgba(15, 23, 38, 125))
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter);

  auto modal = Column::new()
    |> set_id("fc-save-modal")
    |> set_size(380px, fit())
    |> set_padding(18.0)
    |> set_gap(12.0)
    |> set_bg(fcCard(dark))
    |> set_border(1.0, fcDivider(dark))
    |> set_radius(12.0)
    |> set_elevation(GuiElevation::GuiElevationFloating);

  modal.add(Text::new() |> set_text("Save local copy") |> set_text_size(13.5) |> set_text_color(fcText(dark)) |> set_font(gui::medium()));
  modal.add(Text::new() |> set_text("Duplicate the active file into a new local design tab.") |> set_text_size(11.0) |> set_text_color(fcSecondaryText(dark)));

  modal.add(Input::new()
    |> set_id("fc-save-name-input")
    |> set_placeholder("File name...")
    |> set_buffer(&ed.saveAsName[0], 48)
    |> set_size(fill(), 32px));

  auto actions = Row::new() |> set_size(fill(), 34px) |> set_gap(8.0) |> set_align(GuiAlign::GuiAlignCenter);
  actions.add(Spacer::new() |> set_size(fill(), 1px));

  auto cancelBtn = BBox::new()
    |> set_id("fc-save-cancel")
    |> set_size(fit(), 30px)
    |> set_padding_xy(12.0, 0.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_bg(fcField(dark))
    |> set_radius(7.0)
    |> on_click() { -> ed.showSaveAsModal = false; return; };
  cancelBtn.add(Text::new() |> set_text("Cancel") |> set_text_size(11.0) |> set_text_color(fcText(dark)));
  actions.add(cancelBtn);

  auto okBtn = BBox::new()
    |> set_id("fc-save-confirm")
    |> set_size(fit(), 30px)
    |> set_padding_xy(14.0, 0.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_bg(fcGreen())
    |> set_radius(7.0)
    |> on_click() { -> confirmSaveLocalCopy(&ed); return; };
  okBtn.add(Text::new() |> set_text("Save copy") |> set_text_size(11.0) |> set_text_color(fcNavy()) |> set_font(gui::medium()));
  actions.add(okBtn);

  modal.add(actions);
  backdrop.add(modal);
  return backdrop;
}

Widget* exportFormatRow(const char* wid, int fmtIdx, const char* title, const char* subtitle, bool dark) {
  bool sel = ed.exportFormat == fmtIdx;
  auto row = Row::new()
    |> set_id(wid)
    |> set_size(fill(), 38px)
    |> set_padding_xy(10.0, 0.0)
    |> set_gap(10.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_bg(pickColor(sel, fcGreenSoft(dark), fcField(dark)))
    |> set_border(pickFloat(sel, 1.5, 1.0), pickColor(sel, fcGreen(), fcDivider(dark)))
    |> set_radius(8.0)
    |> on_click_tag(fmtIdx) { -> ed.exportFormat = gui::clickTag(); return; };

  row.add(Icon::new()
    |> set_icon(pickText(fmtIdx == 3, std::cui::icons::code(), std::cui::icons::download()))
    |> set_text_size(14.0)
    |> set_text_color(pickColor(sel, fcGreenDark(), fcSecondaryText(dark))));

  auto texts = Column::new() |> set_size(fill(), fit()) |> set_gap(1.0);
  texts.add(Text::new() |> set_text(title) |> set_text_size(11.0) |> set_text_color(fcText(dark)) |> set_font(gui::medium()));
  texts.add(Text::new() |> set_text(subtitle) |> set_text_size(9.5) |> set_text_color(fcMutedText(dark)));
  row.add(texts);

  if (sel) {
    row.add(Icon::new() |> set_icon(std::cui::icons::check()) |> set_text_size(13.0) |> set_text_color(fcGreenDark()));
  }
  return row;
}

Widget* buildExportModal(bool dark) {
  auto backdrop = Column::new()
    |> set_size(fill(), fill())
    |> set_bg(gui::rgba(15, 23, 38, 125))
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter);

  auto modal = Column::new()
    |> set_id("fc-export-modal")
    |> set_size(390px, fit())
    |> set_padding(18.0)
    |> set_gap(10.0)
    |> set_bg(fcCard(dark))
    |> set_border(1.0, fcDivider(dark))
    |> set_radius(12.0)
    |> set_elevation(GuiElevation::GuiElevationFloating);

  modal.add(Text::new() |> set_text("Export design") |> set_text_size(13.5) |> set_text_color(fcText(dark)) |> set_font(gui::medium()));
  modal.add(Text::new() |> set_text(&ed.stageName[0]) |> set_text_size(10.5) |> set_text_color(fcMutedText(dark)));

  modal.add(exportFormatRow("fc-exp-png", 0, "PNG (2x Retina)", "Raster bitmap of active artboard", dark));
  modal.add(exportFormatRow("fc-exp-svg", 1, "SVG Vector", "Scalable vector paths and typography", dark));
  modal.add(exportFormatRow("fc-exp-pdf", 2, "PDF Document", "Print-ready multi-page specification", dark));
  modal.add(exportFormatRow("fc-exp-glang", 3, "Glang UI Code", "Export scene nodes to std.gui widgets", dark));

  auto actions = Row::new() |> set_size(fill(), 34px) |> set_gap(8.0) |> set_align(GuiAlign::GuiAlignCenter);
  actions.add(Spacer::new() |> set_size(fill(), 1px));

  auto cancelBtn = BBox::new()
    |> set_id("fc-exp-cancel")
    |> set_size(fit(), 30px)
    |> set_padding_xy(12.0, 0.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_bg(fcField(dark))
    |> set_radius(7.0)
    |> on_click() { -> ed.showExportModal = false; return; };
  cancelBtn.add(Text::new() |> set_text("Cancel") |> set_text_size(11.0) |> set_text_color(fcText(dark)));
  actions.add(cancelBtn);

  auto exportBtn = BBox::new()
    |> set_id("fc-exp-confirm")
    |> set_size(fit(), 30px)
    |> set_padding_xy(14.0, 0.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_bg(fcGreen())
    |> set_radius(7.0)
    |> on_click() { -> performExport(&ed); return; };
  exportBtn.add(Text::new() |> set_text("Export frame") |> set_text_size(11.0) |> set_text_color(fcNavy()) |> set_font(gui::medium()));
  actions.add(exportBtn);

  modal.add(actions);
  backdrop.add(modal);
  return backdrop;
}
