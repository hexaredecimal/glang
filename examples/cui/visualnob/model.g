// VisualNob Data Model: Script Nodes, Typed Ports, Bezier Wires, Script Variables,
// Context Menu / Quick-Add Palette State, and Global Editor Instance.

import std.gui;
import std.cui;
import examples.cui.visualnob.palette;

enum PinType {
  PinExec,
  PinNumber,
  PinString,
  PinBool,
  PinAny
}

enum NodeCat {
  CatAll,
  CatEvents,
  CatValues,
  CatVariables,
  CatLogic,
  CatFlow,
  CatActions
}

enum VnNodeKind {
  VnOnStart,
  VnOnTick,
  VnConstNumber,
  VnConstString,
  VnConstBool,
  VnGetVar,
  VnSetVar,
  VnMathAdd,
  VnMathMul,
  VnCompare,
  VnLogicNot,
  VnBranch,
  VnRepeat,
  VnSequence,
  VnFormat,
  VnPrintLog,
  VnEmitToast,
  VnComment
}

enum ContextKind {
  CtxNone,
  CtxCanvas,
  CtxNode,
  CtxPort,
  CtxWire
}

struct ScriptPin {
  int pinType;
  char[24] label;
  float defNum;
  char[48] defStr;
  bool defBool;
}

struct ScriptNode {
  int id;
  int kind;
  int category;
  float x;
  float y;
  float w;
  float h;
  char[48] title;
  char[64] strValue;
  float numValue;
  bool boolValue;
  int opMode;
  int inputCount;
  ScriptPin[5] inputs;
  int outputCount;
  ScriptPin[4] outputs;
  bool executed;
  bool collapsed;
}

struct Wire {
  int fromNode;
  int fromPort;
  int toNode;
  int toPort;
  int pinType;
  bool active;
}

struct ScriptVar {
  char[32] name;
  int pinType;
  float numVal;
  char[64] strVal;
  bool boolVal;
  float runtimeNum;
  char[64] runtimeStr;
  bool runtimeBool;
}

struct ConsoleLine {
  int level;
  char[120] text;
}

struct GraphEditor {
  char[48] scriptName;
  int activePreset;

  ScriptNode[64] nodes;
  int nodeCount;
  int nextNodeId;

  Wire[128] wires;
  int wireCount;

  ScriptVar[16] vars;
  int varCount;
  char[32] newVarName;

  ConsoleLine[64] consoleLines;
  int consoleCount;
  int lastStepCount;
  bool hasRun;

  // Selection & hover
  int selectedNode;
  int selectedWire;
  int hoverNode;
  int hoverPortNode;
  int hoverPortIdx;
  bool hoverPortIsOut;
  int hoverWire;

  // Viewport & theme
  bool darkTheme;
  bool leftCollapsed;
  bool snapToGrid;
  bool showGrid;
  bool showMinimap;
  bool showHelp;
  float zoom;
  float panX;
  float panY;
  Rect canvasRect;
  char[16] zoomLabel;
  char[32] statusLabel;
  char[24] stepLabel;

  // Dragging node / Panning / Linking wire
  bool draggingNode;
  float dragStartNodeX;
  float dragStartNodeY;
  float dragStartMouseX;
  float dragStartMouseY;
  bool panning;
  float panStartX;
  float panStartY;

  bool linking;
  int linkStartNode;
  int linkStartPort;
  bool linkFromOutput;
  int linkPinType;
  float linkCurX;
  float linkCurY;

  // Node Palette (docked search + category + cursor quick-add picker)
  int paletteCategory;
  char[48] paletteFilter;
  bool showQuickAdd;
  float quickAddScreenX;
  float quickAddScreenY;
  float quickAddWorldX;
  float quickAddWorldY;
  char[48] quickAddFilter;

  // Context-sensitive right-click menu
  int contextKind;
  float contextScreenX;
  float contextScreenY;
  float contextWorldX;
  float contextWorldY;
  int contextNode;
  int contextPort;
  bool contextPortIsOut;
  int contextWire;
}

