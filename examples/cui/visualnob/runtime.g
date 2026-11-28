// VisualNob Script Interpreter: Live Pull-Evaluation of Data Pins & Exec Flow Stepping.
// Supports recursive expression evaluation, Branch, Repeat, Sequence, SetVar, Print, and Toast.

import std.gui;
import examples.cui.visualnob.palette;
import examples.cui.visualnob.model;
import examples.cui.visualnob.graph;

struct EvalVal {
  int valType; // 1=Number, 2=String, 3=Bool
  float numVal;
  bool boolVal;
  char[64] strVal;
}

int vnActiveLoopIdx = 0;

EvalVal makeNumVal(float v) {
  EvalVal r = EvalVal{valType: PinType::PinNumber as int, numVal: v, boolVal: v != 0.0};
  vnFormatNum(&r.strVal[0], v, 64);
  return r;
}

EvalVal makeBoolVal(bool b) {
  float n = if (b) 1.0 else 0.0;
  EvalVal r = EvalVal{
    valType: PinType::PinBool as int,
    numVal: n,
    boolVal: b
  };
  vnCopyStr(&r.strVal[0], if (b) "true" else "false", 64);
  return r;
}

EvalVal makeStrVal(const char* s) {
  EvalVal r = EvalVal{valType: PinType::PinString as int, numVal: 0.0, boolVal: s != nullptr && s[0] != '\0'};
  vnCopyStr(&r.strVal[0], s, 64);
  return r;
}

int findUpstreamWire(GraphEditor* e, int toNode, int toPort) {
  for (int i = 0; i < e.wireCount; i = i + 1) {
    if (e.wires[i].toNode == toNode && e.wires[i].toPort == toPort) {
      return i;
    }
  }
  return -1;
}

int findExecWire(GraphEditor* e, int fromNode, int fromPort) {
  for (int i = 0; i < e.wireCount; i = i + 1) {
    if (e.wires[i].fromNode == fromNode && e.wires[i].fromPort == fromPort) {
      return i;
    }
  }
  return -1;
}

