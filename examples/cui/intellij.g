// IntelliJ IDEA UI mock built with Glang and CUI.
//
// Every widget is drawn by CUI in immediate mode. The menu bar, toolbar,
// status bar, editor tabs, project tree, and code editor are the native CUI
// components exposed by std/cui.g; the surrounding chrome is ordinary boxes.
//
// Build with examples/cui/build.cmd. Set CUI_SMOKE=1 for a hidden three-frame
// run (used by the build script).

import std.cui;

[[extern, c_abi]]
char* getenv(const char* name);

CuiColor panelColor() => std::cui::rgb(43, 45, 48);
CuiColor editorColor() => std::cui::rgb(30, 31, 34);
CuiColor borderColor() => std::cui::rgb(57, 59, 64);
CuiColor textColor() => std::cui::rgb(223, 225, 229);
CuiColor secondaryText() => std::cui::rgb(188, 190, 196);
CuiColor mutedText() => std::cui::rgb(140, 142, 148);
CuiColor accentColor() => std::cui::rgb(53, 116, 240);
CuiColor successColor() => std::cui::rgb(106, 171, 115);
CuiColor warningColor() => std::cui::rgb(207, 142, 109);
CuiColor selectedRow() => std::cui::rgb(46, 67, 110);

void copyBytes(char* destination, const char* source, int count) {
  int index = 0;
  while (index < count) {
    destination[index] = source[index];
    index++;
  }
}

void copyText(char* destination, const char* source) {
  ulong index = 0;
  while (source[index] != '\0') {
    destination[index] = source[index];
    index++;
  }
  destination[index] = '\0';
}

void notify(CuiCtx ui, const char* title, const char* description) {
  CuiToastOpts toast = CuiToastOpts{
    description: description,
    tone: CuiTone::ToneInfo,
    duration: 2.0
  };
  cui_toast_ex(ui, title, &toast);
}

bool menuItem(CuiCtx ui, const char* label, const char* shortcut) {
  CuiMenuItemOpts opts = CuiMenuItemOpts{shortcut: shortcut};
  return cui_menu_item_ex(ui, label, &opts);
}

bool toolButton(CuiCtx ui, const char* icon, const char* tooltip) {
  CuiToolOpts opts = CuiToolOpts{tooltip: tooltip};
  return cui_toolbar_button_ex(ui, icon, &opts);
}

bool toolButtonShortcut(CuiCtx ui, const char* icon, const char* tooltip, const char* shortcut) {
  CuiToolOpts opts = CuiToolOpts{tooltip: tooltip, shortcut: shortcut};
  return cui_toolbar_button_ex(ui, icon, &opts);
}

bool railButton(CuiCtx ui, const char* icon, bool selected, const char* tooltip) {
  CuiButtonOpts opts = CuiButtonOpts{
    variant: CuiButtonVariant::ButtonGhost,
    size: CuiControlSize::SizeSmall,
    full_width: true,
    selected: selected
  };
  bool clicked = cui_icon_button_ex(ui, icon, &opts);
  cui_tooltip(ui, tooltip);
  return clicked;
}

bool headerButton(CuiCtx ui, const char* icon, const char* tooltip) {
  CuiButtonOpts opts = CuiButtonOpts{
    variant: CuiButtonVariant::ButtonGhost,
    size: CuiControlSize::SizeSmall
  };
  bool clicked = cui_icon_button_ex(ui, icon, &opts);
  cui_tooltip(ui, tooltip);
  return clicked;
}

void monoLine(CuiCtx ui, const char* text, CuiColor color) {
  CuiTextOpts opts = CuiTextOpts{
    font: 3,
    size: 12.0,
    color: color,
    nowrap: true
  };
  cui_text_ex(ui, text, &opts);
}

void bodyText(CuiCtx ui, const char* text, CuiColor color) {
  CuiTextOpts opts = CuiTextOpts{
    font: 0,
    size: 12.5,
    color: color
  };
  cui_text_ex(ui, text, &opts);
}

void bodyTextWrapped(CuiCtx ui, const char* text, CuiColor color) {
  CuiTextOpts opts = CuiTextOpts{
    font: 0,
    size: 12.5,
    color: color,
    width: std::cui::fill()
  };
  cui_text_ex(ui, text, &opts);
}

void mutedText(CuiCtx ui, const char* text) {
  CuiTextOpts opts = CuiTextOpts{
    font: 0,
    size: 11.5,
    color: mutedText()
  };
  cui_text_ex(ui, text, &opts);
}

void sectionTitle(CuiCtx ui, const char* text) {
  CuiTextOpts opts = CuiTextOpts{
    font: 1,
    size: 12.5,
    color: textColor(),
    nowrap: true
  };
  cui_text_ex(ui, text, &opts);
}

