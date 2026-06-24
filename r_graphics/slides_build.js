const pptxgen = require("pptxgenjs");
const React = require("react");
const ReactDOMServer = require("react-dom/server");
const sharp = require("sharp");
const fa = require("react-icons/fa");

// ---------- palette ----------
const DARK   = "14182B";  // midnight indigo
const INK    = "1E2336";  // headings on light
const BODY   = "424A5C";
const MUTED  = "838BA0";
const WHITE  = "FFFFFF";
const GG     = "3B4A8C";   // ggplot2 accent (indigo)
const TP     = "0E8C7F";   // tidyplots accent (teal)
const GG_TINT= "EDEFF8";
const TP_TINT= "E7F4F1";
const CODE   = "20263A";   // code ink
const CORAL  = "D9694C";   // sharp accent for highlights/takeaway
const CARD   = "F4F6FB";

const MONO = "Courier New";
const SANS = "Calibri";
const SERIF= "Cambria";

const shadow = () => ({ type: "outer", color: "000000", blur: 7, offset: 3, angle: 90, opacity: 0.12 });

// ---------- icon rasterizer ----------
async function icon(Comp, color, size = 256) {
  const svg = ReactDOMServer.renderToStaticMarkup(
    React.createElement(Comp, { color, size: String(size) })
  );
  const png = await sharp(Buffer.from(svg)).png().toBuffer();
  return "image/png;base64," + png.toString("base64");
}

