// FigCraft Scene Builder: Ridgeline Studio Dashboard + Components Page + Defaults.
// Populates Page 0 ("Dashboard"), Page 1 ("Components"), tabs, variables,
// and prototype interactions.

import std.gui;
import examples.cui.figcraft.palette;
import examples.cui.figcraft.model;

void addNodeToEditor(Editor* e, NodeKind kind, const char* name, const char* body,
                     float x, float y, float w, float h,
                     Color fill, Color ink, Color stroke,
                     float radius, float border, float textSize, int font) {
  if (e.count >= 160) { return; }
  DesignNode n = DesignNode{
    kind: kind as int,
    id: e.nextId,
    groupIndex: 0,
    x: x,
    y: y,
    w: w,
    h: h,
    radius: radius,
    border: border,
    rotation: 0.0,
    opacity: 1.0,
    textSize: textSize,
    font: font,
    fill: fill,
    ink: ink,
    stroke: stroke,
    visible: true,
    locked: false
  };
  copyStr(&n.name[0], name, 64);
  copyStr(&n.body[0], body, 128);
  e.nextId = e.nextId + 1;
  e.nodes[e.count] = n;
  e.count = e.count + 1;
}

void addScRect(Editor* e, const char* name, float x, float y, float w, float h,
               Color fill, float radius, float border, Color stroke) {
  addNodeToEditor(e, NodeKind::NodeRectangle, name, "", x, y, w, h,
                  fill, gui::clear(), stroke, radius, border, 0.0, 0);
}

void addScText(Editor* e, const char* name, float x, float y, float w, float h,
               float size, Color ink, int font) {
  addNodeToEditor(e, NodeKind::NodeText, name, "", x, y, w, h,
                  gui::clear(), ink, gui::clear(), 0.0, 0.0, size, font);
}

void addScButton(Editor* e, const char* name, float x, float y, float w, float h,
                 Color fill, Color ink) {
  addNodeToEditor(e, NodeKind::NodeButton, name, "", x, y, w, h,
                  fill, ink, gui::clear(), 7.0, 0.0, 12.0, 1);
}

void addScChart(Editor* e, const char* name, float x, float y, float w, float h, Color bar) {
  addNodeToEditor(e, NodeKind::NodeChart, name, "", x, y, w, h,
                  bar, gui::clear(), gui::clear(), 0.0, 0.0, 0.0, 0);
}

void addScDonut(Editor* e, const char* name, float x, float y, float w, float h) {
  addNodeToEditor(e, NodeKind::NodeDonut, name, "", x, y, w, h,
                  fcChartGreen(), fcText(false), gui::clear(), 0.0, 0.0, 0.0, 0);
}

void addScLine(Editor* e, const char* name, float x, float y, float w, float h, Color color) {
  addNodeToEditor(e, NodeKind::NodeLine, name, "", x, y, w, h,
                  color, gui::clear(), gui::clear(), 0.0, 0.0, 0.0, 0);
}

void addScSpark(Editor* e, const char* name, float x, float y, float w, float h, Color color, int variant) {
  addNodeToEditor(e, NodeKind::NodeSparkline, name, "", x, y, w, h,
                  color, gui::clear(), gui::clear(), 0.0, 0.0, 0.0, variant);
}

void addScDot(Editor* e, const char* name, float x, float y, float sz, Color color) {
  addNodeToEditor(e, NodeKind::NodeRectangle, name, "", x, y, sz, sz,
                  color, gui::clear(), gui::clear(), sz * 0.5, 0.0, 0.0, 0);
}

