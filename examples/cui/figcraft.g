// FigCraft UI mock built with Glang and CUI.
//
// A 1:1 recreation of ArtCraft FigCraft's light UI3 workspace: tab strip,
// left rail, pages/layers panel, design canvas, Design/Prototype inspector,
// and the floating bottom toolbar. The canvas is a working mock: pick tools,
// select layers, drag the frame, toggle fill/clip, and switch panels.
//
// Build with examples\cui\build.cmd -Figcraft. Set CUI_SMOKE=1 for a hidden run.

import std.cui;

[[extern, c_abi]]
char* getenv(const char* name);

// ---------------------------------------------------------------------------
// Palette
// ---------------------------------------------------------------------------

CuiColor chromeColor() => std::cui::rgb(239, 239, 239);
CuiColor panelColor() => std::cui::rgb(252, 252, 252);
CuiColor cardColor() => std::cui::rgb(255, 255, 255);
CuiColor canvasColor() => std::cui::rgb(238, 238, 238);
CuiColor borderColor() => std::cui::rgb(226, 226, 226);
CuiColor dividerColor() => std::cui::rgb(234, 234, 234);
CuiColor textColor() => std::cui::rgb(28, 28, 30);
CuiColor secondaryText() => std::cui::rgb(105, 105, 110);
CuiColor mutedText() => std::cui::rgb(150, 150, 155);
CuiColor fieldColor() => std::cui::rgb(245, 245, 246);
CuiColor pageSelected() => std::cui::rgb(240, 240, 241);
CuiColor greenColor() => std::cui::rgb(10, 207, 131);
CuiColor greenDark() => std::cui::rgb(5, 134, 86);
CuiColor greenSoft() => std::cui::rgb(219, 247, 234);
CuiColor greenBorder() => std::cui::rgb(150, 230, 197);
CuiColor purpleColor() => std::cui::rgb(124, 77, 255);
CuiColor purpleSoft() => std::cui::rgb(240, 235, 255);
CuiColor navyColor() => std::cui::rgb(15, 23, 38);
CuiColor navyRaised() => std::cui::rgb(27, 39, 59);
CuiColor navyLine() => std::cui::rgb(45, 59, 82);
CuiColor designBg() => std::cui::rgb(243, 245, 248);
CuiColor designBorder() => std::cui::rgb(231, 234, 239);
CuiColor chartGreen() => std::cui::rgb(16, 163, 127);
CuiColor chartMint() => std::cui::rgb(178, 235, 215);
CuiColor chartBlue() => std::cui::rgb(59, 130, 246);
CuiColor chartPurple() => std::cui::rgb(124, 77, 255);
CuiColor warningColor() => std::cui::rgb(217, 145, 38);
CuiColor warningSoft() => std::cui::rgb(253, 243, 219);
CuiColor dangerColor() => std::cui::rgb(226, 84, 84);
CuiColor dangerSoft() => std::cui::rgb(253, 231, 231);
CuiColor blueSoft() => std::cui::rgb(225, 236, 254);

// ---------------------------------------------------------------------------
// Small helpers
// ---------------------------------------------------------------------------

bool inRect(CuiRect rect, CuiVec2 point) {
  if (point.x < rect.x || point.x >= rect.x + rect.w) {
    return false;
  }
  if (point.y < rect.y || point.y >= rect.y + rect.h) {
    return false;
  }
  return true;
}

bool clickRect(CuiCtx ui, CuiId id) {
  CuiRect rect = cui_get_rect(ui, id);
  return inRect(rect, cui_mouse_pos(ui)) &&
         cui_mouse_clicked(ui, CuiMouseButton::MouseLeft);
}

bool hoverRect(CuiCtx ui, CuiId id) {
  return inRect(cui_get_rect(ui, id), cui_mouse_pos(ui));
}

float clampf(float value, float low, float high) {
  if (value < low) {
    return low;
  }
  if (value > high) {
    return high;
  }
  return value;
}

// Glang has no conditional operator, so keep the choices readable here.
CuiColor pickColor(bool condition, CuiColor yes, CuiColor no) {
  if (condition) {
    return yes;
  }
  return no;
}

float pickFloat(bool condition, float yes, float no) {
  if (condition) {
    return yes;
  }
  return no;
}

const char* pickString(bool condition, const char* yes, const char* no) {
  if (condition) {
    return yes;
  }
  return no;
}

void text(CuiCtx ui, const char* value, float size, CuiColor color, int font) {
  CuiTextOpts opts = CuiTextOpts{
    font: font,
    size: size,
    color: color,
    nowrap: true
  };
  cui_text_ex(ui, value, &opts);
}

void textWrapped(CuiCtx ui, const char* value, float size, CuiColor color, int font) {
  CuiTextOpts opts = CuiTextOpts{
    font: font,
    size: size,
    color: color,
    width: std::cui::fill()
  };
  cui_text_ex(ui, value, &opts);
}

void icon(CuiCtx ui, const char* glyph, float size, CuiColor color) {
  cui_icon(ui, glyph, size, color);
}

void horizontalLine(CuiCtx ui, CuiColor color) {
  CuiBox line = CuiBox{
    width: std::cui::fill(),
    height: std::cui::px(1.0),
    bg: color
  };
  cui_box_begin(ui, &line);
  cui_box_end(ui);
}

void verticalLine(CuiCtx ui, float height, CuiColor color) {
  CuiBox line = CuiBox{
    width: std::cui::px(1.0),
    height: std::cui::px(height),
    bg: color
  };
  cui_box_begin(ui, &line);
  cui_box_end(ui);
}

void toast(CuiCtx ui, const char* title, const char* description) {
  CuiToastOpts opts = CuiToastOpts{
    description: description,
    tone: CuiTone::ToneSuccess,
    duration: 2.4
  };
  cui_toast_ex(ui, title, &opts);
}

// ---------------------------------------------------------------------------
// Shared controls
// ---------------------------------------------------------------------------

void tooltipButton(CuiCtx ui, const char* glyph, const char* tip) {
  CuiButtonOpts opts = CuiButtonOpts{
    variant: CuiButtonVariant::ButtonGhost,
    size: CuiControlSize::SizeSmall,
    tooltip: tip
  };
  cui_icon_button_ex(ui, glyph, &opts);
}

// A compact icon hit target drawn with exact chrome colors.
bool flatIcon(CuiCtx ui, const char* glyph, float size, CuiColor color, const char* tip) {
  CuiBox button = CuiBox{
    id: tip,
    width: std::cui::px(24.0),
    height: std::cui::px(24.0),
    align: CuiAlign::Center,
    justify: CuiJustify::JustifyCenter,
    radius: 5.0
  };
  CuiId id = cui_box_begin(ui, &button);
  icon(ui, glyph, size, color);
  cui_box_end(ui);
  if (hoverRect(ui, id)) {
    cui_tooltip(ui, tip);
  }
  return clickRect(ui, id);
}

// A label / value field, matching the FigCraft inspector rows.
void inspectorField(CuiCtx ui, const char* label, const char* value, float width) {
  CuiBox field = CuiBox{
    width: std::cui::px(width),
    height: std::cui::px(28.0),
    pad_left: 8.0,
    pad_right: 8.0,
    gap: 5.0,
    align: CuiAlign::Center,
    bg: fieldColor(),
    radius: 5.0
  };
  cui_row_begin(ui, &field);
  text(ui, label, 10.0, mutedText(), 0);
  text(ui, value, 10.5, textColor(), 0);
  cui_box_end(ui);
}

void sectionLabel(CuiCtx ui, const char* label) {
  text(ui, label, 10.0, secondaryText(), 0);
}

// A divider with a little breathing room on both sides.
void sectionDivider(CuiCtx ui) {
  CuiBox wrap = CuiBox{
    width: std::cui::fill(),
    height: std::cui::px(13.0),
    align: CuiAlign::Center
  };
  cui_column_begin(ui, &wrap);
  horizontalLine(ui, dividerColor());
  cui_box_end(ui);
}

// ---------------------------------------------------------------------------
// Top tab strip
// ---------------------------------------------------------------------------

void buildTopBar(CuiCtx ui, CuiApp app) {
  CuiBox bar = CuiBox{
    width: std::cui::fill(),
    height: std::cui::px(50.0),
    gap: 0.0,
    bg: chromeColor()
  };
  cui_row_begin(ui, &bar);

  // Home button, in the square area above the rail.
  CuiBox home = CuiBox{
    id: "home",
    width: std::cui::px(52.0),
    height: std::cui::fill(),
    align: CuiAlign::Center,
    justify: CuiJustify::JustifyCenter
  };
  CuiId homeId = cui_box_begin(ui, &home);
  icon(ui, std::cui::icons::home(), 17.0, textColor());
  cui_box_end(ui);
  if (clickRect(ui, homeId)) {
    toast(ui, "Home", "The FigCraft home screen is part of the full app.");
  }

  // Active file tab.
  CuiBox tab = CuiBox{
    width: std::cui::px(252.0),
    height: std::cui::fill(),
    pad_left: 12.0,
    pad_right: 8.0,
    gap: 8.0,
    align: CuiAlign::Center,
    bg: cardColor(),
    border: 1.0,
    border_color: dividerColor(),
    radius_tl: 7.0,
    radius_tr: 7.0
  };
  cui_row_begin(ui, &tab);
  icon(ui, std::cui::icons::layers(), 14.0, greenDark());
  text(ui, "Ridgeline Studio dashboard", 12.0, textColor(), 0);
  cui_spacer(ui);
  if (flatIcon(ui, std::cui::icons::x(), 13.0, mutedText(), "Close tab")) {
    toast(ui, "Tab", "This mock keeps its one open file.");
  }
  cui_box_end(ui);

  CuiBox tabTools = CuiBox{
    height: std::cui::fill(),
    pad_left: 8.0,
    pad_right: 8.0,
    align: CuiAlign::Center
  };
  cui_row_begin(ui, &tabTools);
  if (flatIcon(ui, std::cui::icons::plus(), 15.0, secondaryText(), "New design file")) {
    toast(ui, "New file", "New files open in another tab in the full app.");
  }
  cui_box_end(ui);

  cui_spacer(ui);

  CuiBox windowTools = CuiBox{
    height: std::cui::fill(),
    align: CuiAlign::Center
  };
  cui_row_begin(ui, &windowTools);
  if (flatIcon(ui, std::cui::icons::sun(), 15.0, secondaryText(), "Theme: light")) {
    toast(ui, "Light theme", "This example is intentionally light.");
  }
  if (flatIcon(ui, std::cui::icons::minus(), 15.0, secondaryText(), "Minimize")) {
    cui_app_minimize(app);
  }
  if (flatIcon(ui, std::cui::icons::maximize(), 14.0, secondaryText(), "Maximize")) {
    if (cui_app_window_state(app) == CuiWindowState::Maximized) {
      cui_app_restore(app);
    } else {
      cui_app_maximize(app);
    }
  }
  if (flatIcon(ui, std::cui::icons::x(), 15.0, secondaryText(), "Close")) {
    cui_app_quit(app);
  }
  cui_box_end(ui);

  cui_box_end(ui);
}