EvalVal evalPortValue(GraphEditor* e, int nodeIdx, int portIdx, bool isInput, int depth) {
  if (depth > 24 || nodeIdx < 0 || nodeIdx >= e.nodeCount) {
    return makeNumVal(0.0);
  }
  ScriptNode* n = &e.nodes[nodeIdx];

  if (isInput) {
    if (portIdx < 0 || portIdx >= n.inputCount) { return makeNumVal(0.0); }
    int wIdx = findUpstreamWire(e, nodeIdx, portIdx);
    if (wIdx >= 0) {
      e.wires[wIdx].active = true;
      return evalPortValue(e, e.wires[wIdx].fromNode, e.wires[wIdx].fromPort, false, depth + 1);
    }
    ScriptPin* pin = &n.inputs[portIdx];
    if (pin.pinType == (PinType::PinBool as int)) {
      return makeBoolVal(pin.defBool);
    }
    if (pin.pinType == (PinType::PinString as int) || pin.pinType == (PinType::PinAny as int)) {
      if (pin.defStr[0] != '\0') {
        return makeStrVal(&pin.defStr[0]);
      }
    }
    return makeNumVal(pin.defNum);
  }

  n.executed = true;

  int k = n.kind;
  if (k == (VnNodeKind::VnOnTick as int)) {
    return makeNumVal(1.0);
  }
  if (k == (VnNodeKind::VnConstNumber as int)) {
    return makeNumVal(n.numValue);
  }
  if (k == (VnNodeKind::VnConstString as int)) {
    return makeStrVal(&n.strValue[0]);
  }
  if (k == (VnNodeKind::VnConstBool as int)) {
    return makeBoolVal(n.boolValue);
  }
  if (k == (VnNodeKind::VnGetVar as int) || k == (VnNodeKind::VnSetVar as int)) {
    int vi = findScriptVar(e, &n.strValue[0]);
    if (vi >= 0) {
      if (e.vars[vi].pinType == (PinType::PinString as int)) {
        return makeStrVal(&e.vars[vi].runtimeStr[0]);
      }
      if (e.vars[vi].pinType == (PinType::PinBool as int)) {
        return makeBoolVal(e.vars[vi].runtimeBool);
      }
      return makeNumVal(e.vars[vi].runtimeNum);
    }
    return makeNumVal(n.numValue);
  }
  if (k == (VnNodeKind::VnMathAdd as int)) {
    EvalVal a = evalPortValue(e, nodeIdx, 0, true, depth);
    EvalVal b = evalPortValue(e, nodeIdx, 1, true, depth);
    if (n.opMode == 1) { return makeNumVal(a.numVal - b.numVal); }
    return makeNumVal(a.numVal + b.numVal);
  }
  if (k == (VnNodeKind::VnMathMul as int)) {
    EvalVal a = evalPortValue(e, nodeIdx, 0, true, depth);
    EvalVal b = evalPortValue(e, nodeIdx, 1, true, depth);
    if (n.opMode == 1) {
      if (b.numVal > -0.0001 && b.numVal < 0.0001) { return makeNumVal(0.0); }
      return makeNumVal(a.numVal / b.numVal);
    }
    if (n.opMode == 2) {
      int ia = a.numVal as int;
      int ib = b.numVal as int;
      if (ib == 0) { return makeNumVal(0.0); }
      return makeNumVal((ia % ib) as float);
    }
    return makeNumVal(a.numVal * b.numVal);
  }
  if (k == (VnNodeKind::VnCompare as int)) {
    EvalVal a = evalPortValue(e, nodeIdx, 0, true, depth);
    EvalVal b = evalPortValue(e, nodeIdx, 1, true, depth);
    bool res = false;
    if (n.opMode == 0) { res = a.numVal > b.numVal; }
    else if (n.opMode == 1) { res = a.numVal >= b.numVal; }
    else if (n.opMode == 2) { res = a.numVal < b.numVal; }
    else if (n.opMode == 3) { res = a.numVal <= b.numVal; }
    else if (n.opMode == 4) { res = gui::absf(a.numVal - b.numVal) < 0.001; }
    else { res = gui::absf(a.numVal - b.numVal) >= 0.001; }
    return makeBoolVal(res);
  }
  if (k == (VnNodeKind::VnLogicNot as int)) {
    EvalVal v = evalPortValue(e, nodeIdx, 0, true, depth);
    return makeBoolVal(!v.boolVal);
  }
  if (k == (VnNodeKind::VnRepeat as int)) {
    return makeNumVal(vnActiveLoopIdx as float);
  }
  if (k == (VnNodeKind::VnFormat as int)) {
    EvalVal pre = evalPortValue(e, nodeIdx, 0, true, depth);
    EvalVal dat = evalPortValue(e, nodeIdx, 1, true, depth);
    char[64] outBuf;
    if (findUpstreamWire(e, nodeIdx, 0) >= 0) {
      vnCopyStr(&outBuf[0], &pre.strVal[0], 64);
    } else {
      vnCopyStr(&outBuf[0], &n.strValue[0], 64);
    }
    vnAppendStr(&outBuf[0], &dat.strVal[0], 64);
    return makeStrVal(&outBuf[0]);
  }
  return makeNumVal(n.numValue);
}

EvalVal evalInputPin(GraphEditor* e, int nodeIdx, int portIdx, int depth) {
  return evalPortValue(e, nodeIdx, portIdx, true, depth);
}