GraphEditor vn;

Color pinTypeColor(int pinType, bool dark) {
  if (pinType == (PinType::PinExec as int)) {
    return if (dark) gui::rgb(245, 247, 250) else gui::rgb(30, 34, 44);
  }
  if (pinType == (PinType::PinNumber as int)) { return vnMint(); }
  if (pinType == (PinType::PinString as int)) { return vnAmber(); }
  if (pinType == (PinType::PinBool as int)) { return vnViolet(); }
  return vnBlue();
}

const char* pinTypeName(int pinType) {
  if (pinType == (PinType::PinExec as int)) { return "Exec"; }
  if (pinType == (PinType::PinNumber as int)) { return "Number"; }
  if (pinType == (PinType::PinString as int)) { return "String"; }
  if (pinType == (PinType::PinBool as int)) { return "Bool"; }
  return "Any";
}

Color categoryHeaderColor(int cat, bool dark) {
  if (cat == (NodeCat::CatEvents as int)) { return vnCoral(); }
  if (cat == (NodeCat::CatValues as int)) { return vnMintDark(); }
  if (cat == (NodeCat::CatVariables as int)) { return vnCyan(); }
  if (cat == (NodeCat::CatLogic as int)) { return vnAmber(); }
  if (cat == (NodeCat::CatFlow as int)) { return vnViolet(); }
  if (cat == (NodeCat::CatActions as int)) { return vnBlue(); }
  return if (dark) gui::rgb(78, 82, 94) else gui::rgb(110, 118, 132);
}

const char* categoryLabel(int cat) {
  if (cat == (NodeCat::CatEvents as int)) { return "Event"; }
  if (cat == (NodeCat::CatValues as int)) { return "Value"; }
  if (cat == (NodeCat::CatVariables as int)) { return "Variable"; }
  if (cat == (NodeCat::CatLogic as int)) { return "Logic"; }
  if (cat == (NodeCat::CatFlow as int)) { return "Flow"; }
  if (cat == (NodeCat::CatActions as int)) { return "Action"; }
  return "All";
}

const char* nodeKindDefaultTitle(int kind) {
  if (kind == (VnNodeKind::VnOnStart as int)) { return "On Start"; }
  if (kind == (VnNodeKind::VnOnTick as int)) { return "On Tick"; }
  if (kind == (VnNodeKind::VnConstNumber as int)) { return "Number"; }
  if (kind == (VnNodeKind::VnConstString as int)) { return "String"; }
  if (kind == (VnNodeKind::VnConstBool as int)) { return "Boolean"; }
  if (kind == (VnNodeKind::VnGetVar as int)) { return "Get Var"; }
  if (kind == (VnNodeKind::VnSetVar as int)) { return "Set Var"; }
  if (kind == (VnNodeKind::VnMathAdd as int)) { return "Add / Sub"; }
  if (kind == (VnNodeKind::VnMathMul as int)) { return "Mul / Div"; }
  if (kind == (VnNodeKind::VnCompare as int)) { return "Compare"; }
  if (kind == (VnNodeKind::VnLogicNot as int)) { return "Logic Not"; }
  if (kind == (VnNodeKind::VnBranch as int)) { return "Branch (If)"; }
  if (kind == (VnNodeKind::VnRepeat as int)) { return "Repeat Loop"; }
  if (kind == (VnNodeKind::VnSequence as int)) { return "Sequence"; }
  if (kind == (VnNodeKind::VnFormat as int)) { return "Format Text"; }
  if (kind == (VnNodeKind::VnPrintLog as int)) { return "Print Log"; }
  if (kind == (VnNodeKind::VnEmitToast as int)) { return "Emit Toast"; }
  return "Comment Note";
}

