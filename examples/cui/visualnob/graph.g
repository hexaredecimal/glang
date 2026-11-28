// VisualNob Graph Operations: Node Constructors, Wire Connection/Validation,
// Variable Registry, Auto-Layout, and Starter Visual Scripts.

import std.gui;
import examples.cui.visualnob.palette;
import examples.cui.visualnob.model;
import examples.cui.visualnob.geometry;

void initPin(ScriptPin* p, int pinType, const char* label, float defNum, const char* defStr, bool defBool) {
  p.pinType = pinType;
  vnCopyStr(&p.label[0], label, 24);
  p.defNum = defNum;
  vnCopyStr(&p.defStr[0], defStr, 48);
  p.defBool = defBool;
}

int addScriptVar(GraphEditor* e, const char* name, int pinType, float numVal, const char* strVal, bool boolVal) {
  for (int i = 0; i < e.varCount; i = i + 1) {
    if (vnStrEquals(&e.vars[i].name[0], name)) {
      return i;
    }
  }
  if (e.varCount >= 16) { return -1; }
  int idx = e.varCount;
  vnCopyStr(&e.vars[idx].name[0], name, 32);
  e.vars[idx].pinType = pinType;
  e.vars[idx].numVal = numVal;
  vnCopyStr(&e.vars[idx].strVal[0], strVal, 64);
  e.vars[idx].boolVal = boolVal;
  e.vars[idx].runtimeNum = numVal;
  vnCopyStr(&e.vars[idx].runtimeStr[0], strVal, 64);
  e.vars[idx].runtimeBool = boolVal;
  e.varCount = e.varCount + 1;
  return idx;
}

int findScriptVar(GraphEditor* e, const char* name) {
  for (int i = 0; i < e.varCount; i = i + 1) {
    if (vnStrEquals(&e.vars[i].name[0], name)) {
      return i;
    }
  }
  return -1;
}

