// FigCraft Data Model and Editor State.
// Defines all workspace enums, scene graph nodes, multi-page/multi-tab state,
// variables, prototype interactions, and global Editor instance.

import std.gui;
import std.string;
import examples.cui.figcraft.palette;

enum ToolKind {
  ToolMove,
  ToolFrame,
  ToolRect,
  ToolPen,
  ToolText,
  ToolComment,
  ToolActions,
  ToolHand,
  ToolScale,
  ToolSection,
  ToolSlice,
  ToolLine,
  ToolArrow,
  ToolEllipse,
  ToolPolygon,
  ToolStar,
  ToolImage,
  ToolPencil,
  ToolBodyText,
  ToolBadge
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
  NodeFrame,
  NodeSection,
  NodeSlice,
  NodeEllipse,
  NodeArrow,
  NodePolygon,
  NodeStar,
  NodeImage,
  NodePencil
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

enum ColorTarget {
  ColorTargetFill,
  ColorTargetInk,
  ColorTargetStroke,
  ColorTargetDropShadow,
  ColorTargetInnerShadow,
  ColorTargetBgBlur
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
  bool independentCorners;
  float radiusTL;
  float radiusTR;
  float radiusBR;
  float radiusBL;
  float border;
  int strokeAlign;
  int strokeStyle;
  float rotation;
  float opacity;
  int blendMode;
  int constraintH;
  int constraintV;
  bool clipContent;
  bool fillVisible;
  bool strokeVisible;

  // Typography & Label specifics
  float textSize;
  int font;
  int fontWeight;
  bool fontItalic;
  int textAlign;
  int textVAlign;
  float lineHeight;
  float letterSpacing;
  float paragraphSpacing;
  int textDecoration;
  int textCase;

  // Shape / Vector / Chart specifics
  int shapeSides;
  float shapeRatio;
  int arrowStartCap;
  int arrowEndCap;

  // Colors
  Color fill;
  Color ink;
  Color stroke;

  // Effects: Drop Shadow, Inner Shadow, Layer Blur, Background Blur (all unlinked)
  bool dropShadowEnabled;
  bool dropShadowVisible;
  float dropShadowX;
  float dropShadowY;
  float dropShadowBlur;
  float dropShadowSpread;
  Color dropShadowColor;

  bool innerShadowEnabled;
  bool innerShadowVisible;
  float innerShadowX;
  float innerShadowY;
  float innerShadowBlur;
  float innerShadowSpread;
  Color innerShadowColor;

  bool layerBlurEnabled;
  bool layerBlurVisible;
  float layerBlur;

  bool bgBlurEnabled;
  bool bgBlurVisible;
  float bgBlur;
  Color bgBlurColor;

  bool visible;
  bool locked;
  int parentId;
  bool expanded;
  char[20] rowId;
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
  bool dirty;
  char[24] savedStatus;
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
  int openFlyout;
  int[5] groupTool;
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
  float stageRadius;
  float stageOpacity;
  bool clipContent;
  bool fillVisible;
  bool darkTheme;
  bool leftCollapsed;
  bool rightCollapsed;
  bool accPositionOpen;
  bool accLayoutOpen;
  bool accAppearanceOpen;
  bool accTypographyOpen;
  bool accShapeOpen;
  bool accFillOpen;
  bool accStrokeOpen;
  bool accEffectsOpen;
  bool accSelColorsOpen;
  bool showGrid;
  bool outlineMode;
  bool presentMode;
  bool showHelp;
  bool showActions;
  bool showLayerSearch;
  bool constrainRatio;

  // Start page, main menu, and file modals
  bool showHome;
  int homeTab;
  bool homeGridView;
  char[64] homeSearch;
  bool showMainMenu;
  bool showExitPrompt;
  bool showSaveAsModal;
  bool showExportModal;
  int exportFormat;
  char[48] saveAsName;
  bool dirty;
  char[24] savedStatus;

  // Color picker tool & effect inspector state
  bool showColorPicker;
  int colorTarget;
  float pickerR;
  float pickerG;
  float pickerB;
  float pickerA;
  float lastPickerR;
  float lastPickerG;
  float lastPickerB;
  float lastPickerA;
  int lastSelIdx;
  float lastSelW;
  float lastSelH;
  char[16] pickerHex;
  int openEffectSettings;
  bool showAddEffectMenu;
  bool editDropOpen;
  bool editInnerOpen;
  bool editLayerBlurOpen;
  bool editBgBlurOpen;

  // Smart Snapping & Alignment Guides
  bool snapEnabled;
  int snapCountX;
  float[4] snapLineX;
  float[4] snapLineY0;
  float[4] snapLineY1;
  int[4] snapKindX;
  int snapCountY;
  float[4] snapLineY;
  float[4] snapLineX0;
  float[4] snapLineX1;
  int[4] snapKindY;
  bool snapCenterCenter;
  float snapCenterX;
  float snapCenterY;
  char[32] snapBadgeText;

  // Viewport & interaction state
  float zoom;
  float offsetX;
  float offsetY;
  Rect canvasRect;
  float stageScreenX;
  float stageScreenY;
  float stageScreenW;
  float stageScreenH;

  // Drag / Resize / Pan / Rubberband / Layer & Asset Drag
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

  int[160] layerTreeOrder;
  int[160] layerTreeDepth;
  bool[160] layerTreeHasKids;
  int layerTreeCount;
  bool layerDragArmed;
  bool layerDragActive;
  int layerDragNodeIdx;
  float layerDragMouseX;
  float layerDragMouseY;
  int layerDropTargetIdx;
  int layerDropMode;
  int hoverParentIdx;