void buildMenuBar(CuiCtx ui) {
  CuiMenuBarOpts bar = CuiMenuBarOpts{no_border: true};
  cui_menu_bar_begin(ui, "idea-menu-bar", &bar);

  CuiMenuBarMenuOpts menu = CuiMenuBarMenuOpts{};

  if (cui_menu_bar_menu_begin(ui, "File", &menu)) {
    menuItem(ui, "New Project...", "Ctrl+Alt+Shift+N");
    menuItem(ui, "Open...", "Ctrl+O");
    cui_menu_label(ui, "Recent Projects");
    menuItem(ui, "Close Project", nullptr);
    cui_menu_separator(ui);
    menuItem(ui, "Save All", "Ctrl+S");
    menuItem(ui, "Reload from Disk", nullptr);
    cui_menu_separator(ui);
    menuItem(ui, "Exit", nullptr);
    cui_menu_bar_menu_end(ui);
  }

  if (cui_menu_bar_menu_begin(ui, "Edit", &menu)) {
    menuItem(ui, "Undo", "Ctrl+Z");
    menuItem(ui, "Redo", "Ctrl+Shift+Z");
    cui_menu_separator(ui);
    menuItem(ui, "Cut", "Ctrl+X");
    menuItem(ui, "Copy", "Ctrl+C");
    menuItem(ui, "Paste", "Ctrl+V");
    cui_menu_separator(ui);
    menuItem(ui, "Find...", "Ctrl+F");
    menuItem(ui, "Replace...", "Ctrl+R");
    cui_menu_bar_menu_end(ui);
  }

  if (cui_menu_bar_menu_begin(ui, "View", &menu)) {
    menuItem(ui, "Tool Windows", nullptr);
    menuItem(ui, "Project", "Alt+1");
    menuItem(ui, "Build", "Alt+0");
    menuItem(ui, "Problems", "Alt+6");
    menuItem(ui, "Terminal", "Alt+F12");
    cui_menu_separator(ui);
    menuItem(ui, "Appearance", nullptr);
    menuItem(ui, "Quick Switch Scheme...", "Ctrl+Backquote");
    cui_menu_bar_menu_end(ui);
  }

  if (cui_menu_bar_menu_begin(ui, "Navigate", &menu)) {
    menuItem(ui, "Class...", "Ctrl+N");
    menuItem(ui, "File...", "Ctrl+Shift+N");
    menuItem(ui, "Symbol...", "Ctrl+Alt+Shift+N");
    menuItem(ui, "Line...", "Ctrl+G");
    cui_menu_separator(ui);
    menuItem(ui, "Back", "Ctrl+Alt+Left");
    menuItem(ui, "Forward", "Ctrl+Alt+Right");
    cui_menu_bar_menu_end(ui);
  }

  if (cui_menu_bar_menu_begin(ui, "Code", &menu)) {
    menuItem(ui, "Generate...", "Alt+Insert");
    menuItem(ui, "Override Methods...", "Ctrl+O");
    menuItem(ui, "Implement Methods...", "Ctrl+I");
    cui_menu_separator(ui);
    menuItem(ui, "Reformat Code", "Ctrl+Alt+L");
    menuItem(ui, "Optimize Imports", "Ctrl+Alt+O");
    menuItem(ui, "Folding", nullptr);
    cui_menu_bar_menu_end(ui);
  }

  if (cui_menu_bar_menu_begin(ui, "Run", &menu)) {
    menuItem(ui, "Run 'Main'", "Shift+F10");
    menuItem(ui, "Debug 'Main'", "Shift+F9");
    menuItem(ui, "Stop", "Ctrl+F2");
    cui_menu_separator(ui);
    menuItem(ui, "Edit Configurations...", nullptr);
    menuItem(ui, "Run Anything", "Ctrl+Ctrl");
    cui_menu_bar_menu_end(ui);
  }

  if (cui_menu_bar_menu_begin(ui, "Tools", &menu)) {
    menuItem(ui, "Glang", nullptr);
    menuItem(ui, "Build System", nullptr);
    menuItem(ui, "Terminal", "Alt+F12");
    cui_menu_separator(ui);
    menuItem(ui, "AI Assistant", nullptr);
    menuItem(ui, "Tasks & Contexts", nullptr);
    cui_menu_bar_menu_end(ui);
  }

  if (cui_menu_bar_menu_begin(ui, "VCS", &menu)) {
    menuItem(ui, "Commit...", "Ctrl+K");
    menuItem(ui, "Update Project...", "Ctrl+T");
    menuItem(ui, "Push...", "Ctrl+Shift+K");
    cui_menu_separator(ui);
    menuItem(ui, "Branches...", nullptr);
    menuItem(ui, "Git", nullptr);
    cui_menu_bar_menu_end(ui);
  }

  if (cui_menu_bar_menu_begin(ui, "Window", &menu)) {
    menuItem(ui, "Editor Tabs", nullptr);
    menuItem(ui, "Tool Windows", nullptr);
    cui_menu_separator(ui);
    menuItem(ui, "Restore Default Layout", nullptr);
    menuItem(ui, "Store Current Layout as Default", nullptr);
    cui_menu_bar_menu_end(ui);
  }

  if (cui_menu_bar_menu_begin(ui, "Help", &menu)) {
    menuItem(ui, "Documentation", nullptr);
    menuItem(ui, "Keyboard Shortcuts PDF", nullptr);
    cui_menu_separator(ui);
    if (menuItem(ui, "About IntelliJ IDEA", nullptr)) {
      notify(ui, "IntelliJ IDEA", "Mock UI drawn with Glang and CUI 1.4.0");
    }
    cui_menu_bar_menu_end(ui);
  }

  cui_menu_bar_end(ui);
}