// ---------------------------------------------------------------------------
// Left rail
// ---------------------------------------------------------------------------

bool railItem(CuiCtx ui, const char* label, const char* glyph, bool selected) {
  CuiBox item = CuiBox{
    width: std::cui::fill(),
    height: std::cui::px(50.0),
    gap: 3.0,
    align: CuiAlign::Center
  };
  cui_column_begin(ui, &item);

  CuiButtonOpts opts = CuiButtonOpts{
    variant: CuiButtonVariant::ButtonGhost,
    size: CuiControlSize::SizeSmall,
    tooltip: label,
    selected: selected
  };
  bool clicked = cui_icon_button_ex(ui, glyph, &opts);
  text(ui, label, 10.0, pickColor(selected, textColor(), secondaryText()), 0);
  cui_box_end(ui);
  return clicked;
}

void buildRail(CuiCtx ui, int* leftTab) {
  CuiBox rail = CuiBox{
    width: std::cui::px(52.0),
    height: std::cui::fill(),
    pad_top: 9.0,
    pad_bottom: 8.0,
    gap: 4.0,
    align: CuiAlign::Center,
    bg: panelColor(),
    border: 1.0,
    border_color: dividerColor()
  };
  cui_column_begin(ui, &rail);

  CuiBox logo = CuiBox{
    width: std::cui::px(27.0),
    height: std::cui::px(27.0),
    align: CuiAlign::Center,
    justify: CuiJustify::JustifyCenter,
    bg: greenSoft(),
    radius: 8.0
  };
  cui_box_begin(ui, &logo);
  icon(ui, std::cui::icons::star(), 14.0, greenDark());
  cui_box_end(ui);

  CuiBox logoGap = CuiBox{
    width: std::cui::fill(),
    height: std::cui::px(8.0),
    align: CuiAlign::Center
  };
  cui_column_begin(ui, &logoGap);
  CuiBox logoLine = CuiBox{width: std::cui::px(22.0), height: std::cui::px(1.0), bg: dividerColor()};
  cui_box_begin(ui, &logoLine);
  cui_box_end(ui);
  cui_box_end(ui);

  if (railItem(ui, "File", std::cui::icons::file(), *leftTab == 0)) { *leftTab = 0; }
  if (railItem(ui, "Assets", std::cui::icons::grid(), *leftTab == 1)) { *leftTab = 1; }
  if (railItem(ui, "Variables", std::cui::icons::sliders(), *leftTab == 2)) { *leftTab = 2; }

  cui_spacer(ui);
  if (flatIcon(ui, std::cui::icons::help(), 15.0, mutedText(), "Help")) {
    toast(ui, "Getting started", "Draw a frame, add a layer, pick a tool.");
  }

  cui_box_end(ui);
}

// ---------------------------------------------------------------------------
// File, Assets, and Variables panels
// ---------------------------------------------------------------------------

void panelHeader(CuiCtx ui, const char* title, const char* subtitle) {
  CuiBox header = CuiBox{
    width: std::cui::fill(),
    height: std::cui::px(52.0),
    pad_left: 16.0,
    pad_right: 10.0,
    gap: 6.0,
    align: CuiAlign::Center
  };
  cui_row_begin(ui, &header);

  CuiBox titles = CuiBox{
    width: std::cui::fill(),
    gap: 1.0
  };
  cui_column_begin(ui, &titles);
  text(ui, title, 12.0, textColor(), 1);
  if (subtitle != nullptr) {
    text(ui, subtitle, 10.0, mutedText(), 0);
  }
  cui_box_end(ui);

  if (flatIcon(ui, std::cui::icons::panelLeft(), 14.0, secondaryText(), "Collapse assets panel")) {
    toast(ui, "Panel", "Panels collapse in the full editor.");
  }
  cui_box_end(ui);
  horizontalLine(ui, dividerColor());
}

void panelTitleRow(CuiCtx ui, const char* title, bool add) {
  CuiBox row = CuiBox{
    width: std::cui::fill(),
    height: std::cui::px(38.0),
    pad_left: 16.0,
    pad_right: 12.0,
    align: CuiAlign::Center,
    gap: 2.0
  };
  cui_row_begin(ui, &row);
  text(ui, title, 10.5, secondaryText(), 0);
  cui_spacer(ui);
  if (flatIcon(ui, std::cui::icons::search(), 13.0, mutedText(), "Search pages")) {
    toast(ui, "Search", "Search filters the panel in the full app.");
  }
  if (add) {
    if (flatIcon(ui, std::cui::icons::plus(), 14.0, mutedText(), "Add page")) {
      toast(ui, "Add", "New pages and layers are added here.");
    }
  }
  cui_box_end(ui);
}

bool layerRow(CuiCtx ui, const char* id, int index, int* selected, const char* name,
              const char* glyph, float indent, bool open, bool hasChildren) {
  CuiBox row = CuiBox{
    id: id,
    width: std::cui::fill(),
    height: std::cui::px(30.0),
    pad_left: 6.0 + indent,
    pad_right: 8.0,
    gap: 5.0,
    align: CuiAlign::Center,
    radius: 6.0,
    bg: pickColor(*selected == index, greenSoft(), panelColor())
  };
  CuiId rowId = cui_row_begin(ui, &row);

  if (hasChildren) {
    const char* arrow = std::cui::icons::chevronRight();
    if (open) {
      arrow = std::cui::icons::chevronDown();
    }
    icon(ui, arrow, 11.0, pickColor(*selected == index, greenDark(), mutedText()));
  } else {
    CuiBox indentBox = CuiBox{width: std::cui::px(11.0), height: std::cui::px(1.0)};
    cui_box_begin(ui, &indentBox);
    cui_box_end(ui);
  }

  icon(ui, glyph, 11.0, pickColor(*selected == index, greenDark(), secondaryText()));
  text(ui, name, 11.0, pickColor(*selected == index, textColor(), secondaryText()), 0);
  cui_box_end(ui);

  return clickRect(ui, rowId);
}

void buildFilePanel(CuiCtx ui, int* selectedPage, int* selectedLayer) {
  CuiBox header = CuiBox{
    width: std::cui::fill(),
    height: std::cui::px(53.0),
    pad_left: 16.0,
    pad_right: 10.0,
    align: CuiAlign::Center,
    gap: 4.0
  };
  cui_row_begin(ui, &header);
  CuiBox titles = CuiBox{width: std::cui::fill(), gap: 1.0};
  cui_column_begin(ui, &titles);
  text(ui, "Ridgeline Studio dashboard", 12.0, textColor(), 1);
  text(ui, "Drafts", 10.0, mutedText(), 0);
  cui_box_end(ui);
  if (flatIcon(ui, std::cui::icons::panelLeft(), 14.0, secondaryText(), "Collapse layers panel")) {
    toast(ui, "Panel", "Panels collapse in the full editor.");
  }
  cui_box_end(ui);
  horizontalLine(ui, dividerColor());

  panelTitleRow(ui, "Pages", true);

  CuiBox page = CuiBox{
    id: "page-dashboard",
    width: std::cui::fill(),
    height: std::cui::px(30.0),
    pad_left: 10.0,
    align: CuiAlign::Center,
    bg: pickColor(*selectedPage == 0, pageSelected(), panelColor()),
    radius: 6.0
  };
  CuiId pageId = cui_box_begin(ui, &page);
  text(ui, "Dashboard", 11.0, textColor(), 0);
  cui_box_end(ui);
  if (clickRect(ui, pageId)) { *selectedPage = 0; }

  CuiBox pagePad = CuiBox{width: std::cui::fill(), height: std::cui::px(8.0)};
  cui_box_begin(ui, &pagePad);
  cui_box_end(ui);
  horizontalLine(ui, dividerColor());

  panelTitleRow(ui, "Layers", false);

  CuiBox tree = CuiBox{
    width: std::cui::fill(),
    gap: 2.0,
    pad_left: 8.0,
    pad_right: 8.0
  };
  cui_column_begin(ui, &tree);

  if (layerRow(ui, "layer-root", 0, selectedLayer, "Dashboard — Overview",
               std::cui::icons::layers(), 0.0, true, true)) {
    *selectedLayer = 0;
  }
  if (layerRow(ui, "layer-main", 1, selectedLayer, "Main",
               std::cui::icons::box(), 12.0, false, true)) {
    *selectedLayer = 1;
  }
  if (layerRow(ui, "layer-lower", 2, selectedLayer, "Lower",
               std::cui::icons::layers(), 12.0, false, true)) {
    *selectedLayer = 2;
  }
  if (layerRow(ui, "layer-charts", 3, selectedLayer, "Charts",
               std::cui::icons::chartBar(), 12.0, false, true)) {
    *selectedLayer = 3;
  }
  if (layerRow(ui, "layer-kpis", 4, selectedLayer, "KPIs",
               std::cui::icons::activity(), 12.0, false, false)) {
    *selectedLayer = 4;
  }
  if (layerRow(ui, "layer-topbar", 5, selectedLayer, "Top bar",
               std::cui::icons::dashboard(), 12.0, false, false)) {
    *selectedLayer = 5;
  }
  if (layerRow(ui, "layer-sidebar", 6, selectedLayer, "Sidebar",
               std::cui::icons::panelLeft(), 12.0, false, false)) {
    *selectedLayer = 6;
  }

  cui_box_end(ui);
}

