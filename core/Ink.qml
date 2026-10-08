pragma Singleton
import QtQuick
import qs.Commons
import "InkMath.js" as InkMath

// Paper, four inks and one red, derived live from the Omarchy theme
// (colors.toml via qs.Commons.Color). Nothing in Hanko picks its own colour:
// every surface, line and glyph reads one of these.
QtObject {
  id: root

  readonly property string _fg: String(Color.foreground)
  readonly property string _bg: String(Color.background)
  readonly property var _ramp: InkMath.ramp(_fg, _bg)

  // The page every part of the bar is printed on.
  readonly property color paper: Color.background
  readonly property color ink: _ramp.ink
  readonly property color inkDim: _ramp.inkDim
  readonly property color inkMuted: _ramp.inkMuted
  readonly property color inkFaint: _ramp.inkFaint
  // Red means "you" or "now": the seal, the now-notch, urgent, unread.
  readonly property color seal: Color.urgent

  // Inversion plates: the selected thing turns into solid ink.
  readonly property color bone: Color.foreground
  readonly property color boneInk: Color.background

  // Hairlines are the foreground at a fixed alpha, so they sit on glass too.
  readonly property color line: alpha(Color.foreground, 0.22)
  readonly property color lineSoft: alpha(Color.foreground, 0.10)
  readonly property color lineStrong: alpha(Color.foreground, 0.40)

  readonly property bool light: InkMath.isLight(_bg)

  // Kata 型 (core/Kata.js): the tones every design's parts are drawn in.
  readonly property var _kata: InkMath.kata(_fg, _bg)
  readonly property color ink2: _kata.ink2
  readonly property color ink3: _kata.ink3
  readonly property color ink4: _kata.ink4
  readonly property color kLine: _kata.line
  readonly property color lift: _kata.lift
  readonly property color paper2: _kata.paper2
  readonly property color sunk: _kata.sunk
  // Leaf's card: the cut edge catches light, the underside is in shade, and
  // shadows are hard (offset, never blurred).
  readonly property color cut: light ? Qt.rgba(1, 1, 1, 0.95) : alpha(Color.foreground, 0.11)
  readonly property color edge: light ? alpha(Color.foreground, 0.2) : Qt.rgba(0, 0, 0, 0.7)
  readonly property color edgeSide: alpha(Color.foreground, light ? 0.1 : 0.06)
  readonly property color shade: light ? alpha(Color.foreground, 0.17) : Qt.rgba(0, 0, 0, 0.6)
  readonly property color shade2: light ? alpha(Color.foreground, 0.07) : Qt.rgba(0, 0, 0, 0.3)
  readonly property color shadeIn: light ? alpha(Color.foreground, 0.2) : Qt.rgba(0, 0, 0, 0.65)
  // A score is a crease: a dark line with a light one under it.
  readonly property color scoreDark: light ? alpha(Color.foreground, 0.15) : Qt.rgba(0, 0, 0, 0.6)
  readonly property color scoreLight: light ? Qt.rgba(1, 1, 1, 0.9) : alpha(Color.foreground, 0.07)

  function alpha(c, a) {
    return Qt.rgba(c.r, c.g, c.b, a)
  }

  // Glass is the paper at 74% (COMPONENTS.md, surface: glass).
  function paperAt(a) {
    return alpha(paper, a)
  }
}