int createScriptNode(GraphEditor* e, int kind, float wx, float wy) {
  if (e.nodeCount >= 64) {
    pushConsole(e, 2, "Node limit (64) reached.");
    return -1;
  }
  int idx = e.nodeCount;
  ScriptNode* n = &e.nodes[idx];
  n.id = e.nextNodeId;
  e.nextNodeId = e.nextNodeId + 1;
  n.kind = kind;
  n.category = nodeKindCategory(kind);
  n.x = snapWorld(wx, e.snapToGrid);
  n.y = snapWorld(wy, e.snapToGrid);
  n.w = 188.0;
  n.strValue[0] = '\0';
  n.numValue = 0.0;
  n.boolValue = true;
  n.opMode = 0;
  n.inputCount = 0;
  n.outputCount = 0;
  n.executed = false;
  n.collapsed = false;
  vnCopyStr(&n.title[0], nodeKindDefaultTitle(kind), 48);

  int EX = PinType::PinExec as int;
  int NUM = PinType::PinNumber as int;
  int STR = PinType::PinString as int;
  int BOOL = PinType::PinBool as int;
  int ANY = PinType::PinAny as int;

  if (kind == (VnNodeKind::VnOnStart as int)) {
    n.w = 158.0;
    n.outputCount = 1;
    initPin(&n.outputs[0], EX, "Exec", 0.0, "", false);
  } else if (kind == (VnNodeKind::VnOnTick as int)) {
    n.w = 166.0;
    n.outputCount = 2;
    initPin(&n.outputs[0], EX, "Exec", 0.0, "", false);
    initPin(&n.outputs[1], NUM, "Tick #", 1.0, "", false);
  } else if (kind == (VnNodeKind::VnConstNumber as int)) {
    n.w = 164.0;
    n.numValue = 10.0;
    n.outputCount = 1;
    initPin(&n.outputs[0], NUM, "Value", 10.0, "", false);
  } else if (kind == (VnNodeKind::VnConstString as int)) {
    n.w = 176.0;
    vnCopyStr(&n.strValue[0], "VisualNob", 64);
    n.outputCount = 1;
    initPin(&n.outputs[0], STR, "Text", 0.0, "VisualNob", false);
  } else if (kind == (VnNodeKind::VnConstBool as int)) {
    n.w = 160.0;
    n.boolValue = true;
    n.outputCount = 1;
    initPin(&n.outputs[0], BOOL, "State", 0.0, "", true);
  } else if (kind == (VnNodeKind::VnGetVar as int)) {
    n.w = 176.0;
    vnCopyStr(&n.strValue[0], if (e.varCount > 0) &e.vars[0].name[0] else "score", 64);
    n.outputCount = 1;
    initPin(&n.outputs[0], NUM, "Value", 0.0, "", false);
  } else if (kind == (VnNodeKind::VnSetVar as int)) {
    n.w = 186.0;
    vnCopyStr(&n.strValue[0], if (e.varCount > 0) &e.vars[0].name[0] else "score", 64);
    n.numValue = 1.0;
    n.inputCount = 2;
    initPin(&n.inputs[0], EX, "Exec", 0.0, "", false);
    initPin(&n.inputs[1], NUM, "Value", 1.0, "", false);
    n.outputCount = 2;
    initPin(&n.outputs[0], EX, "Then", 0.0, "", false);
    initPin(&n.outputs[1], NUM, "NewVal", 0.0, "", false);
  } else if (kind == (VnNodeKind::VnMathAdd as int)) {
    n.w = 174.0;
    n.inputCount = 2;
    initPin(&n.inputs[0], NUM, "A", 1.0, "", false);
    initPin(&n.inputs[1], NUM, "B", 1.0, "", false);
    n.outputCount = 1;
    initPin(&n.outputs[0], NUM, "Result", 0.0, "", false);
  } else if (kind == (VnNodeKind::VnMathMul as int)) {
    n.w = 174.0;
    n.inputCount = 2;
    initPin(&n.inputs[0], NUM, "A", 2.0, "", false);
    initPin(&n.inputs[1], NUM, "B", 3.0, "", false);
    n.outputCount = 1;
    initPin(&n.outputs[0], NUM, "Result", 0.0, "", false);
  } else if (kind == (VnNodeKind::VnCompare as int)) {
    n.w = 178.0;
    n.opMode = 0; // A > B
    n.inputCount = 2;
    initPin(&n.inputs[0], NUM, "A", 0.0, "", false);
    initPin(&n.inputs[1], NUM, "B", 10.0, "", false);
    n.outputCount = 1;
    initPin(&n.outputs[0], BOOL, "Match", 0.0, "", false);
  } else if (kind == (VnNodeKind::VnLogicNot as int)) {
    n.w = 160.0;
    n.inputCount = 1;
    initPin(&n.inputs[0], BOOL, "In", 0.0, "", false);
    n.outputCount = 1;
    initPin(&n.outputs[0], BOOL, "Not", 0.0, "", true);
  } else if (kind == (VnNodeKind::VnBranch as int)) {
    n.w = 186.0;
    n.inputCount = 2;
    initPin(&n.inputs[0], EX, "Exec", 0.0, "", false);
    initPin(&n.inputs[1], BOOL, "Condition", 0.0, "", true);
    n.outputCount = 2;
    initPin(&n.outputs[0], EX, "True", 0.0, "", false);
    initPin(&n.outputs[1], EX, "False", 0.0, "", false);
  } else if (kind == (VnNodeKind::VnRepeat as int)) {
    n.w = 186.0;
    n.numValue = 4.0;
    n.inputCount = 2;
    initPin(&n.inputs[0], EX, "Exec", 0.0, "", false);
    initPin(&n.inputs[1], NUM, "Count", 4.0, "", false);
    n.outputCount = 3;
    initPin(&n.outputs[0], EX, "Body", 0.0, "", false);
    initPin(&n.outputs[1], NUM, "Index", 0.0, "", false);
    initPin(&n.outputs[2], EX, "Done", 0.0, "", false);
  } else if (kind == (VnNodeKind::VnSequence as int)) {
    n.w = 172.0;
    n.inputCount = 1;
    initPin(&n.inputs[0], EX, "Exec", 0.0, "", false);
    n.outputCount = 2;
    initPin(&n.outputs[0], EX, "Then 0", 0.0, "", false);
    initPin(&n.outputs[1], EX, "Then 1", 0.0, "", false);
  } else if (kind == (VnNodeKind::VnFormat as int)) {
    n.w = 186.0;
    vnCopyStr(&n.strValue[0], "Value = ", 64);
    n.inputCount = 2;
    initPin(&n.inputs[0], STR, "Prefix", 0.0, "Value = ", false);
    initPin(&n.inputs[1], ANY, "Data", 0.0, "0", false);
    n.outputCount = 1;
    initPin(&n.outputs[0], STR, "Text", 0.0, "", false);
  } else if (kind == (VnNodeKind::VnPrintLog as int)) {
    n.w = 186.0;
    vnCopyStr(&n.strValue[0], "Hello VisualNob", 64);
    n.inputCount = 2;
    initPin(&n.inputs[0], EX, "Exec", 0.0, "", false);
    initPin(&n.inputs[1], ANY, "Message", 0.0, "Hello VisualNob", false);
    n.outputCount = 1;
    initPin(&n.outputs[0], EX, "Then", 0.0, "", false);
  } else if (kind == (VnNodeKind::VnEmitToast as int)) {
    n.w = 188.0;
    vnCopyStr(&n.strValue[0], "Workflow Complete", 64);
    n.inputCount = 2;
    initPin(&n.inputs[0], EX, "Exec", 0.0, "", false);
    initPin(&n.inputs[1], ANY, "Summary", 0.0, "Workflow Complete", false);
    n.outputCount = 1;
    initPin(&n.outputs[0], EX, "Then", 0.0, "", false);
  } else {
    n.w = 216.0;
    vnCopyStr(&n.strValue[0], "Right-click canvas or press Tab to add nodes.", 64);
  }

  n.h = computeNodeHeight(n);
  e.nodeCount = e.nodeCount + 1;
  refreshStatusLabels(e);
  return idx;
}