void assetCard(CuiCtx ui, const char* name, int kind) {
  CuiBox card = CuiBox{
    id: name,
    width: std::cui::fill(),
    height: std::cui::px(94.0),
    pad: 8.0,
    gap: 6.0,
    bg: cardColor(),
    border: 1.0,
    border_color: dividerColor(),
    radius: 7.0
  };
  CuiId id = cui_column_begin(ui, &card);

  CuiBox preview = CuiBox{
    width: std::cui::fill(),
    height: std::cui::px(54.0),
    align: CuiAlign::Center,
    justify: CuiJustify::JustifyCenter,
    bg: fieldColor(),
    radius: 5.0
  };
  cui_box_begin(ui, &preview);
  if (kind == 0) {
    CuiBox pill = CuiBox{
      width: std::cui::px(58.0),
      height: std::cui::px(20.0),
      align: CuiAlign::Center,
      justify: CuiJustify::JustifyCenter,
      bg: greenColor(),
      radius: 10.0
    };
    cui_box_begin(ui, &pill);
    text(ui, "Button", 7.0, navyColor(), 1);
    cui_box_end(ui);
  } else if (kind == 1) {
    CuiBox cardPreview = CuiBox{
      width: std::cui::px(58.0),
      height: std::cui::px(32.0),
      pad: 5.0,
      gap: 3.0,
      bg: cardColor(),
      border: 1.0,
      border_color: borderColor(),
      radius: 4.0
    };
    cui_column_begin(ui, &cardPreview);
    CuiBox line = CuiBox{width: std::cui::px(34.0), height: std::cui::px(3.0), bg: borderColor(), radius: 1.0};
    cui_box_begin(ui, &line);
    cui_box_end(ui);
    CuiBox line2 = CuiBox{width: std::cui::px(24.0), height: std::cui::px(3.0), bg: dividerColor(), radius: 1.0};
    cui_box_begin(ui, &line2);
    cui_box_end(ui);
    cui_box_end(ui);
  } else if (kind == 2) {
    CuiBox bars = CuiBox{height: std::cui::px(32.0), gap: 3.0, align: CuiAlign::End};
    cui_row_begin(ui, &bars);
    CuiBox b1 = CuiBox{width: std::cui::px(6.0), height: std::cui::px(14.0), bg: chartGreen(), radius: 1.0};
    cui_box_begin(ui, &b1);
    cui_box_end(ui);
    CuiBox b2 = CuiBox{width: std::cui::px(6.0), height: std::cui::px(25.0), bg: chartMint(), radius: 1.0};
    cui_box_begin(ui, &b2);
    cui_box_end(ui);
    CuiBox b3 = CuiBox{width: std::cui::px(6.0), height: std::cui::px(19.0), bg: chartGreen(), radius: 1.0};
    cui_box_begin(ui, &b3);
    cui_box_end(ui);
    CuiBox b4 = CuiBox{width: std::cui::px(6.0), height: std::cui::px(29.0), bg: chartBlue(), radius: 1.0};
    cui_box_begin(ui, &b4);
    cui_box_end(ui);
    cui_box_end(ui);
  } else {
    CuiBox avatar = CuiBox{
      width: std::cui::px(28.0),
      height: std::cui::px(28.0),
      align: CuiAlign::Center,
      justify: CuiJustify::JustifyCenter,
      bg: navyColor(),
      radius: 14.0
    };
    cui_box_begin(ui, &avatar);
    icon(ui, std::cui::icons::user(), 14.0, cardColor());
    cui_box_end(ui);
  }
  cui_box_end(ui);

  text(ui, name, 9.5, secondaryText(), 0);
  cui_box_end(ui);

  if (clickRect(ui, id)) {
    toast(ui, name, "Component assets drag onto the canvas in the full app.");
  }
}

void buildAssetsPanel(CuiCtx ui) {
  panelHeader(ui, "Assets", "Local components");
  panelTitleRow(ui, "Components", true);

  CuiBox grid = CuiBox{
    width: std::cui::fill(),
    dir: CuiDir::Grid,
    pad_left: 12.0,
    pad_right: 12.0,
    gap: 8.0,
    columns: 2
  };
  cui_box_begin(ui, &grid);
  assetCard(ui, "Button", 0);
  assetCard(ui, "Card", 1);
  assetCard(ui, "Chart", 2);
  assetCard(ui, "Avatar", 3);
  cui_box_end(ui);

  CuiBox pad = CuiBox{width: std::cui::fill(), height: std::cui::px(12.0)};
  cui_box_begin(ui, &pad);
  cui_box_end(ui);

  CuiBox note = CuiBox{
    width: std::cui::fill(),
    pad: 12.0,
    gap: 4.0
  };
  cui_column_begin(ui, &note);
  text(ui, "Styles", 10.0, secondaryText(), 1);
  textWrapped(ui, "Colour, text, effect and grid styles live here, with the variables that drive both themes.", 10.0, mutedText(), 0);
  cui_box_end(ui);
}

CuiColor titleMuted() => std::cui::rgb(139, 139, 145);

void variableRow(CuiCtx ui, const char* swatch, CuiColor color, const char* name, const char* value) {
  CuiBox row = CuiBox{
    width: std::cui::fill(),
    height: std::cui::px(34.0),
    pad_left: 12.0,
    pad_right: 12.0,
    gap: 7.0,
    align: CuiAlign::Center
  };
  cui_row_begin(ui, &row);
  CuiBox chip = CuiBox{
    width: std::cui::px(16.0),
    height: std::cui::px(16.0),
    bg: color,
    border: 1.0,
    border_color: borderColor(),
    radius: 4.0
  };
  cui_box_begin(ui, &chip);
  cui_box_end(ui);
  text(ui, swatch, 10.0, textColor(), 0);
  cui_spacer(ui);
  text(ui, name, 9.5, mutedText(), 0);
  text(ui, value, 9.5, secondaryText(), 0);
  cui_box_end(ui);
}

void buildVariablesPanel(CuiCtx ui) {
  panelHeader(ui, "Variables", "Theme modes");
  panelTitleRow(ui, "Colour", true);
  variableRow(ui, "surface", cardColor(), "Canvas", "F3F5F8");
  variableRow(ui, "text", navyColor(), "Ink", "0E1726");
  variableRow(ui, "accent", greenColor(), "Accent", "0ACF83");
  variableRow(ui, "muted", titleMuted(), "Muted", "8B8B91");
  variableRow(ui, "warning", warningColor(), "Warning", "D99126");

  sectionDivider(ui);
  panelTitleRow(ui, "Numbers", true);
  variableRow(ui, "radius", fieldColor(), "Corner", "20");
  variableRow(ui, "space", fieldColor(), "Gap", "24");
}

void buildLeftPanel(CuiCtx ui, int leftTab, int* selectedPage, int* selectedLayer) {
  CuiBox panel = CuiBox{
    width: std::cui::px(248.0),
    height: std::cui::fill(),
    bg: panelColor(),
    border: 1.0,
    border_color: dividerColor()
  };
  cui_column_begin(ui, &panel);
  if (leftTab == 0) {
    buildFilePanel(ui, selectedPage, selectedLayer);
  } else if (leftTab == 1) {
    buildAssetsPanel(ui);
  } else {
    buildVariablesPanel(ui);
  }
  cui_box_end(ui);
}

// ---------------------------------------------------------------------------
// Canvas design: the Ridgeline Studio dashboard
// ---------------------------------------------------------------------------

void designNav(CuiCtx ui, const char* label, const char* glyph, bool selected) {
  CuiBox row = CuiBox{
    width: std::cui::fill(),
    height: std::cui::px(24.0),
    pad_left: 8.0,
    gap: 6.0,
    align: CuiAlign::Center,
    radius: 5.0,
    bg: pickColor(selected, std::cui::rgba(255, 255, 255, 18), std::cui::rgba(0, 0, 0, 0))
  };
  cui_row_begin(ui, &row);
  icon(ui, glyph, 9.0, pickColor(selected, greenColor(), std::cui::rgba(219, 226, 238, 190)));
  text(ui, label, 7.5, pickColor(selected, cardColor(), std::cui::rgba(219, 226, 238, 190)), 0);
  if (selected) {
    cui_spacer(ui);
    CuiBox dot = CuiBox{width: std::cui::px(3.0), height: std::cui::px(3.0), bg: greenColor(), radius: 2.0};
    cui_box_begin(ui, &dot);
    cui_box_end(ui);
  }
  cui_box_end(ui);
}

void buildDesignSidebar(CuiCtx ui, int selectedLayer) {
  CuiBox side = CuiBox{
    width: std::cui::px(150.0),
    height: std::cui::fill(),
    pad: 12.0,
    gap: 5.0,
    bg: navyColor(),
    border: pickFloat(selectedLayer == 6, 1.5, 0.0),
    border_color: greenColor()
  };
  cui_column_begin(ui, &side);

  CuiBox brand = CuiBox{width: std::cui::fill(), gap: 6.0, align: CuiAlign::Center};
  cui_row_begin(ui, &brand);
  CuiBox mark = CuiBox{
    width: std::cui::px(21.0),
    height: std::cui::px(21.0),
    align: CuiAlign::Center,
    justify: CuiJustify::JustifyCenter,
    bg: greenColor(),
    radius: 6.0
  };
  cui_box_begin(ui, &mark);
  icon(ui, std::cui::icons::layers(), 10.0, navyColor());
  cui_box_end(ui);
  CuiBox brandText = CuiBox{gap: 0.0};
  cui_column_begin(ui, &brandText);
  text(ui, "Ridgeline", 8.0, cardColor(), 1);
  text(ui, "STUDIO", 4.5, std::cui::rgba(219, 226, 238, 150), 0);
  cui_box_end(ui);
  cui_box_end(ui);

  CuiBox brandGap = CuiBox{width: std::cui::fill(), height: std::cui::px(6.0)};
  cui_box_begin(ui, &brandGap);
  cui_box_end(ui);

  designNav(ui, "Overview", std::cui::icons::dashboard(), true);
  designNav(ui, "Analytics", std::cui::icons::chartLine(), false);
  designNav(ui, "Trails", std::cui::icons::compass(), false);
  designNav(ui, "Rangers", std::cui::icons::user(), false);
  designNav(ui, "Bookings", std::cui::icons::bookmark(), false);
  designNav(ui, "Alerts", std::cui::icons::alert(), false);
  designNav(ui, "Settings", std::cui::icons::settings(), false);

  cui_spacer(ui);

  CuiBox winter = CuiBox{
    width: std::cui::fill(),
    pad: 8.0,
    gap: 4.0,
    bg: std::cui::rgb(18, 73, 57),
    radius: 6.0
  };
  cui_column_begin(ui, &winter);
  text(ui, "Winter season", 7.0, cardColor(), 1);
  textWrapped(ui, "Plan closures and snow routes before the first storm.", 5.3, std::cui::rgba(219, 245, 233, 190), 0);
  CuiBox planner = CuiBox{
    id: "winter-planner",
    width: std::cui::fill(),
    height: std::cui::px(16.0),
    align: CuiAlign::Center,
    justify: CuiJustify::JustifyCenter,
    bg: greenColor(),
    radius: 4.0
  };
  CuiId plannerId = cui_box_begin(ui, &planner);
  text(ui, "Open planner", 5.5, navyColor(), 1);
  cui_box_end(ui);
  if (clickRect(ui, plannerId)) {
    toast(ui, "Winter planner", "Seasonal closures are a canvas layer.");
  }
  cui_box_end(ui);

  CuiBox user = CuiBox{width: std::cui::fill(), height: std::cui::px(22.0), gap: 5.0, align: CuiAlign::Center};
  cui_row_begin(ui, &user);
  CuiBox avatar = CuiBox{
    width: std::cui::px(15.0),
    height: std::cui::px(15.0),
    align: CuiAlign::Center,
    justify: CuiJustify::JustifyCenter,
    bg: greenColor(),
    radius: 8.0
  };
  cui_box_begin(ui, &avatar);
  text(ui, "JO", 4.5, navyColor(), 1);
  cui_box_end(ui);
  CuiBox userText = CuiBox{gap: 0.0};
  cui_column_begin(ui, &userText);
  text(ui, "Jonas Ortiz", 5.8, cardColor(), 0);
  text(ui, "Park operations", 4.6, std::cui::rgba(219, 226, 238, 150), 0);
  cui_box_end(ui);
  cui_box_end(ui);

  cui_box_end(ui);
}