void execChain(GraphEditor* e, int startNode, int depth) {
  if (startNode < 0 || startNode >= e.nodeCount || depth > 48) { return; }
  int cur = startNode;
  int safety = 0;

  while (cur >= 0 && cur < e.nodeCount && safety < 120) {
    safety = safety + 1;
    e.lastStepCount = e.lastStepCount + 1;
    ScriptNode* n = &e.nodes[cur];
    n.executed = true;
    int k = n.kind;
    int nextWire = -1;

    if (k == (VnNodeKind::VnOnStart as int) || k == (VnNodeKind::VnOnTick as int)) {
      nextWire = findExecWire(e, cur, 0);
    } else if (k == (VnNodeKind::VnSetVar as int)) {
      EvalVal v = evalInputPin(e, cur, 1, 0);
      int vi = findScriptVar(e, &n.strValue[0]);
      if (vi < 0) {
        vi = addScriptVar(e, &n.strValue[0], PinType::PinNumber as int, v.numVal, &v.strVal[0], v.boolVal);
      }
      if (vi >= 0) {
        e.vars[vi].runtimeNum = v.numVal;
        e.vars[vi].runtimeBool = v.boolVal;
        vnCopyStr(&e.vars[vi].runtimeStr[0], &v.strVal[0], 64);
      }
      nextWire = findExecWire(e, cur, 0);
    } else if (k == (VnNodeKind::VnBranch as int)) {
      EvalVal cond = evalInputPin(e, cur, 1, 0);
      int branchPort = if (cond.boolVal) 0 else 1;
      nextWire = findExecWire(e, cur, branchPort);
    } else if (k == (VnNodeKind::VnRepeat as int)) {
      EvalVal cntVal = evalInputPin(e, cur, 1, 0);
      int count = cntVal.numVal as int;
      if (count < 0) { count = 0; }
      if (count > 24) { count = 24; }
      int bodyWire = findExecWire(e, cur, 0);
      for (int it = 0; it < count; it = it + 1) {
        vnActiveLoopIdx = it;
        if (bodyWire >= 0) {
          e.wires[bodyWire].active = true;
          execChain(e, e.wires[bodyWire].toNode, depth + 1);
        }
      }
      nextWire = findExecWire(e, cur, 2);
    } else if (k == (VnNodeKind::VnSequence as int)) {
      int w0 = findExecWire(e, cur, 0);
      if (w0 >= 0) {
        e.wires[w0].active = true;
        execChain(e, e.wires[w0].toNode, depth + 1);
      }
      nextWire = findExecWire(e, cur, 1);
    } else if (k == (VnNodeKind::VnPrintLog as int)) {
      EvalVal msg = evalInputPin(e, cur, 1, 0);
      if (findUpstreamWire(e, cur, 1) < 0 && n.inputs[1].defStr[0] == '\0' && n.strValue[0] != '\0') {
        msg = makeStrVal(&n.strValue[0]);
      }
      char[120] line;
      vnCopyStr(&line[0], "> ", 120);
      vnAppendStr(&line[0], &msg.strVal[0], 120);
      pushConsole(e, 1, &line[0]);
      nextWire = findExecWire(e, cur, 0);
    } else if (k == (VnNodeKind::VnEmitToast as int)) {
      EvalVal msg = evalInputPin(e, cur, 1, 0);
      char[120] line;
      vnCopyStr(&line[0], "[Toast] ", 120);
      vnAppendStr(&line[0], &msg.strVal[0], 120);
      pushConsole(e, 3, &line[0]);
      gui::toast("VisualNob Script", &msg.strVal[0]);
      nextWire = findExecWire(e, cur, 0);
    } else {
      cur = -1;
    }

    if (nextWire >= 0) {
      e.wires[nextWire].active = true;
      cur = e.wires[nextWire].toNode;
    } else {
      cur = -1;
    }
  }
}

void runFullScript(GraphEditor* e) {
  clearExecutionMarks(e);
  resetRuntimeVars(e);
  pushConsole(e, 0, "Running OnStart entry points...");

  int entries = 0;
  for (int i = 0; i < e.nodeCount; i = i + 1) {
    if (e.nodes[i].kind == (VnNodeKind::VnOnStart as int)) {
      entries = entries + 1;
      execChain(e, i, 0);
    }
  }
  if (entries == 0) {
    pushConsole(e, 2, "No On Start event node found in graph.");
  }
  e.hasRun = true;
  refreshStatusLabels(e);
}

void triggerTick(GraphEditor* e) {
  int entries = 0;
  for (int i = 0; i < e.nodeCount; i = i + 1) {
    if (e.nodes[i].kind == (VnNodeKind::VnOnTick as int)) {
      entries = entries + 1;
      execChain(e, i, 0);
    }
  }
  if (entries == 0) {
    pushConsole(e, 2, "No On Tick event node in current graph.");
  } else {
    e.hasRun = true;
  }
  refreshStatusLabels(e);
}

void runFromNode(GraphEditor* e, int nodeIdx) {
  if (nodeIdx < 0 || nodeIdx >= e.nodeCount) { return; }
  clearExecutionMarks(e);
  resetRuntimeVars(e);
  pushConsole(e, 0, "Executing from selected node...");
  execChain(e, nodeIdx, 0);
  e.hasRun = true;
  refreshStatusLabels(e);
}