void removeWireAt(GraphEditor* e, int wireIdx) {
  if (wireIdx < 0 || wireIdx >= e.wireCount) { return; }
  for (int i = wireIdx + 1; i < e.wireCount; i = i + 1) {
    e.wires[i - 1] = e.wires[i];
  }
  e.wireCount = e.wireCount - 1;
  if (e.selectedWire == wireIdx) { e.selectedWire = -1; }
  else if (e.selectedWire > wireIdx) { e.selectedWire = e.selectedWire - 1; }
  if (e.hoverWire == wireIdx) { e.hoverWire = -1; }
  refreshStatusLabels(e);
}

void disconnectInputPort(GraphEditor* e, int nodeIdx, int portIdx) {
  int i = e.wireCount - 1;
  while (i >= 0) {
    if (e.wires[i].toNode == nodeIdx && e.wires[i].toPort == portIdx) {
      removeWireAt(e, i);
    }
    i = i - 1;
  }
}

void disconnectPortAll(GraphEditor* e, int nodeIdx, int portIdx, bool isOutput) {
  int i = e.wireCount - 1;
  while (i >= 0) {
    bool match = if (isOutput)
      (e.wires[i].fromNode == nodeIdx && e.wires[i].fromPort == portIdx)
    else
      (e.wires[i].toNode == nodeIdx && e.wires[i].toPort == portIdx);
    if (match) {
      removeWireAt(e, i);
    }
    i = i - 1;
  }
}

void disconnectNodeWires(GraphEditor* e, int nodeIdx) {
  int i = e.wireCount - 1;
  while (i >= 0) {
    if (e.wires[i].fromNode == nodeIdx || e.wires[i].toNode == nodeIdx) {
      removeWireAt(e, i);
    }
    i = i - 1;
  }
}

bool connectPorts(GraphEditor* e, int fromNode, int fromPort, int toNode, int toPort) {
  if (fromNode < 0 || fromNode >= e.nodeCount || toNode < 0 || toNode >= e.nodeCount) { return false; }
  if (fromNode == toNode) { return false; }
  if (fromPort < 0 || fromPort >= e.nodes[fromNode].outputCount) { return false; }
  if (toPort < 0 || toPort >= e.nodes[toNode].inputCount) { return false; }

  int outType = e.nodes[fromNode].outputs[fromPort].pinType;
  int inType = e.nodes[toNode].inputs[toPort].pinType;
  if (!pinsCompatible(outType, inType)) {
    pushConsole(e, 2, "Incompatible port types cannot connect.");
    return false;
  }

  for (int i = 0; i < e.wireCount; i = i + 1) {
    if (e.wires[i].fromNode == fromNode && e.wires[i].fromPort == fromPort &&
        e.wires[i].toNode == toNode && e.wires[i].toPort == toPort) {
      return false;
    }
  }

  // Data input pins accept 1 upstream source; Exec output pins drive 1 target.
  if (inType != (PinType::PinExec as int)) {
    disconnectInputPort(e, toNode, toPort);
  }
  if (outType == (PinType::PinExec as int)) {
    disconnectPortAll(e, fromNode, fromPort, true);
  }

  if (e.wireCount >= 128) {
    pushConsole(e, 2, "Wire limit (128) reached.");
    return false;
  }

  e.wires[e.wireCount] = Wire{
    fromNode: fromNode,
    fromPort: fromPort,
    toNode: toNode,
    toPort: toPort,
    pinType: outType,
    active: false
  };
  e.wireCount = e.wireCount + 1;
  refreshStatusLabels(e);
  return true;
}