void buildToolbar(CuiCtx ui) {
  CuiToolbarOpts opts = CuiToolbarOpts{
    no_border: true,
    style: CuiToolbarStyle::ToolbarPlain
  };
  cui_toolbar_begin(ui, "idea-toolbar", &opts);

  if (toolButtonShortcut(ui, std::cui::icons::arrowLeft(), "Back", "Ctrl+Alt+Left")) {
    notify(ui, "Navigate", "Back");
  }
  if (toolButtonShortcut(ui, std::cui::icons::arrowRight(), "Forward", "Ctrl+Alt+Right")) {
    notify(ui, "Navigate", "Forward");
  }
  cui_toolbar_separator(ui);

  toolButtonShortcut(ui, std::cui::icons::play(), "Run 'Main'", "Shift+F10");
  toolButtonShortcut(ui, std::cui::icons::bug(), "Debug 'Main'", "Shift+F9");
  toolButtonShortcut(ui, std::cui::icons::stop(), "Stop", "Ctrl+F2");
  cui_toolbar_separator(ui);

  if (toolButtonShortcut(ui, std::cui::icons::save(), "Save All", "Ctrl+S")) {
    notify(ui, "Files saved", "All changes have been written to disk.");
  }
  if (toolButtonShortcut(ui, std::cui::icons::search(), "Search Everywhere", "Shift+Shift")) {
    notify(ui, "Search", "Search Everywhere is part of the full IDE.");
  }
  cui_toolbar_separator(ui);

  CuiToolOpts branch = CuiToolOpts{
    label: "main",
    tooltip: "Git branch",
    shortcut: "Ctrl+Shift+Backquote"
  };
  if (cui_toolbar_button_ex(ui, std::cui::icons::gitBranch(), &branch)) {
    notify(ui, "Git", "Branch: main");
  }

  cui_toolbar_spacer(ui);

  CuiToolOpts runConfig = CuiToolOpts{
    label: "Main",
    tooltip: "Run configuration",
    shortcut: "Shift+F10"
  };
  cui_toolbar_button_ex(ui, std::cui::icons::play(), &runConfig);
  toolButton(ui, std::cui::icons::settings(), "Settings");

  cui_toolbar_end(ui);
}