  bool assetDragArmed;
  bool assetDragActive;
  bool assetDragIsSection;
  int assetDragKind;
  float assetDragMouseX;
  float assetDragMouseY;

  // Filter & inspector state
  char[64] layerFilter;
  char[32] dimLabel;
  char[16] zoomLabel;
  char[16] hexLabel;
  char[16] strokeHexLabel;
  char[16] inkHexLabel;
  char[16] dropHexLabel;
  char[16] innerHexLabel;
  char[16] bgBlurHexLabel;
  char[16] dropAlphaLabel;
  char[16] innerAlphaLabel;
  char[16] bgBlurAlphaLabel;
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
  e.openFlyout = -1;
  e.groupTool[0] = ToolKind::ToolMove as int;
  e.groupTool[1] = ToolKind::ToolFrame as int;
  e.groupTool[2] = ToolKind::ToolRect as int;
  e.groupTool[3] = ToolKind::ToolPen as int;
  e.groupTool[4] = ToolKind::ToolText as int;
  e.leftTab = LeftTab::TabFile as int;
  e.rightTab = RightTab::TabDesign as int;
  e.bottomMode = BottomMode::ModeDraw as int;
  e.activeTab = 0;
  e.tabCount = 1;
  e.activePage = 0;
  e.pageCount = 1;
  std::string::copy(&e.stageName[0], "Main Frame", 48);
  e.stageW = 1440.0;
  e.stageH = 960.0;
  e.stageBg = fcWhite();
  e.stageRadius = 2.0;
  e.stageOpacity = 1.0;
  e.clipContent = true;
  e.fillVisible = true;
  e.darkTheme = false;
  e.leftCollapsed = false;
  e.rightCollapsed = false;
  e.accPositionOpen = true;
  e.accLayoutOpen = true;
  e.accAppearanceOpen = true;
  e.accTypographyOpen = true;
  e.accShapeOpen = true;
  e.accFillOpen = true;
  e.accStrokeOpen = true;
  e.accEffectsOpen = true;
  e.accSelColorsOpen = true;
  e.showGrid = false;
  e.outlineMode = false;
  e.presentMode = false;
  e.showHelp = false;
  e.showActions = false;
  e.showLayerSearch = false;
  e.constrainRatio = false;
  e.showHome = false;
  e.homeTab = 0;
  e.homeGridView = true;
  e.homeSearch[0] = '\0';
  e.showMainMenu = false;
  e.showExitPrompt = false;
  e.showSaveAsModal = false;
  e.showExportModal = false;
  e.exportFormat = 0;
  std::string::copy(&e.saveAsName[0], "Untitled 1 copy", 48);
  e.dirty = false;
  std::string::copy(&e.savedStatus[0], "Saved", 24);
  e.showColorPicker = false;
  e.colorTarget = 0;
  e.pickerR = 10.0;
  e.pickerG = 207.0;
  e.pickerB = 131.0;
  e.pickerA = 100.0;
  e.lastPickerR = 10.0;
  e.lastPickerG = 207.0;
  e.lastPickerB = 131.0;
  e.lastPickerA = 100.0;
  e.lastSelIdx = -1;
  e.lastSelW = 1440.0;
  e.lastSelH = 960.0;
  std::string::copy(&e.pickerHex[0], "0ACF83", 16);
  e.openEffectSettings = 0;
  e.showAddEffectMenu = false;
  e.editDropOpen = true;
  e.editInnerOpen = true;
  e.editLayerBlurOpen = true;
  e.editBgBlurOpen = true;
  e.snapEnabled = true;
  e.snapCountX = 0;
  e.snapCountY = 0;
  e.snapCenterCenter = false;
  e.snapCenterX = 0.0;
  e.snapCenterY = 0.0;
  e.snapBadgeText[0] = '\0';
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
  e.layerTreeCount = 0;
  e.layerDragArmed = false;
  e.layerDragActive = false;
  e.layerDragNodeIdx = -1;
  e.layerDragMouseX = 0.0;
  e.layerDragMouseY = 0.0;
  e.layerDropTargetIdx = -2;
  e.layerDropMode = 0;
  e.hoverParentIdx = -1;
  e.assetDragArmed = false;
  e.assetDragActive = false;
  e.assetDragIsSection = false;
  e.assetDragKind = 0;
  e.assetDragMouseX = 0.0;
  e.assetDragMouseY = 0.0;
  e.layerFilter[0] = '\0';
  std::string::copy(&e.dimLabel[0], "1440 x 960", 32);
  std::string::copy(&e.zoomLabel[0], "57%", 16);
  std::string::copy(&e.hexLabel[0], "FFFFFF", 16);
  std::string::copy(&e.strokeHexLabel[0], "E7EAEF", 16);
  std::string::copy(&e.inkHexLabel[0], "0F1726", 16);
  std::string::copy(&e.dropHexLabel[0], "0F1726", 16);
  std::string::copy(&e.innerHexLabel[0], "0F1726", 16);
  std::string::copy(&e.bgBlurHexLabel[0], "FFFFFF", 16);
  std::string::copy(&e.dropAlphaLabel[0], "22%", 16);
  std::string::copy(&e.innerAlphaLabel[0], "28%", 16);
  std::string::copy(&e.bgBlurAlphaLabel[0], "66%", 16);
  std::string::copy(&e.degLabel[0], "0 deg", 24);
  std::string::copy(&e.opacityLabel[0], "100%", 24);
  std::string::copy(&e.layerCountLabel[0], "0", 16);
  e.interactionCount = 0;
  e.colorVarCount = 0;
  e.numberVarCount = 0;
}