int nodeKindCategory(int kind) {
  if (kind == (VnNodeKind::VnOnStart as int) || kind == (VnNodeKind::VnOnTick as int)) {
    return NodeCat::CatEvents as int;
  }
  if (kind == (VnNodeKind::VnConstNumber as int) ||
      kind == (VnNodeKind::VnConstString as int) ||
      kind == (VnNodeKind::VnConstBool as int)) {
    return NodeCat::CatValues as int;
  }
  if (kind == (VnNodeKind::VnGetVar as int) || kind == (VnNodeKind::VnSetVar as int)) {
    return NodeCat::CatVariables as int;
  }
  if (kind == (VnNodeKind::VnMathAdd as int) ||
      kind == (VnNodeKind::VnMathMul as int) ||
      kind == (VnNodeKind::VnCompare as int) ||
      kind == (VnNodeKind::VnLogicNot as int)) {
    return NodeCat::CatLogic as int;
  }
  if (kind == (VnNodeKind::VnBranch as int) ||
      kind == (VnNodeKind::VnRepeat as int) ||
      kind == (VnNodeKind::VnSequence as int)) {
    return NodeCat::CatFlow as int;
  }
  return NodeCat::CatActions as int;
}

const char* nodeKindIcon(int kind) {
  if (kind == (VnNodeKind::VnOnStart as int)) { return std::cui::icons::play(); }
  if (kind == (VnNodeKind::VnOnTick as int)) { return std::cui::icons::clock(); }
  if (kind == (VnNodeKind::VnConstNumber as int)) { return std::cui::icons::sliders(); }
  if (kind == (VnNodeKind::VnConstString as int)) { return std::cui::icons::textTool(); }
  if (kind == (VnNodeKind::VnConstBool as int)) { return std::cui::icons::checkCircle(); }
  if (kind == (VnNodeKind::VnGetVar as int) || kind == (VnNodeKind::VnSetVar as int)) {
    return std::cui::icons::database();
  }
  if (kind == (VnNodeKind::VnMathAdd as int) || kind == (VnNodeKind::VnMathMul as int)) {
    return std::cui::icons::plus();
  }
  if (kind == (VnNodeKind::VnCompare as int) || kind == (VnNodeKind::VnLogicNot as int)) {
    return std::cui::icons::gitBranch();
  }
  if (kind == (VnNodeKind::VnBranch as int)) { return std::cui::icons::gitBranch(); }
  if (kind == (VnNodeKind::VnRepeat as int)) { return std::cui::icons::refresh(); }
  if (kind == (VnNodeKind::VnSequence as int)) { return std::cui::icons::list(); }
  if (kind == (VnNodeKind::VnFormat as int)) { return std::cui::icons::code(); }
  if (kind == (VnNodeKind::VnPrintLog as int)) { return std::cui::icons::terminal(); }
  if (kind == (VnNodeKind::VnEmitToast as int)) { return std::cui::icons::bell(); }
  return std::cui::icons::message();
}

const char* nodeKindDescription(int kind) {
  if (kind == (VnNodeKind::VnOnStart as int)) { return "Entry trigger on script run"; }
  if (kind == (VnNodeKind::VnOnTick as int)) { return "Trigger executed on step tick"; }
  if (kind == (VnNodeKind::VnConstNumber as int)) { return "Numeric constant value"; }
  if (kind == (VnNodeKind::VnConstString as int)) { return "Text string literal"; }
  if (kind == (VnNodeKind::VnConstBool as int)) { return "Boolean true/false literal"; }
  if (kind == (VnNodeKind::VnGetVar as int)) { return "Read named script variable"; }
  if (kind == (VnNodeKind::VnSetVar as int)) { return "Assign variable and continue"; }
  if (kind == (VnNodeKind::VnMathAdd as int)) { return "Add or subtract two numbers"; }
  if (kind == (VnNodeKind::VnMathMul as int)) { return "Multiply, divide, or modulo"; }
  if (kind == (VnNodeKind::VnCompare as int)) { return "Compare A and B to Bool"; }
  if (kind == (VnNodeKind::VnLogicNot as int)) { return "Invert boolean truth value"; }
  if (kind == (VnNodeKind::VnBranch as int)) { return "Route Exec by condition"; }
  if (kind == (VnNodeKind::VnRepeat as int)) { return "Loop N times over Body Exec"; }
  if (kind == (VnNodeKind::VnSequence as int)) { return "Run two Exec paths in order"; }
  if (kind == (VnNodeKind::VnFormat as int)) { return "Combine label prefix + value"; }
  if (kind == (VnNodeKind::VnPrintLog as int)) { return "Write output to script console"; }
  if (kind == (VnNodeKind::VnEmitToast as int)) { return "Show UI toast notification"; }
  return "Sticky annotation card";
}