void buildProjectTree(CuiCtx ui, int* selectedFile, bool* openRoot, bool* openIdea,
                      bool* openSrc, bool* openApp, bool* openConfig) {
  CuiTreeOpts folder = CuiTreeOpts{};
  CuiTreeOpts file = CuiTreeOpts{leaf: true, icon: std::cui::icons::fileText()};

  if (cui_tree_begin(ui, "glang-idea", openRoot, &folder)) {
    if (cui_tree_begin(ui, ".idea", openIdea, &folder)) {
      file.selected = *selectedFile == 10;
      if (cui_tree_begin(ui, "misc.xml", openIdea, &file)) { cui_tree_end(ui); }
      if (cui_tree_clicked(ui)) { *selectedFile = 10; }
      file.selected = *selectedFile == 11;
      if (cui_tree_begin(ui, "workspace.xml", openIdea, &file)) { cui_tree_end(ui); }
      if (cui_tree_clicked(ui)) { *selectedFile = 11; }
      cui_tree_end(ui);
    }

    if (cui_tree_begin(ui, "src", openSrc, &folder)) {
      if (cui_tree_begin(ui, "app", openApp, &folder)) {
        file.selected = *selectedFile == 1;
        if (cui_tree_begin(ui, "ProjectService.g", openApp, &file)) { cui_tree_end(ui); }
        if (cui_tree_clicked(ui)) { *selectedFile = 1; }

        file.selected = *selectedFile == 2;
        if (cui_tree_begin(ui, "Main.g", openApp, &file)) { cui_tree_end(ui); }
        if (cui_tree_clicked(ui)) { *selectedFile = 2; }

        file.selected = *selectedFile == 3;
        if (cui_tree_begin(ui, "Settings.g", openApp, &file)) { cui_tree_end(ui); }
        if (cui_tree_clicked(ui)) { *selectedFile = 3; }
        cui_tree_end(ui);
      }

      if (cui_tree_begin(ui, "config", openConfig, &folder)) {
        file.selected = *selectedFile == 4;
        if (cui_tree_begin(ui, "defaults.g", openConfig, &file)) { cui_tree_end(ui); }
        if (cui_tree_clicked(ui)) { *selectedFile = 4; }

        file.selected = *selectedFile == 5;
        if (cui_tree_begin(ui, "theme.g", openConfig, &file)) { cui_tree_end(ui); }
        if (cui_tree_clicked(ui)) { *selectedFile = 5; }
        cui_tree_end(ui);
      }
      cui_tree_end(ui);
    }

    CuiTreeOpts build = CuiTreeOpts{leaf: true, icon: std::cui::icons::terminal(), selected: *selectedFile == 6};
    if (cui_tree_begin(ui, "build.cmd", openRoot, &build)) { cui_tree_end(ui); }
    if (cui_tree_clicked(ui)) { *selectedFile = 6; }

    CuiTreeOpts readme = CuiTreeOpts{leaf: true, icon: std::cui::icons::file(), selected: *selectedFile == 7};
    if (cui_tree_begin(ui, "README.md", openRoot, &readme)) { cui_tree_end(ui); }
    if (cui_tree_clicked(ui)) { *selectedFile = 7; }

    cui_tree_end(ui);
  }
}

void buildProjectPanel(CuiCtx ui, int railTool, int* selectedFile, char* filter,
                       bool* openRoot, bool* openIdea, bool* openSrc, bool* openApp,
                       bool* openConfig) {
  const char* title = "Project";
  if (railTool == 1) { title = "Commit"; }
  else if (railTool == 2) { title = "Structure"; }
  else if (railTool == 3) { title = "Problems"; }
  else if (railTool == 4) { title = "Terminal"; }
  else if (railTool == 5) { title = "Services"; }

  CuiBox panel = CuiBox{
    width: std::cui::px(300.0),
    height: std::cui::fill(),
    gap: 0.0,
    bg: panelColor(),
    border: 1.0,
    border_color: borderColor()
  };
  cui_column_begin(ui, &panel);

  CuiBox header = CuiBox{
    width: std::cui::fill(),
    height: std::cui::px(38.0),
    pad_left: 12.0,
    pad_right: 6.0,
    align: CuiAlign::Center,
    gap: 4.0
  };
  cui_row_begin(ui, &header);
  sectionTitle(ui, title);
  cui_spacer(ui);
  headerButton(ui, std::cui::icons::plus(), "New");
  headerButton(ui, std::cui::icons::refresh(), "Reload from Disk");
  headerButton(ui, std::cui::icons::more(), "More Actions");
  cui_box_end(ui);

  if (railTool == 0) {
    CuiBox searchWrap = CuiBox{
      width: std::cui::fill(),
      pad_left: 8.0,
      pad_right: 8.0,
      pad_top: 4.0,
      pad_bottom: 4.0
    };
    cui_column_begin(ui, &searchWrap);
    CuiInputOpts search = CuiInputOpts{
      placeholder: "Search files",
      icon: std::cui::icons::search(),
      size: CuiControlSize::SizeSmall,
      width: std::cui::fill(),
      height: 28.0
    };
    cui_search_ex(ui, "project-filter", filter, 64, &search);
    cui_box_end(ui);

    CuiScrollOpts scroll = CuiScrollOpts{
      width: std::cui::fill(),
      height: std::cui::fill(),
      pad: 6.0,
      gap: 1.0
    };
    cui_scroll_begin(ui, &scroll);
    buildProjectTree(ui, selectedFile, openRoot, openIdea, openSrc, openApp,
                     openConfig);
    cui_scroll_end(ui);
  } else {
    CuiEmptyOpts empty = CuiEmptyOpts{
      icon: std::cui::icons::layers(),
      description: "This tool window is part of the mock chrome."
    };
    cui_empty_state_ex(ui, title, &empty);
  }

  cui_box_end(ui);
}

void buildEditorTabs(CuiCtx ui, CuiDocTab* tabs, int* selectedTab) {
  CuiDocTabsOpts opts = CuiDocTabsOpts{shortcuts: true};
  CuiDocTabsResult result = cui_doc_tabs_ex(ui, "idea-doc-tabs", tabs, 3, selectedTab, &opts);
  if (result.close >= 0 && result.close < 3) {
    CuiToastOpts toast = CuiToastOpts{
      description: tabs[result.close].title,
      tone: CuiTone::ToneInfo,
      duration: 2.0
    };
    cui_toast_ex(ui, "Close tab requested", &toast);
  }
}

