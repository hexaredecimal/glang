// VisualNob Right Inspector & Script Output Console Panel.
// Shows node properties, operator modes, port connections, graph variables,
// and live execution log output.

import std.gui;
import std.pipe;
import std.cui;
import examples.cui.visualnob.palette;
import examples.cui.visualnob.model;
import examples.cui.visualnob.geometry;
import examples.cui.visualnob.graph;
import examples.cui.visualnob.runtime;

Widget* opModeChip(int modeVal, const char* label, bool dark) {
  bool sel = vn.selectedNode >= 0 && vn.selectedNode < vn.nodeCount &&
             vn.nodes[vn.selectedNode].opMode == modeVal;
  auto btn = Box::new()
    |> set_size(fit(), 24px)
    |> set_padding_xy(8.0, 0.0)
    |> set_radius(5.0)
    |> set_bg(vnPickColor(sel, vnMintSoft(dark), vnField(dark)))
    |> set_border(1.0, vnPickColor(sel, vnMintDark(), vnDivider(dark)))
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> on_click_tag(modeVal) {
      -> if (vn.selectedNode >= 0 && vn.selectedNode < vn.nodeCount) {
           vn.nodes[vn.selectedNode].opMode = gui::clickTag();
         }
         return;
    };
  btn.add(Text::new()
    |> set_text(label)
    |> set_text_size(10.0)
    |> set_font(gui::mono())
    |> set_text_color(vnPickColor(sel, vnMint(), vnText(dark))));
  return btn;
}

Widget* actionChipBtn(const char* icon, const char* label, int tag, bool danger, bool dark) {
  Color bg = if (danger) vnCoralSoft(dark) else vnField(dark);
  Color br = if (danger) vnCoral() else vnDivider(dark);
  Color fg = if (danger) vnCoral() else vnText(dark);
  auto btn = Row::new()
    |> set_size(fit(), 26px)
    |> set_padding_xy(9.0, 0.0)
    |> set_gap(5.0)
    |> set_radius(5.0)
    |> set_bg(bg)
    |> set_hover_bg(if (danger) vnCoralSoft(dark) else vnHover(dark))
    |> set_border(1.0, br)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> on_click_tag(tag) {
      -> int t = gui::clickTag();
         if (t == 1 && vn.selectedNode >= 0) { duplicateNodeAt(&vn, vn.selectedNode); }
         else if (t == 2 && vn.selectedNode >= 0) { disconnectNodeWires(&vn, vn.selectedNode); }
         else if (t == 3 && vn.selectedNode >= 0) { deleteNodeAt(&vn, vn.selectedNode); }
         else if (t == 4 && vn.selectedWire >= 0) { removeWireAt(&vn, vn.selectedWire); }
         else if (t == 5 && vn.selectedNode >= 0) { runFromNode(&vn, vn.selectedNode); }
         return;
    };
  btn.add(Icon::new() |> set_icon(icon) |> set_text_size(11.5) |> set_text_color(fg));
  btn.add(Text::new() |> set_text(label) |> set_text_size(10.0) |> set_font(gui::medium()) |> set_text_color(fg));
  return btn;
}

