// FigCraft Pure State Actions and Document Operations.
// Encapsulates tab management, page switching, layer CRUD, alignments,
// variable application, zoom, and workspace mode transitions.

import std.gui;
import examples.cui.figcraft.palette;
import examples.cui.figcraft.model;
import examples.cui.figcraft.geometry;
import examples.cui.figcraft.scene;

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
    for (int p = 0; p < e.pageCount && p < 4; p = p + 1) {
      savePageSlotToTab(e, e.activeTab, p);
    }
  }
}

void switchDocTab(Editor* e, int idx) {
  if (idx < 0 || idx >= e.tabCount || idx == e.activeTab) { return; }
  syncActiveTabSave(e);
  e.activeTab = idx;
  e.activePage = e.tabs[idx].activePage;
  e.pageCount = e.tabs[idx].pageCount;
  e.zoom = e.tabs[idx].zoom;
  e.offsetX = e.tabs[idx].offsetX;
  e.offsetY = e.tabs[idx].offsetY;
  e.darkTheme = e.tabs[idx].darkTheme;
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

  copyStr(&e.tabs[ni].title[0], "Untitled ", 48);
  char[12] num;
  formatInt(&num[0], ni + 1, 12);
  appendStr(&e.tabs[ni].title[0], &num[0], 48);

  e.count = 0;
  e.nextId = 100;
  e.selected = -1;
  e.zoom = 1.0;
  e.offsetX = 0.0;
  e.offsetY = 0.0;
  e.stageW = 1280.0;
  e.stageH = 820.0;
  e.stageBg = fcWhite();
  copyStr(&e.stageName[0], "Main Frame", 48);

  // Starter hero frame content
  addScRect(e, "Hero Card", 80.0, 80.0, 1120.0, 260.0, fcNavy(), 16.0, 0.0, gui::clear());
  addScText(e, "New Artboard", 124.0, 132.0, 480.0, 48.0, 32.0, fcWhite(), 1);
  addScText(e, "Start drawing frames, cards, and components with R, T, P, F.", 124.0, 186.0, 680.0, 28.0, 14.0, fcChartMint(), 0);
  addScButton(e, "Get started", 124.0, 244.0, 168.0, 42.0, fcGreen(), fcNavy());

  e.activePage = 0;
  e.pageCount = 1;
  copyStr(&e.pages[0].title[0], "Page 1", 48);
  saveCurrentNodesToPage(e, 0);

  e.tabs[ni].activePage = 0;
  e.tabs[ni].pageCount = 1;
  e.tabs[ni].selected = -1;
  e.tabs[ni].zoom = 1.0;
  e.tabs[ni].offsetX = 0.0;
  e.tabs[ni].offsetY = 0.0;
  e.tabs[ni].darkTheme = e.darkTheme;
  savePageSlotToTab(e, ni, 0);
  refreshInspectorLabels(e);
}

void copyPageData(PageData* dst, PageData* src) {
  copyStr(&dst.title[0], &src.title[0], 48);
  copyStr(&dst.frameName[0], &src.frameName[0], 48);
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
  copyStr(&dst.title[0], &src.title[0], 48);
  dst.activePage = src.activePage;
  dst.pageCount = src.pageCount;
  dst.selected = src.selected;
  dst.zoom = src.zoom;
  dst.offsetX = src.offsetX;
  dst.offsetY = src.offsetY;
  dst.darkTheme = src.darkTheme;
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
  copyStr(&e.pages[np].title[0], "Page ", 48);
  char[12] num;
  formatInt(&num[0], np + 1, 12);
  appendStr(&e.pages[np].title[0], &num[0], 48);

  e.count = 0;
  e.nextId = 600 + np * 50;
  e.selected = -1;
  e.stageW = 1200.0;
  e.stageH = 800.0;
  e.stageBg = fcWhite();
  copyStr(&e.stageName[0], &e.pages[np].title[0], 48);
  addScRect(e, "Canvas Card", 80.0, 80.0, 480.0, 220.0, fcDesignBg(false), 12.0, 1.0, fcDesignBorder());
  addScText(e, "Blank Page", 112.0, 116.0, 260.0, 32.0, 22.0, fcNavy(), 1);
  addScText(e, "Use R, T, F, P or Assets to build your layout.", 112.0, 158.0, 400.0, 24.0, 12.0, fcTitleMuted(), 0);
  saveCurrentNodesToPage(e, np);
  refreshInspectorLabels(e);
}

