// FigCraft Data Model and Editor State.
// Defines all workspace enums, scene graph nodes, multi-page/multi-tab state,
// variables, prototype interactions, and global Editor instance.

import std.gui;
import examples.cui.figcraft.palette;

enum ToolKind {
  ToolMove,
  ToolFrame,
  ToolRect,
  ToolPen,
  ToolText,
  ToolComment,
  ToolActions
}

enum BottomMode {
  ModeDraw,
  ModeLayout,
  ModeDev
}

enum LeftTab {
  TabFile,
  TabAssets,
  TabVariables
}

enum RightTab {
  TabDesign,
  TabPrototype
}

enum NodeKind {
  NodeRectangle,
  NodeText,
  NodeChart,
  NodeButton,
  NodeDonut,
  NodeLine,
  NodeSparkline,
  NodePen,
  NodeComment,
  NodeFrame
}

enum HandleKind {
  HandleNone,
  HandleTL,
  HandleT,
  HandleTR,
  HandleR,
  HandleBR,
  HandleB,
  HandleBL,
  HandleL
}

struct DesignNode {
  int kind;
  int id;
  int groupIndex;
  float x;
  float y;
  float w;
  float h;
  float radius;
  float border;
  float rotation;
  float opacity;
  float textSize;
  int font;
  Color fill;
  Color ink;
  Color stroke;
  bool visible;
  bool locked;
  char[64] name;
  char[128] body;
}

struct PageData {
  char[48] title;
  char[48] frameName;
  float frameW;
  float frameH;
  Color frameBg;
  DesignNode[160] nodes;
  int count;
  int nextId;
}

struct DocTabInfo {
  char[48] title;
  int activePage;
  int pageCount;
  int selected;
  float zoom;
  float offsetX;
  float offsetY;
  bool darkTheme;
  PageData[4] pages;
}

struct InteractionItem {
  int nodeId;
  char[32] trigger;
  char[48] action;
  char[32] animation;
  int durationMs;
}

struct ColorVar {
  char[24] token;
  char[24] group;
  char[16] hex;
  Color color;
}

struct NumberVar {
  char[24] token;
  char[24] label;
  float value;
  char[12] display;
}

struct Editor {
  // Active page working scene
  DesignNode[160] nodes;
  int count;
  int nextId;
  int selected;

  // Tool & workspace modes
  int tool;
  int leftTab;
  int rightTab;
  int bottomMode;

  // Document tabs & pages
  int activeTab;
  int tabCount;
  DocTabInfo[6] tabs;
  int activePage;
  int pageCount;
  PageData[4] pages;

  // Active stage frame properties
  char[48] stageName;
  float stageW;
  float stageH;
  Color stageBg;
  bool clipContent;
  bool fillVisible;
  bool darkTheme;
  bool leftCollapsed;
  bool showGrid;
  bool outlineMode;
  bool presentMode;
  bool showHelp;
  bool showActions;
  bool showLayerSearch;
  bool constrainRatio;

  // Viewport & interaction state
  float zoom;
  float offsetX;
  float offsetY;
  Rect canvasRect;
  float stageScreenX;
  float stageScreenY;
  float stageScreenW;
  float stageScreenH;

  // Drag / Resize / Pan / Rubberband
  bool dragging;
  int dragHandle;
  float dragStartX;
  float dragStartY;
  float dragStartW;
  float dragStartH;
  float dragMouseX;
  float dragMouseY;
  bool panning;
  bool creating;
  float createStartDx;
  float createStartDy;
  float createCurDx;
  float createCurDy;

  // Filter & inspector state
  char[64] layerFilter;
  char[32] dimLabel;
  char[16] zoomLabel;
  char[16] hexLabel;
  char[24] degLabel;
  char[24] opacityLabel;
  char[16] layerCountLabel;

  // Prototype interactions & variables
  InteractionItem[16] interactions;
  int interactionCount;
  ColorVar[8] colorVars;
  int colorVarCount;
  NumberVar[4] numberVars;
  int numberVarCount;
}

Editor ed;

void resetEditorFields(Editor* e) {
  e.count = 0;
  e.nextId = 100;
  e.selected = -1;
  e.tool = ToolKind::ToolMove as int;
  e.leftTab = LeftTab::TabFile as int;
  e.rightTab = RightTab::TabDesign as int;
  e.bottomMode = BottomMode::ModeDraw as int;
  e.activeTab = 0;
  e.tabCount = 1;
  e.activePage = 0;
  e.pageCount = 2;
  copyStr(&e.stageName[0], "Dashboard - Overview", 48);
  e.stageW = 1440.0;
  e.stageH = 960.0;
  e.stageBg = fcDesignBg(false);
  e.clipContent = true;
  e.fillVisible = true;
  e.darkTheme = false;
  e.leftCollapsed = false;
  e.showGrid = false;
  e.outlineMode = false;
  e.presentMode = false;
  e.showHelp = false;
  e.showActions = false;
  e.showLayerSearch = false;
  e.constrainRatio = false;
  e.zoom = 1.0;
  e.offsetX = 0.0;
  e.offsetY = 0.0;
  e.canvasRect = Rect{x: 300.0, y: 50.0, w: 840.0, h: 850.0};
  e.stageScreenX = 312.0;
  e.stageScreenY = 160.0;
  e.stageScreenW = 816.0;
  e.stageScreenH = 544.0;
  e.dragging = false;
  e.dragHandle = HandleKind::HandleNone as int;
  e.dragStartX = 0.0;
  e.dragStartY = 0.0;
  e.dragStartW = 0.0;
  e.dragStartH = 0.0;
  e.dragMouseX = 0.0;
  e.dragMouseY = 0.0;
  e.panning = false;
  e.creating = false;
  e.createStartDx = 0.0;
  e.createStartDy = 0.0;
  e.createCurDx = 0.0;
  e.createCurDy = 0.0;
  e.layerFilter[0] = '\0';
  copyStr(&e.dimLabel[0], "1440 x 960", 32);
  copyStr(&e.zoomLabel[0], "57%", 16);
  copyStr(&e.hexLabel[0], "F3F5F8", 16);
  copyStr(&e.degLabel[0], "0 deg", 24);
  copyStr(&e.opacityLabel[0], "100%", 24);
  copyStr(&e.layerCountLabel[0], "0", 16);
  e.interactionCount = 0;
  e.colorVarCount = 0;
  e.numberVarCount = 0;
}