Widget* buildNodeInspector(bool dark) {
  ScriptNode* n = &vn.nodes[vn.selectedNode];
  int k = n.kind;
  Color catCol = categoryHeaderColor(n.category, dark);

  auto col = Column::new() |> set_size(fill(), fit()) |> set_gap(9.0);

  // Header badge + category
  auto head = Row::new() |> set_size(fill(), 24px) |> set_gap(6.0) |> set_align(GuiAlign::GuiAlignCenter);
  head.add(Box::new() |> set_size(8px, 8px) |> set_radius(4.0) |> set_bg(catCol));
  head.add(Text::new() |> set_text(nodeKindDefaultTitle(k)) |> set_text_size(11.5) |> set_font(gui::medium()) |> set_text_color(vnText(dark)));
  head.add(Spacer::new() |> set_size(fill(), 1px));
  head.add(Text::new() |> set_text(categoryLabel(n.category)) |> set_text_size(9.5) |> set_text_color(vnMutedText(dark)));
  col.add(head);

  // Editable Title
  col.add(Input::new()
    |> set_id("vn-node-title")
    |> set_label("Node Title")
    |> set_placeholder("Node title")
    |> set_buffer(&n.title[0], 48)
    |> set_size(fill(), 28px));

  // Node-specific configuration
  if (k == (VnNodeKind::VnConstNumber as int)) {
    col.add(Scrub::new() |> set_text("Number") |> set_value(&n.numValue, -10000.0, 10000.0) |> set_step(0.5) |> set_width(fill()));
  } else if (k == (VnNodeKind::VnConstString as int) || k == (VnNodeKind::VnComment as int) ||
             k == (VnNodeKind::VnFormat as int) || k == (VnNodeKind::VnPrintLog as int) ||
             k == (VnNodeKind::VnEmitToast as int)) {
    col.add(Input::new()
      |> set_id("vn-node-str")
      |> set_label(if (k == (VnNodeKind::VnFormat as int)) "Prefix Text" else "Text Content")
      |> set_placeholder("Enter text...")
      |> set_buffer(&n.strValue[0], 64)
      |> set_size(fill(), 28px));
  } else if (k == (VnNodeKind::VnConstBool as int)) {
    col.add(Checkbox::new() |> set_text("Boolean Value (True / False)") |> set_checked(&n.boolValue));
  } else if (k == (VnNodeKind::VnGetVar as int) || k == (VnNodeKind::VnSetVar as int)) {
    col.add(Input::new()
      |> set_id("vn-node-var")
      |> set_label("Variable Name")
      |> set_placeholder("e.g. score")
      |> set_buffer(&n.strValue[0], 64)
      |> set_size(fill(), 28px));
  } else if (k == (VnNodeKind::VnRepeat as int)) {
    col.add(Scrub::new() |> set_text("Iterations") |> set_value(&n.inputs[1].defNum, 0.0, 24.0) |> set_step(1.0) |> set_width(fill()));
  } else if (k == (VnNodeKind::VnMathAdd as int)) {
    col.add(Text::new() |> set_text("Operator") |> set_text_size(10.0) |> set_text_color(vnSecondaryText(dark)));
    auto opRow = Row::new() |> set_size(fill(), fit()) |> set_gap(5.0);
    opRow.add(opModeChip(0, "A + B", dark));
    opRow.add(opModeChip(1, "A - B", dark));
    col.add(opRow);
  } else if (k == (VnNodeKind::VnMathMul as int)) {
    col.add(Text::new() |> set_text("Operator") |> set_text_size(10.0) |> set_text_color(vnSecondaryText(dark)));
    auto opRow = Row::new() |> set_size(fill(), fit()) |> set_gap(5.0);
    opRow.add(opModeChip(0, "A * B", dark));
    opRow.add(opModeChip(1, "A / B", dark));
    opRow.add(opModeChip(2, "A % B", dark));
    col.add(opRow);
  } else if (k == (VnNodeKind::VnCompare as int)) {
    col.add(Text::new() |> set_text("Comparison Mode") |> set_text_size(10.0) |> set_text_color(vnSecondaryText(dark)));
    auto row1 = Row::new() |> set_size(fill(), fit()) |> set_gap(4.0);
    row1.add(opModeChip(0, ">", dark));
    row1.add(opModeChip(1, ">=", dark));
    row1.add(opModeChip(2, "<", dark));
    row1.add(opModeChip(3, "<=", dark));
    row1.add(opModeChip(4, "==", dark));
    row1.add(opModeChip(5, "!=", dark));
    col.add(row1);
  }

  // Fallback pin defaults for unconnected data inputs
  bool anyEditableIn = false;
  for (int p = 0; p < n.inputCount; p = p + 1) {
    if (n.inputs[p].pinType == (PinType::PinNumber as int) && !inputPortHasWire(&vn, vn.selectedNode, p)) {
      if (!anyEditableIn) {
        col.add(Text::new() |> set_text("Unwired Input Defaults") |> set_text_size(10.0) |> set_text_color(vnSecondaryText(dark)));
        anyEditableIn = true;
      }
      col.add(Scrub::new() |> set_text(&n.inputs[p].label[0]) |> set_value(&n.inputs[p].defNum, -10000.0, 10000.0) |> set_step(0.5) |> set_width(fill()));
    }
  }

  col.add(Divider::new() |> set_size(fill(), 1px) |> set_bg(vnDivider(dark)));

  // Connected Ports List
  col.add(Text::new() |> set_text("Ports") |> set_text_size(10.0) |> set_font(gui::medium()) |> set_text_color(vnSecondaryText(dark)));
  for (int p = 0; p < n.inputCount; p = p + 1) {
    bool wired = inputPortHasWire(&vn, vn.selectedNode, p);
    Color pc = pinTypeColor(n.inputs[p].pinType, dark);
    auto prow = Row::new() |> set_size(fill(), 22px) |> set_gap(6.0) |> set_align(GuiAlign::GuiAlignCenter);
    prow.add(Box::new() |> set_size(8px, 8px) |> set_radius(4.0) |> set_bg(pc));
    prow.add(Text::new() |> set_text("In:") |> set_text_size(9.5) |> set_text_color(vnMutedText(dark)));
    prow.add(Text::new() |> set_text(&n.inputs[p].label[0]) |> set_text_size(10.0) |> set_text_color(vnText(dark)));
    prow.add(Spacer::new() |> set_size(fill(), 1px));
    if (wired) {
      auto cutBtn = Box::new()
        |> set_size(fit(), 18px)
        |> set_padding_xy(6.0, 0.0)
        |> set_bg(vnCoralSoft(dark))
        |> set_radius(4.0)
        |> set_align(GuiAlign::GuiAlignCenter)
        |> on_click_tag(p) {
          -> disconnectPortAll(&vn, vn.selectedNode, gui::clickTag(), false);
             return;
        };
      cutBtn.add(Text::new() |> set_text("Unplug") |> set_text_size(8.5) |> set_text_color(vnCoral()));
      prow.add(cutBtn);
    } else {
      prow.add(Text::new() |> set_text(pinTypeName(n.inputs[p].pinType)) |> set_text_size(9.0) |> set_text_color(vnMutedText(dark)));
    }
    col.add(prow);
  }

  for (int p = 0; p < n.outputCount; p = p + 1) {
    bool wired = outputPortHasWire(&vn, vn.selectedNode, p);
    Color pc = pinTypeColor(n.outputs[p].pinType, dark);
    auto prow = Row::new() |> set_size(fill(), 22px) |> set_gap(6.0) |> set_align(GuiAlign::GuiAlignCenter);
    prow.add(Box::new() |> set_size(8px, 8px) |> set_radius(4.0) |> set_bg(pc));
    prow.add(Text::new() |> set_text("Out:") |> set_text_size(9.5) |> set_text_color(vnMutedText(dark)));
    prow.add(Text::new() |> set_text(&n.outputs[p].label[0]) |> set_text_size(10.0) |> set_text_color(vnText(dark)));
    prow.add(Spacer::new() |> set_size(fill(), 1px));
    if (wired) {
      auto cutBtn = Box::new()
        |> set_size(fit(), 18px)
        |> set_padding_xy(6.0, 0.0)
        |> set_bg(vnCoralSoft(dark))
        |> set_radius(4.0)
        |> set_align(GuiAlign::GuiAlignCenter)
        |> on_click_tag(p) {
          -> disconnectPortAll(&vn, vn.selectedNode, gui::clickTag(), true);
             return;
        };
      cutBtn.add(Text::new() |> set_text("Unplug") |> set_text_size(8.5) |> set_text_color(vnCoral()));
      prow.add(cutBtn);
    } else {
      prow.add(Text::new() |> set_text(pinTypeName(n.outputs[p].pinType)) |> set_text_size(9.0) |> set_text_color(vnMutedText(dark)));
    }
    col.add(prow);
  }

  col.add(Divider::new() |> set_size(fill(), 1px) |> set_bg(vnDivider(dark)));

  // Node Action buttons
  auto act1 = Row::new() |> set_size(fill(), fit()) |> set_gap(6.0);
  act1.add(actionChipBtn(std::cui::icons::play(), "Run Here", 5, false, dark));
  act1.add(actionChipBtn(std::cui::icons::copy(), "Duplicate", 1, false, dark));
  col.add(act1);

  auto act2 = Row::new() |> set_size(fill(), fit()) |> set_gap(6.0);
  act2.add(actionChipBtn(std::cui::icons::link(), "Unlink", 2, false, dark));
  act2.add(actionChipBtn(std::cui::icons::trash(), "Delete", 3, true, dark));
  col.add(act2);

  return col;
}

