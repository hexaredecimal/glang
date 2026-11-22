import std.cui;

int main() {
  CuiSize fill = std::cui::fill();
  if (fill.kind != CuiSizeKind::Grow || fill.value != 1.0) {
    return 1;
  }

  CuiSize fixed = std::cui::px(240.0);
  if (fixed.kind != CuiSizeKind::Fixed || fixed.value != 240.0) {
    return 2;
  }

  CuiSize percent = std::cui::pct(50.0);
  if (percent.kind != CuiSizeKind::Percent || percent.value != 50.0) {
    return 3;
  }

  CuiColor accent = std::cui::rgb(66, 133, 244);
  if (accent.r != 66 || accent.g != 133 || accent.b != 244 || accent.a != 255) {
    return 4;
  }

  CuiBox box = CuiBox{
    pad: 24.0,
    gap: 12.0,
    width: fill,
    align: CuiAlign::Center,
    justify: CuiJustify::JustifyBetween
  };
  if (box.pad != 24.0 || box.gap != 12.0 || box.width.kind != CuiSizeKind::Grow ||
      box.align != CuiAlign::Center || box.justify != CuiJustify::JustifyBetween) {
    return 5;
  }

  CuiButtonOpts button = CuiButtonOpts{
    variant: CuiButtonVariant::ButtonPrimary,
    size: CuiControlSize::SizeLarge,
    full_width: true
  };
  if (button.variant != CuiButtonVariant::ButtonPrimary ||
      button.size != CuiControlSize::SizeLarge || !button.full_width) {
    return 6;
  }

  CuiCheckOpts check = CuiCheckOpts{description: "Enabled", disabled: false};
  CuiSliderOpts slider = CuiSliderOpts{step: 0.1, show_value: true};
  CuiInputOpts input = CuiInputOpts{label: "Name", placeholder: "Type here", clearable: true};
  CuiProgressOpts progress = CuiProgressOpts{
    tone: CuiTone::ToneAccent,
    label: "Progress",
    show_value: true
  };
  float[3] chartValues;
  chartValues[0] = 4.0;
  chartValues[1] = 7.0;
  chartValues[2] = 5.0;
  CuiSeries series = CuiSeries{
    name: "Visitors",
    values: &chartValues[0],
    count: 3,
    color: accent
  };
  CuiChartOpts chart = CuiChartOpts{
    width: fill,
    height: 120.0,
    area: true,
    no_grid: true,
    smooth: true
  };
  if (check.description == nullptr || slider.step != 0.1 || input.label == nullptr ||
      progress.tone != CuiTone::ToneAccent || series.count != 3 ||
      chart.height != 120.0 || !chart.area) {
    return 7;
  }

  CuiScrollOpts scroll = CuiScrollOpts{
    id: "project-tree",
    width: fill,
    height: std::cui::px(320.0),
    horizontal: false,
    pad: 6.0,
    gap: 1.0,
    fade_edges: true
  };
  CuiSplitOpts split = CuiSplitOpts{vertical: true, min_first: 80.0, min_second: 120.0};
  if (scroll.width.kind != CuiSizeKind::Grow || scroll.height.value != 320.0 ||
      scroll.gap != 1.0 || split.min_first != 80.0) {
    return 9;
  }

  CuiMenuBarOpts menuBar = CuiMenuBarOpts{no_border: true};
  CuiMenuBarMenuOpts menu = CuiMenuBarMenuOpts{mnemonic: 'F'};
  CuiMenuItemOpts item = CuiMenuItemOpts{
    icon: std::cui::icons::save(),
    shortcut: "Ctrl+S",
    checked: true
  };
  CuiMenuOpts dropdown = CuiMenuOpts{variant: CuiButtonVariant::ButtonGhost, placement: CuiPlacement::PlaceBottomStart};
  if (!menuBar.no_border || menu.mnemonic != 'F' || item.shortcut == nullptr ||
      dropdown.placement != CuiPlacement::PlaceBottomStart) {
    return 10;
  }

  CuiToolbarOpts toolbar = CuiToolbarOpts{no_border: true, style: CuiToolbarStyle::ToolbarGrouped};
  CuiToolOpts tool = CuiToolOpts{
    label: "main",
    tooltip: "Git branch",
    shortcut: "Ctrl+Shift+Backquote"
  };
  CuiToolbarRadioOpts radio = CuiToolbarRadioOpts{};
  if (toolbar.style != CuiToolbarStyle::ToolbarGrouped || tool.label == nullptr || radio.labels != nullptr) {
    return 11;
  }

  CuiStatusBarOpts statusBar = CuiStatusBarOpts{no_border: true};
  CuiStatusItemOpts statusItem = CuiStatusItemOpts{
    icon: std::cui::icons::circleCheck(),
    tone: CuiTone::ToneSuccess,
    tooltip: "No errors"
  };
  CuiStatusProgressOpts statusProgress = CuiStatusProgressOpts{
    label: "Indexing",
    width: 132.0
  };
  if (!statusBar.no_border || statusItem.tone != CuiTone::ToneSuccess ||
      statusProgress.width != 132.0) {
    return 12;
  }

  CuiDocTab[3] tabs;
  tabs[0] = CuiDocTab{title: "ProjectService.g", icon: std::cui::icons::fileText()};
  tabs[1] = CuiDocTab{title: "Main.g", dirty: true};
  tabs[2] = CuiDocTab{title: "build.cmd", icon: std::cui::icons::terminal(), tooltip: "build.cmd"};
  CuiDocTabsOpts docOpts = CuiDocTabsOpts{shortcuts: true, no_reorder: true};
  CuiDocTabsResult docResult = CuiDocTabsResult{};
  if (tabs[2].tooltip == nullptr || !docOpts.shortcuts || docResult.close != 0) {
    return 13;
  }

  CuiNavOpts nav = CuiNavOpts{icon: std::cui::icons::gitBranch(), badge: "1", selected: true};
  CuiTreeOpts tree = CuiTreeOpts{icon: std::cui::icons::folder(), leaf: false, selected: true};
  CuiListItemOpts listItem = CuiListItemOpts{
    icon: std::cui::icons::pencil(),
    subtitle: "Modified",
    trailing: "M",
    selected: true
  };
  CuiTabBarItem tabBarItem = CuiTabBarItem{icon: std::cui::icons::terminal(), label: "Terminal", badge: 1};
  CuiTabBarOpts tabBar = CuiTabBarOpts{width: std::cui::px(520.0)};
  if (nav.badge == nullptr || tree.icon == nullptr || listItem.trailing == nullptr ||
      tabBarItem.badge != 1 || tabBar.width.value != 520.0) {
    return 14;
  }

  CuiPopoverOpts popover = CuiPopoverOpts{
    placement: CuiPlacement::PlaceRight,
    width: 280.0,
    pad: 12.0,
    gap: 8.0
  };
  CuiAvatarOpts avatar = CuiAvatarOpts{size: 24.0, status: "online", square: true};
  CuiEmptyOpts empty = CuiEmptyOpts{
    icon: std::cui::icons::layers(),
    description: "Nothing here yet",
    action: "Create"
  };
  CuiCommand command = CuiCommand{
    title: "Open File",
    icon: std::cui::icons::file(),
    group: "Navigate",
    shortcut: "Ctrl+Shift+N"
  };
  if (popover.placement != CuiPlacement::PlaceRight || avatar.image != 0 ||
      empty.action == nullptr || command.group == nullptr) {
    return 15;
  }

  CuiTextMark mark = CuiTextMark{start: 0, end: 4, color: 1};
  CuiCodeEditorOpts editor = CuiCodeEditorOpts{
    lang: "glang",
    width: fill,
    height: -1.0,
    size: 13.0,
    tab_size: 4,
    read_only: false,
    placeholder: "Open a file"
  };
  CuiCodeEditorResult editorResult = CuiCodeEditorResult{};
  if (mark.end != 4 || editor.lang == nullptr || editor.height != -1.0 ||
      editor.tab_size != 4 || editorResult.bracket != 0) {
    return 16;
  }

  const char*[4] tabLabels;
  tabLabels[0] = "Run";
  tabLabels[1] = "Problems";
  tabLabels[2] = "Terminal";
  tabLabels[3] = "Git";
  int bottomTab = 0;
  CuiTabsOpts bottomTabs = CuiTabsOpts{variant: CuiTabsVariant::TabsUnderline};
  cui_tabs_ex(nullptr, "bottom-tabs", &tabLabels[0], 4, &bottomTab, &bottomTabs);
  if (tabLabels[3] == nullptr || bottomTabs.variant != CuiTabsVariant::TabsUnderline) {
    return 17;
  }

  if (std::cui::icons::check() == nullptr || std::cui::icons::bug() == nullptr ||
      std::cui::icons::circleCheck() == nullptr || std::cui::icons::sparkles() == nullptr ||
      std::cui::icons::layers() == nullptr || std::cui::icons::grip() == nullptr ||
      std::cui::icons::textTool() == nullptr || std::cui::icons::home() == nullptr ||
      std::cui::icons::move() == nullptr || std::cui::icons::palette() == nullptr) {
    return 18;
  }

  CuiAppDesc desc = std::cui::appDesc("CUI binding test", 320, 240);
  desc.theme = CuiThemeMode::Dark;
  desc.accent = CuiAccent::Violet;
  desc.hidden = true;
  if (desc.title == nullptr || desc.width != 320 || desc.height != 240 ||
      desc.theme != CuiThemeMode::Dark || desc.accent != CuiAccent::Violet) {
    return 8;
  }

  CuiApp app = cui_app_create(&desc);
  if (app != nullptr) {
    CuiCtx ui = cui_app_ui(app);
    CuiButtonOpts defaults = CuiButtonOpts{};
    cui_button_ex(ui, "Test", &defaults);
    cui_app_destroy(app);
  }

  return 0;
}