void kpiCard(CuiCtx ui, const char* label, const char* value, const char* delta,
             bool up, float* data, int count, bool selected) {
  CuiBox card = CuiBox{
    width: std::cui::fill(),
    height: std::cui::fill(),
    pad: 8.0,
    gap: 2.0,
    bg: cardColor(),
    border: pickFloat(selected, 1.5, 1.0),
    border_color: pickColor(selected, greenColor(), designBorder()),
    radius: 5.0
  };
  cui_column_begin(ui, &card);

  text(ui, label, 5.5, mutedText(), 0);
  text(ui, value, 15.0, textColor(), 1);

  CuiBox foot = CuiBox{width: std::cui::fill(), height: std::cui::px(19.0), gap: 4.0, align: CuiAlign::Center};
  cui_row_begin(ui, &foot);
  text(ui, delta, 5.2, pickColor(up, greenDark(), dangerColor()), 0);
  cui_spacer(ui);
  cui_sparkline(ui, data, count, std::cui::px(55.0), 16.0, pickColor(up, chartGreen(), dangerColor()));
  cui_box_end(ui);

  cui_box_end(ui);
}

void barGroup(CuiCtx ui, const char* label, float current, float previous) {
  CuiBox group = CuiBox{
    width: std::cui::fill(),
    height: std::cui::fill(),
    gap: 4.0,
    justify: CuiJustify::JustifyEnd,
    align: CuiAlign::Center
  };
  cui_column_begin(ui, &group);
  CuiBox bars = CuiBox{height: std::cui::px(78.0), gap: 4.0, align: CuiAlign::End};
  cui_row_begin(ui, &bars);
  CuiBox prior = CuiBox{
    width: std::cui::px(7.0),
    height: std::cui::px(previous),
    bg: chartMint(),
    radius: 2.0
  };
  cui_box_begin(ui, &prior);
  cui_box_end(ui);
  CuiBox now = CuiBox{
    width: std::cui::px(7.0),
    height: std::cui::px(current),
    bg: chartGreen(),
    radius: 2.0
  };
  cui_box_begin(ui, &now);
  cui_box_end(ui);
  cui_box_end(ui);
  text(ui, label, 5.2, mutedText(), 0);
  cui_box_end(ui);
}

void conditionBadge(CuiCtx ui, const char* label, CuiColor bg, CuiColor fg) {
  CuiBox badge = CuiBox{
    width: std::cui::px(42.0),
    height: std::cui::px(13.0),
    gap: 3.0,
    align: CuiAlign::Center,
    justify: CuiJustify::JustifyCenter,
    bg: bg,
    radius: 4.0
  };
  cui_row_begin(ui, &badge);
  CuiBox dot = CuiBox{width: std::cui::px(3.0), height: std::cui::px(3.0), bg: fg, radius: 2.0};
  cui_box_begin(ui, &dot);
  cui_box_end(ui);
  text(ui, label, 4.8, fg, 0);
  cui_box_end(ui);
}

void trailRow(CuiCtx ui, const char* name, const char* region, const char* hikes,
              const char* rating, const char* condition, CuiColor badgeBg, CuiColor badgeFg) {
  CuiBox row = CuiBox{
    width: std::cui::fill(),
    height: std::cui::px(20.0),
    gap: 5.0,
    align: CuiAlign::Center,
    border: 0.0
  };
  cui_row_begin(ui, &row);
  CuiBox thumb = CuiBox{
    width: std::cui::px(13.0),
    height: std::cui::px(13.0),
    bg: chartMint(),
    radius: 3.0
  };
  cui_box_begin(ui, &thumb);
  cui_box_end(ui);

  CuiBox nameBox = CuiBox{width: std::cui::fill()};
  cui_column_begin(ui, &nameBox);
  text(ui, name, 5.8, textColor(), 0);
  cui_box_end(ui);

  CuiBox regionBox = CuiBox{width: std::cui::px(56.0)};
  cui_column_begin(ui, &regionBox);
  text(ui, region, 5.2, secondaryText(), 0);
  cui_box_end(ui);

  CuiBox hikesBox = CuiBox{width: std::cui::px(24.0)};
  cui_column_begin(ui, &hikesBox);
  text(ui, hikes, 5.2, secondaryText(), 0);
  cui_box_end(ui);

  CuiBox ratingBox = CuiBox{width: std::cui::px(36.0), gap: 2.0, align: CuiAlign::Center};
  cui_row_begin(ui, &ratingBox);
  icon(ui, std::cui::icons::star(), 5.0, warningColor());
  text(ui, rating, 5.2, secondaryText(), 0);
  cui_box_end(ui);

  conditionBadge(ui, condition, badgeBg, badgeFg);
  cui_box_end(ui);
}

void trailHeaderLabel(CuiCtx ui, const char* label, float width) {
  CuiBox box = CuiBox{width: std::cui::px(width)};
  cui_column_begin(ui, &box);
  text(ui, label, 4.5, mutedText(), 0);
  cui_box_end(ui);
}

void buildBarCard(CuiCtx ui, bool selected) {
  CuiBox card = CuiBox{
    width: std::cui::fill(),
    height: std::cui::fill(),
    pad: 9.0,
    gap: 5.0,
    bg: cardColor(),
    border: pickFloat(selected, 1.5, 1.0),
    border_color: pickColor(selected, greenColor(), designBorder()),
    radius: 5.0
  };
  cui_column_begin(ui, &card);

  CuiBox head = CuiBox{width: std::cui::fill(), align: CuiAlign::Center};
  cui_row_begin(ui, &head);
  CuiBox title = CuiBox{gap: 0.0};
  cui_column_begin(ui, &title);
  text(ui, "Hikes per day", 7.5, textColor(), 1);
  text(ui, "2,184 this week · +9% on last week", 4.8, mutedText(), 0);
  cui_box_end(ui);
  cui_spacer(ui);
  CuiBox dot1 = CuiBox{width: std::cui::px(3.0), height: std::cui::px(3.0), bg: chartGreen(), radius: 2.0};
  cui_box_begin(ui, &dot1);
  cui_box_end(ui);
  text(ui, "This week", 4.6, secondaryText(), 0);
  CuiBox dot2 = CuiBox{width: std::cui::px(3.0), height: std::cui::px(3.0), bg: chartMint(), radius: 2.0};
  cui_box_begin(ui, &dot2);
  cui_box_end(ui);
  text(ui, "Last week", 4.6, secondaryText(), 0);
  cui_box_end(ui);

  CuiBox chart = CuiBox{
    width: std::cui::fill(),
    height: std::cui::fill(),
    gap: 4.0,
    align: CuiAlign::End
  };
  cui_row_begin(ui, &chart);
  barGroup(ui, "Mon", 42.0, 30.0);
  barGroup(ui, "Tue", 58.0, 36.0);
  barGroup(ui, "Wed", 36.0, 28.0);
  barGroup(ui, "Thu", 66.0, 44.0);
  barGroup(ui, "Fri", 52.0, 40.0);
  barGroup(ui, "Sat", 78.0, 60.0);
  barGroup(ui, "Sun", 68.0, 50.0);
  cui_box_end(ui);

  cui_box_end(ui);
}

void buildDonutCard(CuiCtx ui) {
  CuiBox card = CuiBox{
    width: std::cui::px(190.0),
    height: std::cui::fill(),
    pad: 9.0,
    gap: 4.0,
    bg: cardColor(),
    border: 1.0,
    border_color: designBorder(),
    radius: 5.0
  };
  cui_column_begin(ui, &card);
  text(ui, "Difficulty mix", 7.5, textColor(), 1);

  float[3] values;
  values[0] = 45.0;
  values[1] = 35.0;
  values[2] = 20.0;
  CuiChartOpts opts = CuiChartOpts{
    height: 102.0,
    no_grid: true,
    no_legend: true
  };
  cui_donut_chart_ex(ui, "figcraft-donut", &values[0], nullptr, 3, &opts);

  CuiBox legend = CuiBox{width: std::cui::fill(), gap: 6.0, align: CuiAlign::Center};
  cui_row_begin(ui, &legend);
  CuiBox easyDot = CuiBox{width: std::cui::px(4.0), height: std::cui::px(4.0), bg: chartGreen(), radius: 2.0};
  cui_box_begin(ui, &easyDot);
  cui_box_end(ui);
  text(ui, "Easy", 4.8, secondaryText(), 0);
  CuiBox modDot = CuiBox{width: std::cui::px(4.0), height: std::cui::px(4.0), bg: chartBlue(), radius: 2.0};
  cui_box_begin(ui, &modDot);
  cui_box_end(ui);
  text(ui, "Moderate", 4.8, secondaryText(), 0);
  CuiBox hardDot = CuiBox{width: std::cui::px(4.0), height: std::cui::px(4.0), bg: warningColor(), radius: 2.0};
  cui_box_begin(ui, &hardDot);
  cui_box_end(ui);
  text(ui, "Hard", 4.8, secondaryText(), 0);
  cui_box_end(ui);

  cui_box_end(ui);
}