void populateDashboardScene(Editor* e) {
  e.count = 0;
  e.nextId = 100;
  e.stageW = 1440.0;
  e.stageH = 960.0;
  e.stageBg = fcDesignBg(false);
  copyStr(&e.stageName[0], "Dashboard - Overview", 48);

  Color sidebar = gui::rgb(12, 25, 41);
  Color sidebarRaised = gui::rgb(23, 43, 62);
  Color navMuted = gui::rgb(164, 179, 196);
  Color ink = gui::rgb(23, 32, 44);
  Color muted = gui::rgb(122, 135, 148);
  Color line = gui::rgb(231, 235, 240);
  Color card = fcWhite();
  Color green = fcGreen();
  Color greenDark = fcGreenDark();
  Color blue = fcChartBlue();
  Color warn = fcWarning();
  Color danger = fcDanger();

  // Sidebar
  addScRect(e, "Sidebar", 0.0, 0.0, 265.0, 960.0, sidebar, 0.0, 0.0, gui::clear());
  addScRect(e, "Brand mark", 21.0, 21.0, 37.0, 37.0, green, 10.0, 0.0, gui::clear());
  addScText(e, "R", 33.0, 26.0, 20.0, 26.0, 17.0, sidebar, 1);
  addScText(e, "Ridgeline", 67.0, 21.0, 150.0, 26.0, 14.0, card, 1);
  addScText(e, "STUDIO", 68.0, 43.0, 100.0, 16.0, 8.0, navMuted, 0);
  addScRect(e, "Overview active", 21.0, 69.0, 223.0, 42.0, sidebarRaised, 8.0, 0.0, gui::clear());
  addScDot(e, "Active nav dot", 224.0, 86.0, 7.0, green);
  addScText(e, "Overview", 55.0, 80.0, 150.0, 22.0, 13.0, card, 1);
  addScText(e, "Analytics", 55.0, 131.0, 150.0, 22.0, 13.0, navMuted, 0);
  addScText(e, "Trails", 55.0, 182.0, 150.0, 22.0, 13.0, navMuted, 0);
  addScText(e, "Rangers", 55.0, 233.0, 150.0, 22.0, 13.0, navMuted, 0);
  addScText(e, "Bookings", 55.0, 284.0, 150.0, 22.0, 13.0, navMuted, 0);
  addScText(e, "Alerts", 55.0, 335.0, 150.0, 22.0, 13.0, navMuted, 0);
  addScText(e, "Settings", 55.0, 386.0, 150.0, 22.0, 13.0, navMuted, 0);

  // Winter season card
  addScRect(e, "Winter planner", 21.0, 716.0, 223.0, 150.0, gui::rgb(18, 73, 57), 10.0, 0.0, gui::clear());
  addScText(e, "Winter season", 36.0, 731.0, 190.0, 24.0, 12.0, card, 1);
  addScText(e, "Plan closures and snow", 36.0, 758.0, 192.0, 16.0, 9.0, gui::rgb(199, 235, 222), 0);
  addScText(e, "routes before the first storm.", 36.0, 774.0, 192.0, 16.0, 8.5, gui::rgb(199, 235, 222), 0);
  addScButton(e, "Open planner", 36.0, 812.0, 193.0, 30.0, green, sidebar);

  // User footer
  addScDot(e, "Avatar", 21.0, 898.0, 27.0, green);
  addScText(e, "JO", 27.0, 904.0, 20.0, 16.0, 8.0, sidebar, 1);
  addScText(e, "Jonas Ortiz", 56.0, 896.0, 150.0, 20.0, 10.5, card, 1);
  addScText(e, "Park operations", 56.0, 916.0, 150.0, 16.0, 8.2, navMuted, 0);

  // Top Header
  addScText(e, "Good afternoon, Jonas", 289.0, 33.0, 560.0, 36.0, 21.0, ink, 1);
  addScText(e, "Here is how the park's trails did this week.", 289.0, 66.0, 520.0, 20.0, 10.0, muted, 0);
  addScRect(e, "Search field", 893.0, 40.0, 222.0, 44.0, card, 22.0, 1.0, line);
  addScText(e, "Search trails or rangers", 914.0, 53.0, 190.0, 20.0, 9.2, gui::rgb(150, 160, 172), 0);
  addScRect(e, "Date chip", 1129.0, 40.0, 136.0, 44.0, card, 9.0, 1.0, line);
  addScText(e, "6 - 12 Oct 2026", 1147.0, 53.0, 118.0, 20.0, 8.4, muted, 0);
  addScButton(e, "New trail", 1279.0, 40.0, 136.0, 44.0, green, sidebar);

  // KPI Cards + Sparklines
  addScRect(e, "KPI hikers", 289.0, 123.0, 268.0, 152.0, card, 9.0, 1.0, line);
  addScText(e, "Active hikers", 305.0, 137.0, 200.0, 18.0, 9.7, muted, 0);
  addScText(e, "12,480", 305.0, 156.0, 220.0, 42.0, 26.5, ink, 1);
  addScText(e, "^ 18.2% vs last week", 305.0, 238.0, 150.0, 18.0, 8.6, greenDark, 0);
  addScSpark(e, "Hikers sparkline", 456.0, 226.0, 86.0, 32.0, fcChartGreen(), 0);

  addScRect(e, "KPI check-ins", 575.0, 123.0, 268.0, 152.0, card, 9.0, 1.0, line);
  addScText(e, "Trail check-ins", 591.0, 137.0, 200.0, 18.0, 9.7, muted, 0);
  addScText(e, "3,916", 591.0, 156.0, 220.0, 42.0, 26.5, ink, 1);
  addScText(e, "^ 12.4% vs last week", 591.0, 238.0, 150.0, 18.0, 8.6, greenDark, 0);
  addScSpark(e, "Check-ins sparkline", 742.0, 226.0, 86.0, 32.0, fcChartGreen(), 1);

  addScRect(e, "KPI rating", 861.0, 123.0, 268.0, 152.0, card, 9.0, 1.0, line);
  addScText(e, "Avg. rating", 877.0, 137.0, 200.0, 18.0, 9.7, muted, 0);
  addScText(e, "4.82", 877.0, 156.0, 220.0, 42.0, 26.5, ink, 1);
  addScText(e, "^ 0.06 vs last week", 877.0, 238.0, 150.0, 18.0, 8.6, greenDark, 0);
  addScSpark(e, "Rating sparkline", 1028.0, 226.0, 86.0, 32.0, fcChartGreen(), 2);

  addScRect(e, "KPI incidents", 1147.0, 123.0, 268.0, 152.0, card, 9.0, 1.0, line);
  addScText(e, "Open incidents", 1163.0, 137.0, 200.0, 18.0, 9.7, muted, 0);
  addScText(e, "7", 1163.0, 156.0, 220.0, 42.0, 26.5, ink, 1);
  addScText(e, "v 3 vs last week", 1163.0, 238.0, 150.0, 18.0, 8.6, danger, 0);
  addScSpark(e, "Incidents sparkline", 1314.0, 226.0, 86.0, 32.0, danger, 3);

  // Hikes bar card
  addScRect(e, "Hikes card", 289.0, 293.0, 772.0, 328.0, card, 9.0, 1.0, line);
  addScText(e, "Hikes per day", 305.0, 308.0, 260.0, 26.0, 13.0, ink, 1);
  addScText(e, "2,184 this week · +9% on last week", 305.0, 330.0, 360.0, 18.0, 8.5, muted, 0);
  addScDot(e, "This week dot", 884.0, 317.0, 7.0, fcChartGreen());
  addScText(e, "This week", 896.0, 312.0, 72.0, 16.0, 8.2, muted, 0);
  addScDot(e, "Last week dot", 974.0, 317.0, 7.0, fcChartMint());
  addScText(e, "Last week", 986.0, 312.0, 72.0, 16.0, 8.2, muted, 0);
  addScChart(e, "Hikes bars", 305.0, 356.0, 740.0, 220.0, fcChartGreen());
  addScText(e, "Mon", 342.0, 586.0, 40.0, 16.0, 8.5, muted, 0);
  addScText(e, "Tue", 448.0, 586.0, 40.0, 16.0, 8.5, muted, 0);
  addScText(e, "Wed", 554.0, 586.0, 40.0, 16.0, 8.5, muted, 0);
  addScText(e, "Thu", 660.0, 586.0, 40.0, 16.0, 8.5, muted, 0);
  addScText(e, "Fri", 766.0, 586.0, 40.0, 16.0, 8.5, muted, 0);
  addScText(e, "Sat", 872.0, 586.0, 40.0, 16.0, 8.5, muted, 0);
  addScText(e, "Sun", 978.0, 586.0, 40.0, 16.0, 8.5, muted, 0);

  // Difficulty donut card
  addScRect(e, "Difficulty card", 1079.0, 293.0, 336.0, 328.0, card, 9.0, 1.0, line);
  addScText(e, "Difficulty mix", 1095.0, 308.0, 240.0, 26.0, 13.0, ink, 1);
  addScDonut(e, "Difficulty donut", 1095.0, 340.0, 304.0, 206.0);
  addScDot(e, "Easy dot", 1104.0, 566.0, 8.0, fcChartGreen());
  addScText(e, "Easy", 1117.0, 561.0, 60.0, 18.0, 8.6, muted, 0);
  addScDot(e, "Moderate dot", 1178.0, 566.0, 8.0, blue);
  addScText(e, "Moderate", 1191.0, 561.0, 90.0, 18.0, 8.6, muted, 0);
  addScDot(e, "Hard dot", 1288.0, 566.0, 8.0, warn);
  addScText(e, "Hard", 1301.0, 561.0, 60.0, 18.0, 8.6, muted, 0);

  // Trails table card
  addScRect(e, "Trails card", 289.0, 639.0, 772.0, 296.0, card, 9.0, 1.0, line);
  addScText(e, "Top trails this week", 305.0, 654.0, 300.0, 26.0, 13.0, ink, 1);
  addScText(e, "View all", 987.0, 657.0, 60.0, 18.0, 9.0, greenDark, 0);
  addScText(e, "TRAIL", 336.0, 686.0, 180.0, 16.0, 7.6, muted, 0);
  addScText(e, "REGION", 560.0, 686.0, 100.0, 16.0, 7.6, muted, 0);
  addScText(e, "HIKES", 700.0, 686.0, 50.0, 16.0, 7.6, muted, 0);
  addScText(e, "RATING", 770.0, 686.0, 60.0, 16.0, 7.6, muted, 0);
  addScText(e, "CONDITIONS", 896.0, 686.0, 90.0, 16.0, 7.6, muted, 0);

  // Trail rows
  addScRect(e, "Trail thumb 1", 305.0, 712.0, 22.0, 22.0, fcChartMint(), 5.0, 0.0, gui::clear());
  addScText(e, "Larch Valley Loop", 336.0, 713.0, 210.0, 22.0, 10.2, ink, 0);
  addScText(e, "Lake district", 560.0, 714.0, 130.0, 20.0, 9.0, muted, 0);
  addScText(e, "612", 700.0, 714.0, 50.0, 20.0, 9.0, ink, 0);
  addScText(e, "4.9", 770.0, 714.0, 50.0, 20.0, 9.0, ink, 0);
  addScRect(e, "Open pill 1", 896.0, 709.0, 74.0, 26.0, fcGreenSoft(false), 13.0, 0.0, gui::clear());
  addScText(e, "Open", 916.0, 714.0, 50.0, 18.0, 8.6, greenDark, 1);

  addScRect(e, "Trail thumb 2", 305.0, 756.0, 22.0, 22.0, fcChartMint(), 5.0, 0.0, gui::clear());
  addScText(e, "Emerald Lake Circuit", 336.0, 757.0, 210.0, 22.0, 10.2, ink, 0);
  addScText(e, "Yoho valley", 560.0, 758.0, 130.0, 20.0, 9.0, muted, 0);
  addScText(e, "488", 700.0, 758.0, 50.0, 20.0, 9.0, ink, 0);
  addScText(e, "4.8", 770.0, 758.0, 50.0, 20.0, 9.0, ink, 0);
  addScRect(e, "Open pill 2", 896.0, 753.0, 74.0, 26.0, fcGreenSoft(false), 13.0, 0.0, gui::clear());
  addScText(e, "Open", 916.0, 758.0, 50.0, 18.0, 8.6, greenDark, 1);

  addScRect(e, "Trail thumb 3", 305.0, 800.0, 22.0, 22.0, fcChartMint(), 5.0, 0.0, gui::clear());
  addScText(e, "Sulphur Ridge Lookout", 336.0, 801.0, 210.0, 22.0, 10.2, ink, 0);
  addScText(e, "Hot springs", 560.0, 802.0, 130.0, 20.0, 9.0, muted, 0);
  addScText(e, "351", 700.0, 802.0, 50.0, 20.0, 9.0, ink, 0);
  addScText(e, "4.7", 770.0, 802.0, 50.0, 20.0, 9.0, ink, 0);
  addScRect(e, "Muddy pill", 896.0, 797.0, 74.0, 26.0, fcWarningSoft(false), 13.0, 0.0, gui::clear());
  addScText(e, "Muddy", 912.0, 802.0, 60.0, 18.0, 8.6, warn, 1);

  addScRect(e, "Trail thumb 4", 305.0, 844.0, 22.0, 22.0, fcChartMint(), 5.0, 0.0, gui::clear());
  addScText(e, "Tunnel Peak Traverse", 336.0, 845.0, 210.0, 22.0, 10.2, ink, 0);
  addScText(e, "North gate", 560.0, 846.0, 130.0, 20.0, 9.0, muted, 0);
  addScText(e, "207", 700.0, 846.0, 50.0, 20.0, 9.0, ink, 0);
  addScText(e, "4.6", 770.0, 846.0, 50.0, 20.0, 9.0, ink, 0);
  addScRect(e, "Snow pill", 896.0, 841.0, 74.0, 26.0, fcBlueSoft(false), 13.0, 0.0, gui::clear());
  addScText(e, "Snow", 914.0, 846.0, 60.0, 18.0, 8.6, blue, 1);

  // Visitors card
  addScRect(e, "Visitors card", 1079.0, 639.0, 336.0, 296.0, card, 9.0, 1.0, line);
  addScText(e, "Visitors, last 30 days", 1095.0, 654.0, 240.0, 22.0, 12.0, ink, 1);
  addScText(e, "+18%", 1352.0, 657.0, 60.0, 18.0, 9.0, greenDark, 0);
  addScText(e, "41,230", 1095.0, 680.0, 220.0, 44.0, 28.0, ink, 1);
  addScLine(e, "Visitors trend", 1095.0, 732.0, 304.0, 160.0, blue);
  addScText(e, "12 Sep", 1095.0, 904.0, 60.0, 18.0, 7.6, muted, 0);
  addScText(e, "22 Sep", 1180.0, 904.0, 60.0, 18.0, 7.6, muted, 0);
  addScText(e, "2 Oct", 1262.0, 904.0, 60.0, 18.0, 7.6, muted, 0);
  addScText(e, "12 Oct", 1340.0, 904.0, 60.0, 18.0, 7.6, muted, 0);
}

