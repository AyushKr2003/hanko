import QtQuick
import "../../core"

// One band of mist (Kasumi 霞): the suyari-gasumi of Yamato-e scrolls and
// gold screens, a long flat cloud with a lip above and below set in from
// its ends, rounded off. It reaches as far across the sheet as its level
// (never shorter than `shortest`, so the shape survives), in from the left
// or, `fromRight`, from the right. Gilt, it is gold leaf (the theme's
// foreground), its faint seams showing the squares of leaf laid edge to
// edge; not gilt, a thin mist with no gold. `sealed` presses a small red seal
// on its far end. Settable: a click or a drag along the band draws it to
// there, the wheel five per cent at a time.
Item {
  id: root

  property real level: 0
  property bool gilt: true
  property bool lead: false
  property bool sealed: false
  property bool fromRight: false
  property bool settable: false
  property bool clickable: false
  property string name: ""
  property string note: ""
  property color noteColor: sealed ? Ink.seal : Ink.inkMuted
  // The shortest band still holds its name (but never more than half the sheet).
  readonly property real shortest: Math.min(width * 0.5, Math.max(Type.px(84), title.implicitWidth + Type.px(sealed || lead ? 58 : 40)))
  readonly property real len: Math.max(shortest, width * Math.max(0, Math.min(1, level)))
  readonly property bool full: len >= width - Type.px(60)
  signal picked(real level)

  // Te 手 (core/Cursor.js): a band you can set or press is a stop.
  readonly property bool keyStop: settable || clickable
  readonly property bool keyStep: settable
  function keyAdjust(d) { root.picked(Math.max(0, Math.min(1, root.level + d * 0.05))) }
  function keyPress() { if (root.clickable) root.clicked() }
  signal clicked()

  height: Type.px(lead ? 40 : 34)

  Canvas {
    id: mist
    x: root.fromRight ? root.width - width : 0
    width: root.len
    height: root.height - Type.px(4)
    onWidthChanged: requestPaint()
    Behavior on width {
      enabled: Motion.live
      NumberAnimation { duration: Motion.ms(180); easing.type: Easing.OutCubic }
    }
    onPaint: {
      var g = getContext("2d"), L = width, H = height
      g.reset()
      function cap(x0, y0, x1, h) {
        var r = h / 2
        g.moveTo(x0 + r, y0)
        g.lineTo(x1 - r, y0)
        g.arc(x1 - r, y0 + r, r, -Math.PI / 2, Math.PI / 2, false)
        g.lineTo(x0 + r, y0 + h)
        g.arc(x0 + r, y0 + r, r, Math.PI / 2, Math.PI * 1.5, false)
      }
      g.beginPath()
      // The body, and a lip above and below, set in from the ends.
      cap(0, H * 0.24, L, H * 0.52)
      g.closePath()
      cap(root.fromRight ? L * 0.16 : L * 0.08, 0, root.fromRight ? L * 0.92 : L * 0.78, H * 0.46)
      g.closePath()
      cap(root.fromRight ? L * 0.04 : L * 0.22, H * 0.54, root.fromRight ? L * 0.7 : L * 0.96, H * 0.46)
      g.closePath()
      if (root.gilt) {
        g.fillStyle = Ink.alpha(Ink.bone, root.lead ? 0.9 : 0.62)
        g.fill()
        // Leaf squares: the faint seams of gold leaf laid edge to edge.
        g.save(); g.clip()
        g.strokeStyle = Ink.alpha(Ink.boneInk, 0.07); g.lineWidth = 1
        for (var x = Type.px(22); x < L; x += Type.px(22)) { g.beginPath(); g.moveTo(x, 0); g.lineTo(x, H); g.stroke() }
        g.restore()
      } else {
        // Not gilt: a thin mist, the gold not yet laid.
        g.fillStyle = Ink.alpha(Ink.bone, 0.1)
        g.fill()
      }
    }
  }
  Text {
    id: title
    x: mist.x + Type.px(18)
    width: Math.max(0, mist.width - Type.px(root.sealed || root.lead ? 52 : 36) - (root.full ? noteIn.width + Type.px(12) : 0))
    anchors.verticalCenter: mist.verticalCenter
    elide: Text.ElideRight
    text: root.name
    color: root.gilt ? Ink.boneInk : Ink.inkMuted
    font.family: Type.display
    font.italic: true
    font.pixelSize: Type.px(root.lead ? 17 : 15)
    font.weight: Font.Normal
    font.variableAxes: Type.axes(Type.px(root.lead ? 17 : 15), 380)
  }
  // The note sits in the open paper beyond the band…
  Text {
    visible: !root.full && text !== ""
    width: Math.min(implicitWidth, root.width - mist.width - Type.px(10))
    elide: Text.ElideRight
    x: root.fromRight ? mist.x - width - Type.px(10) : mist.x + mist.width + Type.px(10)
    anchors.verticalCenter: mist.verticalCenter
    text: root.note.toUpperCase()
    color: root.noteColor
    font.family: Type.mono
    font.pixelSize: Type.tag
    font.letterSpacing: Type.trackTag
  }
  // …or, on a band across the whole sheet, inside its far end.
  Text {
    id: noteIn
    visible: root.full && text !== ""
    x: mist.x + mist.width - width - Type.px(root.sealed || root.lead ? 40 : 18)
    anchors.verticalCenter: mist.verticalCenter
    text: root.note.toUpperCase()
    color: root.gilt ? Ink.alpha(Ink.boneInk, 0.7) : Ink.inkMuted
    font.family: Type.mono
    font.pixelSize: Type.tag
    font.letterSpacing: Type.trackTag
  }
  // The seal pressed on the band in use.
  Rectangle {
    visible: root.sealed
    x: mist.x + mist.width - width - Type.px(16)
    anchors.verticalCenter: mist.verticalCenter
    width: Type.px(14); height: width; radius: 1
    color: Ink.seal
    Rectangle { anchors.fill: parent; anchors.margins: Type.px(2); color: "transparent"; border.width: 1; border.color: Ink.alpha(Ink.paper, 0.5) }
  }

  MouseArea {
    anchors.fill: parent
    enabled: root.settable || root.clickable
    cursorShape: Qt.PointingHandCursor
    function at(x) {
      var v = (root.fromRight ? root.width - x : x) / Math.max(1, root.width)
      return Math.max(0, Math.min(1, v))
    }
    onPressed: function(m) { if (root.settable) root.picked(at(m.x)) }
    onPositionChanged: function(m) { if (root.settable && pressed) root.picked(at(m.x)) }
    onClicked: if (!root.settable) root.clicked()
    onWheel: function(w) {
      if (root.settable) root.picked(Math.max(0, Math.min(1, root.level + (w.angleDelta.y > 0 ? 0.05 : -0.05))))
    }
  }
}