void buildBreadcrumbs(CuiCtx ui, const char* fileName) {
  CuiBox crumbs = CuiBox{
    width: std::cui::fill(),
    height: std::cui::px(28.0),
    pad_left: 14.0,
    pad_right: 14.0,
    align: CuiAlign::Center,
    gap: 4.0
  };
  cui_row_begin(ui, &crumbs);
  mutedText(ui, "glang-idea");
  mutedText(ui, ">");
  mutedText(ui, "src");
  mutedText(ui, ">");
  mutedText(ui, "app");
  mutedText(ui, ">");
  sectionTitle(ui, fileName);
  cui_box_end(ui);
}

void buildEditor(CuiCtx ui, char* code, int* caretLine, int* caretColumn) {
  CuiCodeEditorOpts opts = CuiCodeEditorOpts{
    lang: "glang",
    width: std::cui::fill(),
    height: -1.0,
    size: 13.0,
    tab_size: 4,
    read_only: false,
    no_line_numbers: false,
    placeholder: "Open a Glang file to start editing"
  };

  CuiCodeEditorResult result = cui_code_editor_ex(ui, "idea-editor", code, 8192, &opts);
  if (result.line > 0) {
    *caretLine = result.line;
    *caretColumn = result.column;
  }
}

void buildBottomPanel(CuiCtx ui, int* bottomTab) {
  CuiBox panel = CuiBox{
    width: std::cui::fill(),
    height: std::cui::px(188.0),
    gap: 0.0,
    bg: panelColor(),
    border: 1.0,
    border_color: borderColor()
  };
  cui_column_begin(ui, &panel);

  char[26] tabText;
  copyBytes(&tabText[0], "Run\0Problems\0Terminal\0Git\0", 26);
  const char*[4] tabLabels;
  tabLabels[0] = &tabText[0];
  tabLabels[1] = &tabText[4];
  tabLabels[2] = &tabText[13];
  tabLabels[3] = &tabText[22];
  CuiTabsOpts tabsOpts = CuiTabsOpts{variant: CuiTabsVariant::TabsUnderline};
  cui_tabs_ex(ui, "idea-bottom-tabs", &tabLabels[0], 4, bottomTab, &tabsOpts);

  CuiScrollOpts scroll = CuiScrollOpts{
    width: std::cui::fill(),
    height: std::cui::fill(),
    pad: 10.0,
    gap: 1.0
  };
  cui_scroll_begin(ui, &scroll);

  if (*bottomTab == 0) {
    monoLine(ui, "> Task :compileGlang", mutedText());
    monoLine(ui, "> Task :linkGlang", mutedText());
    monoLine(ui, "> Task :classes", mutedText());
    monoLine(ui, "", secondaryText());
    monoLine(ui, "BUILD SUCCESSFUL in 1s 204ms", successColor());
    monoLine(ui, "3 actionable tasks: 3 executed", secondaryText());
    monoLine(ui, "", secondaryText());
    monoLine(ui, "[WARN] unused import 'std.cui' in Main.g", warningColor());
  } else if (*bottomTab == 1) {
    CuiAlertOpts alert = CuiAlertOpts{
      description: "Unused import 'std.cui' in Main.g",
      tone: CuiTone::ToneWarning,
      icon: std::cui::icons::alert()
    };
    cui_alert_ex(ui, "1 warning, 0 errors", &alert);
    monoLine(ui, "Main.g:3  unused import 'std.cui'", warningColor());
  } else if (*bottomTab == 2) {
    monoLine(ui, "$ .\\build.cmd", secondaryText());
    monoLine(ui, "[INFO] gcli build src/app/Main.g --cpp", mutedText());
    monoLine(ui, "[INFO] g++ -std=c++26 build/app/Main.cpp", mutedText());
    monoLine(ui, "[INFO] Build successful", mutedText());
    monoLine(ui, "core, ui, tools", textColor());
    monoLine(ui, "BUILD SUCCESSFUL in 1s 802ms", successColor());
    monoLine(ui, "$ ", textColor());
  } else {
    CuiListItemOpts changed = CuiListItemOpts{
      icon: std::cui::icons::pencil(),
      subtitle: "Modified",
      trailing: "M",
      selected: true
    };
    cui_list_item_ex(ui, "src/app/ProjectService.g", &changed);
    CuiListItemOpts added = CuiListItemOpts{
      icon: std::cui::icons::plus(),
      subtitle: "Untracked",
      trailing: "A"
    };
    cui_list_item_ex(ui, "src/app/Settings.g", &added);
  }

  cui_scroll_end(ui);
  cui_box_end(ui);
}