void deleteNodeAt(GraphEditor* e, int nodeIdx) {
  if (nodeIdx < 0 || nodeIdx >= e.nodeCount) { return; }
  disconnectNodeWires(e, nodeIdx);

  for (int i = nodeIdx + 1; i < e.nodeCount; i = i + 1) {
    e.nodes[i - 1] = e.nodes[i];
  }
  e.nodeCount = e.nodeCount - 1;

  for (int w = 0; w < e.wireCount; w = w + 1) {
    if (e.wires[w].fromNode > nodeIdx) { e.wires[w].fromNode = e.wires[w].fromNode - 1; }
    if (e.wires[w].toNode > nodeIdx) { e.wires[w].toNode = e.wires[w].toNode - 1; }
  }

  if (e.selectedNode == nodeIdx) { e.selectedNode = -1; }
  else if (e.selectedNode > nodeIdx) { e.selectedNode = e.selectedNode - 1; }
  e.hoverNode = -1;
  refreshStatusLabels(e);
}

int bringNodeToFront(GraphEditor* e, int nodeIdx) {
  if (nodeIdx < 0 || nodeIdx >= e.nodeCount - 1) { return nodeIdx; }
  ScriptNode moved = e.nodes[nodeIdx];
  int last = e.nodeCount - 1;
  for (int i = nodeIdx; i < last; i = i + 1) {
    e.nodes[i] = e.nodes[i + 1];
  }
  e.nodes[last] = moved;

  for (int w = 0; w < e.wireCount; w = w + 1) {
    if (e.wires[w].fromNode == nodeIdx) { e.wires[w].fromNode = last; }
    else if (e.wires[w].fromNode > nodeIdx) { e.wires[w].fromNode = e.wires[w].fromNode - 1; }

    if (e.wires[w].toNode == nodeIdx) { e.wires[w].toNode = last; }
    else if (e.wires[w].toNode > nodeIdx) { e.wires[w].toNode = e.wires[w].toNode - 1; }
  }
  if (e.selectedNode == nodeIdx) { e.selectedNode = last; }
  return last;
}

int duplicateNodeAt(GraphEditor* e, int nodeIdx) {
  if (nodeIdx < 0 || nodeIdx >= e.nodeCount || e.nodeCount >= 64) { return -1; }
  ScriptNode src = e.nodes[nodeIdx];
  int dst = e.nodeCount;
  e.nodes[dst] = src;
  e.nodes[dst].id = e.nextNodeId;
  e.nextNodeId = e.nextNodeId + 1;
  e.nodes[dst].x = src.x + 32.0;
  e.nodes[dst].y = src.y + 32.0;
  e.nodes[dst].executed = false;
  e.nodeCount = e.nodeCount + 1;
  e.selectedNode = dst;
  e.selectedWire = -1;
  refreshStatusLabels(e);
  return dst;
}

void clearExecutionMarks(GraphEditor* e) {
  for (int i = 0; i < e.nodeCount; i = i + 1) {
    e.nodes[i].executed = false;
  }
  for (int w = 0; w < e.wireCount; w = w + 1) {
    e.wires[w].active = false;
  }
  e.hasRun = false;
  e.lastStepCount = 0;
  refreshStatusLabels(e);
}

void resetRuntimeVars(GraphEditor* e) {
  for (int i = 0; i < e.varCount; i = i + 1) {
    e.vars[i].runtimeNum = e.vars[i].numVal;
    vnCopyStr(&e.vars[i].runtimeStr[0], &e.vars[i].strVal[0], 64);
    e.vars[i].runtimeBool = e.vars[i].boolVal;
  }
}