void selectTool(Editor* e, int toolIdx) {
  if (toolIdx == (ToolKind::ToolActions as int)) {
    e.showActions = !e.showActions;
    return;
  }
  e.tool = toolIdx;
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

void deleteSelectedNode(Editor* e) {
  if (e.selected < 0 || e.selected >= e.count) { return; }
  for (int j = e.selected; j < e.count - 1; j = j + 1) {
    e.nodes[j] = e.nodes[j + 1];
  }
  e.count = e.count - 1;
  if (e.selected >= e.count) {
    e.selected = e.count - 1;
  }
  refreshInspectorLabels(e);
}

void duplicateSelectedNode(Editor* e) {
  if (e.selected < 0 || e.selected >= e.count) { return; }
  if (e.count >= 160) { return; }
  DesignNode copy = e.nodes[e.selected];
  copy.id = e.nextId;
  e.nextId = e.nextId + 1;
  copy.x = copy.x + 24.0;
  copy.y = copy.y + 24.0;
  appendStr(&copy.name[0], " copy", 64);
  e.nodes[e.count] = copy;
  e.selected = e.count;
  e.count = e.count + 1;
  refreshInspectorLabels(e);
}

void moveLayerOrder(Editor* e, int idx, int dir) {
  if (idx < 0 || idx >= e.count) { return; }
  int target = idx + dir;
  if (target < 0 || target >= e.count) { return; }
  DesignNode tmp = e.nodes[idx];
  e.nodes[idx] = e.nodes[target];
  e.nodes[target] = tmp;
  e.selected = target;
}

void nudgeSelected(Editor* e, float dx, float dy) {
  if (e.selected >= 0 && e.selected < e.count) {
    if (e.nodes[e.selected].locked) { return; }
    e.nodes[e.selected].x = e.nodes[e.selected].x + dx;
    e.nodes[e.selected].y = e.nodes[e.selected].y + dy;
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
  e.nodes[e.selected].x = aligned.x;
  e.nodes[e.selected].y = aligned.y;
}

void insertComponentAsset(Editor* e, int assetKind) {
  if (e.count >= 156) {
    gui::toast("Canvas", "Maximum layer limit reached on this page.");
    return;
  }
  float cx = e.stageW * 0.5 - 90.0 + ((e.count % 5) as float) * 18.0;
  float cy = e.stageH * 0.5 - 60.0 + ((e.count % 4) as float) * 16.0;
  if (assetKind == 0) {
    addScButton(e, "Action Button", cx, cy, 160.0, 40.0, fcGreen(), fcNavy());
  } else if (assetKind == 1) {
    addScRect(e, "Surface Card", cx, cy, 240.0, 130.0, fcWhite(), 10.0, 1.0, fcDesignBorder());
  } else if (assetKind == 2) {
    addScChart(e, "Activity Bars", cx, cy, 320.0, 160.0, fcChartGreen());
  } else {
    addScDot(e, "Avatar Badge", cx, cy, 44.0, fcNavy());
  }
  e.selected = e.count - 1;
  e.tool = ToolKind::ToolMove as int;
  refreshInspectorLabels(e);
}

void applyColorVar(Editor* e, int varIdx) {
  if (varIdx < 0 || varIdx >= e.colorVarCount) { return; }
  Color c = e.colorVars[varIdx].color;
  if (e.selected >= 0 && e.selected < e.count) {
    if (e.nodes[e.selected].kind == (NodeKind::NodeText as int)) {
      e.nodes[e.selected].ink = c;
    } else {
      e.nodes[e.selected].fill = c;
    }
  } else {
    e.stageBg = c;
    e.fillVisible = true;
  }
  refreshInspectorLabels(e);
}

void applyNumberVar(Editor* e, int varIdx) {
  if (varIdx < 0 || varIdx >= e.numberVarCount) { return; }
  if (e.selected >= 0 && e.selected < e.count) {
    e.nodes[e.selected].radius = e.numberVars[varIdx].value;
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
}

void removeInteractionAt(Editor* e, int idx) {
  if (idx < 0 || idx >= e.interactionCount) { return; }
  for (int i = idx; i < e.interactionCount - 1; i = i + 1) {
    e.interactions[i] = e.interactions[i + 1];
  }
  e.interactionCount = e.interactionCount - 1;
}
