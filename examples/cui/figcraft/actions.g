// FigCraft Pure State Actions and Document Operations.
// Encapsulates tab management, page switching, layer CRUD, alignments,
// variable application, zoom, and workspace mode transitions.

import std.gui;
import std.cui;
import std.string;
import examples.cui.figcraft.palette;
import examples.cui.figcraft.model;
import examples.cui.figcraft.geometry;
import examples.cui.figcraft.scene;

int toolGroupOf(int toolIdx) {
  if (toolIdx == (ToolKind::ToolMove as int) ||
      toolIdx == (ToolKind::ToolHand as int) ||
      toolIdx == (ToolKind::ToolScale as int)) {
    return 0;
  }
  if (toolIdx == (ToolKind::ToolFrame as int) ||
      toolIdx == (ToolKind::ToolSection as int) ||
      toolIdx == (ToolKind::ToolSlice as int)) {
    return 1;
  }
  if (toolIdx == (ToolKind::ToolRect as int) ||
      toolIdx == (ToolKind::ToolLine as int) ||
      toolIdx == (ToolKind::ToolArrow as int) ||
      toolIdx == (ToolKind::ToolEllipse as int) ||
      toolIdx == (ToolKind::ToolPolygon as int) ||
      toolIdx == (ToolKind::ToolStar as int) ||
      toolIdx == (ToolKind::ToolImage as int)) {
    return 2;
  }
  if (toolIdx == (ToolKind::ToolPen as int) ||
      toolIdx == (ToolKind::ToolPencil as int)) {
    return 3;
  }
  if (toolIdx == (ToolKind::ToolText as int) ||
      toolIdx == (ToolKind::ToolBodyText as int) ||
      toolIdx == (ToolKind::ToolBadge as int)) {
    return 4;
  }
  return -1;
}

const char* toolGlyphOf(int toolIdx) {
  if (toolIdx == (ToolKind::ToolMove as int)) { return std::cui::icons::move(); }
  if (toolIdx == (ToolKind::ToolHand as int)) { return std::cui::icons::compass(); }
  if (toolIdx == (ToolKind::ToolScale as int)) { return std::cui::icons::maximize(); }
  if (toolIdx == (ToolKind::ToolFrame as int)) { return std::cui::icons::grid(); }
  if (toolIdx == (ToolKind::ToolSection as int)) { return std::cui::icons::box(); }
  if (toolIdx == (ToolKind::ToolSlice as int)) { return std::cui::icons::target(); }
  if (toolIdx == (ToolKind::ToolRect as int)) { return std::cui::icons::square(); }
  if (toolIdx == (ToolKind::ToolLine as int)) { return std::cui::icons::minus(); }
  if (toolIdx == (ToolKind::ToolArrow as int)) { return std::cui::icons::arrowRight(); }
  if (toolIdx == (ToolKind::ToolEllipse as int)) { return std::cui::icons::circle(); }
  if (toolIdx == (ToolKind::ToolPolygon as int)) { return std::cui::icons::layers(); }
  if (toolIdx == (ToolKind::ToolStar as int)) { return std::cui::icons::star(); }
  if (toolIdx == (ToolKind::ToolImage as int)) { return std::cui::icons::sparkles(); }
  if (toolIdx == (ToolKind::ToolPen as int)) { return std::cui::icons::pencil(); }
  if (toolIdx == (ToolKind::ToolPencil as int)) { return std::cui::icons::activity(); }
  if (toolIdx == (ToolKind::ToolText as int)) { return std::cui::icons::textTool(); }
  if (toolIdx == (ToolKind::ToolBodyText as int)) { return std::cui::icons::fileText(); }
  if (toolIdx == (ToolKind::ToolBadge as int)) { return std::cui::icons::tag(); }
  if (toolIdx == (ToolKind::ToolComment as int)) { return std::cui::icons::message(); }
  return std::cui::icons::zap();
}

const char* toolLabelOf(int toolIdx) {
  if (toolIdx == (ToolKind::ToolMove as int)) { return "Move"; }
  if (toolIdx == (ToolKind::ToolHand as int)) { return "Hand tool"; }
  if (toolIdx == (ToolKind::ToolScale as int)) { return "Scale"; }
  if (toolIdx == (ToolKind::ToolFrame as int)) { return "Frame"; }
  if (toolIdx == (ToolKind::ToolSection as int)) { return "Section"; }
  if (toolIdx == (ToolKind::ToolSlice as int)) { return "Slice"; }
  if (toolIdx == (ToolKind::ToolRect as int)) { return "Rectangle"; }
  if (toolIdx == (ToolKind::ToolLine as int)) { return "Line"; }
  if (toolIdx == (ToolKind::ToolArrow as int)) { return "Arrow"; }
  if (toolIdx == (ToolKind::ToolEllipse as int)) { return "Ellipse"; }
  if (toolIdx == (ToolKind::ToolPolygon as int)) { return "Polygon"; }
  if (toolIdx == (ToolKind::ToolStar as int)) { return "Star"; }
  if (toolIdx == (ToolKind::ToolImage as int)) { return "Place image"; }
  if (toolIdx == (ToolKind::ToolPen as int)) { return "Pen"; }
  if (toolIdx == (ToolKind::ToolPencil as int)) { return "Pencil"; }
  if (toolIdx == (ToolKind::ToolText as int)) { return "Heading text"; }
  if (toolIdx == (ToolKind::ToolBodyText as int)) { return "Body text"; }
  if (toolIdx == (ToolKind::ToolBadge as int)) { return "Pill / Label"; }
  if (toolIdx == (ToolKind::ToolComment as int)) { return "Comment"; }
  return "Actions";
}

const char* toolShortcutOf(int toolIdx) {
  if (toolIdx == (ToolKind::ToolMove as int)) { return "V"; }
  if (toolIdx == (ToolKind::ToolHand as int)) { return "H"; }
  if (toolIdx == (ToolKind::ToolScale as int)) { return "Shift+K"; }
  if (toolIdx == (ToolKind::ToolFrame as int)) { return "F"; }
  if (toolIdx == (ToolKind::ToolSection as int)) { return "Shift+S"; }
  if (toolIdx == (ToolKind::ToolSlice as int)) { return "S"; }
  if (toolIdx == (ToolKind::ToolRect as int)) { return "R"; }
  if (toolIdx == (ToolKind::ToolLine as int)) { return "L"; }
  if (toolIdx == (ToolKind::ToolArrow as int)) { return "Shift+L"; }
  if (toolIdx == (ToolKind::ToolEllipse as int)) { return "O"; }
  if (toolIdx == (ToolKind::ToolPolygon as int)) { return ""; }
  if (toolIdx == (ToolKind::ToolStar as int)) { return ""; }
  if (toolIdx == (ToolKind::ToolImage as int)) { return "I"; }
  if (toolIdx == (ToolKind::ToolPen as int)) { return "P"; }
  if (toolIdx == (ToolKind::ToolPencil as int)) { return "Shift+P"; }
  if (toolIdx == (ToolKind::ToolText as int)) { return "T"; }
  if (toolIdx == (ToolKind::ToolBodyText as int)) { return ""; }
  if (toolIdx == (ToolKind::ToolBadge as int)) { return ""; }
  if (toolIdx == (ToolKind::ToolComment as int)) { return "C"; }
  return "K";
}

const char* toolTipOf(int toolIdx) {
  if (toolIdx == (ToolKind::ToolMove as int)) { return "Move (V)"; }
  if (toolIdx == (ToolKind::ToolHand as int)) { return "Hand tool (H)"; }
  if (toolIdx == (ToolKind::ToolScale as int)) { return "Scale (Shift+K)"; }
  if (toolIdx == (ToolKind::ToolFrame as int)) { return "Frame (F)"; }
  if (toolIdx == (ToolKind::ToolSection as int)) { return "Section (Shift+S)"; }
  if (toolIdx == (ToolKind::ToolSlice as int)) { return "Slice (S)"; }
  if (toolIdx == (ToolKind::ToolRect as int)) { return "Rectangle (R)"; }
  if (toolIdx == (ToolKind::ToolLine as int)) { return "Line (L)"; }
  if (toolIdx == (ToolKind::ToolArrow as int)) { return "Arrow (Shift+L)"; }
  if (toolIdx == (ToolKind::ToolEllipse as int)) { return "Ellipse (O)"; }
  if (toolIdx == (ToolKind::ToolPolygon as int)) { return "Polygon"; }
  if (toolIdx == (ToolKind::ToolStar as int)) { return "Star"; }
  if (toolIdx == (ToolKind::ToolImage as int)) { return "Place image (I)"; }
  if (toolIdx == (ToolKind::ToolPen as int)) { return "Pen (P)"; }
  if (toolIdx == (ToolKind::ToolPencil as int)) { return "Pencil (Shift+P)"; }
  if (toolIdx == (ToolKind::ToolText as int)) { return "Text (T)"; }
  if (toolIdx == (ToolKind::ToolBodyText as int)) { return "Body text"; }
  if (toolIdx == (ToolKind::ToolBadge as int)) { return "Pill / Label"; }
  if (toolIdx == (ToolKind::ToolComment as int)) { return "Comment (C)"; }
  return "Actions (K)";
}