void fitGraphInView(GraphEditor* e) {
  if (e.nodeCount == 0) {
    e.zoom = 1.0;
    e.panX = 40.0;
    e.panY = 40.0;
    refreshStatusLabels(e);
    return;
  }
  float minX = e.nodes[0].x;
  float minY = e.nodes[0].y;
  float maxX = e.nodes[0].x + e.nodes[0].w;
  float maxY = e.nodes[0].y + computeNodeHeight(&e.nodes[0]);
  for (int i = 1; i < e.nodeCount; i = i + 1) {
    float h = computeNodeHeight(&e.nodes[i]);
    if (e.nodes[i].x < minX) { minX = e.nodes[i].x; }
    if (e.nodes[i].y < minY) { minY = e.nodes[i].y; }
    if (e.nodes[i].x + e.nodes[i].w > maxX) { maxX = e.nodes[i].x + e.nodes[i].w; }
    if (e.nodes[i].y + h > maxY) { maxY = e.nodes[i].y + h; }
  }
  float bw = gui::maxf(120.0, maxX - minX);
  float bh = gui::maxf(120.0, maxY - minY);
  float availW = gui::maxf(260.0, e.canvasRect.w - 80.0);
  float availH = gui::maxf(220.0, e.canvasRect.h - 100.0);
  float z = gui::minf(availW / bw, availH / bh);
  e.zoom = gui::clampf(z, 0.55, 1.25);
  e.panX = (e.canvasRect.w - bw * e.zoom) * 0.5 - minX * e.zoom;
  e.panY = (e.canvasRect.h - bh * e.zoom) * 0.5 - minY * e.zoom;
  refreshStatusLabels(e);
}

void stepZoomGraph(GraphEditor* e, int dir) {
  float oldZoom = e.zoom;
  if (dir == 0) {
    fitGraphInView(e);
    return;
  }
  float next = if (dir > 0) e.zoom + 0.12 else e.zoom - 0.12;
  e.zoom = gui::clampf(next, 0.45, 2.0);
  float cx = e.canvasRect.w * 0.5;
  float cy = e.canvasRect.h * 0.5;
  float worldCx = (cx - e.panX) / oldZoom;
  float worldCy = (cy - e.panY) / oldZoom;
  e.panX = cx - worldCx * e.zoom;
  e.panY = cy - worldCy * e.zoom;
  refreshStatusLabels(e);
}

void autoArrangeGraph(GraphEditor* e) {
  if (e.nodeCount == 0) { return; }
  int[64] col;
  for (int i = 0; i < e.nodeCount; i = i + 1) {
    col[i] = 0;
  }
  for (int pass = 0; pass < e.nodeCount; pass = pass + 1) {
    for (int w = 0; w < e.wireCount; w = w + 1) {
      int u = e.wires[w].fromNode;
      int v = e.wires[w].toNode;
      if (col[v] <= col[u]) {
        col[v] = col[u] + 1;
      }
    }
  }
  int[16] rowPerCol;
  for (int c = 0; c < 16; c = c + 1) { rowPerCol[c] = 0; }
  for (int i = 0; i < e.nodeCount; i = i + 1) {
    int c = col[i];
    if (c > 12) { c = 12; }
    int r = rowPerCol[c];
    rowPerCol[c] = r + 1;
    e.nodes[i].x = 48.0 + (c as float) * 240.0;
    e.nodes[i].y = 48.0 + (r as float) * 164.0;
  }
  fitGraphInView(e);
  pushConsole(e, 0, "Auto-arranged nodes by topological flow depth.");
}

// ---------------------------------------------------------------------------
// Starter Visual Scripting Language Presets
// ---------------------------------------------------------------------------