void buildTrailsCard(CuiCtx ui) {
  CuiBox card = CuiBox{
    width: std::cui::fill(),
    height: std::cui::fill(),
    pad: 9.0,
    gap: 3.0,
    bg: cardColor(),
    border: 1.0,
    border_color: designBorder(),
    radius: 5.0
  };
  cui_column_begin(ui, &card);

  CuiBox head = CuiBox{width: std::cui::fill(), align: CuiAlign::Center};
  cui_row_begin(ui, &head);
  text(ui, "Top trails this week", 7.5, textColor(), 1);
  cui_spacer(ui);
  text(ui, "View all", 5.2, greenDark(), 0);
  cui_box_end(ui);

  CuiBox headRow = CuiBox{width: std::cui::fill(), height: std::cui::px(11.0), gap: 5.0, align: CuiAlign::Center};
  cui_row_begin(ui, &headRow);
  CuiBox headThumb = CuiBox{width: std::cui::px(13.0)};
  cui_box_begin(ui, &headThumb);
  cui_box_end(ui);
  CuiBox headName = CuiBox{width: std::cui::fill()};
  cui_column_begin(ui, &headName);
  text(ui, "TRAIL", 4.5, mutedText(), 0);
  cui_box_end(ui);
  trailHeaderLabel(ui, "REGION", 56.0);
  trailHeaderLabel(ui, "HIKES", 24.0);
  trailHeaderLabel(ui, "RATING", 36.0);
  trailHeaderLabel(ui, "CONDITIONS", 42.0);
  cui_box_end(ui);

  trailRow(ui, "Larch Valley Loop", "Lake district", "612", "4.9", "Open", greenSoft(), greenDark());
  trailRow(ui, "Emerald Lake Circuit", "Yoho valley", "488", "4.8", "Open", greenSoft(), greenDark());
  trailRow(ui, "Sulphur Ridge Lookout", "Hot springs", "351", "4.7", "Muddy", warningSoft(), warningColor());
  trailRow(ui, "Tunnel Peak Traverse", "North gate", "207", "4.6", "Snow", blueSoft(), chartBlue());

  cui_box_end(ui);
}

void buildVisitorsCard(CuiCtx ui) {
  CuiBox card = CuiBox{
    width: std::cui::px(190.0),
    height: std::cui::fill(),
    pad: 9.0,
    gap: 2.0,
    bg: cardColor(),
    border: 1.0,
    border_color: designBorder(),
    radius: 5.0
  };
  cui_column_begin(ui, &card);

  CuiBox head = CuiBox{width: std::cui::fill(), align: CuiAlign::Center};
  cui_row_begin(ui, &head);
  text(ui, "Visitors, last 30 days", 7.0, textColor(), 1);
  cui_spacer(ui);
  text(ui, "+18%", 5.0, greenDark(), 0);
  cui_box_end(ui);

  text(ui, "41,230", 16.0, textColor(), 1);

  float[14] visitors;
  visitors[0] = 14.0; visitors[1] = 18.0; visitors[2] = 16.0; visitors[3] = 22.0;
  visitors[4] = 20.0; visitors[5] = 26.0; visitors[6] = 24.0; visitors[7] = 29.0;
  visitors[8] = 27.0; visitors[9] = 33.0; visitors[10] = 31.0; visitors[11] = 36.0;
  visitors[12] = 34.0; visitors[13] = 40.0;
  cui_sparkline(ui, &visitors[0], 14, std::cui::fill(), 63.0, chartBlue());

  CuiBox axis = CuiBox{width: std::cui::fill(), align: CuiAlign::Center};
  cui_row_begin(ui, &axis);
  text(ui, "12 Sep", 4.3, mutedText(), 0);
  cui_spacer(ui);
  text(ui, "22 Sep", 4.3, mutedText(), 0);
  cui_spacer(ui);
  text(ui, "2 Oct", 4.3, mutedText(), 0);
  cui_spacer(ui);
  text(ui, "12 Oct", 4.3, mutedText(), 0);
  cui_box_end(ui);

  cui_box_end(ui);
}

void buildDesignMain(CuiCtx ui, int selectedLayer) {
  CuiBox main = CuiBox{
    width: std::cui::fill(),
    height: std::cui::fill(),
    pad: 14.0,
    gap: 10.0,
    border: pickFloat(selectedLayer == 1, 1.5, 0.0),
    border_color: greenColor()
  };
  cui_column_begin(ui, &main);

  // Top bar.
  CuiBox header = CuiBox{
    width: std::cui::fill(),
    height: std::cui::px(46.0),
    gap: 8.0,
    align: CuiAlign::Center,
    border: pickFloat(selectedLayer == 5, 1.5, 0.0),
    border_color: greenColor()
  };
  cui_row_begin(ui, &header);
  CuiBox greeting = CuiBox{width: std::cui::fill(), gap: 1.0};
  cui_column_begin(ui, &greeting);
  text(ui, "Good afternoon, Jonas", 12.0, textColor(), 1);
  text(ui, "Here is how the park's trails did this week.", 5.8, mutedText(), 0);
  cui_box_end(ui);

  CuiBox search = CuiBox{
    width: std::cui::px(126.0),
    height: std::cui::px(24.0),
    pad_left: 7.0,
    gap: 4.0,
    align: CuiAlign::Center,
    bg: cardColor(),
    border: 1.0,
    border_color: designBorder(),
    radius: 12.0
  };
  cui_row_begin(ui, &search);
  icon(ui, std::cui::icons::search(), 8.0, mutedText());
  text(ui, "Search trails or rangers", 5.2, mutedText(), 0);
  cui_box_end(ui);

  CuiBox date = CuiBox{
    width: std::cui::px(74.0),
    height: std::cui::px(24.0),
    gap: 4.0,
    align: CuiAlign::Center,
    justify: CuiJustify::JustifyCenter,
    bg: cardColor(),
    border: 1.0,
    border_color: designBorder(),
    radius: 5.0
  };
  cui_row_begin(ui, &date);
  icon(ui, std::cui::icons::clock(), 7.0, secondaryText());
  text(ui, "6 – 12 Oct 2026", 4.6, secondaryText(), 0);
  cui_box_end(ui);

  CuiBox newTrail = CuiBox{
    id: "new-trail",
    width: std::cui::px(68.0),
    height: std::cui::px(24.0),
    gap: 3.0,
    align: CuiAlign::Center,
    justify: CuiJustify::JustifyCenter,
    bg: greenColor(),
    radius: 5.0
  };
  CuiId newTrailId = cui_row_begin(ui, &newTrail);
  icon(ui, std::cui::icons::plus(), 7.0, navyColor());
  text(ui, "New trail", 5.4, navyColor(), 1);
  cui_box_end(ui);
  if (clickRect(ui, newTrailId)) {
    toast(ui, "New trail", "A blank trail card is added to the canvas.");
  }

  cui_box_end(ui);

  // KPI row.
  float[12] kpi1;
  kpi1[0] = 4.0; kpi1[1] = 5.0; kpi1[2] = 4.5; kpi1[3] = 7.0;
  kpi1[4] = 6.0; kpi1[5] = 8.0; kpi1[6] = 7.5; kpi1[7] = 9.5;
  kpi1[8] = 9.0; kpi1[9] = 10.5; kpi1[10] = 10.0; kpi1[11] = 12.0;
  float[12] kpi2;
  kpi2[0] = 6.0; kpi2[1] = 5.0; kpi2[2] = 7.0; kpi2[3] = 6.0;
  kpi2[4] = 8.0; kpi2[5] = 7.0; kpi2[6] = 9.0; kpi2[7] = 8.0;
  kpi2[8] = 10.0; kpi2[9] = 9.5; kpi2[10] = 11.0; kpi2[11] = 12.0;
  float[12] kpi3;
  kpi3[0] = 7.0; kpi3[1] = 7.2; kpi3[2] = 7.1; kpi3[3] = 7.4;
  kpi3[4] = 7.2; kpi3[5] = 7.5; kpi3[6] = 7.4; kpi3[7] = 7.7;
  kpi3[8] = 7.6; kpi3[9] = 7.8; kpi3[10] = 7.7; kpi3[11] = 7.9;
  float[12] kpi4;
  kpi4[0] = 9.0; kpi4[1] = 8.0; kpi4[2] = 8.5; kpi4[3] = 7.0;
  kpi4[4] = 7.5; kpi4[5] = 6.0; kpi4[6] = 6.5; kpi4[7] = 5.0;
  kpi4[8] = 4.5; kpi4[9] = 5.0; kpi4[10] = 4.0; kpi4[11] = 3.5;

  CuiBox kpis = CuiBox{
    width: std::cui::fill(),
    height: std::cui::px(86.0),
    gap: 10.0,
    border: pickFloat(selectedLayer == 4, 1.5, 0.0),
    border_color: greenColor()
  };
  cui_row_begin(ui, &kpis);
  kpiCard(ui, "Active hikers", "12,480", "▲ 18.2% vs last week", true, &kpi1[0], 12, false);
  kpiCard(ui, "Trail check-ins", "3,916", "▲ 12.4% vs last week", true, &kpi2[0], 12, false);
  kpiCard(ui, "Avg. rating", "4.82", "▲ 0.06 vs last week", true, &kpi3[0], 12, false);
  kpiCard(ui, "Open incidents", "7", "▼ 3 vs last week", false, &kpi4[0], 12, false);
  cui_box_end(ui);

  // Middle row: bar chart and donut.
  CuiBox middle = CuiBox{
    width: std::cui::fill(),
    height: std::cui::px(186.0),
    gap: 10.0,
    border: pickFloat(selectedLayer == 2, 1.5, 0.0),
    border_color: greenColor()
  };
  cui_row_begin(ui, &middle);
  buildBarCard(ui, selectedLayer == 3);
  buildDonutCard(ui);
  cui_box_end(ui);

  // Bottom row: trails and visitors.
  CuiBox lower = CuiBox{
    width: std::cui::fill(),
    height: std::cui::fill(),
    gap: 10.0,
    border: pickFloat(selectedLayer == 2, 1.5, 0.0),
    border_color: greenColor()
  };
  cui_row_begin(ui, &lower);
  buildTrailsCard(ui);
  buildVisitorsCard(ui);
  cui_box_end(ui);

  cui_box_end(ui);
}

const char* layerDimensions(int selectedLayer) {
  if (selectedLayer == 0) { return "1440 × 960"; }
  if (selectedLayer == 1) { return "1290 × 960"; }
  if (selectedLayer == 2) { return "1290 × 390"; }
  if (selectedLayer == 3) { return "900 × 360"; }
  if (selectedLayer == 4) { return "1290 × 170"; }
  if (selectedLayer == 5) { return "1290 × 92"; }
  return "300 × 960";
}

