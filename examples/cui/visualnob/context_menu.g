// VisualNob Context-Sensitive Right-Click Menu Overlay.
// Displays tailored actions for Empty Canvas, Node Cards, Input/Output Ports, and Wires.

import std.gui;
import std.pipe;
import std.cui;
import examples.cui.visualnob.palette;
import examples.cui.visualnob.model;
import examples.cui.visualnob.geometry;
import examples.cui.visualnob.graph;
import examples.cui.visualnob.runtime;
import examples.cui.visualnob.canvas;

void execContextAction(int action) {
  if (action == 1) {
    float sx = vn.canvasRect.x + vn.contextScreenX;
    float sy = vn.canvasRect.y + vn.contextScreenY;
    openQuickAddAt(&vn, sx, sy);
    return;
  }
  if (action == 2) {
    int idx = createScriptNode(&vn, VnNodeKind::VnConstNumber as int, vn.contextWorldX, vn.contextWorldY);
    if (idx >= 0) { vn.selectedNode = idx; }
  } else if (action == 3) {
    int idx = createScriptNode(&vn, VnNodeKind::VnBranch as int, vn.contextWorldX, vn.contextWorldY);
    if (idx >= 0) { vn.selectedNode = idx; }
  } else if (action == 4) {
    int idx = createScriptNode(&vn, VnNodeKind::VnPrintLog as int, vn.contextWorldX, vn.contextWorldY);
    if (idx >= 0) { vn.selectedNode = idx; }
  } else if (action == 5) {
    int idx = createScriptNode(&vn, VnNodeKind::VnComment as int, vn.contextWorldX, vn.contextWorldY);
    if (idx >= 0) { vn.selectedNode = idx; }
  } else if (action == 6) {
    autoArrangeGraph(&vn);
  } else if (action == 7) {
    fitGraphInView(&vn);
  } else if (action == 8) {
    clearExecutionMarks(&vn);
  } else if (action == 10) {
    runFromNode(&vn, vn.contextNode);
  } else if (action == 11) {
    duplicateNodeAt(&vn, vn.contextNode);
  } else if (action == 12) {
    if (vn.contextNode >= 0 && vn.contextNode < vn.nodeCount) {
      vn.nodes[vn.contextNode].collapsed = !vn.nodes[vn.contextNode].collapsed;
    }
  } else if (action == 13) {
    bringNodeToFront(&vn, vn.contextNode);
  } else if (action == 14) {
    disconnectNodeWires(&vn, vn.contextNode);
  } else if (action == 15) {
    deleteNodeAt(&vn, vn.contextNode);
  } else if (action == 20) {
    disconnectPortAll(&vn, vn.contextNode, vn.contextPort, vn.contextPortIsOut);
  } else if (action == 30) {
    removeWireAt(&vn, vn.contextWire);
  } else if (action == 31) {
    if (vn.contextWire >= 0 && vn.contextWire < vn.wireCount) {
      vn.selectedNode = vn.wires[vn.contextWire].fromNode;
      vn.selectedWire = -1;
    }
  } else if (action == 32) {
    if (vn.contextWire >= 0 && vn.contextWire < vn.wireCount) {
      vn.selectedNode = vn.wires[vn.contextWire].toNode;
      vn.selectedWire = -1;
    }
  }
  vn.contextKind = ContextKind::CtxNone as int;
}