void loadPresetThreshold(GraphEditor* e) {
  vnCopyStr(&e.scriptName[0], "Threshold Flow.vnob", 48);
  e.activePreset = 0;
  e.nodeCount = 0;
  e.wireCount = 0;
  e.varCount = 0;
  e.selectedNode = 1;
  e.selectedWire = -1;
  clearExecutionMarks(e);

  addScriptVar(e, "score", PinType::PinNumber as int, 18.0, "", false);
  addScriptVar(e, "bonus", PinType::PinNumber as int, 7.0, "", false);

  int nStart = createScriptNode(e, VnNodeKind::VnOnStart as int, 32.0, 96.0);
  int nScore = createScriptNode(e, VnNodeKind::VnGetVar as int, 32.0, 224.0);
  vnCopyStr(&e.nodes[nScore].strValue[0], "score", 64);

  int nBonus = createScriptNode(e, VnNodeKind::VnGetVar as int, 32.0, 352.0);
  vnCopyStr(&e.nodes[nBonus].strValue[0], "bonus", 64);

  int nAdd = createScriptNode(e, VnNodeKind::VnMathAdd as int, 256.0, 256.0);
  vnCopyStr(&e.nodes[nAdd].title[0], "Total Score", 48);

  int nSetTotal = createScriptNode(e, VnNodeKind::VnSetVar as int, 256.0, 96.0);
  vnCopyStr(&e.nodes[nSetTotal].strValue[0], "total", 64);

  int nLimit = createScriptNode(e, VnNodeKind::VnConstNumber as int, 256.0, 416.0);
  e.nodes[nLimit].numValue = 20.0;

  int nCmp = createScriptNode(e, VnNodeKind::VnCompare as int, 480.0, 304.0);
  e.nodes[nCmp].opMode = 1; // >=

  int nBranch = createScriptNode(e, VnNodeKind::VnBranch as int, 480.0, 96.0);
  int nFmt = createScriptNode(e, VnNodeKind::VnFormat as int, 480.0, 448.0);
  vnCopyStr(&e.nodes[nFmt].strValue[0], "Passed score: ", 64);

  int nPrintPass = createScriptNode(e, VnNodeKind::VnPrintLog as int, 720.0, 80.0);
  int nToast = createScriptNode(e, VnNodeKind::VnEmitToast as int, 944.0, 80.0);
  int nPrintFail = createScriptNode(e, VnNodeKind::VnPrintLog as int, 720.0, 240.0);
  vnCopyStr(&e.nodes[nPrintFail].inputs[1].defStr[0], "Score below threshold", 48);

  int nNote = createScriptNode(e, VnNodeKind::VnComment as int, 32.0, 480.0);
  vnCopyStr(&e.nodes[nNote].strValue[0], "Drag ports to rewire, right-click for menu, or click Run!", 64);

  connectPorts(e, nStart, 0, nSetTotal, 0);
  connectPorts(e, nScore, 0, nAdd, 0);
  connectPorts(e, nBonus, 0, nAdd, 1);
  connectPorts(e, nAdd, 0, nSetTotal, 1);
  connectPorts(e, nSetTotal, 0, nBranch, 0);
  connectPorts(e, nSetTotal, 1, nCmp, 0);
  connectPorts(e, nLimit, 0, nCmp, 1);
  connectPorts(e, nCmp, 0, nBranch, 1);
  connectPorts(e, nSetTotal, 1, nFmt, 1);
  connectPorts(e, nBranch, 0, nPrintPass, 0);
  connectPorts(e, nFmt, 0, nPrintPass, 1);
  connectPorts(e, nPrintPass, 0, nToast, 0);
  connectPorts(e, nFmt, 0, nToast, 1);
  connectPorts(e, nBranch, 1, nPrintFail, 0);

  e.zoom = 0.92;
  e.panX = 24.0;
  e.panY = 24.0;
  refreshStatusLabels(e);
}

void loadPresetLoop(GraphEditor* e) {
  vnCopyStr(&e.scriptName[0], "Loop Multiplier.vnob", 48);
  e.activePreset = 1;
  e.nodeCount = 0;
  e.wireCount = 0;
  e.varCount = 0;
  e.selectedNode = 2;
  e.selectedWire = -1;
  clearExecutionMarks(e);

  addScriptVar(e, "acc", PinType::PinNumber as int, 1.0, "", false);

  int nStart = createScriptNode(e, VnNodeKind::VnOnStart as int, 32.0, 96.0);
  int nRep = createScriptNode(e, VnNodeKind::VnRepeat as int, 240.0, 96.0);
  e.nodes[nRep].inputs[1].defNum = 5.0;
  e.nodes[nRep].numValue = 5.0;

  int nGet = createScriptNode(e, VnNodeKind::VnGetVar as int, 240.0, 304.0);
  vnCopyStr(&e.nodes[nGet].strValue[0], "acc", 64);

  int nFactor = createScriptNode(e, VnNodeKind::VnConstNumber as int, 240.0, 432.0);
  e.nodes[nFactor].numValue = 2.0;

  int nMul = createScriptNode(e, VnNodeKind::VnMathMul as int, 464.0, 336.0);
  int nSet = createScriptNode(e, VnNodeKind::VnSetVar as int, 496.0, 96.0);
  vnCopyStr(&e.nodes[nSet].strValue[0], "acc", 64);

  int nFmt = createScriptNode(e, VnNodeKind::VnFormat as int, 736.0, 336.0);
  vnCopyStr(&e.nodes[nFmt].strValue[0], "Power of 2 = ", 64);

  int nLogBody = createScriptNode(e, VnNodeKind::VnPrintLog as int, 736.0, 96.0);
  int nLogDone = createScriptNode(e, VnNodeKind::VnEmitToast as int, 496.0, 224.0);
  vnCopyStr(&e.nodes[nLogDone].inputs[1].defStr[0], "Loop finished!", 48);

  connectPorts(e, nStart, 0, nRep, 0);
  connectPorts(e, nRep, 0, nSet, 0);
  connectPorts(e, nGet, 0, nMul, 0);
  connectPorts(e, nFactor, 0, nMul, 1);
  connectPorts(e, nMul, 0, nSet, 1);
  connectPorts(e, nSet, 0, nLogBody, 0);
  connectPorts(e, nSet, 1, nFmt, 1);
  connectPorts(e, nFmt, 0, nLogBody, 1);
  connectPorts(e, nRep, 2, nLogDone, 0);

  e.zoom = 0.94;
  e.panX = 24.0;
  e.panY = 24.0;
  refreshStatusLabels(e);
}