CuiId buildDesignFrame(CuiCtx ui, int selectedLayer) {
  CuiBox frame = CuiBox{
    id: "design-frame",
    width: std::cui::px(816.0),
    height: std::cui::px(544.0),
    gap: 0.0,
    bg: designBg(),
    border: pickFloat(selectedLayer == 0, 1.5, 1.0),
    border_color: pickColor(selectedLayer == 0, greenColor(), designBorder()),
    radius: 2.0,
    elevation: CuiElevation::Raised,
    clip: true
  };
  CuiId frameId = cui_row_begin(ui, &frame);
  buildDesignSidebar(ui, selectedLayer);
  buildDesignMain(ui, selectedLayer);
  cui_box_end(ui);
  return frameId;
}

void designBadge(CuiCtx ui, int selectedLayer) {
  CuiBox badgeRow = CuiBox{
    width: std::cui::fill(),
    height: std::cui::px(24.0),
    align: CuiAlign::Center,
    justify: CuiJustify::JustifyCenter
  };
  cui_row_begin(ui, &badgeRow);
  CuiBox badge = CuiBox{
    width: std::cui::fit(),
    height: std::cui::px(19.0),
    pad_left: 7.0,
    pad_right: 7.0,
    align: CuiAlign::Center,
    justify: CuiJustify::JustifyCenter,
    bg: greenColor(),
    radius: 4.0
  };
  cui_box_begin(ui, &badge);
  text(ui, layerDimensions(selectedLayer), 8.5, cardColor(), 1);
  cui_box_end(ui);
  cui_box_end(ui);
}

// ---------------------------------------------------------------------------
// Canvas and floating toolbar
// ---------------------------------------------------------------------------

void selectionHandle(CuiCtx ui, float x, float y) {
  CuiRect handle = CuiRect{x: x - 3.5, y: y - 3.5, w: 7.0, h: 7.0};
  CuiCorners corners = CuiCorners{tl: 1.0, tr: 1.0, br: 1.0, bl: 1.0};
  cui_draw_rect_border(ui, handle, corners, cardColor(), greenDark(), 1.0);
}

// FigCraft marks the active frame with a soft wash, quarter guides, and
// square handles. Drawn in screen space so it sits above the frame's content.
void drawCanvasSelection(CuiCtx ui, CuiRect frame) {
  if (frame.w <= 0.0 || frame.h <= 0.0) {
    return;
  }
  CuiCorners square = CuiCorners{tl: 2.0, tr: 2.0, br: 2.0, bl: 2.0};
  CuiCorners sharp = CuiCorners{tl: 0.0, tr: 0.0, br: 0.0, bl: 0.0};
  cui_draw_rect(ui, frame, square, std::cui::rgba(242, 78, 30, 10));

  CuiColor guide = std::cui::rgba(242, 78, 30, 28);
  float q1 = frame.x + frame.w * 0.25;
  float q2 = frame.x + frame.w * 0.50;
  float q3 = frame.x + frame.w * 0.75;
  cui_draw_line(ui, CuiVec2{x: q1, y: frame.y}, CuiVec2{x: q1, y: frame.y + frame.h}, 1.0, guide);
  cui_draw_line(ui, CuiVec2{x: q2, y: frame.y}, CuiVec2{x: q2, y: frame.y + frame.h}, 1.0, guide);
  cui_draw_line(ui, CuiVec2{x: q3, y: frame.y}, CuiVec2{x: q3, y: frame.y + frame.h}, 1.0, guide);

  cui_draw_rect_border(ui, frame, sharp, std::cui::rgba(0, 0, 0, 0), greenColor(), 1.5);

  // The overlay canvas clips to the frame, so keep each handle just inside it.
  float in = 4.0;
  float l = frame.x + in;
  float r = frame.x + frame.w - in;
  float t = frame.y + in;
  float b = frame.y + frame.h - in;
  float cx = frame.x + frame.w * 0.5;
  float cy = frame.y + frame.h * 0.5;
  selectionHandle(ui, l, t);
  selectionHandle(ui, r, t);
  selectionHandle(ui, l, b);
  selectionHandle(ui, r, b);
  selectionHandle(ui, cx, t);
  selectionHandle(ui, cx, b);
  selectionHandle(ui, l, cy);
  selectionHandle(ui, r, cy);
}

void paintSelection(CuiCtx ui, CuiRect rect, void* user) {
  drawCanvasSelection(ui, rect);
}

void handleShortcuts(CuiCtx ui, int* tool) {
  if (cui_key_pressed(ui, CuiKey::KeyV)) { *tool = 0; }
  if (cui_key_pressed(ui, CuiKey::KeyF)) { *tool = 1; }
  if (cui_key_pressed(ui, CuiKey::KeyR)) { *tool = 2; }
  if (cui_key_pressed(ui, CuiKey::KeyP)) { *tool = 3; }
  if (cui_key_pressed(ui, CuiKey::KeyT)) { *tool = 4; }
  if (cui_key_pressed(ui, CuiKey::KeyC)) { *tool = 5; }
  if (cui_key_pressed(ui, CuiKey::KeyK)) { *tool = 6; }
}

void toolButton(CuiCtx ui, const char* glyph, int index, int* tool, const char* tip) {
  bool selected = *tool == index;
  CuiBox button = CuiBox{
    id: tip,
    width: std::cui::px(27.0),
    height: std::cui::px(27.0),
    align: CuiAlign::Center,
    justify: CuiJustify::JustifyCenter,
    bg: pickColor(selected, greenColor(), std::cui::rgba(0, 0, 0, 0)),
    radius: 6.0
  };
  CuiId id = cui_box_begin(ui, &button);
  icon(ui, glyph, 14.0, pickColor(selected, navyColor(), secondaryText()));
  cui_box_end(ui);
  if (hoverRect(ui, id)) {
    cui_tooltip(ui, tip);
  }
  if (clickRect(ui, id)) {
    *tool = index;
  }
}

void flyoutMark(CuiCtx ui) {
  CuiBox mark = CuiBox{
    width: std::cui::px(16.0),
    height: std::cui::px(27.0),
    align: CuiAlign::Center,
    justify: CuiJustify::JustifyCenter
  };
  cui_box_begin(ui, &mark);
  icon(ui, std::cui::icons::chevronDown(), 10.0, mutedText());
  cui_box_end(ui);
}

void modeButton(CuiCtx ui, const char* glyph, int index, int* mode, const char* tip) {
  bool selected = *mode == index;
  CuiBox wrap = CuiBox{
    id: tip,
    width: std::cui::px(28.0),
    height: std::cui::px(26.0),
    align: CuiAlign::Center,
    justify: CuiJustify::JustifyCenter,
    bg: pickColor(selected, cardColor(), std::cui::rgba(0, 0, 0, 0)),
    border: pickFloat(selected, 1.0, 0.0),
    border_color: dividerColor(),
    radius: 6.0
  };
  CuiId id = cui_box_begin(ui, &wrap);
  icon(ui, glyph, 13.0, pickColor(selected, greenDark(), secondaryText()));
  cui_box_end(ui);
  if (hoverRect(ui, id)) {
    cui_tooltip(ui, tip);
  }
  if (clickRect(ui, id)) {
    *mode = index;
  }
}

void buildBottomToolbar(CuiCtx ui, int* tool, int* bottomMode) {
  CuiBox strip = CuiBox{
    width: std::cui::fill(),
    height: std::cui::px(64.0),
    align: CuiAlign::Center,
    justify: CuiJustify::JustifyCenter,
    bg: canvasColor()
  };
  cui_row_begin(ui, &strip);

  CuiBox toolbar = CuiBox{
    width: std::cui::fit(),
    height: std::cui::px(45.0),
    pad_left: 6.0,
    pad_right: 6.0,
    gap: 1.0,
    align: CuiAlign::Center,
    bg: cardColor(),
    border: 1.0,
    border_color: dividerColor(),
    radius: 13.0,
    elevation: CuiElevation::Floating
  };
  cui_row_begin(ui, &toolbar);

  toolButton(ui, std::cui::icons::move(), 0, tool, "Move (V)");
  flyoutMark(ui);
  toolButton(ui, std::cui::icons::grid(), 1, tool, "Frame (F)");
  flyoutMark(ui);
  toolButton(ui, std::cui::icons::square(), 2, tool, "Rectangle (R)");
  flyoutMark(ui);
  toolButton(ui, std::cui::icons::pencil(), 3, tool, "Pen (P)");
  flyoutMark(ui);
  toolButton(ui, std::cui::icons::textTool(), 4, tool, "Text (T)");
  flyoutMark(ui);
  toolButton(ui, std::cui::icons::message(), 5, tool, "Comment (C)");
  toolButton(ui, std::cui::icons::zap(), 6, tool, "Actions (Ctrl+K)");
  verticalLine(ui, 23.0, dividerColor());

  CuiBox modes = CuiBox{
    width: std::cui::px(102.0),
    height: std::cui::px(31.0),
    pad: 2.0,
    gap: 2.0,
    align: CuiAlign::Center,
    bg: fieldColor(),
    radius: 8.0
  };
  cui_row_begin(ui, &modes);
  modeButton(ui, std::cui::icons::pencil(), 0, bottomMode, "Draw");
  modeButton(ui, std::cui::icons::grid(), 1, bottomMode, "Layout");
  modeButton(ui, std::cui::icons::code(), 2, bottomMode, "Dev mode");
  cui_box_end(ui);

  cui_box_end(ui);
  cui_box_end(ui);
}

void canvasBadge(CuiCtx ui, const char* label) {
  CuiBox badge = CuiBox{
    width: std::cui::fit(),
    height: std::cui::px(22.0),
    pad_left: 8.0,
    pad_right: 8.0,
    align: CuiAlign::Center,
    justify: CuiJustify::JustifyCenter,
    bg: cardColor(),
    border: 1.0,
    border_color: dividerColor(),
    radius: 6.0
  };
  cui_box_begin(ui, &badge);
  text(ui, label, 9.0, secondaryText(), 0);
  cui_box_end(ui);
}