void markDirty(Editor* e) {
  e.dirty = true;
  std::string::copy(&e.savedStatus[0], "Unsaved", 24);
  if (e.activeTab >= 0 && e.activeTab < e.tabCount) {
    e.tabs[e.activeTab].dirty = true;
    std::string::copy(&e.tabs[e.activeTab].savedStatus[0], "Unsaved", 24);
  }
}

bool hasAnyUnsavedWork(Editor* e) {
  if (e.dirty) { return true; }
  for (int i = 0; i < e.tabCount; i = i + 1) {
    if (e.tabs[i].dirty) { return true; }
  }
  return false;
}

void syncActiveTabSave(Editor* e) {
  saveCurrentNodesToPage(e, e.activePage);
  if (e.activeTab >= 0 && e.activeTab < e.tabCount) {
    e.tabs[e.activeTab].activePage = e.activePage;
    e.tabs[e.activeTab].pageCount = e.pageCount;
    e.tabs[e.activeTab].selected = e.selected;
    e.tabs[e.activeTab].zoom = e.zoom;
    e.tabs[e.activeTab].offsetX = e.offsetX;
    e.tabs[e.activeTab].offsetY = e.offsetY;
    e.tabs[e.activeTab].darkTheme = e.darkTheme;
    e.tabs[e.activeTab].dirty = e.dirty;
    std::string::copy(&e.tabs[e.activeTab].savedStatus[0], &e.savedStatus[0], 24);
    for (int p = 0; p < e.pageCount && p < 4; p = p + 1) {
      savePageSlotToTab(e, e.activeTab, p);
    }
  }
}

void switchDocTab(Editor* e, int idx) {
  if (idx < 0 || idx >= e.tabCount) { return; }
  e.showHome = false;
  e.showMainMenu = false;
  e.openFlyout = -1;
  if (idx == e.activeTab) { return; }
  syncActiveTabSave(e);
  e.activeTab = idx;
  e.activePage = e.tabs[idx].activePage;
  e.pageCount = e.tabs[idx].pageCount;
  e.zoom = e.tabs[idx].zoom;
  e.offsetX = e.tabs[idx].offsetX;
  e.offsetY = e.tabs[idx].offsetY;
  e.darkTheme = e.tabs[idx].darkTheme;
  e.dirty = e.tabs[idx].dirty;
  std::string::copy(&e.savedStatus[0], &e.tabs[idx].savedStatus[0], 24);
  gui::setTheme(e.darkTheme);
  for (int p = 0; p < e.pageCount && p < 4; p = p + 1) {
    loadPageSlotFromTab(e, idx, p);
  }
  loadPageNodesToEditor(e, e.activePage);
  e.selected = e.tabs[idx].selected;
  if (e.selected >= e.count) { e.selected = -1; }
  refreshInspectorLabels(e);
}

void addNewDocTab(Editor* e) {
  if (e.tabCount >= 6) {
    gui::toast("Tabs", "Maximum 6 open tabs reached in this workspace.");
    return;
  }
  syncActiveTabSave(e);
  int ni = e.tabCount;
  e.tabCount = e.tabCount + 1;
  e.activeTab = ni;
  e.showHome = false;
  e.showMainMenu = false;
  e.openFlyout = -1;

  std::string::copy(&e.tabs[ni].title[0], "Untitled ", 48);
  char[12] num;
  std::string::format_int(&num[0], ni + 1, 12);
  std::string::append_into(&e.tabs[ni].title[0], &num[0], 48);

  e.count = 0;
  e.nextId = 100;
  e.selected = -1;
  e.zoom = 1.0;
  e.offsetX = 0.0;
  e.offsetY = 0.0;
  e.stageW = 1440.0;
  e.stageH = 960.0;
  e.stageBg = fcWhite();
  std::string::copy(&e.stageName[0], "Main Frame", 48);
  e.dirty = false;
  std::string::copy(&e.savedStatus[0], "Saved", 24);

  e.activePage = 0;
  e.pageCount = 1;
  std::string::copy(&e.pages[0].title[0], "Page 1", 48);
  saveCurrentNodesToPage(e, 0);

  e.tabs[ni].activePage = 0;
  e.tabs[ni].pageCount = 1;
  e.tabs[ni].selected = -1;
  e.tabs[ni].zoom = 1.0;
  e.tabs[ni].offsetX = 0.0;
  e.tabs[ni].offsetY = 0.0;
  e.tabs[ni].darkTheme = e.darkTheme;
  e.tabs[ni].dirty = false;
  std::string::copy(&e.tabs[ni].savedStatus[0], "Saved", 24);
  savePageSlotToTab(e, ni, 0);
  refreshInspectorLabels(e);
}

void copyPageData(PageData* dst, PageData* src) {
  std::string::copy(&dst.title[0], &src.title[0], 48);
  std::string::copy(&dst.frameName[0], &src.frameName[0], 48);
  dst.frameW = src.frameW;
  dst.frameH = src.frameH;
  dst.frameBg = src.frameBg;
  dst.count = src.count;
  dst.nextId = src.nextId;
  for (int i = 0; i < src.count && i < 160; i = i + 1) {
    dst.nodes[i] = src.nodes[i];
  }
}

void copyDocTab(DocTabInfo* dst, DocTabInfo* src) {
  std::string::copy(&dst.title[0], &src.title[0], 48);
  dst.activePage = src.activePage;
  dst.pageCount = src.pageCount;
  dst.selected = src.selected;
  dst.zoom = src.zoom;
  dst.offsetX = src.offsetX;
  dst.offsetY = src.offsetY;
  dst.darkTheme = src.darkTheme;
  dst.dirty = src.dirty;
  std::string::copy(&dst.savedStatus[0], &src.savedStatus[0], 24);
  for (int p = 0; p < src.pageCount && p < 4; p = p + 1) {
    copyPageData(&dst.pages[p], &src.pages[p]);
  }
}

void closeDocTab(Editor* e, int idx) {
  if (e.tabCount <= 1) {
    gui::toast("Tab", "At least one design file stays open.");
    return;
  }
  if (idx < 0 || idx >= e.tabCount) { return; }
  syncActiveTabSave(e);

  for (int i = idx; i < e.tabCount - 1; i = i + 1) {
    copyDocTab(&e.tabs[i], &e.tabs[i + 1]);
  }
  e.tabCount = e.tabCount - 1;
  if (e.activeTab >= e.tabCount) {
    e.activeTab = e.tabCount - 1;
  }
  int cur = e.activeTab;
  e.activePage = e.tabs[cur].activePage;
  e.pageCount = e.tabs[cur].pageCount;
  e.zoom = e.tabs[cur].zoom;
  e.offsetX = e.tabs[cur].offsetX;
  e.offsetY = e.tabs[cur].offsetY;
  e.dirty = e.tabs[cur].dirty;
  std::string::copy(&e.savedStatus[0], &e.tabs[cur].savedStatus[0], 24);
  for (int p = 0; p < e.pageCount && p < 4; p = p + 1) {
    loadPageSlotFromTab(e, cur, p);
  }
  loadPageNodesToEditor(e, e.activePage);
  refreshInspectorLabels(e);
}

void switchPage(Editor* e, int pageIdx) {
  if (pageIdx < 0 || pageIdx >= e.pageCount || pageIdx == e.activePage) { return; }
  saveCurrentNodesToPage(e, e.activePage);
  e.activePage = pageIdx;
  loadPageNodesToEditor(e, pageIdx);
  refreshInspectorLabels(e);
}

void addNewPage(Editor* e) {
  if (e.pageCount >= 4) {
    gui::toast("Pages", "Up to 4 pages supported per file.");
    return;
  }
  saveCurrentNodesToPage(e, e.activePage);
  int np = e.pageCount;
  e.pageCount = e.pageCount + 1;
  e.activePage = np;
  std::string::copy(&e.pages[np].title[0], "Page ", 48);
  char[12] num;
  std::string::format_int(&num[0], np + 1, 12);
  std::string::append_into(&e.pages[np].title[0], &num[0], 48);

  e.count = 0;
  e.nextId = 600 + np * 50;
  e.selected = -1;
  e.stageW = 1440.0;
  e.stageH = 960.0;
  e.stageBg = fcWhite();
  std::string::copy(&e.stageName[0], &e.pages[np].title[0], 48);
  saveCurrentNodesToPage(e, np);
  markDirty(e);
  refreshInspectorLabels(e);
}

void selectTool(Editor* e, int toolIdx) {
  e.openFlyout = -1;
  e.showMainMenu = false;
  if (toolIdx == (ToolKind::ToolActions as int)) {
    e.showActions = !e.showActions;
    return;
  }
  e.tool = toolIdx;
  int grp = toolGroupOf(toolIdx);
  if (grp >= 0 && grp < 5) {
    e.groupTool[grp] = toolIdx;
  }
}