void populateComponentsScene(Editor* e) {
  e.count = 0;
  e.nextId = 400;
  e.stageW = 1440.0;
  e.stageH = 960.0;
  e.stageBg = fcWhite();
  copyStr(&e.stageName[0], "Design System - Kit", 48);

  Color ink = gui::rgb(23, 32, 44);
  Color muted = gui::rgb(122, 135, 148);
  Color line = gui::rgb(231, 235, 240);
  Color card = fcWhite();

  addScText(e, "Ridgeline Design System", 64.0, 56.0, 480.0, 40.0, 28.0, ink, 1);
  addScText(e, "Core components, chart primitives, and semantic tokens.", 64.0, 102.0, 540.0, 24.0, 12.0, muted, 0);

  // Buttons specimen card
  addScRect(e, "Buttons Frame", 64.0, 156.0, 620.0, 240.0, fcDesignBg(false), 12.0, 1.0, line);
  addScText(e, "Actions & Buttons", 92.0, 182.0, 240.0, 24.0, 14.0, ink, 1);
  addScButton(e, "Primary Action", 92.0, 230.0, 168.0, 42.0, fcGreen(), fcNavy());
  addScButton(e, "Secondary", 280.0, 230.0, 150.0, 42.0, fcNavy(), card);
  addScButton(e, "Subtle", 450.0, 230.0, 140.0, 42.0, fcGreenSoft(false), fcGreenDark());
  addScRect(e, "Input Specimen", 92.0, 298.0, 320.0, 44.0, card, 10.0, 1.0, line);
  addScText(e, "Search trails or rangers...", 112.0, 311.0, 260.0, 20.0, 10.0, muted, 0);

  // Palette specimen card
  addScRect(e, "Tokens Frame", 716.0, 156.0, 660.0, 240.0, fcDesignBg(false), 12.0, 1.0, line);
  addScText(e, "Brand & Semantic Swatches", 744.0, 182.0, 300.0, 24.0, 14.0, ink, 1);
  addScRect(e, "Token Accent", 744.0, 230.0, 110.0, 96.0, fcGreen(), 10.0, 0.0, gui::clear());
  addScRect(e, "Token Navy", 872.0, 230.0, 110.0, 96.0, fcNavy(), 10.0, 0.0, gui::clear());
  addScRect(e, "Token Blue", 1000.0, 230.0, 110.0, 96.0, fcChartBlue(), 10.0, 0.0, gui::clear());
  addScRect(e, "Token Warn", 1128.0, 230.0, 110.0, 96.0, fcWarning(), 10.0, 0.0, gui::clear());
  addScText(e, "0ACF83", 744.0, 338.0, 90.0, 18.0, 9.5, muted, 0);
  addScText(e, "0F1726", 872.0, 338.0, 90.0, 18.0, 9.5, muted, 0);
  addScText(e, "3B82F6", 1000.0, 338.0, 90.0, 18.0, 9.5, muted, 0);
  addScText(e, "D99126", 1128.0, 338.0, 90.0, 18.0, 9.5, muted, 0);

  // Data Visualization card
  addScRect(e, "Data Viz Frame", 64.0, 428.0, 1312.0, 460.0, fcDesignBg(false), 12.0, 1.0, line);
  addScText(e, "Data Visualization Modules", 92.0, 456.0, 360.0, 26.0, 15.0, ink, 1);
  addScRect(e, "Bar Specimen Card", 92.0, 502.0, 540.0, 340.0, card, 10.0, 1.0, line);
  addScChart(e, "Weekly Series", 120.0, 540.0, 480.0, 260.0, fcChartGreen());
  addScRect(e, "Donut Specimen Card", 660.0, 502.0, 330.0, 340.0, card, 10.0, 1.0, line);
  addScDonut(e, "Mix Donut", 684.0, 540.0, 282.0, 260.0);
  addScRect(e, "Trend Specimen Card", 1018.0, 502.0, 326.0, 340.0, card, 10.0, 1.0, line);
  addScLine(e, "30-Day Line", 1044.0, 560.0, 274.0, 220.0, fcChartBlue());
}