(async () => {
  const pres = new pptxgen();
  pres.layout = "LAYOUT_WIDE"; // 13.3 x 7.5
  pres.author = "Bioinformatics & Research Computing";
  pres.title  = "ggplot2 vs tidyplots";
  const W = 13.3, H = 7.5;

  // pre-render icons
  const ic = {
    dna_w:    await icon(fa.FaDna, "#" + WHITE),
    scale:    await icon(fa.FaBalanceScale, "#" + WHITE),
    vials:    await icon(fa.FaVials, "#" + WHITE),
    bar:      await icon(fa.FaChartBar, "#" + WHITE),
    stream:   await icon(fa.FaStream, "#" + WHITE),
    grid:     await icon(fa.FaTh, "#" + WHITE),
    braille:  await icon(fa.FaBraille, "#" + WHITE),
    bulb_w:   await icon(fa.FaLightbulb, "#" + WHITE),
    code_w:   await icon(fa.FaCode, "#" + WHITE),
  };

  // ---------- helpers ----------
  // header with icon-in-circle + title on a light slide
  function lightHeader(slide, iconData, circleColor, title, kicker) {
    slide.addShape(pres.shapes.OVAL, { x: 0.6, y: 0.42, w: 0.62, h: 0.62,
      fill: { color: circleColor }, shadow: shadow() });
    slide.addImage({ data: iconData, x: 0.75, y: 0.57, w: 0.32, h: 0.32 });
    if (kicker) slide.addText(kicker.toUpperCase(), { x: 1.42, y: 0.40, w: 11, h: 0.3,
      fontFace: SANS, fontSize: 11, color: MUTED, charSpacing: 2, bold: true, margin: 0 });
    slide.addText(title, { x: 1.42, y: kicker ? 0.66 : 0.5, w: 11.3, h: 0.62,
      fontFace: SERIF, fontSize: 27, color: INK, bold: true, margin: 0 });
  }

  // a code card: array of {t, hot} lines
  function codeCard(slide, x, y, w, h, label, labelColor, tint, lines) {
    slide.addShape(pres.shapes.ROUNDED_RECTANGLE, { x, y, w, h, rectRadius: 0.09,
      fill: { color: tint }, shadow: shadow() });
    // package pill
    const pillW = 0.28 + label.length * 0.105;
    slide.addShape(pres.shapes.ROUNDED_RECTANGLE, { x: x + 0.28, y: y + 0.24, w: pillW, h: 0.42,
      rectRadius: 0.21, fill: { color: labelColor } });
    slide.addText(label, { x: x + 0.28, y: y + 0.24, w: pillW, h: 0.42,
      fontFace: SANS, fontSize: 13, color: WHITE, bold: true, align: "center", valign: "middle", margin: 0 });
    // code
    const runs = lines.map((ln, i) => ({
      text: ln.t === "" ? " " : ln.t,
      options: { color: ln.hot ? CORAL : CODE, bold: !!ln.hot, breakLine: true }
    }));
    slide.addText(runs, { x: x + 0.30, y: y + 0.84, w: w - 0.58, h: h - 1.05,
      fontFace: MONO, fontSize: 12.5, color: CODE, align: "left", valign: "top",
      lineSpacingMultiple: 1.06, margin: 0 });
  }

  // takeaway strip
  function takeaway(slide, y, text) {
    slide.addShape(pres.shapes.ROUNDED_RECTANGLE, { x: 0.6, y, w: W - 1.2, h: 1.0, rectRadius: 0.08,
      fill: { color: "FBF1ED" }, shadow: shadow() });
    slide.addText("TAKEAWAY", { x: 0.92, y: y + 0.16, w: 1.7, h: 0.3,
      fontFace: SANS, fontSize: 12, color: CORAL, bold: true, charSpacing: 2, margin: 0 });
    slide.addText(text, { x: 0.92, y: y + 0.44, w: W - 1.9, h: 0.45,
      fontFace: SANS, fontSize: 14.5, color: "5A3A30", margin: 0, valign: "top" });
  }

  // =================================================================
  // SLIDE 1 — Title
  // =================================================================
  let s = pres.addSlide();
  s.background = { color: DARK };
  // subtle motif: two faint big circles
  s.addShape(pres.shapes.OVAL, { x: 9.7, y: -1.4, w: 5.2, h: 5.2, fill: { color: GG, transparency: 82 } });
  s.addShape(pres.shapes.OVAL, { x: 11.0, y: 3.6, w: 4.6, h: 4.6, fill: { color: TP, transparency: 82 } });
  s.addShape(pres.shapes.OVAL, { x: 0.85, y: 0.85, w: 0.95, h: 0.95, fill: { color: "FFFFFF", transparency: 88 } });
  s.addImage({ data: ic.dna_w, x: 1.07, y: 1.07, w: 0.5, h: 0.5 });
  s.addText("A SIDE-BY-SIDE TEACHING DECK", { x: 0.9, y: 2.15, w: 10, h: 0.35,
    fontFace: SANS, fontSize: 14, color: "AEB7D0", charSpacing: 3, bold: true });
  s.addText("Two grammars, one figure set", { x: 0.85, y: 2.5, w: 11.5, h: 1.0,
    fontFace: SERIF, fontSize: 46, color: WHITE, bold: true });
  s.addText([
    { text: "ggplot2", options: { color: "AAB4E8", bold: true } },
    { text: "  vs  ", options: { color: MUTED } },
    { text: "tidyplots", options: { color: "5FD2C2", bold: true } },
    { text: "   for scRNA-seq visualization", options: { color: "C7CDDD" } },
  ], { x: 0.9, y: 3.6, w: 11.5, h: 0.6, fontFace: SANS, fontSize: 22 });
  s.addText("Same grammar of graphics — opposite ergonomics. Four figures, built both ways.",
    { x: 0.9, y: 4.35, w: 10.5, h: 0.5, fontFace: SANS, fontSize: 15, color: MUTED, italic: true });
  s.addText("Bioinformatics & Research Computing", { x: 0.9, y: 6.7, w: 8, h: 0.4,
    fontFace: SANS, fontSize: 13, color: "6E7798" });

  // =================================================================
  // SLIDE 2 — The big idea (two mental models)
  // =================================================================
  s = pres.addSlide();
  s.background = { color: WHITE };
  lightHeader(s, ic.scale, GG, "Same grammar of graphics, opposite ergonomics", "The big idea");

  function modelCard(x, label, labelColor, tint, lines) {
    s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x, y: 1.5, w: 5.95, h: 3.5, rectRadius: 0.09,
      fill: { color: tint }, shadow: shadow() });
    const pillW = 0.28 + label.length * 0.105;
    s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x: x + 0.3, y: 1.74, w: pillW, h: 0.44,
      rectRadius: 0.22, fill: { color: labelColor } });
    s.addText(label, { x: x + 0.3, y: 1.74, w: pillW, h: 0.44, fontFace: SANS, fontSize: 14,
      color: WHITE, bold: true, align: "center", valign: "middle", margin: 0 });
    s.addText(lines.map(t => ({ text: t, options: { bullet: { indent: 14 }, breakLine: true, paraSpaceAfter: 9 } })),
      { x: x + 0.34, y: 2.42, w: 5.25, h: 2.4, fontFace: SANS, fontSize: 14.5, color: BODY, margin: 0, valign: "top" });
  }
  modelCard(0.6, "ggplot2", GG, GG_TINT, [
    "Map data to aesthetics in aes(), then stack geoms, stats, scales and themes.",
    "Maximum control; more typing.",
    "Stats & significance need helpers (stat_summary, ggsignif, ggpubr).",
    "Faceting via facet_wrap() / facet_grid().",
  ]);
  modelCard(6.75, "tidyplots", TP, TP_TINT, [
    "Pipe a data frame into tidyplot(), then add_<statistic>_<representation>().",
    "Publication-styled defaults out of the box.",
    "Means, error bars and tests are built-in verbs.",
    "Faceting via split_plot(by = ...).",
  ]);
  s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x: 0.6, y: 5.2, w: W - 1.2, h: 1.55, rectRadius: 0.08,
    fill: { color: CARD }, shadow: shadow() });
  s.addImage({ data: ic.code_w, x: 0.95, y: 5.62, w: 0.42, h: 0.42 });
  s.addShape(pres.shapes.OVAL, { x: 0.86, y: 5.53, w: 0.6, h: 0.6, fill: { color: CORAL } });
  s.addImage({ data: ic.code_w, x: 0.99, y: 5.66, w: 0.34, h: 0.34 });
  s.addText("The escape hatch keeps them compatible", { x: 1.7, y: 5.46, w: 11, h: 0.4,
    fontFace: SANS, fontSize: 16, color: INK, bold: true, margin: 0 });
  s.addText([
    { text: "tidyplots is a stats-first on-ramp that never traps you: ", options: { color: BODY } },
    { text: "add(ggplot2::geom_*())", options: { color: GG, fontFace: MONO, bold: true } },
    { text: " drops any tidyplot back into raw ggplot2.", options: { color: BODY } },
  ], { x: 1.7, y: 5.92, w: 11, h: 0.7, fontFace: SANS, fontSize: 14, margin: 0, valign: "top" });

  // =================================================================
  // SLIDE 3 — The dataset
  // =================================================================
  s = pres.addSlide();
  s.background = { color: WHITE };
  lightHeader(s, ic.vials, TP, "A small synthetic scRNA-seq dataset", "The data");

  // left: description card
  s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x: 0.6, y: 1.55, w: 6.4, h: 5.2, rectRadius: 0.09,
    fill: { color: CARD }, shadow: shadow() });
  s.addText("What we simulate", { x: 0.95, y: 1.85, w: 5.7, h: 0.4, fontFace: SERIF, fontSize: 19, color: INK, bold: true, margin: 0 });
  s.addText([
    "4 marker genes — CD3D, MS4A1, LYZ, IL2",
    "3 cell types — T cell, B cell, Monocyte",
    "2 conditions — Control, Stimulated",
    "40 cells per group → 960 rows, tidy long format",
    "Log-normalized expression with realistic noise",
  ].map(t => ({ text: t, options: { bullet: { indent: 14 }, breakLine: true, paraSpaceAfter: 10 } })),
    { x: 0.98, y: 2.4, w: 5.95, h: 2.7, fontFace: SANS, fontSize: 15, color: BODY, margin: 0, valign: "top" });
  s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x: 0.95, y: 5.35, w: 5.7, h: 1.15, rectRadius: 0.08,
    fill: { color: TP_TINT } });
  s.addText([
    { text: "The wired-in effect:  ", options: { color: TP, bold: true } },
    { text: "IL2 is induced by stimulation in T cells — a real signal for the significance test.", options: { color: "245249" } },
  ], { x: 1.2, y: 5.5, w: 5.25, h: 0.9, fontFace: SANS, fontSize: 13.5, margin: 0, valign: "middle" });

  // right: schematic table
  s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x: 7.25, y: 1.55, w: 5.45, h: 5.2, rectRadius: 0.09,
    fill: { color: WHITE }, line: { color: "E2E6F0", width: 1 }, shadow: shadow() });
  s.addText("Tidy long format (one row per cell × gene)", { x: 7.55, y: 1.82, w: 4.9, h: 0.4,
    fontFace: SANS, fontSize: 13, color: MUTED, italic: true, margin: 0 });
  const tdata = [
    ["cell_type","condition","gene","expression"].map(h => ({ text: h, options: { bold: true, color: WHITE, fill: { color: TP }, fontFace: SANS, fontSize: 12, align: "center" } })),
    ["T cell","Stimulated","IL2","2.71"],
    ["T cell","Stimulated","CD3D","3.10"],
    ["B cell","Control","MS4A1","3.04"],
    ["Monocyte","Control","LYZ","3.62"],
    ["T cell","Control","IL2","0.42"],
    ["Monocyte","Stimulated","CD3D","0.18"],
  ];
  s.addTable(tdata, { x: 7.55, y: 2.3, w: 4.85, colW: [1.35,1.4,0.95,1.15],
    fontFace: SANS, fontSize: 11.5, color: BODY, align: "center", valign: "middle",
    border: { type: "solid", pt: 0.5, color: "E6E9F2" }, rowH: 0.42,
    fill: { color: "FBFCFE" } });
  s.addText("Each plot filters or summarises this one frame.", { x: 7.55, y: 5.7, w: 4.9, h: 0.5,
    fontFace: SANS, fontSize: 13.5, color: BODY, italic: true, margin: 0 });

  // =================================================================
  // CODE SLIDES 4-7
  // =================================================================
  function codeSlide(iconData, circleColor, kicker, title, gg, tp, take) {
    const sl = pres.addSlide();
    sl.background = { color: WHITE };
    lightHeader(sl, iconData, circleColor, title, kicker);
    codeCard(sl, 0.6, 1.5, 5.95, 4.05, "ggplot2", GG, GG_TINT, gg);
    codeCard(sl, 6.75, 1.5, 5.95, 4.05, "tidyplots", TP, TP_TINT, tp);
    takeaway(sl, 5.8, take);
    return sl;
  }

  // Plot 1
  codeSlide(ic.bar, GG, "Plot 1", "Points + mean ± SEM + significance test",
    [
      { t: "ggplot(il2, aes(condition," },
      { t: "            expression)) +" },
      { t: "  stat_summary(aes(fill=condition)," },
      { t: '    fun=mean, geom="col", alpha=.4) +' },
      { t: "  stat_summary(fun.data=mean_se," },
      { t: '    geom="errorbar", width=.2) +' },
      { t: "  ggbeeswarm::geom_quasirandom(", hot: true },
      { t: "    aes(color=condition)) +", hot: true },
      { t: "  ggsignif::geom_signif(", hot: true },
      { t: "    map_signif_level=TRUE,", hot: true },
      { t: '    comparisons=list(c("Control",', hot: true },
      { t: '                       "Stimulated")))', hot: true },
    ],
    [
      { t: "il2 |>" },
      { t: "  tidyplot(x=condition," },
      { t: "           y=expression," },
      { t: "           color=condition) |>" },
      { t: "  add_mean_bar(alpha=.4) |>" },
      { t: "  add_sem_errorbar() |>" },
      { t: "  add_data_points_beeswarm() |>" },
      { t: "  add_test_asterisks()", hot: true },
    ],
    "Statistic and visual are named together. Significance is one verb in tidyplots vs. an extra package (ggsignif) plus stat_summary in ggplot2.");

  // Plot 2
  codeSlide(ic.stream, TP, "Plot 2", "Marker-gene violins across cell types (faceting)",
    [
      { t: "ggplot(markers," },
      { t: "  aes(cell_type, expression," },
      { t: "      fill=cell_type)) +" },
      { t: '  geom_violin(scale="width") +' },
      { t: "  geom_boxplot(width=.12) +" },
      { t: "  facet_wrap(~gene,", hot: true },
      { t: '             scales="free_y")', hot: true },
    ],
    [
      { t: "markers |>" },
      { t: "  tidyplot(x=cell_type," },
      { t: "           y=expression," },
      { t: "           color=cell_type) |>" },
      { t: "  add_violin() |>" },
      { t: "  add_boxplot(width=.15) |>" },
      { t: "  split_plot(by=gene)", hot: true },
    ],
    "facet_wrap() keeps one ggplot object; split_plot() returns independent panels you can tune separately. This is the closest the two packages ever feel.");

  // Plot 3
  codeSlide(ic.grid, GG, "Plot 3", "Mean-expression heatmap",
    [
      { t: "# after group_by |> summarise()" },
      { t: "ggplot(heat," },
      { t: "  aes(cell_type, gene," },
      { t: "      fill=mean_expr)) +" },
      { t: "  geom_tile() +" },
      { t: "  scale_fill_viridis_c()", hot: true },
    ],
    [
      { t: "# after group_by |> summarise()" },
      { t: "heat |>" },
      { t: "  tidyplot(x=cell_type, y=gene," },
      { t: "           color=mean_expr) |>" },
      { t: "  add_heatmap()", hot: true },
    ],
    "Both summarise() first. tidyplots brings a sensible continuous scale for free; ggplot2 leaves the palette choice explicitly to you.");

  // Plot 4 — the ceiling. Precompute strip + two cards.
  s = pres.addSlide();
  s.background = { color: WHITE };
  lightHeader(s, ic.braille, CORAL, "The dot plot: where both grammars hit their ceiling", "Plot 4");
  // precompute strip
  s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x: 0.6, y: 1.42, w: W - 1.2, h: 1.18, rectRadius: 0.08,
    fill: { color: "FBF1ED" }, shadow: shadow() });
  s.addText("Shared precompute — two statistics + a per-gene z-score (neither package computes these for you):",
    { x: 0.9, y: 1.54, w: 11.6, h: 0.34, fontFace: SANS, fontSize: 13.5, color: "5A3A30", bold: true, margin: 0 });
  s.addText([
    { text: "dot <- sc |> group_by(gene, cell_type) |> ", options: {} },
    { text: "summarise(pct=mean(expr>0)*100, avg=mean(expr))", options: { color: CORAL, bold: true } },
    { text: " |> group_by(gene) |> ", options: {} },
    { text: "mutate(avg_z = scale(avg))", options: { color: CORAL, bold: true } },
  ], { x: 0.9, y: 1.92, w: 11.6, h: 0.6, fontFace: MONO, fontSize: 12.5, color: CODE, margin: 0, valign: "top" });

  codeCard(s, 0.6, 2.78, 5.95, 2.9, "ggplot2", GG, GG_TINT, [
    { t: "ggplot(dot, aes(cell_type, gene)) +" },
    { t: "  geom_point(aes(size=pct," },
    { t: "                 color=avg_z)) +" },
    { t: "  scale_size_area(max_size=9) +" },
    { t: "  scale_color_gradient2(midpoint=0)" },
    { t: "# natural, but two scales by hand" },
  ]);
  codeCard(s, 6.75, 2.78, 5.95, 2.9, "tidyplots", TP, TP_TINT, [
    { t: "dot |>" },
    { t: "  tidyplot(x=cell_type, y=gene," },
    { t: "           color=avg_z) |>" },
    { t: "  add(ggplot2::geom_point(", hot: true },
    { t: "        ggplot2::aes(size=pct)))", hot: true },
    { t: "# no add_* fits → fall back to ggplot2" },
  ]);
  takeaway(s, 5.82, "Two statistics on one mark → no native add_*. You precompute and drop to ggplot2 via add(). The escape hatch stops being a curiosity and becomes the only way through.");

  // =================================================================
  // SLIDE 8 — Takeaways
  // =================================================================
  s = pres.addSlide();
  s.background = { color: DARK };
  s.addShape(pres.shapes.OVAL, { x: 10.4, y: -1.6, w: 5.0, h: 5.0, fill: { color: TP, transparency: 84 } });
  s.addShape(pres.shapes.OVAL, { x: 0.85, y: 0.7, w: 0.85, h: 0.85, fill: { color: CORAL } });
  s.addImage({ data: ic.bulb_w, x: 1.04, y: 0.89, w: 0.47, h: 0.47 });
  s.addText("When to reach for which", { x: 1.85, y: 0.78, w: 10, h: 0.7,
    fontFace: SERIF, fontSize: 30, color: WHITE, bold: true, valign: "middle", margin: 0 });

  const tk = [
    ["tidyplots", TP, "Teaching, exploration, and standard scientific figures. Statistics-first verbs and publication defaults get students to a clean, correct plot fast."],
    ["ggplot2", "8C96D8", "Full control and anything non-standard. The grammar has no ceiling — every scale, layer and theme is yours to bend."],
    ["both, together", CORAL, "They share an engine. Start tidy, then add(ggplot2::geom_*()) the moment a figure outgrows the add_* model."],
  ];
  let yy = 1.95;
  tk.forEach(([label, col, body]) => {
    s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x: 0.85, y: yy, w: 3.05, h: 1.25, rectRadius: 0.1,
      fill: { color: col } });
    s.addText(label, { x: 0.85, y: yy, w: 3.05, h: 1.25, fontFace: SANS, fontSize: 18,
      color: label === "tidyplots" || label === "both, together" ? WHITE : DARK, bold: true,
      align: "center", valign: "middle", margin: 0 });
    s.addText(body, { x: 4.15, y: yy, w: 8.4, h: 1.25, fontFace: SANS, fontSize: 15,
      color: "D7DCEC", valign: "middle", margin: 0 });
    yy += 1.45;
  });

  s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x: 0.85, y: 6.35, w: W - 1.7, h: 0.82, rectRadius: 0.08,
    fill: { color: "1F2540" } });
  s.addText([
    { text: "The line that writes itself:  ", options: { color: CORAL, bold: true } },
    { text: "high-level grammars are wonderful until a figure encodes multiple derived quantities — and the dot plot is the canonical scRNA-seq case where that happens.", options: { color: "C7CDE2", italic: true } },
  ], { x: 1.15, y: 6.35, w: W - 2.3, h: 0.82, fontFace: SANS, fontSize: 13.5, valign: "middle", margin: 0 });

  await pres.writeFile({ fileName: "ggplot2_vs_tidyplots_slides.pptx" });
  console.log("written");
})();