void toggleToolFlyout(Editor* e, int groupIdx) {
  e.showMainMenu = false;
  e.showActions = false;
  if (groupIdx < 0 || groupIdx >= 5) {
    e.openFlyout = -1;
    return;
  }
  e.openFlyout = if (e.openFlyout == groupIdx) -1 else groupIdx;
}

void goHome(Editor* e) {
  syncActiveTabSave(e);
  e.showHome = true;
  e.showMainMenu = false;
  e.openFlyout = -1;
  e.showHelp = false;
  e.showActions = false;
}

void openTabFromHome(Editor* e, int tabIdx) {
  if (tabIdx < 0 || tabIdx >= e.tabCount) { return; }
  switchDocTab(e, tabIdx);
  e.showHome = false;
  e.showMainMenu = false;
  e.openFlyout = -1;
}

void openNewDesignFile(Editor* e) {
  addNewDocTab(e);
  e.showHome = false;
  e.showMainMenu = false;
}

void openTemplateFile(Editor* e, int templateIdx, const char* title) {
  syncActiveTabSave(e);
  int targetTab = e.activeTab;
  if (e.tabCount < 6) {
    targetTab = e.tabCount;
    e.tabCount = e.tabCount + 1;
  }
  e.activeTab = targetTab;
  std::string::copy(&e.tabs[targetTab].title[0], title, 48);

  populateTemplateScene(e, templateIdx);
  e.activePage = 0;
  e.pageCount = 1;
  e.zoom = 1.0;
  e.offsetX = 0.0;
  e.offsetY = 0.0;
  e.dirty = false;
  std::string::copy(&e.savedStatus[0], "Saved", 24);
  std::string::copy(&e.pages[0].title[0], title, 48);
  saveCurrentNodesToPage(e, 0);

  e.tabs[targetTab].activePage = 0;
  e.tabs[targetTab].pageCount = 1;
  e.tabs[targetTab].selected = -1;
  e.tabs[targetTab].zoom = 1.0;
  e.tabs[targetTab].offsetX = 0.0;
  e.tabs[targetTab].offsetY = 0.0;
  e.tabs[targetTab].darkTheme = e.darkTheme;
  e.tabs[targetTab].dirty = false;
  std::string::copy(&e.tabs[targetTab].savedStatus[0], "Saved", 24);
  savePageSlotToTab(e, targetTab, 0);

  e.showHome = false;
  e.showMainMenu = false;
  e.openFlyout = -1;
  refreshInspectorLabels(e);
  gui::toast("Template opened", title);
}

void saveActiveDocument(Editor* e) {
  e.dirty = false;
  std::string::copy(&e.savedStatus[0], "Saved", 24);
  syncActiveTabSave(e);
  e.showMainMenu = false;
  gui::toast("File saved", &e.tabs[e.activeTab].title[0]);
}

void openSaveLocalCopyModal(Editor* e) {
  std::string::copy(&e.saveAsName[0], &e.tabs[e.activeTab].title[0], 48);
  std::string::append_into(&e.saveAsName[0], " copy", 48);
  e.showSaveAsModal = true;
  e.showMainMenu = false;
}

void confirmSaveLocalCopy(Editor* e) {
  syncActiveTabSave(e);
  if (e.tabCount < 6) {
    int ni = e.tabCount;
    copyDocTab(&e.tabs[ni], &e.tabs[e.activeTab]);
    if (e.saveAsName[0] != '\0') {
      std::string::copy(&e.tabs[ni].title[0], &e.saveAsName[0], 48);
    }
    e.tabs[ni].dirty = false;
    std::string::copy(&e.tabs[ni].savedStatus[0], "Saved", 24);
    e.tabCount = e.tabCount + 1;
    switchDocTab(e, ni);
  } else {
    if (e.saveAsName[0] != '\0') {
      std::string::copy(&e.tabs[e.activeTab].title[0], &e.saveAsName[0], 48);
    }
    e.dirty = false;
    std::string::copy(&e.savedStatus[0], "Saved", 24);
    syncActiveTabSave(e);
  }
  e.showSaveAsModal = false;
  gui::toast("Local copy saved", &e.tabs[e.activeTab].title[0]);
}

void performExport(Editor* e) {
  e.showExportModal = false;
  if (e.exportFormat == 0) {
    gui::toast("Exported PNG (2x)", &e.stageName[0]);
  } else if (e.exportFormat == 1) {
    gui::toast("Exported SVG Vector", &e.stageName[0]);
  } else if (e.exportFormat == 2) {
    gui::toast("Exported PDF Document", &e.stageName[0]);
  } else {
    gui::toast("Exported Glang UI Code", &e.stageName[0]);
  }
}

void closeActiveTabOrHome(Editor* e) {
  e.showMainMenu = false;
  if (e.tabCount > 1) {
    closeDocTab(e, e.activeTab);
  } else {
    goHome(e);
  }
}

void requestExitFigcraft(Editor* e) {
  e.showMainMenu = false;
  e.openFlyout = -1;
  if (hasAnyUnsavedWork(e)) {
    e.showExitPrompt = true;
  } else {
    gui::quit();
  }
}

void setBottomMode(Editor* e, int modeIdx) {
  e.bottomMode = modeIdx;
  if (modeIdx == (BottomMode::ModeLayout as int)) {
    e.showGrid = true;
  } else if (modeIdx == (BottomMode::ModeDraw as int)) {
    e.showGrid = false;
  }
}

void toggleNodeVisibility(Editor* e, int idx) {
  if (idx < 0 || idx >= e.count) { return; }
  e.nodes[idx].visible = !e.nodes[idx].visible;
}

void toggleNodeLock(Editor* e, int idx) {
  if (idx < 0 || idx >= e.count) { return; }
  e.nodes[idx].locked = !e.nodes[idx].locked;
}

void appendHierarchyChildren(Editor* e, int parentId, DesignNode* outBuf, bool* used, int* outCount, int depth) {
  if (depth > 16) { return; }
  for (int i = 0; i < e.count; i = i + 1) {
    if (!used[i] && e.nodes[i].parentId == parentId) {
      used[i] = true;
      int wi = *outCount;
      if (wi < 160) {
        outBuf[wi] = e.nodes[i];
        *outCount = wi + 1;
      }
      if (isNodeContainerKind(e.nodes[i].kind)) {
        appendHierarchyChildren(e, e.nodes[i].id, outBuf, used, outCount, depth + 1);
      }
    }
  }
}

void normalizeHierarchyOrder(Editor* e) {
  if (e.count <= 0) {
    e.selected = -1;
    return;
  }
  int selId = if (e.selected >= 0 && e.selected < e.count) e.nodes[e.selected].id else -1;

  for (int i = 0; i < e.count; i = i + 1) {
    int pid = e.nodes[i].parentId;
    if (pid >= 0) {
      int pIdx = findNodeIndexById(e, pid);
      if (pIdx < 0 || pIdx == i || !isNodeContainerKind(e.nodes[pIdx].kind) ||
          isNodeDescendant(e, pIdx, e.nodes[i].id)) {
        e.nodes[i].parentId = -1;
      }
    }
  }

  DesignNode[160] tmp;
  bool[160] used;
  for (int i = 0; i < 160; i = i + 1) {
    used[i] = false;
  }
  int outCount = 0;
  appendHierarchyChildren(e, -1, &tmp[0], &used[0], &outCount, 0);

  for (int i = 0; i < e.count && outCount < 160; i = i + 1) {
    if (!used[i]) {
      used[i] = true;
      tmp[outCount] = e.nodes[i];
      tmp[outCount].parentId = -1;
      outCount = outCount + 1;
    }
  }

  for (int i = 0; i < outCount; i = i + 1) {
    e.nodes[i] = tmp[i];
  }
  e.count = outCount;
  e.selected = findNodeIndexById(e, selId);
}

void appendLayerTreeChildren(Editor* e, int parentId, int depth, bool forceExpand) {
  if (depth > 16) { return; }
  for (int i = e.count - 1; i >= 0; i = i - 1) {
    if (e.nodes[i].parentId == parentId && e.layerTreeCount < 160) {
      int rowSlot = e.layerTreeCount;
      bool hasKids = nodeHasChildren(e, i);
      e.layerTreeOrder[rowSlot] = i;
      e.layerTreeDepth[rowSlot] = depth;
      e.layerTreeHasKids[rowSlot] = hasKids;
      e.layerTreeCount = rowSlot + 1;
      if ((hasKids || isNodeContainerKind(e.nodes[i].kind)) && (e.nodes[i].expanded || forceExpand)) {
        appendLayerTreeChildren(e, e.nodes[i].id, depth + 1, forceExpand);
      }
    }
  }
}

void buildLayerTreeCache(Editor* e) {
  e.layerTreeCount = 0;
  bool filtering = e.layerFilter[0] != '\0';
  appendLayerTreeChildren(e, -1, 0, filtering);
}

