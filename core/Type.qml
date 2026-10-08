pragma Singleton
import QtQuick
import qs.Commons
import "Style.js" as HankoStyle

// Three faces with fixed jobs, plus the system's CJK faces for kanji.
//   display  Fraunces: the clock, titles, bylines (bundled, OFL)
//   text     Space Grotesk: values and language (bundled, OFL)
//   mono     your Omarchy monospace (`omarchy font set`): labels and keys
//   jp/jpSerif  Yuji Boku, a brush face (bundled, OFL), with Noto CJK behind it
QtObject {
  id: root

  readonly property FontLoader _fraunces: FontLoader { source: Qt.resolvedUrl("../assets/fonts/Fraunces.ttf") }
  readonly property FontLoader _frauncesItalic: FontLoader { source: Qt.resolvedUrl("../assets/fonts/Fraunces-Italic.ttf") }
  readonly property FontLoader _grotesk: FontLoader { source: Qt.resolvedUrl("../assets/fonts/SpaceGrotesk.ttf") }
  // Yuji Boku (OFL), a brushed face: every kanji Hanko draws is written,
  // not typeset. Subset to the kanji and kana Hanko uses; anything else (a
  // glyph you type yourself) falls back to Noto CJK.
  readonly property FontLoader _brush: FontLoader { source: Qt.resolvedUrl("../assets/fonts/YujiBoku.ttf") }

  readonly property string display: _fraunces.status === FontLoader.Ready ? _fraunces.name : "serif"
  readonly property string text: _grotesk.status === FontLoader.Ready ? _grotesk.name : "sans-serif"
  readonly property string mono: Style.font.family || "monospace"
  readonly property string brush: _brush.status === FontLoader.Ready ? _brush.name : "Noto Serif CJK JP"
  // Both kanji faces are the brush now, glosses and seals alike, so the
  // bar's Japanese reads as one hand.
  readonly property string jp: brush
  readonly property string jpSerif: brush

  // The Typeset mockups were drawn at Omarchy's default 12px base; everything
  // scales with `[font] base-size` like the rest of the shell, times the
  // style's type size (small, regular, large).
  readonly property real scale: Style.font.body / 12 * (HankoStyle.TYPE_SCALE[Typeset.current.typeSize] || 1)

  function px(v) {
    return Math.round(v * scale)
  }

  // The type scale. The mockups were drawn at 2x, where an 8px label is
  // sixteen device pixels; on a 1x panel it is eight, too few to read. So
  // nothing anyone has to read sits under 10px at regular size, decoration
  // under 9, and small sizes never fall under those floors at any scale.
  //   tag      mono 9    keycaps, corner tags: decoration only
  //   label    mono 10   bar labels (NET, VOL), date stack, row notes, options
  //   eyebrow  mono 11   section heads (// OUTPUT), sheet heads, buttons
  //   figure   mono 12   numbers set in mono: row indexes, offsets, counts
  //   note     text 12   descriptions and details
  //   value    text 13   the bar's values
  //   row      text 14   a row's name in sheets, the scroll and settings
  //   byline   display 15, clock 22, title 40, hero 46
  //   gloss    jp 11     kanji beside a label (brush: a step over the caps)
  //   glossMid jp 12     kanji on their own (sheet heads, index plate, options)
  //   glossBig jp 13     section kanji
  function floored(v, min) {
    return Math.max(min, px(v))
  }
  readonly property int tag: floored(9, 8)
  readonly property int label: floored(10, 9)
  readonly property int eyebrow: floored(11, 10)
  readonly property int figure: floored(12, 10)
  readonly property int note: floored(12, 10)
  readonly property int value: px(13)
  readonly property int row: px(14)
  readonly property int byline: px(15)
  readonly property int clock: px(22)
  readonly property int title: px(40)
  readonly property int hero: px(46)
  // The brush's hairlines need a few more pixels than a sans to survive at
  // 1x, so glosses are set a step larger than the caps they sit beside.
  readonly property int gloss: floored(11, 10)
  readonly property int glossMid: floored(12, 11)
  readonly property int glossBig: px(13)

  // Tracking for caps, in proportion to the size it spaces.
  readonly property real trackTag: tag * 0.1
  readonly property real trackLabel: label * 0.14
  readonly property real trackEyebrow: eyebrow * 0.2
  readonly property real trackFigure: figure * 0.05

  // Labels and values are Medium, as Ryoku's settings set theirs: Regular
  // reads grey at 1x on dark paper. A mono face without a Medium cut
  // falls back to its Regular.
  readonly property int labelWeight: Font.Medium
  readonly property int valueWeight: Font.Medium
  // Space Grotesk is variable too: its weight goes on the axis as well.
  readonly property var valueAxes: ({ "wght": 500 })

  // Fraunces is variable: its optical size follows the size it is set at
  // (sturdier hairlines when small), and the weight must be given here and
  // as font.weight: Font.Normal, or it renders bold.
  // Kata's skins also set the SOFT axis (skin.soft: 30 for paper, 0 cut sharp).
  function axes(size, wght, soft) {
    var a = { "opsz": Math.max(9, Math.min(144, size)), "wght": wght === undefined ? 400 : wght }
    if (soft !== undefined) a["SOFT"] = soft
    return a
  }
}