void buildCanvas(CuiCtx ui, int* selectedLayer, int* tool, int* bottomMode,
                 float* offsetX, float* offsetY, bool* dragging,
                 float* dragMouseX, float* dragMouseY) {
  CuiVec2 vp = cui_viewport_size(ui);
  float canvasW = vp.x - 600.0;
  float canvasH = vp.y - 50.0 - 64.0;
  float frameW = 816.0;
  float frameH = 544.0;

  float baseLeft = (canvasW - frameW) * 0.5;
  float baseTop = (canvasH - frameH - 24.0) * 0.5 + 26.0;
  if (baseTop < 10.0) { baseTop = 10.0; }
  if (baseLeft < 4.0) { baseLeft = 4.0; }

  float absLeft = 300.0 + baseLeft + *offsetX;
  float absTop = 50.0 + baseTop + *offsetY;
  CuiVec2 mouse = cui_mouse_pos(ui);
  CuiRect frameRect = CuiRect{x: absLeft, y: absTop, w: frameW, h: frameH};

  if (cui_mouse_clicked(ui, CuiMouseButton::MouseLeft) && inRect(frameRect, mouse)) {
    if (*tool == 0) {
      *dragging = true;
      *dragMouseX = mouse.x - absLeft;
      *dragMouseY = mouse.y - absTop;
      *selectedLayer = 0;
    } else {
      toast(ui, "Tool armed", "Draw inside the frame in the full editor.");
    }
  }

  if (*dragging) {
    if (cui_mouse_down(ui, CuiMouseButton::MouseLeft)) {
      *offsetX = mouse.x - *dragMouseX - (300.0 + baseLeft);
      *offsetY = mouse.y - *dragMouseY - (50.0 + baseTop);
    } else {
      *dragging = false;
    }
  }

  CuiBox canvas = CuiBox{
    width: std::cui::fill(),
    height: std::cui::fill(),
    gap: 0.0,
    bg: canvasColor()
  };
  cui_column_begin(ui, &canvas);

  float top = clampf(baseTop + *offsetY, 4.0, canvasH - 80.0);
  float left = clampf(baseLeft + *offsetX, -frameW + 80.0, canvasW - 80.0);

  CuiBox topPad = CuiBox{width: std::cui::fill(), height: std::cui::px(top)};
  cui_box_begin(ui, &topPad);
  cui_box_end(ui);

  CuiBox stageRow = CuiBox{
    width: std::cui::fill(),
    height: std::cui::px(frameH + 24.0),
    gap: 0.0
  };
  cui_row_begin(ui, &stageRow);

  if (left > 0.0) {
    CuiBox leftPad = CuiBox{width: std::cui::px(left), height: std::cui::px(1.0)};
    cui_box_begin(ui, &leftPad);
    cui_box_end(ui);
  }

  CuiBox stage = CuiBox{
    width: std::cui::px(frameW),
    height: std::cui::px(frameH + 24.0),
    gap: 0.0
  };
  cui_column_begin(ui, &stage);

  // A stack puts the frame and its paint-only selection canvas in the same
  // cell. The canvas paints after the frame, so the overlay sits on top.
  CuiBox frameStack = CuiBox{
    width: std::cui::fill(),
    height: std::cui::px(frameH),
    dir: CuiDir::Stack,
    gap: 0.0
  };
  cui_box_begin(ui, &frameStack);
  buildDesignFrame(ui, *selectedLayer);
  if (*selectedLayer == 0) {
    cui_push_disabled(ui, true);
    cui_canvas(ui, "selection-overlay", std::cui::px(frameW), std::cui::px(frameH),
               paintSelection, nullptr, 0);
    cui_pop_disabled(ui);
  }
  cui_box_end(ui);

  designBadge(ui, *selectedLayer);
  cui_box_end(ui);

  cui_spacer(ui);
  cui_box_end(ui);

  cui_spacer(ui);
  buildBottomToolbar(ui, tool, bottomMode);
  cui_box_end(ui);
}

// ---------------------------------------------------------------------------
// Design inspector
// ---------------------------------------------------------------------------

void inspectorSection(CuiCtx ui, const char* title, bool plus) {
  CuiBox row = CuiBox{
    width: std::cui::fill(),
    height: std::cui::px(27.0),
    align: CuiAlign::Center,
    gap: 4.0
  };
  cui_row_begin(ui, &row);
  text(ui, title, 10.5, textColor(), 1);
  cui_spacer(ui);
  if (plus) {
    if (flatIcon(ui, std::cui::icons::plus(), 13.0, mutedText(), "Add property")) {
      toast(ui, title, "Add a property in the full editor.");
    }
  }
  cui_box_end(ui);
}

void alignButton(CuiCtx ui, const char* glyph, const char* tip) {
  CuiBox button = CuiBox{
    width: std::cui::px(30.0),
    height: std::cui::px(27.0),
    align: CuiAlign::Center,
    justify: CuiJustify::JustifyCenter,
    bg: fieldColor(),
    radius: 5.0
  };
  CuiId id = cui_box_begin(ui, &button);
  icon(ui, glyph, 13.0, secondaryText());
  cui_box_end(ui);
  if (hoverRect(ui, id)) {
    cui_tooltip(ui, tip);
  }
}

void buildDesignInspector(CuiCtx ui, int selectedLayer, bool* clipContent, bool* fillVisible) {
  CuiBox body = CuiBox{
    width: std::cui::fill(),
    gap: 9.0
  };
  cui_column_begin(ui, &body);

  CuiBox typeRow = CuiBox{width: std::cui::fill(), height: std::cui::px(29.0), align: CuiAlign::Center, gap: 6.0};
  cui_row_begin(ui, &typeRow);
  text(ui, pickString(selectedLayer == 0, "Frame", "Group"), 11.0, textColor(), 1);
  icon(ui, std::cui::icons::chevronDown(), 11.0, secondaryText());
  cui_spacer(ui);
  flatIcon(ui, std::cui::icons::rotateCcw(), 13.0, secondaryText(), "Reset rotation");
  flatIcon(ui, std::cui::icons::link(), 13.0, secondaryText(), "Copy properties");
  flatIcon(ui, std::cui::icons::code(), 13.0, secondaryText(), "Copy as code");
  flatIcon(ui, std::cui::icons::grid(), 13.0, secondaryText(), "Layout grid");
  flatIcon(ui, std::cui::icons::square(), 13.0, secondaryText(), "Outline");
  cui_box_end(ui);

  sectionLabel(ui, "Position");
  CuiBox align = CuiBox{width: std::cui::fill(), gap: 5.0};
  cui_row_begin(ui, &align);
  alignButton(ui, std::cui::icons::alignLeft(), "Align left");
  alignButton(ui, std::cui::icons::layers(), "Align horizontal centers");
  alignButton(ui, std::cui::icons::grid(), "Align right");
  CuiBox alignGap = CuiBox{width: std::cui::px(6.0), height: std::cui::px(1.0)};
  cui_box_begin(ui, &alignGap);
  cui_box_end(ui);
  alignButton(ui, std::cui::icons::alignLeft(), "Align top");
  alignButton(ui, std::cui::icons::sliders(), "Align vertical centers");
  alignButton(ui, std::cui::icons::panelLeft(), "Align bottom");
  cui_box_end(ui);

  sectionLabel(ui, "Position");
  CuiBox position = CuiBox{width: std::cui::fill(), gap: 7.0};
  cui_row_begin(ui, &position);
  inspectorField(ui, "X", "0", 122.0);
  inspectorField(ui, "Y", "0", 122.0);
  cui_box_end(ui);

  sectionLabel(ui, "Rotation");
  CuiBox rotation = CuiBox{width: std::cui::fill(), gap: 5.0, align: CuiAlign::Center};
  cui_row_begin(ui, &rotation);
  inspectorField(ui, "∠", "0°", 122.0);
  flatIcon(ui, std::cui::icons::rotateCcw(), 13.0, secondaryText(), "Rotate");
  flatIcon(ui, std::cui::icons::square(), 13.0, secondaryText(), "Flip horizontal");
  flatIcon(ui, std::cui::icons::layers(), 13.0, secondaryText(), "Flip vertical");
  cui_box_end(ui);

  sectionDivider(ui);
  inspectorSection(ui, "Layout", true);
  sectionLabel(ui, "Dimensions");
  CuiBox dimensions = CuiBox{width: std::cui::fill(), gap: 5.0, align: CuiAlign::Center};
  cui_row_begin(ui, &dimensions);
  inspectorField(ui, "W", layerDimensions(selectedLayer), 122.0);
  inspectorField(ui, "H", "960", 122.0);
  flatIcon(ui, std::cui::icons::link(), 13.0, secondaryText(), "Constrain proportions");
  cui_box_end(ui);

  CuiCheckOpts clip = CuiCheckOpts{};
  cui_checkbox_ex(ui, "Clip content", clipContent, &clip);

  sectionDivider(ui);
  CuiBox appearanceHead = CuiBox{width: std::cui::fill(), height: std::cui::px(27.0), align: CuiAlign::Center};
  cui_row_begin(ui, &appearanceHead);
  text(ui, "Appearance", 10.5, textColor(), 1);
  cui_spacer(ui);
  flatIcon(ui, std::cui::icons::eye(), 13.0, secondaryText(), "Show layer");
  flatIcon(ui, std::cui::icons::target(), 13.0, secondaryText(), "Focus");
  flatIcon(ui, std::cui::icons::eyeOff(), 13.0, secondaryText(), "Hide");
  cui_box_end(ui);

  CuiBox appearance = CuiBox{width: std::cui::fill(), height: std::cui::px(28.0), gap: 7.0, align: CuiAlign::Center};
  cui_row_begin(ui, &appearance);
  inspectorField(ui, "◐", "100%", 122.0);
  inspectorField(ui, "⌜", "20", 122.0);
  cui_box_end(ui);

  sectionDivider(ui);
  inspectorSection(ui, "Fill", true);
  CuiBox fillRow = CuiBox{width: std::cui::fill(), height: std::cui::px(26.0), gap: 7.0, align: CuiAlign::Center};
  cui_row_begin(ui, &fillRow);
  flatIcon(ui, std::cui::icons::grip(), 12.0, mutedText(), "Reorder fill");
  CuiBox swatch = CuiBox{width: std::cui::px(15.0), height: std::cui::px(15.0), bg: designBg(), border: 1.0, border_color: borderColor(), radius: 3.0};
  cui_box_begin(ui, &swatch);
  cui_box_end(ui);
  text(ui, "Surface/Canvas", 10.0, secondaryText(), 0);
  cui_spacer(ui);
  if (flatIcon(ui, pickString(*fillVisible, std::cui::icons::eye(), std::cui::icons::eyeOff()), 12.0, mutedText(), "Toggle fill")) {
    *fillVisible = !*fillVisible;
  }
  flatIcon(ui, std::cui::icons::minus(), 12.0, mutedText(), "Remove fill");
  cui_box_end(ui);

  CuiBox fillValue = CuiBox{width: std::cui::fill(), height: std::cui::px(26.0), pad_left: 22.0, gap: 7.0, align: CuiAlign::Center};
  cui_row_begin(ui, &fillValue);
  CuiBox colorChip = CuiBox{width: std::cui::px(15.0), height: std::cui::px(15.0), bg: cardColor(), border: 1.0, border_color: borderColor(), radius: 3.0};
  cui_box_begin(ui, &colorChip);
  cui_box_end(ui);
  text(ui, "F3F5F8", 9.0, mutedText(), 0);
  cui_spacer(ui);
  text(ui, "100%", 9.0, secondaryText(), 0);
  flatIcon(ui, std::cui::icons::eye(), 12.0, mutedText(), "Show color");
  flatIcon(ui, std::cui::icons::minus(), 12.0, mutedText(), "Remove color");
  cui_box_end(ui);

  sectionDivider(ui);
  inspectorSection(ui, "Stroke", true);
  sectionDivider(ui);
  inspectorSection(ui, "Effects", true);
  sectionDivider(ui);
  inspectorSection(ui, "Selection colors", false);

  variableRow(ui, "Surface/Canvas", cardColor(), "Selected", "100%");
  variableRow(ui, "0E1726", navyColor(), "Ink", "100%");
  variableRow(ui, "Gradient", chartGreen(), "Accent", "100%");

  CuiBox endPad = CuiBox{width: std::cui::fill(), height: std::cui::px(8.0)};
  cui_box_begin(ui, &endPad);
  cui_box_end(ui);

  cui_box_end(ui);
}