void moveNodeSubtree(Editor* e, int rootIdx, float dx, float dy) {
  if (rootIdx < 0 || rootIdx >= e.count) { return; }
  int rootId = e.nodes[rootIdx].id;
  e.nodes[rootIdx].x = e.nodes[rootIdx].x + dx;
  e.nodes[rootIdx].y = e.nodes[rootIdx].y + dy;
  for (int i = 0; i < e.count; i = i + 1) {
    if (i != rootIdx && isNodeDescendant(e, i, rootId)) {
      e.nodes[i].x = e.nodes[i].x + dx;
      e.nodes[i].y = e.nodes[i].y + dy;
    }
  }
}

bool reparentNode(Editor* e, int nodeIdx, int newParentId) {
  if (nodeIdx < 0 || nodeIdx >= e.count) { return false; }
  int nodeId = e.nodes[nodeIdx].id;
  if (newParentId >= 0) {
    int pIdx = findNodeIndexById(e, newParentId);
    if (pIdx < 0 || pIdx == nodeIdx || !isNodeContainerKind(e.nodes[pIdx].kind) ||
        isNodeDescendant(e, pIdx, nodeId)) {
      return false;
    }
    e.nodes[pIdx].expanded = true;
  }
  if (e.nodes[nodeIdx].parentId == newParentId) { return false; }
  e.nodes[nodeIdx].parentId = newParentId;
  int selId = if (e.selected >= 0 && e.selected < e.count) e.nodes[e.selected].id else -1;
  normalizeHierarchyOrder(e);
  if (selId >= 0) { e.selected = findNodeIndexById(e, selId); }
  markDirty(e);
  refreshInspectorLabels(e);
  return true;
}

int findContainerAtPoint(Editor* e, float dx, float dy, int excludeRootIdx) {
  int exId = if (excludeRootIdx >= 0 && excludeRootIdx < e.count) e.nodes[excludeRootIdx].id else -1;
  for (int i = e.count - 1; i >= 0; i = i - 1) {
    if (i == excludeRootIdx) { continue; }
    if (exId >= 0 && isNodeDescendant(e, i, exId)) { continue; }
    if (!isNodeContainerKind(e.nodes[i].kind)) { continue; }
    if (!isNodeVisibleInHierarchy(e, i)) { continue; }
    if (!pointInsideClippedAncestors(e, i, dx, dy)) { continue; }
    if (dx >= e.nodes[i].x && dx <= e.nodes[i].x + e.nodes[i].w &&
        dy >= e.nodes[i].y && dy <= e.nodes[i].y + e.nodes[i].h) {
      return i;
    }
  }
  return -1;
}

void reparentNodeOnCanvasDrop(Editor* e, int nodeIdx) {
  if (nodeIdx < 0 || nodeIdx >= e.count) { return; }
  float cx = e.nodes[nodeIdx].x + e.nodes[nodeIdx].w * 0.5;
  float cy = e.nodes[nodeIdx].y + e.nodes[nodeIdx].h * 0.5;
  int targetContainer = findContainerAtPoint(e, cx, cy, nodeIdx);
  if (targetContainer >= 0) {
    int pid = e.nodes[targetContainer].id;
    if (e.nodes[nodeIdx].parentId != pid) {
      reparentNode(e, nodeIdx, pid);
    }
  } else if (e.nodes[nodeIdx].parentId >= 0) {
    reparentNode(e, nodeIdx, -1);
  }
}

void reorderLayerRelative(Editor* e, int dragIdx, int targetIdx, int dropMode) {
  if (dragIdx < 0 || dragIdx >= e.count) { return; }
  int dragId = e.nodes[dragIdx].id;

  if (targetIdx == -1) {
    DesignNode moved = e.nodes[dragIdx];
    moved.parentId = -1;
    for (int i = dragIdx; i < e.count - 1; i = i + 1) {
      e.nodes[i] = e.nodes[i + 1];
    }
    e.nodes[e.count - 1] = moved;
    normalizeHierarchyOrder(e);
    e.selected = findNodeIndexById(e, dragId);
    markDirty(e);
    refreshInspectorLabels(e);
    return;
  }

  if (targetIdx < 0 || targetIdx >= e.count || targetIdx == dragIdx) { return; }
  if (isNodeDescendant(e, targetIdx, dragId)) { return; }

  int targetId = e.nodes[targetIdx].id;
  int newParentId = e.nodes[targetIdx].parentId;
  if (dropMode == 1 && isNodeContainerKind(e.nodes[targetIdx].kind)) {
    newParentId = targetId;
    e.nodes[targetIdx].expanded = true;
  }

  DesignNode moved = e.nodes[dragIdx];
  moved.parentId = newParentId;
  int total = e.count;
  for (int i = dragIdx; i < total - 1; i = i + 1) {
    e.nodes[i] = e.nodes[i + 1];
  }
  e.count = total - 1;

  int newTIdx = findNodeIndexById(e, targetId);
  if (newTIdx < 0) {
    e.nodes[total - 1] = moved;
    e.count = total;
    normalizeHierarchyOrder(e);
    e.selected = findNodeIndexById(e, dragId);
    markDirty(e);
    refreshInspectorLabels(e);
    return;
  }

  int insertAt = newTIdx;
  if (dropMode != 2) {
    insertAt = newTIdx + 1;
    while (insertAt < e.count && isNodeDescendant(e, insertAt, targetId)) {
      insertAt = insertAt + 1;
    }
  }

  for (int i = total - 1; i > insertAt; i = i - 1) {
    e.nodes[i] = e.nodes[i - 1];
  }
  e.nodes[insertAt] = moved;
  e.count = total;

  normalizeHierarchyOrder(e);
  e.selected = findNodeIndexById(e, dragId);
  markDirty(e);
  refreshInspectorLabels(e);
}

void deleteSelectedNode(Editor* e) {
  if (e.selected < 0 || e.selected >= e.count) { return; }
  int rootId = e.nodes[e.selected].id;
  int writeIdx = 0;
  for (int i = 0; i < e.count; i = i + 1) {
    if (i != e.selected && !isNodeDescendant(e, i, rootId)) {
      e.nodes[writeIdx] = e.nodes[i];
      writeIdx = writeIdx + 1;
    }
  }
  e.count = writeIdx;
  if (e.selected >= e.count) {
    e.selected = e.count - 1;
  }
  markDirty(e);
  refreshInspectorLabels(e);
}

void duplicateSelectedNode(Editor* e) {
  if (e.selected < 0 || e.selected >= e.count) { return; }
  int rootId = e.nodes[e.selected].id;
  int[160] srcIdx;
  int subCount = 0;
  srcIdx[0] = e.selected;
  subCount = 1;
  for (int i = 0; i < e.count; i = i + 1) {
    if (i != e.selected && isNodeDescendant(e, i, rootId)) {
      srcIdx[subCount] = i;
      subCount = subCount + 1;
    }
  }
  if (e.count + subCount > 160) {
    gui::toast("Layers", "Not enough layer slots to duplicate subtree.");
    return;
  }

  int[160] oldIds;
  int[160] newIds;
  for (int k = 0; k < subCount; k = k + 1) {
    oldIds[k] = e.nodes[srcIdx[k]].id;
    newIds[k] = e.nextId;
    e.nextId = e.nextId + 1;
  }

  for (int k = 0; k < subCount; k = k + 1) {
    DesignNode copy = e.nodes[srcIdx[k]];
    copy.id = newIds[k];
    copy.x = copy.x + 24.0;
    copy.y = copy.y + 24.0;
    if (k == 0) {
      std::string::append_into(&copy.name[0], " copy", 64);
    } else {
      for (int m = 0; m < subCount; m = m + 1) {
        if (oldIds[m] == copy.parentId) {
          copy.parentId = newIds[m];
          break;
        }
      }
    }
    writeNodeRowId(&copy);
    e.nodes[e.count] = copy;
    e.count = e.count + 1;
  }

  int newRootId = newIds[0];
  normalizeHierarchyOrder(e);
  e.selected = findNodeIndexById(e, newRootId);
  markDirty(e);
  refreshInspectorLabels(e);
}

void moveLayerOrder(Editor* e, int idx, int dir) {
  if (idx < 0 || idx >= e.count || dir == 0) { return; }
  int pid = e.nodes[idx].parentId;
  int sibIdx = idx + dir;
  while (sibIdx >= 0 && sibIdx < e.count) {
    if (e.nodes[sibIdx].parentId == pid) {
      reorderLayerRelative(e, idx, sibIdx, if (dir > 0) 0 else 2);
      return;
    }
    sibIdx = sibIdx + dir;
  }
}

void nudgeSelected(Editor* e, float dx, float dy) {
  if (e.selected >= 0 && e.selected < e.count) {
    if (e.nodes[e.selected].locked) { return; }
    moveNodeSubtree(e, e.selected, dx, dy);
    markDirty(e);
  } else {
    e.offsetX = e.offsetX + dx;
    e.offsetY = e.offsetY + dy;
  }
}

