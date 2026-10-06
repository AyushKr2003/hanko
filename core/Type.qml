pragma Singleton
import QtQuick
import qs.Commons

// Three faces with fixed jobs, plus the system's CJK faces for kanji.
//   display  Fraunces: the clock, titles, bylines (bundled, OFL)
//   text     Space Grotesk: values and language (bundled, OFL)
//   mono     your Omarchy monospace (`omarchy font set`): labels and keys
//   jp/jpSerif  Noto CJK, which Omarchy installs (noto-fonts-cjk)
QtObject {
  id: root

  readonly property FontLoader _fraunces: FontLoader { source: Qt.resolvedUrl("../assets/fonts/Fraunces.ttf") }
  readonly property FontLoader _frauncesItalic: FontLoader { source: Qt.resolvedUrl("../assets/fonts/Fraunces-Italic.ttf") }
  readonly property FontLoader _grotesk: FontLoader { source: Qt.resolvedUrl("../assets/fonts/SpaceGrotesk.ttf") }

  readonly property string display: _fraunces.status === FontLoader.Ready ? _fraunces.name : "serif"
  readonly property string text: _grotesk.status === FontLoader.Ready ? _grotesk.name : "sans-serif"
  readonly property string mono: Style.font.family || "monospace"
  readonly property string jp: "Noto Sans CJK JP"
  readonly property string jpSerif: "Noto Serif CJK JP"

  // The Typeset mockups were drawn at Omarchy's default 12px base; everything
  // scales with `[font] base-size` like the rest of the shell.
  readonly property real scale: Style.font.body / 12

  function px(v) {
    return Math.round(v * scale)
  }
}