void buildAiPanel(CuiCtx ui, char* prompt) {
  CuiBox panel = CuiBox{
    width: std::cui::px(300.0),
    height: std::cui::fill(),
    gap: 0.0,
    bg: panelColor(),
    border: 1.0,
    border_color: borderColor()
  };
  cui_column_begin(ui, &panel);

  CuiBox header = CuiBox{
    width: std::cui::fill(),
    height: std::cui::px(38.0),
    pad_left: 12.0,
    pad_right: 6.0,
    align: CuiAlign::Center,
    gap: 6.0
  };
  cui_row_begin(ui, &header);
  cui_icon(ui, std::cui::icons::sparkles(), 15.0, accentColor());
  sectionTitle(ui, "AI Assistant");
  CuiBadgeOpts beta = CuiBadgeOpts{tone: CuiTone::ToneViolet, size: CuiControlSize::SizeSmall};
  cui_badge_ex(ui, "Beta", &beta);
  cui_spacer(ui);
  headerButton(ui, std::cui::icons::more(), "More");
  cui_box_end(ui);

  CuiScrollOpts scroll = CuiScrollOpts{
    width: std::cui::fill(),
    height: std::cui::fill(),
    pad: 10.0,
    gap: 10.0
  };
  cui_scroll_begin(ui, &scroll);

  CuiCardOpts card = CuiCardOpts{
    width: std::cui::fill(),
    pad: 12.0,
    gap: 8.0,
    hoverable: true
  };
  if (cui_card_begin(ui, &card)) {
    notify(ui, "AI Assistant", "Explain the selected code");
  }
  CuiBox cardTitle = CuiBox{width: std::cui::fill(), gap: 4.0, align: CuiAlign::Center};
  cui_row_begin(ui, &cardTitle);
  cui_icon(ui, std::cui::icons::message(), 14.0, accentColor());
  sectionTitle(ui, "Explain activeModules()");
  cui_box_end(ui);
  bodyTextWrapped(ui, "Counts the modules that contain at least one file and returns the total.", secondaryText());
  cui_card_end(ui);

  CuiBox userMessage = CuiBox{
    width: std::cui::fill(),
    pad: 10.0,
    gap: 6.0,
    bg: selectedRow(),
    radius: 6.0
  };
  cui_column_begin(ui, &userMessage);
  sectionTitle(ui, "You");
  bodyTextWrapped(ui, "Why does describe() return a StringBuilder instead of a pointer?", textColor());
  cui_box_end(ui);

  CuiBox assistant = CuiBox{
    width: std::cui::fill(),
    pad: 10.0,
    gap: 6.0,
    bg: editorColor(),
    border: 1.0,
    border_color: borderColor(),
    radius: 6.0
  };
  cui_column_begin(ui, &assistant);
  CuiBox assistantHeader = CuiBox{width: std::cui::fill(), align: CuiAlign::Center, gap: 6.0};
  cui_row_begin(ui, &assistantHeader);
  CuiAvatarOpts avatar = CuiAvatarOpts{size: 20.0, status: "online"};
  cui_avatar_ex(ui, "Glang AI", &avatar);
  sectionTitle(ui, "Assistant");
  cui_box_end(ui);
  bodyTextWrapped(ui, "It walks the module list through a read-only pointer and appends each name to a local StringBuilder. The project state is never changed.", textColor());
  cui_box_end(ui);

  CuiBox context = CuiBox{
    width: std::cui::fill(),
    pad: 10.0,
    gap: 6.0,
    bg: editorColor(),
    border: 1.0,
    border_color: borderColor(),
    radius: 6.0
  };
  cui_column_begin(ui, &context);
  mutedText(ui, "Context");
  CuiBox contextRow = CuiBox{width: std::cui::fill(), align: CuiAlign::Center, gap: 6.0};
  cui_row_begin(ui, &contextRow);
  cui_icon(ui, std::cui::icons::fileText(), 14.0, accentColor());
  bodyText(ui, "ProjectService.g", secondaryText());
  cui_spacer(ui);
  mutedText(ui, "1 file");
  cui_box_end(ui);
  cui_box_end(ui);

  cui_scroll_end(ui);

  CuiBox composer = CuiBox{
    width: std::cui::fill(),
    pad: 10.0,
    border: 1.0,
    border_color: borderColor()
  };
  cui_column_begin(ui, &composer);
  CuiInputOpts input = CuiInputOpts{
    placeholder: "Ask AI Assistant...",
    icon: std::cui::icons::sparkles(),
    width: std::cui::fill()
  };
  cui_input_ex(ui, "ai-prompt", prompt, 128, &input);
  CuiBox hints = CuiBox{width: std::cui::fill(), align: CuiAlign::Center, gap: 6.0};
  cui_row_begin(ui, &hints);
  cui_kbd(ui, "Enter");
  mutedText(ui, "to send");
  cui_box_end(ui);
  cui_box_end(ui);

  cui_box_end(ui);
}