void alignSelectedNode(Editor* e, int alignMode) {
  if (e.selected < 0 || e.selected >= e.count) { return; }
  if (e.nodes[e.selected].locked) { return; }
  Rect aligned = computeAlignedPos(e.stageW, e.stageH, e.nodes[e.selected].w, e.nodes[e.selected].h,
                                   alignMode, e.nodes[e.selected].x, e.nodes[e.selected].y);
  float ddx = aligned.x - e.nodes[e.selected].x;
  float ddy = aligned.y - e.nodes[e.selected].y;
  moveNodeSubtree(e, e.selected, ddx, ddy);
  markDirty(e);
}

void insertComponentAssetAt(Editor* e, int assetKind, float dropCx, float dropCy, int dropParentId) {
  if (e.count >= 154) {
    gui::toast("Canvas", "Maximum layer limit reached on this page.");
    return;
  }
  Rect fp = computeDropFootprint(e, false, assetKind, dropCx, dropCy);
  float cx = fp.x;
  float cy = fp.y;
  int firstIdx = e.count;

  if (assetKind == 0) {
    addScButton(e, "Action Button", cx, cy, 160.0, 42.0, fcGreen(), fcNavy());
  } else if (assetKind == 1) {
    addNodeToEditor(e, NodeKind::NodeButton, "Secondary", "", cx, cy, 160.0, 42.0,
                    fcWhite(), fcNavy(), fcDesignBorder(), 21.0, 1.5, 11.5, 1);
  } else if (assetKind == 2) {
    addScRect(e, "Surface Card", cx, cy, 260.0, 148.0, fcWhite(), 12.0, 1.0, fcDesignBorder());
    int ci = e.count - 1;
    if (ci >= 0) {
      e.nodes[ci].dropShadowEnabled = true;
      e.nodes[ci].dropShadowY = 8.0;
      e.nodes[ci].dropShadowBlur = 20.0;
      e.nodes[ci].dropShadowColor = gui::rgba(15, 23, 38, 44);
    }
  } else if (assetKind == 3) {
    addNodeToEditor(e, NodeKind::NodeFrame, "Input Field", "", cx, cy, 240.0, 60.0,
                    gui::clear(), gui::clear(), gui::clear(), 0.0, 0.0, 0.0, 0);
    int frameId = e.nodes[firstIdx].id;
    addScText(e, "Email address", cx, cy, 140.0, 18.0, 11.0, fcNavy(), 1);
    e.nodes[e.count - 1].parentId = frameId;
    addScRect(e, "Input Box", cx, cy + 22.0, 240.0, 38.0, fcWhite(), 8.0, 1.2, fcDesignBorder());
    e.nodes[e.count - 1].parentId = frameId;
    addScText(e, "name@studio.dev", cx + 12.0, cy + 32.0, 180.0, 18.0, 11.0, fcTitleMuted(), 0);
    e.nodes[e.count - 1].parentId = frameId;
  } else if (assetKind == 4) {
    addScButton(e, "In Progress", cx, cy, 108.0, 26.0, fcGreenSoft(false), fcGreenDark());
  } else if (assetKind == 5) {
    addScChart(e, "Activity Bars", cx, cy, 300.0, 150.0, fcChartGreen());
  } else if (assetKind == 6) {
    addScSpark(e, "Revenue Trend", cx, cy, 220.0, 76.0, fcChartGreen(), 0);
  } else if (assetKind == 7) {
    addScDonut(e, "Completion Ring", cx, cy, 128.0, 128.0);
  } else if (assetKind == 8) {
    addScDot(e, "Avatar Badge", cx, cy, 48.0, fcNavy());
  } else if (assetKind == 9) {
    addNodeToEditor(e, NodeKind::NodeFrame, "Toggle Switch", "", cx, cy, 52.0, 28.0,
                    gui::clear(), gui::clear(), gui::clear(), 14.0, 0.0, 0.0, 0);
    int frameId = e.nodes[firstIdx].id;
    addScRect(e, "Toggle Track", cx, cy, 52.0, 28.0, fcGreen(), 14.0, 0.0, gui::clear());
    e.nodes[e.count - 1].parentId = frameId;
    addScDot(e, "Toggle Knob", cx + 27.0, cy + 3.0, 22.0, fcWhite());
    e.nodes[e.count - 1].parentId = frameId;
  } else if (assetKind == 10) {
    addNodeToEditor(e, NodeKind::NodeImage, "Media Frame", "", cx, cy, 240.0, 150.0,
                    fcWhite(), fcNavy(), fcDesignBorder(), 10.0, 1.2, 0.0, 0);
  } else {
    addNodeToEditor(e, NodeKind::NodeComment, "Review Note", "Looks ready for handoff!", cx, cy, 148.0, 30.0,
                    fcNavy(), fcWhite(), fcGreen(), 10.0, 1.5, 10.0, 1);
  }

  int rootId = e.nodes[firstIdx].id;
  if (dropParentId >= 0) {
    int pIdx = findNodeIndexById(e, dropParentId);
    if (pIdx >= 0 && isNodeContainerKind(e.nodes[pIdx].kind)) {
      e.nodes[firstIdx].parentId = dropParentId;
      e.nodes[pIdx].expanded = true;
    }
  }
  normalizeHierarchyOrder(e);
  e.selected = findNodeIndexById(e, rootId);
  selectTool(e, ToolKind::ToolMove as int);
  markDirty(e);
  refreshInspectorLabels(e);
}

void insertComponentAsset(Editor* e, int assetKind) {
  float stagger = ((e.count % 5) as float) * 20.0;
  float dropCx = e.stageW * 0.5 + stagger;
  float dropCy = e.stageH * 0.5 + ((e.count % 4) as float) * 18.0;
  insertComponentAssetAt(e, assetKind, dropCx, dropCy, -1);
}