void buildPrototypeInspector(CuiCtx ui) {
  CuiBox body = CuiBox{width: std::cui::fill(), gap: 10.0};
  cui_column_begin(ui, &body);
  text(ui, "Interactions", 10.5, textColor(), 1);
  CuiBox card = CuiBox{
    width: std::cui::fill(),
    pad: 10.0,
    gap: 6.0,
    bg: fieldColor(),
    radius: 6.0
  };
  cui_column_begin(ui, &card);
  text(ui, "On click", 9.5, mutedText(), 0);
  text(ui, "Navigate to Dashboard", 10.5, textColor(), 1);
  CuiBox delay = CuiBox{width: std::cui::fill(), height: std::cui::px(26.0), gap: 6.0, align: CuiAlign::Center};
  cui_row_begin(ui, &delay);
  text(ui, "Smart animate", 9.0, secondaryText(), 0);
  cui_spacer(ui);
  text(ui, "300 ms", 9.0, secondaryText(), 0);
  icon(ui, std::cui::icons::chevronDown(), 10.0, mutedText());
  cui_box_end(ui);
  cui_box_end(ui);

  CuiBox add = CuiBox{
    id: "add-interaction",
    width: std::cui::fill(),
    height: std::cui::px(30.0),
    align: CuiAlign::Center,
    justify: CuiJustify::JustifyCenter,
    border: 1.0,
    border_color: borderColor(),
    radius: 6.0
  };
  CuiId addId = cui_box_begin(ui, &add);
  icon(ui, std::cui::icons::plus(), 12.0, secondaryText());
  text(ui, "Add interaction", 9.5, secondaryText(), 0);
  cui_box_end(ui);
  if (clickRect(ui, addId)) {
    toast(ui, "Prototype", "Interactions are edited here in the full app.");
  }

  sectionDivider(ui);
  text(ui, "Flow starting points", 10.5, textColor(), 1);
  textWrapped(ui, "Present from the current frame to preview the flow with device chrome and hotspot hints.", 9.5, mutedText(), 0);

  CuiBox present = CuiBox{
    id: "present-flow",
    width: std::cui::fill(),
    height: std::cui::px(32.0),
    align: CuiAlign::Center,
    justify: CuiJustify::JustifyCenter,
    bg: greenColor(),
    radius: 6.0
  };
  CuiId presentId = cui_box_begin(ui, &present);
  icon(ui, std::cui::icons::play(), 11.0, navyColor());
  text(ui, "Present", 10.0, navyColor(), 1);
  cui_box_end(ui);
  if (clickRect(ui, presentId)) {
    toast(ui, "Present", "The presentation view is part of the full app.");
  }
  cui_box_end(ui);
}

void buildRightPanel(CuiCtx ui, int* rightTab, int selectedLayer, bool* clipContent, bool* fillVisible) {
  CuiBox panel = CuiBox{
    width: std::cui::px(300.0),
    height: std::cui::fill(),
    gap: 0.0,
    bg: cardColor(),
    border: 1.0,
    border_color: dividerColor()
  };
  cui_column_begin(ui, &panel);

  CuiBox head = CuiBox{
    width: std::cui::fill(),
    height: std::cui::px(52.0),
    pad_left: 16.0,
    pad_right: 14.0,
    gap: 8.0,
    align: CuiAlign::Center
  };
  cui_row_begin(ui, &head);
  CuiBox avatar = CuiBox{
    width: std::cui::px(26.0),
    height: std::cui::px(26.0),
    align: CuiAlign::Center,
    justify: CuiJustify::JustifyCenter,
    bg: navyColor(),
    radius: 13.0
  };
  cui_box_begin(ui, &avatar);
  text(ui, "MC", 7.5, cardColor(), 1);
  cui_box_end(ui);
  icon(ui, std::cui::icons::chevronDown(), 11.0, secondaryText());
  cui_spacer(ui);
  if (flatIcon(ui, std::cui::icons::play(), 15.0, textColor(), "Present file")) {
    toast(ui, "Present", "Opening the presentation view.");
  }
  icon(ui, std::cui::icons::chevronDown(), 10.0, mutedText());

  CuiBox share = CuiBox{
    id: "share-file",
    width: std::cui::px(76.0),
    height: std::cui::px(32.0),
    align: CuiAlign::Center,
    justify: CuiJustify::JustifyCenter,
    bg: greenColor(),
    radius: 8.0
  };
  CuiId shareId = cui_box_begin(ui, &share);
  text(ui, "Share", 11.0, navyColor(), 1);
  cui_box_end(ui);
  if (clickRect(ui, shareId)) {
    toast(ui, "Share link copied", "Anyone with the link can view this file.");
  }
  cui_box_end(ui);

  CuiBox tabs = CuiBox{
    width: std::cui::fill(),
    height: std::cui::px(44.0),
    pad_left: 16.0,
    pad_right: 14.0,
    gap: 5.0,
    align: CuiAlign::Center
  };
  cui_row_begin(ui, &tabs);

  CuiBox designTab = CuiBox{
    id: "inspector-design",
    width: std::cui::px(71.0),
    height: std::cui::px(27.0),
    align: CuiAlign::Center,
    justify: CuiJustify::JustifyCenter,
    bg: pickColor(*rightTab == 0, cardColor(), std::cui::rgba(0, 0, 0, 0)),
    border: pickFloat(*rightTab == 0, 1.0, 0.0),
    border_color: borderColor(),
    radius: 6.0
  };
  CuiId designId = cui_box_begin(ui, &designTab);
  text(ui, "Design", 10.5, pickColor(*rightTab == 0, textColor(), mutedText()), 0);
  cui_box_end(ui);
  if (clickRect(ui, designId)) { *rightTab = 0; }

  CuiBox prototypeTab = CuiBox{
    id: "inspector-prototype",
    width: std::cui::px(81.0),
    height: std::cui::px(27.0),
    align: CuiAlign::Center,
    justify: CuiJustify::JustifyCenter,
    radius: 6.0
  };
  CuiId prototypeId = cui_box_begin(ui, &prototypeTab);
  text(ui, "Prototype", 10.5, pickColor(*rightTab == 1, textColor(), mutedText()), 0);
  cui_box_end(ui);
  if (clickRect(ui, prototypeId)) { *rightTab = 1; }

  cui_spacer(ui);
  text(ui, "57%", 10.0, secondaryText(), 0);
  icon(ui, std::cui::icons::chevronDown(), 10.0, mutedText());
  cui_box_end(ui);
  horizontalLine(ui, dividerColor());

  CuiScrollOpts scroll = CuiScrollOpts{
    width: std::cui::fill(),
    height: std::cui::fill(),
    pad: 16.0,
    gap: 10.0
  };
  cui_scroll_begin(ui, &scroll);
  if (*rightTab == 0) {
    buildDesignInspector(ui, selectedLayer, clipContent, fillVisible);
  } else {
    buildPrototypeInspector(ui);
  }
  cui_scroll_end(ui);

  cui_box_end(ui);
}

// ---------------------------------------------------------------------------
// App
// ---------------------------------------------------------------------------

int main() {
  bool smoke = getenv("CUI_SMOKE") != nullptr;

  CuiAppDesc desc = CuiAppDesc{
    title: "FigCraft - Ridgeline Studio",
    width: 1440,
    height: 900,
    min_width: 1180,
    min_height: 760,
    theme: CuiThemeMode::Light,
    accent: CuiAccent::Green,
    hidden: smoke,
    continuous: smoke
  };

  CuiApp app = cui_app_create(&desc);
  if (app == nullptr) {
    return 1;
  }
  defer cui_app_destroy(app);

  int leftTab = 0;
  int selectedPage = 0;
  int selectedLayer = 0;
  int rightTab = 0;
  int tool = 0;
  int bottomMode = 0;
  bool clipContent = true;
  bool fillVisible = true;
  bool dragging = false;
  float dragMouseX = 0.0;
  float dragMouseY = 0.0;
  float offsetX = 0.0;
  float offsetY = 0.0;
  int frames = 0;

  while (cui_app_frame(app)) {
    CuiCtx ui = cui_app_ui(app);
    handleShortcuts(ui, &tool);

    CuiBox root = CuiBox{
      width: std::cui::fill(),
      height: std::cui::fill(),
      gap: 0.0,
      bg: chromeColor()
    };
    cui_column_begin(ui, &root);

    buildTopBar(ui, app);

    CuiBox main = CuiBox{
      width: std::cui::fill(),
      height: std::cui::fill(),
      gap: 0.0
    };
    cui_row_begin(ui, &main);

    buildRail(ui, &leftTab);
    buildLeftPanel(ui, leftTab, &selectedPage, &selectedLayer);
    buildCanvas(ui, &selectedLayer, &tool, &bottomMode,
                &offsetX, &offsetY, &dragging, &dragMouseX, &dragMouseY);
    buildRightPanel(ui, &rightTab, selectedLayer, &clipContent, &fillVisible);

    cui_box_end(ui);
    cui_box_end(ui);

    frames++;
    if (smoke && frames >= 3) {
      cui_app_quit(app);
    }
  }

  return 0;
}