void buildStatusBar(CuiCtx ui, const char* fileName, int line, int column) {
  CuiStatusBarOpts bar = CuiStatusBarOpts{no_border: true};
  cui_status_bar_begin(ui, "idea-status-bar", &bar);

  CuiStatusItemOpts item = CuiStatusItemOpts{};
  item.icon = std::cui::icons::gitBranch();
  item.tooltip = "Git branch";
  cui_status_bar_item_ex(ui, "main", &item);

  item.icon = std::cui::icons::checkCircle();
  item.tone = CuiTone::ToneSuccess;
  item.tooltip = "No VCS problems";
  cui_status_bar_text_ex(ui, "glang-idea", &item);

  cui_status_bar_spacer(ui);

  item.icon = nullptr;
  item.tone = CuiTone::ToneNeutral;
  cui_status_bar_text_ex(ui, fileName, &item);
  cui_status_bar_item_ex(ui, "Glang", &item);
  cui_status_bar_item_ex(ui, "UTF-8", &item);
  cui_status_bar_item_ex(ui, "LF", &item);
  cui_status_bar_item_ex(ui, "4 spaces", &item);

  CuiStatusProgressOpts progress = CuiStatusProgressOpts{
    label: "Indexing",
    width: 132.0
  };
  cui_status_bar_progress_ex(ui, 0.78, &progress);

  item.icon = std::cui::icons::circleCheck();
  item.tone = CuiTone::ToneSuccess;
  cui_status_bar_text_ex(ui, "0 errors", &item);

  cui_textf(ui, "Ln %d, Col %d", line, column);

  cui_status_bar_end(ui);
}