void insertPrebuiltSectionAt(Editor* e, int sectionKind, float dropCx, float dropCy, int dropParentId) {
  if (e.count >= 145) {
    gui::toast("Canvas", "Not enough remaining layer slots for a section.");
    return;
  }
  Rect fp = computeDropFootprint(e, true, sectionKind, dropCx, dropCy);
  float bx = fp.x;
  float by = fp.y;
  int firstIdx = e.count;

  if (sectionKind == 0) {
    addNodeToEditor(e, NodeKind::NodeFrame, "Navbar Surface", "", bx, by, 1120.0, 68.0,
                    fcWhite(), gui::clear(), fcDesignBorder(), 12.0, 1.0, 0.0, 0);
    int frameId = e.nodes[firstIdx].id;
    e.nodes[firstIdx].dropShadowEnabled = true;
    e.nodes[firstIdx].dropShadowY = 6.0;
    e.nodes[firstIdx].dropShadowBlur = 18.0;
    e.nodes[firstIdx].dropShadowColor = gui::rgba(15, 23, 38, 36);
    addScDot(e, "Brand Mark", bx + 22.0, by + 20.0, 28.0, fcGreen());
    e.nodes[e.count - 1].parentId = frameId;
    addScText(e, "FigCraft UI", bx + 60.0, by + 23.0, 140.0, 24.0, 15.0, fcNavy(), 1);
    e.nodes[e.count - 1].parentId = frameId;
    addScText(e, "Product", bx + 380.0, by + 25.0, 72.0, 20.0, 12.0, fcTitleMuted(), 0);
    e.nodes[e.count - 1].parentId = frameId;
    addScText(e, "Templates", bx + 472.0, by + 25.0, 84.0, 20.0, 12.0, fcTitleMuted(), 0);
    e.nodes[e.count - 1].parentId = frameId;
    addScText(e, "Pricing", bx + 578.0, by + 25.0, 72.0, 20.0, 12.0, fcTitleMuted(), 0);
    e.nodes[e.count - 1].parentId = frameId;
    addScButton(e, "Get started", bx + 962.0, by + 16.0, 136.0, 36.0, fcGreen(), fcNavy());
    e.nodes[e.count - 1].parentId = frameId;
  } else if (sectionKind == 1) {
    addNodeToEditor(e, NodeKind::NodeFrame, "Hero Banner", "", bx, by, 1120.0, 320.0,
                    fcNavy(), gui::clear(), gui::clear(), 18.0, 0.0, 0.0, 0);
    int frameId = e.nodes[firstIdx].id;
    e.nodes[firstIdx].dropShadowEnabled = true;
    e.nodes[firstIdx].dropShadowY = 14.0;
    e.nodes[firstIdx].dropShadowBlur = 32.0;
    e.nodes[firstIdx].dropShadowColor = gui::rgba(15, 23, 38, 84);
    addScButton(e, "NEW RELEASE 3.0", bx + 52.0, by + 44.0, 138.0, 26.0, fcGreenSoft(true), fcGreen());
    e.nodes[e.count - 1].parentId = frameId;
    addScText(e, "Design systems at lightning speed.", bx + 52.0, by + 88.0, 680.0, 48.0, 32.0, fcWhite(), 2);
    e.nodes[e.count - 1].parentId = frameId;
    addScText(e, "Compose responsive frames, shadows, and interactive states from one canvas.",
              bx + 52.0, by + 148.0, 620.0, 26.0, 13.5, fcChartMint(), 0);
    e.nodes[e.count - 1].parentId = frameId;
    addScButton(e, "Start Designing", bx + 52.0, by + 218.0, 166.0, 44.0, fcGreen(), fcNavy());
    e.nodes[e.count - 1].parentId = frameId;
    addNodeToEditor(e, NodeKind::NodeButton, "Live Demo", "", bx + 234.0, by + 218.0, 148.0, 44.0,
                    gui::rgba(255, 255, 255, 20), fcWhite(), fcGreen(), 22.0, 1.5, 11.5, 1);
    e.nodes[e.count - 1].parentId = frameId;
  } else if (sectionKind == 2) {
    addNodeToEditor(e, NodeKind::NodeSection, "3-Col Feature Grid", "", bx, by, 1120.0, 210.0,
                    gui::clear(), gui::clear(), gui::clear(), 12.0, 0.0, 0.0, 0);
    e.nodes[firstIdx].clipContent = false;
    int secId = e.nodes[firstIdx].id;
    float cardW = 348.0;
    float gap = 38.0;
    for (int col = 0; col < 3; col = col + 1) {
      float cx = bx + (col as float) * (cardW + gap);
      int ci = e.count;
      addNodeToEditor(e, NodeKind::NodeFrame,
                      if (col == 0) "Card Fast Tokens" else if (col == 1) "Card Live Effects" else "Card Dev Handoff",
                      "", cx, by, cardW, 210.0, fcWhite(), gui::clear(), fcDesignBorder(), 14.0, 1.0, 0.0, 0);
      e.nodes[ci].parentId = secId;
      e.nodes[ci].dropShadowEnabled = true;
      e.nodes[ci].dropShadowY = 8.0;
      e.nodes[ci].dropShadowBlur = 22.0;
      e.nodes[ci].dropShadowColor = gui::rgba(15, 23, 38, 42);
      int cardId = e.nodes[ci].id;
      addScDot(e, "Feature Badge", cx + 24.0, by + 24.0, 34.0,
               if (col == 0) fcGreen() else if (col == 1) fcChartBlue() else fcPurple());
      e.nodes[e.count - 1].parentId = cardId;
      addScText(e, if (col == 0) "Design Tokens" else if (col == 1) "Layered Effects" else "Clean Handoff",
                cx + 24.0, by + 76.0, 260.0, 26.0, 16.0, fcNavy(), 1);
      e.nodes[e.count - 1].parentId = cardId;
      addScText(e, if (col == 0) "Shared palette & corner variables." else if (col == 1) "Drop shadow, inner bevel & blur." else "Production specs built in.",
                cx + 24.0, by + 112.0, 290.0, 22.0, 12.0, fcTitleMuted(), 0);
      e.nodes[e.count - 1].parentId = cardId;
      addScButton(e, "Explore", cx + 24.0, by + 154.0, 108.0, 32.0, fcGreenSoft(false), fcGreenDark());
      e.nodes[e.count - 1].parentId = cardId;
    }
  } else if (sectionKind == 3) {
    addNodeToEditor(e, NodeKind::NodeFrame, "Login Card", "", bx, by, 380.0, 360.0,
                    fcWhite(), gui::clear(), fcDesignBorder(), 16.0, 1.0, 0.0, 0);
    int frameId = e.nodes[firstIdx].id;
    e.nodes[firstIdx].dropShadowEnabled = true;
    e.nodes[firstIdx].dropShadowY = 12.0;
    e.nodes[firstIdx].dropShadowBlur = 28.0;
    e.nodes[firstIdx].dropShadowColor = gui::rgba(15, 23, 38, 52);
    addScText(e, "Welcome back", bx + 28.0, by + 28.0, 240.0, 30.0, 20.0, fcNavy(), 2);
    e.nodes[e.count - 1].parentId = frameId;
    addScText(e, "Sign in to continue to workspace", bx + 28.0, by + 62.0, 280.0, 20.0, 11.5, fcTitleMuted(), 0);
    e.nodes[e.count - 1].parentId = frameId;
    addScText(e, "Email", bx + 28.0, by + 106.0, 120.0, 18.0, 11.0, fcNavy(), 1);
    e.nodes[e.count - 1].parentId = frameId;
    addScRect(e, "Email Input", bx + 28.0, by + 128.0, 324.0, 40.0, fcDesignBg(false), 8.0, 1.0, fcDesignBorder());
    e.nodes[e.count - 1].parentId = frameId;
    addScText(e, "Password", bx + 28.0, by + 186.0, 120.0, 18.0, 11.0, fcNavy(), 1);
    e.nodes[e.count - 1].parentId = frameId;
    addScRect(e, "Password Input", bx + 28.0, by + 208.0, 324.0, 40.0, fcDesignBg(false), 8.0, 1.0, fcDesignBorder());
    e.nodes[e.count - 1].parentId = frameId;
    addScButton(e, "Sign in", bx + 28.0, by + 282.0, 324.0, 44.0, fcGreen(), fcNavy());
    e.nodes[e.count - 1].parentId = frameId;
  } else if (sectionKind == 4) {
    addNodeToEditor(e, NodeKind::NodeFrame, "KPI Analytics Card", "", bx, by, 440.0, 240.0,
                    fcWhite(), gui::clear(), fcDesignBorder(), 14.0, 1.0, 0.0, 0);
    int frameId = e.nodes[firstIdx].id;
    e.nodes[firstIdx].dropShadowEnabled = true;
    e.nodes[firstIdx].dropShadowY = 10.0;
    e.nodes[firstIdx].dropShadowBlur = 24.0;
    e.nodes[firstIdx].dropShadowColor = gui::rgba(15, 23, 38, 46);
    addScText(e, "Monthly Recurring Revenue", bx + 24.0, by + 22.0, 240.0, 20.0, 11.5, fcTitleMuted(), 1);
    e.nodes[e.count - 1].parentId = frameId;
    addScText(e, "$48,290", bx + 24.0, by + 48.0, 200.0, 36.0, 26.0, fcNavy(), 2);
    e.nodes[e.count - 1].parentId = frameId;
    addScButton(e, "+18.4%", bx + 332.0, by + 24.0, 84.0, 26.0, fcGreenSoft(false), fcGreenDark());
    e.nodes[e.count - 1].parentId = frameId;
    addScSpark(e, "MRR Sparkline", bx + 24.0, by + 106.0, 392.0, 108.0, fcChartGreen(), 0);
    e.nodes[e.count - 1].parentId = frameId;
  } else {
    addNodeToEditor(e, NodeKind::NodeFrame, "Footer Bar", "", bx, by, 1120.0, 92.0,
                    fcNavy(), gui::clear(), gui::clear(), 12.0, 0.0, 0.0, 0);
    int frameId = e.nodes[firstIdx].id;
    addScDot(e, "Footer Brand Dot", bx + 28.0, by + 34.0, 24.0, fcGreen());
    e.nodes[e.count - 1].parentId = frameId;
    addScText(e, "FigCraft Studio", bx + 62.0, by + 35.0, 160.0, 22.0, 13.0, fcWhite(), 1);
    e.nodes[e.count - 1].parentId = frameId;
    addScText(e, "Docs", bx + 840.0, by + 37.0, 60.0, 20.0, 11.0, fcChartMint(), 0);
    e.nodes[e.count - 1].parentId = frameId;
    addScText(e, "Changelog", bx + 920.0, by + 37.0, 84.0, 20.0, 11.0, fcChartMint(), 0);
    e.nodes[e.count - 1].parentId = frameId;
    addScText(e, "Privacy", bx + 1024.0, by + 37.0, 72.0, 20.0, 11.0, fcChartMint(), 0);
    e.nodes[e.count - 1].parentId = frameId;
  }

  int rootId = e.nodes[firstIdx].id;
  if (dropParentId >= 0) {
    int pIdx = findNodeIndexById(e, dropParentId);
    if (pIdx >= 0 && isNodeContainerKind(e.nodes[pIdx].kind)) {
      e.nodes[firstIdx].parentId = dropParentId;
      e.nodes[pIdx].expanded = true;
    }
  }
  normalizeHierarchyOrder(e);
  e.selected = findNodeIndexById(e, rootId);
  selectTool(e, ToolKind::ToolMove as int);
  markDirty(e);
  refreshInspectorLabels(e);
  gui::toast("Section inserted", "Prebuilt section added to canvas.");
}

void insertPrebuiltSection(Editor* e, int sectionKind) {
  float stagger = ((e.count % 4) as float) * 24.0;
  float dropCx = e.stageW * 0.5 + stagger;
  float dropCy = e.stageH * 0.5 + ((e.count % 6) as float) * 20.0;
  insertPrebuiltSectionAt(e, sectionKind, dropCx, dropCy, -1);
}