bool pinsCompatible(int outType, int inType) {
  if (outType == (PinType::PinExec as int)) {
    return inType == (PinType::PinExec as int);
  }
  if (inType == (PinType::PinExec as int)) {
    return false;
  }
  if (inType == (PinType::PinAny as int) || outType == (PinType::PinAny as int)) {
    return true;
  }
  if (outType == inType) {
    return true;
  }
  if (inType == (PinType::PinString as int)) {
    return true;
  }
  return false;
}

void pushConsole(GraphEditor* e, int level, const char* msg) {
  if (e.consoleCount >= 64) {
    for (int i = 1; i < 64; i = i + 1) {
      e.consoleLines[i - 1] = e.consoleLines[i];
    }
    e.consoleCount = 63;
  }
  e.consoleLines[e.consoleCount].level = level;
  vnCopyStr(&e.consoleLines[e.consoleCount].text[0], msg, 120);
  e.consoleCount = e.consoleCount + 1;
}

void clearConsole(GraphEditor* e) {
  e.consoleCount = 0;
}

void refreshStatusLabels(GraphEditor* e) {
  vnFormatPercent(&e.zoomLabel[0], e.zoom, 16);
  char[12] nb;
  char[12] wb;
  vnFormatInt(&nb[0], e.nodeCount, 12);
  vnFormatInt(&wb[0], e.wireCount, 12);
  vnCopyStr(&e.statusLabel[0], &nb[0], 32);
  vnAppendStr(&e.statusLabel[0], " nodes  ", 32);
  vnAppendStr(&e.statusLabel[0], &wb[0], 32);
  vnAppendStr(&e.statusLabel[0], " wires", 32);

  vnFormatInt(&e.stepLabel[0], e.lastStepCount, 24);
  vnAppendStr(&e.stepLabel[0], " ops", 24);
}

void resetEditorDefaults(GraphEditor* e) {
  vnCopyStr(&e.scriptName[0], "Threshold Flow.vnob", 48);
  e.activePreset = 0;
  e.nodeCount = 0;
  e.nextNodeId = 1;
  e.wireCount = 0;
  e.varCount = 0;
  vnCopyStr(&e.newVarName[0], "limit", 32);
  e.consoleCount = 0;
  e.lastStepCount = 0;
  e.hasRun = false;

  e.selectedNode = -1;
  e.selectedWire = -1;
  e.hoverNode = -1;
  e.hoverPortNode = -1;
  e.hoverPortIdx = -1;
  e.hoverPortIsOut = false;
  e.hoverWire = -1;

  e.darkTheme = true;
  e.leftCollapsed = false;
  e.snapToGrid = true;
  e.showGrid = true;
  e.showMinimap = true;
  e.showHelp = false;
  e.zoom = 1.0;
  e.panX = 28.0;
  e.panY = 36.0;
  e.canvasRect = Rect{x: 260.0, y: 46.0, w: 860.0, h: 850.0};

  e.draggingNode = false;
  e.panning = false;
  e.linking = false;
  e.linkStartNode = -1;
  e.linkStartPort = -1;

  e.paletteCategory = NodeCat::CatAll as int;
  e.paletteFilter[0] = '\0';
  e.showQuickAdd = false;
  e.quickAddFilter[0] = '\0';

  e.contextKind = ContextKind::CtxNone as int;
  e.contextNode = -1;
  e.contextPort = -1;
  e.contextWire = -1;
  refreshStatusLabels(e);
}