void saveCurrentNodesToPage(Editor* e, int pageIdx) {
  if (pageIdx < 0 || pageIdx >= 4) { return; }
  PageData* pg = &e.pages[pageIdx];
  copyStr(&pg.frameName[0], &e.stageName[0], 48);
  pg.frameW = e.stageW;
  pg.frameH = e.stageH;
  pg.frameBg = e.stageBg;
  pg.count = e.count;
  pg.nextId = e.nextId;
  for (int i = 0; i < e.count && i < 160; i = i + 1) {
    pg.nodes[i] = e.nodes[i];
  }
}

void loadPageNodesToEditor(Editor* e, int pageIdx) {
  if (pageIdx < 0 || pageIdx >= 4) { return; }
  PageData* pg = &e.pages[pageIdx];
  copyStr(&e.stageName[0], &pg.frameName[0], 48);
  e.stageW = pg.frameW;
  e.stageH = pg.frameH;
  e.stageBg = pg.frameBg;
  e.count = pg.count;
  e.nextId = pg.nextId;
  for (int i = 0; i < pg.count && i < 160; i = i + 1) {
    e.nodes[i] = pg.nodes[i];
  }
  e.selected = -1;
}

void savePageSlotToTab(Editor* e, int tabIdx, int pageIdx) {
  if (tabIdx < 0 || tabIdx >= 6 || pageIdx < 0 || pageIdx >= 4) { return; }
  PageData* src = &e.pages[pageIdx];
  PageData* dst = &e.tabs[tabIdx].pages[pageIdx];
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

void loadPageSlotFromTab(Editor* e, int tabIdx, int pageIdx) {
  if (tabIdx < 0 || tabIdx >= 6 || pageIdx < 0 || pageIdx >= 4) { return; }
  PageData* src = &e.tabs[tabIdx].pages[pageIdx];
  PageData* dst = &e.pages[pageIdx];
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

void addColorVar(Editor* e, const char* token, const char* group, const char* hex, Color c) {
  if (e.colorVarCount >= 8) { return; }
  ColorVar* v = &e.colorVars[e.colorVarCount];
  copyStr(&v.token[0], token, 24);
  copyStr(&v.group[0], group, 24);
  copyStr(&v.hex[0], hex, 16);
  v.color = c;
  e.colorVarCount = e.colorVarCount + 1;
}

void addNumberVar(Editor* e, const char* token, const char* label, float val, const char* disp) {
  if (e.numberVarCount >= 4) { return; }
  NumberVar* v = &e.numberVars[e.numberVarCount];
  copyStr(&v.token[0], token, 24);
  copyStr(&v.label[0], label, 24);
  v.value = val;
  copyStr(&v.display[0], disp, 12);
  e.numberVarCount = e.numberVarCount + 1;
}

void addInteractionRecord(Editor* e, int nodeId, const char* trigger, const char* action, const char* anim, int ms) {
  if (e.interactionCount >= 16) { return; }
  InteractionItem* it = &e.interactions[e.interactionCount];
  it.nodeId = nodeId;
  copyStr(&it.trigger[0], trigger, 32);
  copyStr(&it.action[0], action, 48);
  copyStr(&it.animation[0], anim, 32);
  it.durationMs = ms;
  e.interactionCount = e.interactionCount + 1;
}

void initDefaultWorkspace(Editor* e) {
  resetEditorFields(e);

  // Page 1 first ("Components"), then Page 0 ("Dashboard")
  copyStr(&e.pages[1].title[0], "Components", 48);
  populateComponentsScene(e);
  saveCurrentNodesToPage(e, 1);

  copyStr(&e.pages[0].title[0], "Dashboard", 48);
  populateDashboardScene(e);
  saveCurrentNodesToPage(e, 0);

  e.activePage = 0;
  e.pageCount = 2;
  e.selected = -1;

  // Initial tab 0
  e.tabCount = 1;
  e.activeTab = 0;
  copyStr(&e.tabs[0].title[0], "Ridgeline Studio dashboard", 48);
  e.tabs[0].activePage = 0;
  e.tabs[0].pageCount = 2;
  e.tabs[0].selected = -1;
  e.tabs[0].zoom = 1.0;
  e.tabs[0].offsetX = 0.0;
  e.tabs[0].offsetY = 0.0;
  e.tabs[0].darkTheme = false;
  savePageSlotToTab(e, 0, 0);
  savePageSlotToTab(e, 0, 1);

  // Variables
  addColorVar(e, "surface", "Canvas", "F3F5F8", fcDesignBg(false));
  addColorVar(e, "text", "Ink", "0F1726", fcNavy());
  addColorVar(e, "accent", "Accent", "0ACF83", fcGreen());
  addColorVar(e, "muted", "Muted", "8B8B91", fcTitleMuted());
  addColorVar(e, "warning", "Warning", "D99126", fcWarning());
  addColorVar(e, "blue", "Primary", "3B82F6", fcChartBlue());

  addNumberVar(e, "radius", "Corner", 20.0, "20");
  addNumberVar(e, "space", "Gap", 24.0, "24");
  addNumberVar(e, "card", "Card R", 9.0, "9");

  // Prototype interactions
  addInteractionRecord(e, -1, "On click", "Navigate to Components", "Smart animate", 300);
  addInteractionRecord(e, 118, "On click", "Open Winter planner", "Dissolve", 200);
}