void applyColorVar(Editor* e, int varIdx) {
  if (varIdx < 0 || varIdx >= e.colorVarCount) { return; }
  Color c = e.colorVars[varIdx].color;
  if (e.showColorPicker) {
    applySwatchToTarget(e, c, false);
    return;
  }
  if (e.selected >= 0 && e.selected < e.count) {
    if (e.nodes[e.selected].kind == (NodeKind::NodeText as int)) {
      e.nodes[e.selected].ink = c;
    } else {
      e.nodes[e.selected].fill = c;
      e.nodes[e.selected].fillVisible = true;
    }
  } else {
    e.stageBg = c;
    e.fillVisible = true;
  }
  markDirty(e);
  refreshInspectorLabels(e);
}

void applyNumberVar(Editor* e, int varIdx) {
  if (varIdx < 0 || varIdx >= e.numberVarCount) { return; }
  if (e.selected >= 0 && e.selected < e.count) {
    e.nodes[e.selected].radius = e.numberVars[varIdx].value;
    markDirty(e);
  }
}

void stepZoom(Editor* e, int dir) {
  if (dir > 0) {
    e.zoom = gui::clampf(e.zoom * 1.15, 0.35, 2.5);
  } else if (dir < 0) {
    e.zoom = gui::clampf(e.zoom / 1.15, 0.35, 2.5);
  } else {
    e.zoom = 1.0;
    e.offsetX = 0.0;
    e.offsetY = 0.0;
  }
  refreshInspectorLabels(e);
}

void toggleThemeMode(Editor* e) {
  e.darkTheme = !e.darkTheme;
  gui::setTheme(e.darkTheme);
}

void addDefaultInteraction(Editor* e) {
  const char* dest = if (e.pageCount > 1 && e.activePage == 0) "Navigate to Components" else "Navigate to Dashboard";
  int nid = if (e.selected >= 0 && e.selected < e.count) e.nodes[e.selected].id else -1;
  addInteractionRecord(e, nid, "On click", dest, "Smart animate", 300);
  markDirty(e);
}

void removeInteractionAt(Editor* e, int idx) {
  if (idx < 0 || idx >= e.interactionCount) { return; }
  for (int i = idx; i < e.interactionCount - 1; i = i + 1) {
    e.interactions[i] = e.interactions[i + 1];
  }
  e.interactionCount = e.interactionCount - 1;
  markDirty(e);
}

// ---------------------------------------------------------------------------
// Inspector Properties, Typography, Effects & Color Picker Actions
// ---------------------------------------------------------------------------

Color getActiveTargetColor(Editor* e, int target) {
  if (e.selected < 0 || e.selected >= e.count) {
    return e.stageBg;
  }
  DesignNode* n = &e.nodes[e.selected];
  if (target == (ColorTarget::ColorTargetInk as int)) {
    return n.ink;
  }
  if (target == (ColorTarget::ColorTargetStroke as int)) {
    return n.stroke;
  }
  if (target == (ColorTarget::ColorTargetDropShadow as int)) {
    return n.dropShadowColor;
  }
  if (target == (ColorTarget::ColorTargetInnerShadow as int)) {
    return n.innerShadowColor;
  }
  if (target == (ColorTarget::ColorTargetBgBlur as int)) {
    return n.bgBlurColor;
  }
  if (n.kind == (NodeKind::NodeText as int) && n.fill.a == 0) {
    return n.ink;
  }
  return n.fill;
}

void setActiveTargetColor(Editor* e, int target, Color c) {
  if (e.selected < 0 || e.selected >= e.count) {
    e.stageBg = c;
    e.fillVisible = true;
    markDirty(e);
    refreshInspectorLabels(e);
    return;
  }
  DesignNode* n = &e.nodes[e.selected];
  if (target == (ColorTarget::ColorTargetInk as int)) {
    n.ink = c;
  } else if (target == (ColorTarget::ColorTargetStroke as int)) {
    n.stroke = c;
    n.strokeVisible = true;
    if (n.border <= 0.0) { n.border = 1.5; }
  } else if (target == (ColorTarget::ColorTargetDropShadow as int)) {
    n.dropShadowColor = c;
    n.dropShadowEnabled = true;
    n.dropShadowVisible = true;
  } else if (target == (ColorTarget::ColorTargetInnerShadow as int)) {
    n.innerShadowColor = c;
    n.innerShadowEnabled = true;
    n.innerShadowVisible = true;
  } else if (target == (ColorTarget::ColorTargetBgBlur as int)) {
    n.bgBlurColor = c;
    n.bgBlurEnabled = true;
    n.bgBlurVisible = true;
  } else {
    if (n.kind == (NodeKind::NodeText as int)) {
      n.ink = c;
    } else {
      n.fill = c;
      n.fillVisible = true;
    }
  }
  markDirty(e);
  refreshInspectorLabels(e);
}

void loadPickerFromTarget(Editor* e, int target) {
  e.colorTarget = target;
  Color c = getActiveTargetColor(e, target);
  e.pickerR = c.r as float;
  e.pickerG = c.g as float;
  e.pickerB = c.b as float;
  int aPct = (((c.a as float) / 255.0) * 100.0 + 0.5) as int;
  if (aPct < 0) { aPct = 0; }
  if (aPct > 100) { aPct = 100; }
  e.pickerA = aPct as float;
  e.lastPickerR = e.pickerR;
  e.lastPickerG = e.pickerG;
  e.lastPickerB = e.pickerB;
  e.lastPickerA = e.pickerA;
  formatHexColor(&e.pickerHex[0], c, 16);
}

void openColorPicker(Editor* e, int target) {
  if (e.selected < 0 || e.selected >= e.count) {
    target = ColorTarget::ColorTargetFill as int;
  }
  loadPickerFromTarget(e, target);
  e.showColorPicker = true;
}

void syncColorFromPickerChannels(Editor* e) {
  int r = gui::clampf(e.pickerR, 0.0, 255.0) as int;
  int g = gui::clampf(e.pickerG, 0.0, 255.0) as int;
  int b = gui::clampf(e.pickerB, 0.0, 255.0) as int;
  int a = ((gui::clampf(e.pickerA, 0.0, 100.0) / 100.0) * 255.0 + 0.5) as int;
  e.lastPickerR = e.pickerR;
  e.lastPickerG = e.pickerG;
  e.lastPickerB = e.pickerB;
  e.lastPickerA = e.pickerA;
  Color c = gui::rgba(r, g, b, a);
  formatHexColor(&e.pickerHex[0], c, 16);
  setActiveTargetColor(e, e.colorTarget, c);
}

void applyPickerHexString(Editor* e) {
  Color cur = getActiveTargetColor(e, e.colorTarget);
  int alphaInt = ((gui::clampf(e.pickerA, 0.0, 100.0) / 100.0) * 255.0 + 0.5) as int;
  Color parsed = parseHexColor(&e.pickerHex[0], alphaInt as uchar, cur);
  e.pickerR = parsed.r as float;
  e.pickerG = parsed.g as float;
  e.pickerB = parsed.b as float;
  e.lastPickerR = e.pickerR;
  e.lastPickerG = e.pickerG;
  e.lastPickerB = e.pickerB;
  e.lastPickerA = e.pickerA;
  setActiveTargetColor(e, e.colorTarget, parsed);
}

void applySwatchToTarget(Editor* e, Color c, bool preserveAlpha) {
  int alpha = if (preserveAlpha) ((gui::clampf(e.pickerA, 0.0, 100.0) / 100.0) * 255.0 + 0.5) as int else (c.a as int);
  if (alpha <= 0) { alpha = 255; }
  Color finalCol = gui::rgba(c.r as int, c.g as int, c.b as int, alpha);
  e.pickerR = finalCol.r as float;
  e.pickerG = finalCol.g as float;
  e.pickerB = finalCol.b as float;
  e.pickerA = ((alpha as float) / 255.0 * 100.0 + 0.5) as int as float;
  e.lastPickerR = e.pickerR;
  e.lastPickerG = e.pickerG;
  e.lastPickerB = e.pickerB;
  e.lastPickerA = e.pickerA;
  formatHexColor(&e.pickerHex[0], finalCol, 16);
  setActiveTargetColor(e, e.colorTarget, finalCol);
}

void syncLiveInspectorEdits(Editor* e) {
  if (e.showColorPicker) {
    float dr = e.pickerR - e.lastPickerR; if (dr < 0.0) { dr = -dr; }
    float dg = e.pickerG - e.lastPickerG; if (dg < 0.0) { dg = -dg; }
    float db = e.pickerB - e.lastPickerB; if (db < 0.0) { db = -db; }
    float da = e.pickerA - e.lastPickerA; if (da < 0.0) { da = -da; }
    if (dr > 0.25 || dg > 0.25 || db > 0.25 || da > 0.25) {
      syncColorFromPickerChannels(e);
    }
  }
  if (e.selected >= 0 && e.selected < e.count) {
    DesignNode* n = &e.nodes[e.selected];
    if (e.lastSelIdx == e.selected && e.constrainRatio && !e.dragging) {
      float dw = n.w - e.lastSelW; if (dw < 0.0) { dw = -dw; }
      float dh = n.h - e.lastSelH; if (dh < 0.0) { dh = -dh; }
      if (e.lastSelW > 1.0 && e.lastSelH > 1.0) {
        if (dw > 0.05 && dh <= 0.05) {
          n.h = gui::clampf(n.w * (e.lastSelH / e.lastSelW), 8.0, 5000.0);
          markDirty(e);
        } else if (dh > 0.05 && dw <= 0.05) {
          n.w = gui::clampf(n.h * (e.lastSelW / e.lastSelH), 8.0, 5000.0);
          markDirty(e);
        }
      }
    }
    e.lastSelIdx = e.selected;
    e.lastSelW = n.w;
    e.lastSelH = n.h;
  } else {
    e.lastSelIdx = -1;
    e.lastSelW = e.stageW;
    e.lastSelH = e.stageH;
  }
}