Widget* ctxMenuItem(const char* icon, const char* label, const char* shortcut,
                    int actionTag, bool danger, bool dark) {
  Color ink = if (danger) vnCoral() else vnText(dark);
  Color ico = if (danger) vnCoral() else vnSecondaryText(dark);
  auto row = Row::new()
    |> set_size(fill(), 26px)
    |> set_padding_xy(8.0, 0.0)
    |> set_gap(8.0)
    |> set_radius(5.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_hover_bg(if (danger) vnCoralSoft(dark) else vnHover(dark))
    |> on_click_tag(actionTag) { -> execContextAction(gui::clickTag()); return; };

  row.add(Icon::new() |> set_icon(icon) |> set_text_size(11.5) |> set_text_color(ico));
  row.add(Text::new() |> set_text(label) |> set_text_size(10.5) |> set_text_color(ink));
  row.add(Spacer::new() |> set_size(fill(), 1px));
  if (shortcut != nullptr) {
    row.add(Text::new() |> set_text(shortcut) |> set_text_size(9.0) |> set_font(gui::mono()) |> set_text_color(vnMutedText(dark)));
  }
  return row;
}

Widget* buildContextMenuOverlay() {
  bool dark = vn.darkTheme;
  auto wrap = Column::new()
    |> set_size(fill(), fill())
    |> set_padding_each(vn.contextScreenY, 0.0, 0.0, vn.contextScreenX)
    |> set_align(GuiAlign::GuiAlignStart)
    |> set_justify(GuiJustify::GuiJustifyStart);

  auto card = Column::new()
    |> set_id("vn-context-menu")
    |> set_size(208px, fit())
    |> set_padding(6.0)
    |> set_gap(2.0)
    |> set_bg(vnCard(dark))
    |> set_border(1.0, vnBorder(dark))
    |> set_radius(8.0)
    |> set_elevation(GuiElevation::GuiElevationFloating);

  if (vn.contextKind == (ContextKind::CtxCanvas as int)) {
    card.add(ctxMenuItem(std::cui::icons::search(), "Add Node...", "Tab", 1, false, dark));
    card.add(Divider::new() |> set_size(fill(), 1px) |> set_bg(vnDivider(dark)));
    card.add(ctxMenuItem(std::cui::icons::sliders(), "Spawn Number", nullptr, 2, false, dark));
    card.add(ctxMenuItem(std::cui::icons::gitBranch(), "Spawn Branch (If)", nullptr, 3, false, dark));
    card.add(ctxMenuItem(std::cui::icons::terminal(), "Spawn Print Log", nullptr, 4, false, dark));
    card.add(ctxMenuItem(std::cui::icons::message(), "Add Comment Note", nullptr, 5, false, dark));
    card.add(Divider::new() |> set_size(fill(), 1px) |> set_bg(vnDivider(dark)));
    card.add(ctxMenuItem(std::cui::icons::grid(), "Auto-Layout Graph", "A", 6, false, dark));
    card.add(ctxMenuItem(std::cui::icons::maximize(), "Fit Graph to View", "0", 7, false, dark));
    card.add(ctxMenuItem(std::cui::icons::rotateCcw(), "Clear Run Highlights", nullptr, 8, false, dark));
  } else if (vn.contextKind == (ContextKind::CtxNode as int)) {
    const char* nTitle = if (vn.contextNode >= 0 && vn.contextNode < vn.nodeCount)
      &vn.nodes[vn.contextNode].title[0] else "Node";
    auto titleRow = Row::new() |> set_size(fill(), 20px) |> set_padding_xy(8.0, 0.0) |> set_align(GuiAlign::GuiAlignCenter);
    titleRow.add(Text::new() |> set_text(nTitle) |> set_text_size(9.5) |> set_font(gui::medium()) |> set_text_color(vnMint()));
    card.add(titleRow);
    card.add(Divider::new() |> set_size(fill(), 1px) |> set_bg(vnDivider(dark)));
    card.add(ctxMenuItem(std::cui::icons::play(), "Run From Node", nullptr, 10, false, dark));
    card.add(ctxMenuItem(std::cui::icons::copy(), "Duplicate Node", "D", 11, false, dark));
    card.add(ctxMenuItem(std::cui::icons::minimize(), "Toggle Collapse", nullptr, 12, false, dark));
    card.add(ctxMenuItem(std::cui::icons::layers(), "Bring to Front", nullptr, 13, false, dark));
    card.add(ctxMenuItem(std::cui::icons::link(), "Disconnect All Wires", nullptr, 14, false, dark));
    card.add(Divider::new() |> set_size(fill(), 1px) |> set_bg(vnDivider(dark)));
    card.add(ctxMenuItem(std::cui::icons::trash(), "Delete Node", "Del", 15, true, dark));
  } else if (vn.contextKind == (ContextKind::CtxPort as int)) {
    card.add(ctxMenuItem(std::cui::icons::x(), "Disconnect Port Wire(s)", nullptr, 20, true, dark));
  } else if (vn.contextKind == (ContextKind::CtxWire as int)) {
    card.add(ctxMenuItem(std::cui::icons::arrowLeft(), "Select Source Node", nullptr, 31, false, dark));
    card.add(ctxMenuItem(std::cui::icons::arrowRight(), "Select Target Node", nullptr, 32, false, dark));
    card.add(Divider::new() |> set_size(fill(), 1px) |> set_bg(vnDivider(dark)));
    card.add(ctxMenuItem(std::cui::icons::trash(), "Delete Wire", "Del", 30, true, dark));
  }

  wrap.add(card);
  return wrap;
}