int main() {
  bool smoke = getenv("CUI_SMOKE") != nullptr;

  CuiAppDesc desc = CuiAppDesc{
    title: "IntelliJ IDEA - glang-idea",
    width: 1440,
    height: 900,
    min_width: 1100,
    min_height: 700,
    theme: CuiThemeMode::Dark,
    accent: CuiAccent::Blue,
    hidden: smoke,
    continuous: smoke
  };

  CuiApp app = cui_app_create(&desc);
  if (app == nullptr) {
    return 1;
  }
  defer cui_app_destroy(app);

  char[8192] serviceCode;
  char[8192] mainCode;
  char[8192] settingsCode;
  char[64] projectFilter;
  char[128] aiPrompt;
  projectFilter[0] = '\0';
  aiPrompt[0] = '\0';

  copyText(&serviceCode[0], "// ProjectService.g - owns the module table for glang-idea.\nimport std.string;\nimport std.container.list : List;\n\nstruct Module {\n  const char* name;\n  const char* owner;\n  int files;\n}\n\nstruct ProjectService {\n  List<Module> modules;\n}\n\nProjectService makeService(Module[] seed) {\n  ProjectService service = ProjectService{};\n  for (int index = 0; index < seed.length; index = index + 1) {\n    service.modules.push_back(seed[index]);\n  }\n  return service;\n}\n\nint activeModules(ProjectService* service) {\n  int active = 0;\n  for (int index = 0; index < service->modules.size(); index = index + 1) {\n    Module module = service->modules[index];\n    if (module.files > 0) {\n      active = active + 1;\n    }\n  }\n  return active;\n}\n\nStringBuilder describe(ProjectService* service) {\n  StringBuilder summary = builder();\n  for (int index = 0; index < service->modules.size(); index = index + 1) {\n    Module module = service->modules[index];\n    if (module.files == 0) {\n      continue;\n    }\n    if (summary.len() > 0) {\n      summary = summary << \", \";\n    }\n    summary = summary << module.name;\n  }\n  return summary;\n}\n");

  copyText(&mainCode[0], "// Main.g - opens ProjectService and prints the active modules.\nimport std.io;\nimport std.string;\nimport std.cui;\nimport app.ProjectService;\n\nint main() {\n  Module[3] seed = [\n    Module{name: \"core\", owner: \"compiler\", files: 42},\n    Module{name: \"ui\", owner: \"runtime\", files: 18},\n    Module{name: \"tools\", owner: \"cli\", files: 9}\n  ];\n  ProjectService service = makeService(seed);\n  StringBuilder summary = describe(&service);\n  println(to_string(&summary));\n  return activeModules(&service);\n}\n");

  copyText(&settingsCode[0], "// Settings.g - editor and build preferences for glang-idea.\nimport std.string;\n\nstruct Settings {\n  bool wrapLines;\n  bool showLineNumbers;\n  int tabSize;\n  const char* theme;\n}\n\nSettings defaultSettings() {\n  return Settings{\n    wrapLines: false,\n    showLineNumbers: true,\n    tabSize: 4,\n    theme: \"intellij-dark\"\n  };\n}\n\nbool apply(Settings* settings, const char* key, const char* value) {\n  if (compare_strings(key, \"tabSize\") == 0) {\n    auto (size, ok) = parse_int(value);\n    if (ok) {\n      settings->tabSize = size;\n    }\n    return ok;\n  }\n  if (compare_strings(key, \"theme\") == 0) {\n    settings->theme = value;\n    return true;\n  }\n  return false;\n}\n");

  CuiDocTab[3] tabs;
  tabs[0] = CuiDocTab{
    title: "ProjectService.g",
    icon: std::cui::icons::fileText(),
    tooltip: "src/app/ProjectService.g"
  };
  tabs[1] = CuiDocTab{
    title: "Main.g",
    icon: std::cui::icons::fileText(),
    tooltip: "src/app/Main.g"
  };
  tabs[2] = CuiDocTab{
    title: "Settings.g",
    icon: std::cui::icons::fileText(),
    tooltip: "src/app/Settings.g",
    dirty: true
  };

  int selectedTab = 0;
  int selectedFile = 1;
  int railTool = 0;
  int bottomTab = 0;
  int caretLine = 25;
  int caretColumn = 3;
  int frames = 0;

  bool openRoot = true;
  bool openIdea = false;
  bool openSrc = true;
  bool openApp = true;
  bool openConfig = false;

  while (cui_app_frame(app)) {
    CuiCtx ui = cui_app_ui(app);

    CuiBox root = CuiBox{
      width: std::cui::fill(),
      height: std::cui::fill(),
      gap: 0.0,
      bg: editorColor()
    };
    cui_column_begin(ui, &root);

    buildMenuBar(ui);
    buildToolbar(ui);

    CuiBox main = CuiBox{
      width: std::cui::fill(),
      height: std::cui::fill(),
      gap: 0.0
    };
    cui_row_begin(ui, &main);

    CuiBox rail = CuiBox{
      width: std::cui::px(42.0),
      height: std::cui::fill(),
      pad_top: 6.0,
      pad_bottom: 6.0,
      gap: 3.0,
      align: CuiAlign::Center,
      bg: panelColor(),
      border: 1.0,
      border_color: borderColor()
    };
    cui_column_begin(ui, &rail);
    if (railButton(ui, std::cui::icons::folder(), railTool == 0, "Project")) { railTool = 0; }
    if (railButton(ui, std::cui::icons::gitBranch(), railTool == 1, "Commit")) { railTool = 1; }
    if (railButton(ui, std::cui::icons::layers(), railTool == 2, "Structure")) { railTool = 2; }
    if (railButton(ui, std::cui::icons::alert(), railTool == 3, "Problems")) { railTool = 3; }
    if (railButton(ui, std::cui::icons::terminal(), railTool == 4, "Terminal")) { railTool = 4; }
    if (railButton(ui, std::cui::icons::server(), railTool == 5, "Services")) { railTool = 5; }
    cui_spacer(ui);
    if (railButton(ui, std::cui::icons::settings(), false, "Settings")) {
      notify(ui, "Settings", "Preferences are part of the full IDE.");
    }
    cui_box_end(ui);

    buildProjectPanel(ui, railTool, &selectedFile, &projectFilter[0], &openRoot,
                      &openIdea, &openSrc, &openApp, &openConfig);

    CuiBox center = CuiBox{
      width: std::cui::fill(),
      height: std::cui::fill(),
      gap: 0.0,
      bg: editorColor()
    };
    cui_column_begin(ui, &center);

    buildEditorTabs(ui, &tabs[0], &selectedTab);

    const char* fileName = tabs[selectedTab].title;
    buildBreadcrumbs(ui, fileName);

    char* activeCode = &serviceCode[0];
    if (selectedTab == 1) {
      activeCode = &mainCode[0];
    } else if (selectedTab == 2) {
      activeCode = &settingsCode[0];
    }

    CuiBox editorArea = CuiBox{
      width: std::cui::fill(),
      height: std::cui::fill(),
      pad: 0.0,
      gap: 0.0
    };
    cui_column_begin(ui, &editorArea);
    buildEditor(ui, activeCode, &caretLine, &caretColumn);
    cui_box_end(ui);

    buildBottomPanel(ui, &bottomTab);
    cui_box_end(ui);

    buildAiPanel(ui, &aiPrompt[0]);
    cui_box_end(ui);

    buildStatusBar(ui, fileName, caretLine, caretColumn);
    cui_box_end(ui);

    frames++;
    if (smoke && frames >= 3) {
      cui_app_quit(app);
    }
  }

  return 0;
}