void toggleNodeFillVisible(Editor* e) {
  if (e.selected >= 0 && e.selected < e.count) {
    e.nodes[e.selected].fillVisible = !e.nodes[e.selected].fillVisible;
    markDirty(e);
  } else {
    e.fillVisible = !e.fillVisible;
    markDirty(e);
  }
}

void toggleNodeStrokeVisible(Editor* e) {
  if (e.selected < 0 || e.selected >= e.count) { return; }
  DesignNode* n = &e.nodes[e.selected];
  if (!n.strokeVisible) {
    n.strokeVisible = true;
    if (n.border <= 0.0) { n.border = 1.5; }
    if (n.stroke.a == 0) { n.stroke = fcNavy(); }
  } else {
    n.strokeVisible = false;
  }
  markDirty(e);
  refreshInspectorLabels(e);
}

void toggleIndependentCorners(Editor* e) {
  if (e.selected < 0 || e.selected >= e.count) { return; }
  DesignNode* n = &e.nodes[e.selected];
  if (!n.independentCorners) {
    n.radiusTL = n.radius;
    n.radiusTR = n.radius;
    n.radiusBR = n.radius;
    n.radiusBL = n.radius;
    n.independentCorners = true;
  } else {
    n.radius = n.radiusTL;
    n.independentCorners = false;
  }
  markDirty(e);
}

void setNodeBlendMode(Editor* e, int mode) {
  if (e.selected < 0 || e.selected >= e.count) { return; }
  e.nodes[e.selected].blendMode = mode;
  markDirty(e);
}

void setNodeFontFamily(Editor* e, int fontRole) {
  if (e.selected < 0 || e.selected >= e.count) { return; }
  e.nodes[e.selected].font = fontRole;
  markDirty(e);
}

void setNodeFontWeight(Editor* e, int weight) {
  if (e.selected < 0 || e.selected >= e.count) { return; }
  e.nodes[e.selected].fontWeight = weight;
  markDirty(e);
}

void toggleNodeItalic(Editor* e) {
  if (e.selected < 0 || e.selected >= e.count) { return; }
  e.nodes[e.selected].fontItalic = !e.nodes[e.selected].fontItalic;
  markDirty(e);
}

void setNodeTextAlign(Editor* e, int align) {
  if (e.selected < 0 || e.selected >= e.count) { return; }
  e.nodes[e.selected].textAlign = align;
  markDirty(e);
}

void setNodeTextVAlign(Editor* e, int valign) {
  if (e.selected < 0 || e.selected >= e.count) { return; }
  e.nodes[e.selected].textVAlign = valign;
  markDirty(e);
}

void setNodeTextDecoration(Editor* e, int dec) {
  if (e.selected < 0 || e.selected >= e.count) { return; }
  e.nodes[e.selected].textDecoration = dec;
  markDirty(e);
}

void setNodeTextCase(Editor* e, int tc) {
  if (e.selected < 0 || e.selected >= e.count) { return; }
  e.nodes[e.selected].textCase = tc;
  markDirty(e);
}

void setNodeStrokeAlign(Editor* e, int align) {
  if (e.selected < 0 || e.selected >= e.count) { return; }
  e.nodes[e.selected].strokeAlign = align;
  markDirty(e);
}

void setNodeStrokeStyle(Editor* e, int style) {
  if (e.selected < 0 || e.selected >= e.count) { return; }
  e.nodes[e.selected].strokeStyle = style;
  markDirty(e);
}

void toggleDropShadow(Editor* e, bool enable) {
  if (e.selected < 0 || e.selected >= e.count) { return; }
  DesignNode* n = &e.nodes[e.selected];
  n.dropShadowEnabled = enable;
  if (enable) {
    n.dropShadowVisible = true;
    if (n.dropShadowColor.a == 0) {
      n.dropShadowColor = gui::rgba(15, 23, 38, 64);
    }
    if (n.dropShadowBlur <= 0.0) {
      n.dropShadowY = 8.0;
      n.dropShadowBlur = 18.0;
    }
    e.openEffectSettings = 0;
    e.editDropOpen = true;
    e.accEffectsOpen = true;
  }
  markDirty(e);
  refreshInspectorLabels(e);
}

void toggleDropShadowVisible(Editor* e) {
  if (e.selected < 0 || e.selected >= e.count) { return; }
  e.nodes[e.selected].dropShadowVisible = !e.nodes[e.selected].dropShadowVisible;
  markDirty(e);
}

void toggleInnerShadow(Editor* e, bool enable) {
  if (e.selected < 0 || e.selected >= e.count) { return; }
  DesignNode* n = &e.nodes[e.selected];
  n.innerShadowEnabled = enable;
  if (enable) {
    n.innerShadowVisible = true;
    if (n.innerShadowColor.a == 0) {
      n.innerShadowColor = gui::rgba(15, 23, 38, 76);
    }
    if (n.innerShadowBlur <= 0.0) {
      n.innerShadowY = 3.0;
      n.innerShadowBlur = 10.0;
    }
    e.openEffectSettings = 1;
    e.editInnerOpen = true;
    e.accEffectsOpen = true;
  }
  markDirty(e);
  refreshInspectorLabels(e);
}

void toggleInnerShadowVisible(Editor* e) {
  if (e.selected < 0 || e.selected >= e.count) { return; }
  e.nodes[e.selected].innerShadowVisible = !e.nodes[e.selected].innerShadowVisible;
  markDirty(e);
}

void toggleLayerBlur(Editor* e, bool enable) {
  if (e.selected < 0 || e.selected >= e.count) { return; }
  DesignNode* n = &e.nodes[e.selected];
  n.layerBlurEnabled = enable;
  if (enable) {
    n.layerBlurVisible = true;
    if (n.layerBlur <= 0.0) { n.layerBlur = 6.0; }
    e.editLayerBlurOpen = true;
    e.accEffectsOpen = true;
  }
  markDirty(e);
}

void toggleLayerBlurVisible(Editor* e) {
  if (e.selected < 0 || e.selected >= e.count) { return; }
  e.nodes[e.selected].layerBlurVisible = !e.nodes[e.selected].layerBlurVisible;
  markDirty(e);
}

void toggleBgBlur(Editor* e, bool enable) {
  if (e.selected < 0 || e.selected >= e.count) { return; }
  DesignNode* n = &e.nodes[e.selected];
  n.bgBlurEnabled = enable;
  if (enable) {
    n.bgBlurVisible = true;
    if (n.bgBlur <= 0.0) { n.bgBlur = 12.0; }
    if (n.bgBlurColor.a == 0) { n.bgBlurColor = gui::rgba(255, 255, 255, 168); }
    e.editBgBlurOpen = true;
    e.accEffectsOpen = true;
  }
  markDirty(e);
  refreshInspectorLabels(e);
}

void toggleBgBlurVisible(Editor* e) {
  if (e.selected < 0 || e.selected >= e.count) { return; }
  e.nodes[e.selected].bgBlurVisible = !e.nodes[e.selected].bgBlurVisible;
  markDirty(e);
}

void toggleSnapping(Editor* e) {
  e.snapEnabled = !e.snapEnabled;
  if (!e.snapEnabled) {
    clearSnapGuides(e);
  }
  if (e.snapEnabled) {
    gui::toast("Snapping enabled", "Alignment and center-center guides active.");
  } else {
    gui::toast("Snapping disabled", "Free placement without guide snapping.");
  }
}

void syncConstrainedSize(Editor* e, float prevW, float prevH) {
  if (!e.constrainRatio || e.selected < 0 || e.selected >= e.count) { return; }
  DesignNode* n = &e.nodes[e.selected];
  if (prevW > 1.0 && prevH > 1.0) {
    float dw = n.w - prevW;
    float dh = n.h - prevH;
    if (dw < 0.0) { dw = -dw; }
    if (dh < 0.0) { dh = -dh; }
    if (dw > 0.01 && dh <= 0.01) {
      n.h = gui::clampf(n.w * (prevH / prevW), 8.0, 5000.0);
    } else if (dh > 0.01 && dw <= 0.01) {
      n.w = gui::clampf(n.h * (prevW / prevH), 8.0, 5000.0);
    }
  }
}