Widget* buildGraphOverviewInspector(bool dark) {
  auto col = Column::new() |> set_size(fill(), fit()) |> set_gap(9.0);

  if (vn.selectedWire >= 0 && vn.selectedWire < vn.wireCount) {
    Wire* w = &vn.wires[vn.selectedWire];
    col.add(Text::new() |> set_text("Selected Connection") |> set_text_size(11.5) |> set_font(gui::medium()) |> set_text_color(vnText(dark)));
    col.add(Text::new() |> set_text(&vn.nodes[w.fromNode].title[0]) |> set_text_size(10.5) |> set_text_color(vnMint()));
    col.add(Text::new() |> set_text("-> connects to ->") |> set_text_size(9.5) |> set_text_color(vnMutedText(dark)));
    col.add(Text::new() |> set_text(&vn.nodes[w.toNode].title[0]) |> set_text_size(10.5) |> set_text_color(vnBlue()));
    col.add(actionChipBtn(std::cui::icons::trash(), "Delete Connection", 4, true, dark));
    col.add(Divider::new() |> set_size(fill(), 1px) |> set_bg(vnDivider(dark)));
  }

  col.add(Text::new() |> set_text("Script Graph") |> set_text_size(11.5) |> set_font(gui::medium()) |> set_text_color(vnText(dark)));
  col.add(Input::new()
    |> set_id("vn-script-name")
    |> set_label("Script Title")
    |> set_placeholder("Script name")
    |> set_buffer(&vn.scriptName[0], 48)
    |> set_size(fill(), 28px));

  col.add(Text::new() |> set_text(&vn.statusLabel[0]) |> set_text_size(10.0) |> set_font(gui::mono()) |> set_text_color(vnSecondaryText(dark)));
  col.add(Checkbox::new() |> set_text("Snap nodes to 16px grid") |> set_checked(&vn.snapToGrid));
  col.add(Checkbox::new() |> set_text("Show canvas minimap") |> set_checked(&vn.showMinimap));

  col.add(Divider::new() |> set_size(fill(), 1px) |> set_bg(vnDivider(dark)));
  col.add(Text::new() |> set_text("Script Variables (Initial)") |> set_text_size(10.5) |> set_font(gui::medium()) |> set_text_color(vnText(dark)));

  for (int i = 0; i < vn.varCount; i = i + 1) {
    if (i >= 6) { break; }
    col.add(Scrub::new()
      |> set_text(&vn.vars[i].name[0])
      |> set_value(&vn.vars[i].numVal, -10000.0, 10000.0)
      |> set_step(1.0)
      |> set_width(fill()));
  }

  auto addRow = Row::new() |> set_size(fill(), fit()) |> set_gap(6.0) |> set_align(GuiAlign::GuiAlignCenter);
  addRow.add(Input::new()
    |> set_id("vn-new-var")
    |> set_placeholder("var name")
    |> set_buffer(&vn.newVarName[0], 32)
    |> set_size(fill(), 26px));
  auto addBtn = Box::new()
    |> set_size(fit(), 26px)
    |> set_padding_xy(8.0, 0.0)
    |> set_bg(vnCyanSoft(dark))
    |> set_border(1.0, vnCyan())
    |> set_radius(5.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> on_click() {
      -> if (vn.newVarName[0] != '\0') {
           addScriptVar(&vn, &vn.newVarName[0], PinType::PinNumber as int, 0.0, "", false);
         }
         return;
    };
  addBtn.add(Text::new() |> set_text("Add") |> set_text_size(10.0) |> set_font(gui::medium()) |> set_text_color(vnCyan()));
  addRow.add(addBtn);
  col.add(addRow);

  return col;
}

Widget* buildConsolePanel(bool dark) {
  auto consoleBox = Column::new()
    |> set_id("vn-console-box")
    |> set_size(fill(), 210px)
    |> set_bg(vnCanvasBg(dark))
    |> set_gap(0.0);

  auto head = Row::new()
    |> set_size(fill(), 30px)
    |> set_padding_xy(10.0, 0.0)
    |> set_bg(vnPanel(dark))
    |> set_gap(6.0)
    |> set_align(GuiAlign::GuiAlignCenter);
  head.add(Icon::new() |> set_icon(std::cui::icons::terminal()) |> set_text_size(11.5) |> set_text_color(vnMint()));
  head.add(Text::new() |> set_text("Console Output") |> set_text_size(10.5) |> set_font(gui::medium()) |> set_text_color(vnText(dark)));
  head.add(Text::new() |> set_text(&vn.stepLabel[0]) |> set_text_size(9.5) |> set_font(gui::mono()) |> set_text_color(vnMutedText(dark)));
  head.add(Spacer::new() |> set_size(fill(), 1px));

  auto clearBtn = Box::new()
    |> set_size(fit(), 20px)
    |> set_padding_xy(6.0, 0.0)
    |> set_radius(4.0)
    |> set_hover_bg(vnHover(dark))
    |> set_align(GuiAlign::GuiAlignCenter)
    |> on_click() { -> clearConsole(&vn); return; };
  clearBtn.add(Text::new() |> set_text("Clear") |> set_text_size(9.5) |> set_text_color(vnSecondaryText(dark)));
  head.add(clearBtn);

  consoleBox.add(Divider::new() |> set_size(fill(), 1px) |> set_bg(vnBorder(dark)));
  consoleBox.add(head);
  consoleBox.add(Divider::new() |> set_size(fill(), 1px) |> set_bg(vnDivider(dark)));

  auto logScroll = Scroll::new()
    |> set_id("vn-console-scroll")
    |> set_size(fill(), fill())
    |> set_padding(8.0)
    |> set_gap(3.0);

  if (vn.consoleCount == 0) {
    logScroll.add(Text::new() |> set_text("Click Run to execute script.") |> set_text_size(9.5) |> set_font(gui::mono()) |> set_text_color(vnMutedText(dark)));
  } else {
    int start = if (vn.consoleCount > 24) vn.consoleCount - 24 else 0;
    for (int i = start; i < vn.consoleCount; i = i + 1) {
      int lv = vn.consoleLines[i].level;
      Color lineCol = vnSecondaryText(dark);
      if (lv == 1) { lineCol = vnMint(); }
      else if (lv == 2) { lineCol = vnAmber(); }
      else if (lv == 3) { lineCol = vnBlue(); }
      logScroll.add(Text::new()
        |> set_text(&vn.consoleLines[i].text[0])
        |> set_text_size(9.8)
        |> set_font(gui::mono())
        |> set_text_color(lineCol));
    }
  }
  consoleBox.add(logScroll);
  return consoleBox;
}

Widget* buildRightInspector() {
  bool dark = vn.darkTheme;
  auto panel = Column::new()
    |> set_id("vn-right-panel")
    |> set_size(296px, fill())
    |> set_bg(vnPanel(dark))
    |> set_border(1.0, vnBorder(dark))
    |> set_gap(0.0);

  auto scroll = Scroll::new()
    |> set_id("vn-inspector-scroll")
    |> set_size(fill(), fill())
    |> set_padding(12.0)
    |> set_gap(8.0);

  if (vn.selectedNode >= 0 && vn.selectedNode < vn.nodeCount) {
    scroll.add(buildNodeInspector(dark));
  } else {
    scroll.add(buildGraphOverviewInspector(dark));
  }
  panel.add(scroll);
  panel.add(buildConsolePanel(dark));
  return panel;
}