void loadPresetGreeter(GraphEditor* e) {
  vnCopyStr(&e.scriptName[0], "Sequence Pipeline.vnob", 48);
  e.activePreset = 2;
  e.nodeCount = 0;
  e.wireCount = 0;
  e.varCount = 0;
  e.selectedNode = 1;
  e.selectedWire = -1;
  clearExecutionMarks(e);

  addScriptVar(e, "ticks", PinType::PinNumber as int, 0.0, "", false);

  int nStart = createScriptNode(e, VnNodeKind::VnOnStart as int, 32.0, 80.0);
  int nSeq = createScriptNode(e, VnNodeKind::VnSequence as int, 240.0, 80.0);
  int nStr = createScriptNode(e, VnNodeKind::VnConstString as int, 240.0, 240.0);
  vnCopyStr(&e.nodes[nStr].strValue[0], "Glang Engine Ready", 64);

  int nPrint1 = createScriptNode(e, VnNodeKind::VnPrintLog as int, 480.0, 64.0);
  int nToast = createScriptNode(e, VnNodeKind::VnEmitToast as int, 480.0, 224.0);
  vnCopyStr(&e.nodes[nToast].inputs[1].defStr[0], "Try clicking Step Tick!", 48);

  int nTick = createScriptNode(e, VnNodeKind::VnOnTick as int, 32.0, 368.0);
  int nGetTick = createScriptNode(e, VnNodeKind::VnGetVar as int, 32.0, 512.0);
  vnCopyStr(&e.nodes[nGetTick].strValue[0], "ticks", 64);
  int nAdd = createScriptNode(e, VnNodeKind::VnMathAdd as int, 256.0, 448.0);
  int nSetTick = createScriptNode(e, VnNodeKind::VnSetVar as int, 480.0, 368.0);
  vnCopyStr(&e.nodes[nSetTick].strValue[0], "ticks", 64);
  int nFmt = createScriptNode(e, VnNodeKind::VnFormat as int, 480.0, 528.0);
  vnCopyStr(&e.nodes[nFmt].strValue[0], "Tick count: ", 64);
  int nPrintTick = createScriptNode(e, VnNodeKind::VnPrintLog as int, 736.0, 368.0);

  connectPorts(e, nStart, 0, nSeq, 0);
  connectPorts(e, nSeq, 0, nPrint1, 0);
  connectPorts(e, nStr, 0, nPrint1, 1);
  connectPorts(e, nSeq, 1, nToast, 0);
  connectPorts(e, nTick, 0, nSetTick, 0);
  connectPorts(e, nGetTick, 0, nAdd, 0);
  connectPorts(e, nTick, 1, nAdd, 1);
  connectPorts(e, nAdd, 0, nSetTick, 1);
  connectPorts(e, nSetTick, 0, nPrintTick, 0);
  connectPorts(e, nSetTick, 1, nFmt, 1);
  connectPorts(e, nFmt, 0, nPrintTick, 1);

  e.zoom = 0.90;
  e.panX = 24.0;
  e.panY = 18.0;
  refreshStatusLabels(e);
}
