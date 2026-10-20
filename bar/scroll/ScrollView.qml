pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Scroll.js" as Scroll
import "../../core/Weather.js" as Wx
import "../../core/Leaf.js" as LeafJs
import "../../core/Densho.js" as Densho

// The handscroll 巻 (docs/COMPONENTS.md, "Panels"; panels: scroll): one
// long paper, its eight sections side by side with an interlude between
// each two (Interlude.qml); sections fade out at the side edges so the
// neighbours always show, and the edges are bare or curl under (`sides`). An index plate names every section
// (the one in the middle inverted), and a position bar runs along the foot;
// `guides` shows both, either or neither.
// Pure QtQuick: bar/ScrollWindow.qml drives the motion and feeds live data;
// the harness renders it still.
Item {
  id: root

  // The section on the plate.
  property int current: 0
  // The track's x inside the view; ScrollWindow pans it. By default the
  // current section sits in the middle.
  property real trackX: Scroll.centred(current, view.width, Type.scale)
  // The bar is at the bottom: the scroll hangs upward, the plate below.
  property bool atBottom: false
  // 0..1: how far the paper has unrolled, and how far the ink has come in.
  property real reveal: 1
  property real ink: 1
  // Panel opacity (Style.js panelOpacity), 0..1.
  property real paperOpacity: 1
  // The sheets' feed (now, zones, timeShift, sound, network, bluetooth,
  // power, display, letters, dnd) plus spaces, weather and weatherShown,
  // and the end leaf's: leaf (services/Leaf.qml reading), endShown, font,
  // version, preset, switches ({awake, night, dnd}) and sealGlyph.
  property var feed: ({})
  // What sits between sections (Style.js `interlude`).
  property string divider: "seal"
  // Which leaf sits after Inbox (Style.js `endleaf`).
  property string endleaf: "koyomi"
  // The side edges (Style.js `sides`): bare or curl.
  property string sides: "curl"
  // The index plate and the position bar (Style.js `guides`): both, tabs,
  // foot or none.
  property string guides: "both"
  // Densho 伝書 (Style.js arrival, letters, faults, order; docs/densho on
  // the design-densho branch).
  property string arrival: "fade"
  property string letters: "open"
  property string faults: "plain"
  property string order: "emaki"
  // How far the brush may write (arrival: brush): ScrollWindow runs it
  // 0 -> 1 as the paper opens and after a stance; the harness fixes it.
  property real writeIn: 1
  // 0..1: the stance a jump cuts to (order: mokuroku), the sign of section
  // `stanceAt` held alone over the paper.
  property real stance: 0
  property int stanceAt: 0
  // 0..1: the cut, a hairline at the depth the paper will reach, held for
  // the beat before the Iai draw (order: mokuroku).
  property real cut: 0
  // The colophon's second seal is pressed: the scroll is rolling up.
  property bool sealed: false
  // The first letter's warmth under letters: sealed, for the harness (-1:
  // the pointer decides).
  property real warmed: -1

  readonly property bool brush: arrival === "brush"
  readonly property bool mokuroku: order === "mokuroku"
  // How far the brush has written what sits at track x `x`, `w` wide.
  function writeAtX(x, w) {
    if (!brush) return 1
    return Math.min(writeIn, Densho.writeAt(trackX + x + w / 2 - view.width / 2, view.width / 2))
  }
  function writeOf(i) { return writeAtX(layout.xs[i], layout.widths[i]) }
  function poemOf(i) { return mokuroku ? sections[i].poem : "" }
  function faultOf(key) { return faults === "seam" && Densho.faultOf(key, feed) }

  signal request(string section, string what, var arg)
  // A name on the index plate was clicked.
  signal picked(int index)
  // The paper is being dragged sideways (dx since the press), let go at
  // `velocity` px/s, or wheeled a step (+1 on, -1 back).
  signal dragged(real dx)
  signal released(real velocity)
  signal stepped(int delta)

  readonly property var sections: Scroll.SECTIONS
  readonly property var layout: Scroll.layout(Type.scale)
  readonly property int interlude: Math.round(Scroll.INTERLUDE * Type.scale)
  // The weather leaf's width: the bare paper left of Time while Time is in
  // the middle (0 when the view is too narrow, or the leaf is hidden).
  readonly property int leafWidth: !root.mokuroku && root.feed.weatherShown === false ? 0
    : Wx.leafWidth(view.width, layout.widths[0], interlude, Type.scale)

  // The end leaf's width: the bare paper right of Inbox while Inbox is in
  // the middle, the weather leaf's twin.
  readonly property int endWidth: !root.mokuroku && root.feed.endShown === false ? 0
    : Wx.leafWidth(view.width, layout.widths[layout.widths.length - 1], interlude, Type.scale)

  implicitHeight: Type.px(460)

  // The cut (order: mokuroku): where the paper will stop, before it moves.
  Rectangle {
    visible: root.cut > 0
    opacity: root.cut
    y: root.atBottom ? 0 : root.height - 1
    width: root.width
    height: 1
    gradient: Gradient {
      orientation: Gradient.Horizontal
      GradientStop { position: 0; color: Ink.alpha(Ink.bone, 0) }
      GradientStop { position: 0.15; color: Ink.bone }
      GradientStop { position: 0.85; color: Ink.bone }
      GradientStop { position: 1; color: Ink.alpha(Ink.bone, 0) }
    }
  }

  // The unrolled part: the paper grows away from the bar.
  Item {
    id: press
    width: parent.width
    height: Math.round(root.height * root.reveal)
    y: root.atBottom ? root.height - height : 0
    clip: true

    Item {
      id: paper
      width: root.width
      height: root.height
      y: root.atBottom ? press.height - root.height : 0

      Rectangle { anchors.fill: parent; color: Ink.alpha(Ink.paper, root.paperOpacity) }
      // A hairline on the free edge, none against the bar; the sides are
      // drawn below (Style.js `sides`).
      Rectangle { y: root.atBottom ? 0 : parent.height - 1; width: parent.width; height: 1; color: Ink.line }

      // ------------------------------------------------------ the paper
      Item {
        id: view
        x: Type.px(26)
        width: parent.width - 2 * x
        height: parent.height
        clip: true
        opacity: root.ink * (1 - root.stance)

        // Behind the sections: a drag anywhere on bare paper pans it, and
        // the wheel steps a section at a time. Controls on top keep theirs.
        MouseArea {
          anchors.fill: parent
          cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
          preventStealing: true
          property real startX: 0
          property real lastX: 0
          property real lastT: 0
          property real speed: 0
          onPressed: function(mouse) { startX = lastX = mouse.x; lastT = Date.now(); speed = 0 }
          onPositionChanged: function(mouse) {
            var t = Date.now()
            if (t > lastT) speed = 0.6 * speed + 0.4 * (mouse.x - lastX) * 1000 / (t - lastT)
            lastX = mouse.x
            lastT = t
            root.dragged(mouse.x - startX)
          }
          onReleased: root.released(Date.now() - lastT > 80 ? 0 : speed)
          onWheel: function(wheel) {
            var d = Math.abs(wheel.angleDelta.x) > Math.abs(wheel.angleDelta.y) ? -wheel.angleDelta.x : -wheel.angleDelta.y
            if (d !== 0) root.stepped(d > 0 ? 1 : -1)
          }
        }

        Item {
          id: track
          x: Math.round(root.trackX)
          width: root.layout.width
          height: view.height

          // Before Time, on paper that is otherwise bare: the weather leaf
          // and an interlude between it and the day.
          WeatherLeaf {
            visible: root.leafWidth > 0 && !root.mokuroku
            x: root.layout.xs[0] - root.interlude - width
            width: root.leafWidth
            height: track.height
            weather: root.feed.weather || null
            brush: root.brush
            write: root.writeAtX(x, width)
          }
          DenshoLeaf {
            visible: root.leafWidth > 0 && root.mokuroku
            kind: "house"
            x: root.layout.xs[0] - root.interlude - width
            width: root.leafWidth
            height: track.height
            now: root.feed.now || new Date()
            reading: root.feed.leaf || ({})
            version: root.feed.version || ""
            preset: root.feed.preset || ""
            sealGlyph: root.feed.sealGlyph || "鑑"
            brush: root.brush
            write: root.writeAtX(x, width)
          }
          Interlude {
            visible: root.leafWidth > 0
            seed: 11
            style: root.divider
            x: root.layout.xs[0] - width
            y: Type.px(64)
            width: root.interlude
            height: track.height - Type.px(98)
          }

          TimeSection {
            x: root.layout.xs[0]; width: root.layout.widths[0]; height: track.height
            brush: root.brush; write: root.writeOf(0); poem: root.poemOf(0)
            info: root.sections[0]
            now: root.feed.now || new Date()
            zones: root.feed.zones || []
            shift: root.feed.timeShift || 0
            onRequest: function(what, arg) { root.request("time", what, arg) }
          }
          SoundSection {
            x: root.layout.xs[1]; width: root.layout.widths[1]; height: track.height
            brush: root.brush; write: root.writeOf(1); poem: root.poemOf(1)
            info: root.sections[1]
            sound: root.feed.sound || null
            onRequest: function(what, arg) { root.request("sound", what, arg) }
          }
          NetworkSection {
            x: root.layout.xs[2]; width: root.layout.widths[2]; height: track.height
            brush: root.brush; write: root.writeOf(2); poem: root.poemOf(2)
            fault: root.faultOf("network")
            info: root.sections[2]
            net: root.feed.network || null
            onRequest: function(what, arg) { root.request("network", what, arg) }
          }
          BluetoothSection {
            x: root.layout.xs[3]; width: root.layout.widths[3]; height: track.height
            brush: root.brush; write: root.writeOf(3); poem: root.poemOf(3)
            info: root.sections[3]
            blue: root.feed.bluetooth || null
            onRequest: function(what, arg) { root.request("bluetooth", what, arg) }
          }
          PowerSection {
            x: root.layout.xs[4]; width: root.layout.widths[4]; height: track.height
            brush: root.brush; write: root.writeOf(4); poem: root.poemOf(4)
            fault: root.faultOf("power")
            info: root.sections[4]
            power: root.feed.power || null
            onRequest: function(what, arg) { root.request("power", what, arg) }
          }
          DisplaySection {
            x: root.layout.xs[5]; width: root.layout.widths[5]; height: track.height
            brush: root.brush; write: root.writeOf(5); poem: root.poemOf(5)
            info: root.sections[5]
            display: root.feed.display || null
            onRequest: function(what, arg) { root.request("display", what, arg) }
          }
          SpacesSection {
            x: root.layout.xs[6]; width: root.layout.widths[6]; height: track.height
            brush: root.brush; write: root.writeOf(6); poem: root.poemOf(6)
            info: root.sections[6]
            spaces: root.feed.spaces || []
            onRequest: function(what, arg) { root.request("spaces", what, arg) }
          }
          InboxSection {
            x: root.layout.xs[7]; width: root.layout.widths[7]; height: track.height
            brush: root.brush; write: root.writeOf(7); poem: root.poemOf(7)
            sealed: root.letters === "sealed"
            warmed: root.warmed
            info: root.sections[7]
            letters: root.feed.letters || []
            dnd: !!root.feed.dnd
            now: root.feed.now || new Date()
            onRequest: function(what, arg) { root.request("inbox", what, arg) }
          }

          // After Inbox, on paper that is otherwise bare: an interlude and
          // the end leaf.
          Interlude {
            visible: root.endWidth > 0
            seed: root.sections.length - 1
            after: root.mokuroku ? ({ no: "09", jp: "奥", label: "COLOPHON" })
              : ({ no: "09", jp: LeafJs.kindOf(root.endleaf).jp, label: LeafJs.kindOf(root.endleaf).label })
            style: root.divider
            x: root.layout.xs[root.sections.length - 1] + root.layout.widths[root.sections.length - 1]
            y: Type.px(64)
            width: root.interlude
            height: track.height - Type.px(98)
          }
          DenshoLeaf {
            visible: root.endWidth > 0 && root.mokuroku
            kind: "colophon"
            x: root.layout.xs[root.sections.length - 1] + root.layout.widths[root.sections.length - 1] + root.interlude
            width: root.endWidth
            height: track.height
            now: root.feed.now || new Date()
            reading: root.feed.leaf || ({})
            preset: root.feed.preset || ""
            sealGlyph: root.feed.sealGlyph || "鑑"
            sealed: root.sealed
            brush: root.brush
            write: root.writeAtX(x, width)
          }
          EndLeaf {
            visible: root.endWidth > 0 && !root.mokuroku
            x: root.layout.xs[root.sections.length - 1] + root.layout.widths[root.sections.length - 1] + root.interlude
            width: root.endWidth
            height: track.height
            kind: root.endleaf
            now: root.feed.now || new Date()
            reading: root.feed.leaf || ({})
            font: root.feed.font || Type.mono
            version: root.feed.version || ""
            preset: root.feed.preset || ""
            switches: root.feed.switches || ({})
            sealGlyph: root.feed.sealGlyph || "判"
            sections: root.sections.length
            onRequest: function(what, arg) { root.request("leaf", what, arg) }
          }

          // Interludes, in the gaps between sections.
          Repeater {
            model: root.sections.length - 1
            Interlude {
              id: sliver
              required property int index
              seed: sliver.index
              style: root.divider
              x: root.layout.xs[sliver.index] + root.layout.widths[sliver.index]
              y: Type.px(64)
              width: Math.round(Scroll.INTERLUDE * Type.scale)
              height: track.height - Type.px(98)
            }
          }
        }

        // Sections fade out at the side edges: the paper fades into itself.
        Rectangle {
          width: Type.px(120)
          height: parent.height
          gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.08; color: Ink.alpha(Ink.paper, root.paperOpacity) }
            GradientStop { position: 1; color: Ink.alpha(Ink.paper, 0) }
          }
        }
        Rectangle {
          x: parent.width - width
          width: Type.px(120)
          height: parent.height
          gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Ink.alpha(Ink.paper, 0) }
            GradientStop { position: 0.92; color: Ink.alpha(Ink.paper, root.paperOpacity) }
          }
        }
      }

      // ------------------------------------------------------ the stance
      // A jump under order: mokuroku cuts here first: the section's sign,
      // large and alone, its number and poetic name set vertically beside
      // it, a hairline across, held for Densho.STANCE_MS.
      Item {
        id: stanceCard
        visible: root.stance > 0
        anchors.fill: parent
        opacity: root.stance
        readonly property var sign: root.sections[Math.max(0, Math.min(root.sections.length - 1, root.stanceAt))]
        Rectangle {
          anchors.verticalCenter: parent.verticalCenter
          x: parent.width * 0.12
          width: parent.width * 0.76
          height: 1
          gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Ink.alpha(Ink.bone, 0) }
            GradientStop { position: 0.2; color: Ink.alpha(Ink.bone, 0.7) }
            GradientStop { position: 0.8; color: Ink.alpha(Ink.bone, 0.7) }
            GradientStop { position: 1; color: Ink.alpha(Ink.bone, 0) }
          }
        }
        Row {
          anchors.centerIn: parent
          spacing: Type.px(22)
          Text {
            text: stanceCard.sign.jp
            color: Ink.ink
            font.family: Type.brush
            font.pixelSize: Type.px(260)
            lineHeight: 1
            lineHeightMode: Text.ProportionalHeight
          }
          Vertical {
            y: Type.px(34)
            text: stanceCard.sign.no + " · " + stanceCard.sign.label
            color: Ink.inkMuted
            family: Type.mono
            size: Type.eyebrow
            tracking: Type.trackEyebrow
          }
          Vertical {
            y: Type.px(34)
            text: stanceCard.sign.poem
            color: Ink.inkFaint
            family: Type.display
            italic: true
            size: Type.px(20)
          }
        }
      }

      // ------------------------------------------------------ the sides
      // Style.js `sides` (docs/revision3 on the docs branch; they replaced
      // the rollers): bare leaves the paper to fade out on its own, curl
      // shades each edge as if the paper rolls under there.
      Rectangle {
        visible: root.sides === "curl"
        width: Type.px(22)
        height: paper.height
        gradient: Gradient {
          orientation: Gradient.Horizontal
          GradientStop { position: 0; color: Ink.alpha(Ink.ink, 0.16) }
          GradientStop { position: 0.35; color: Ink.alpha(Ink.ink, 0.05) }
          GradientStop { position: 0.6; color: Ink.alpha(Ink.ink, 0.02) }
          GradientStop { position: 1; color: Ink.alpha(Ink.ink, 0) }
        }
      }
      Rectangle {
        visible: root.sides === "curl"
        x: paper.width - width
        width: Type.px(22)
        height: paper.height
        gradient: Gradient {
          orientation: Gradient.Horizontal
          GradientStop { position: 0; color: Ink.alpha(Ink.ink, 0) }
          GradientStop { position: 0.4; color: Ink.alpha(Ink.ink, 0.02) }
          GradientStop { position: 0.65; color: Ink.alpha(Ink.ink, 0.05) }
          GradientStop { position: 1; color: Ink.alpha(Ink.ink, 0.16) }
        }
      }

      // ------------------------------------------------------ index plate
      Rectangle {
        id: plate
        visible: root.guides === "both" || root.guides === "tabs"
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.atBottom ? paper.height - Type.px(14) - height : Type.px(14)
        width: names.width + 2 * Type.px(3)
        height: names.height + 2 * Type.px(3)
        radius: 4
        color: Ink.paper
        border.width: 1
        border.color: Ink.line
        opacity: root.ink

        Row {
          id: names
          x: Type.px(3)
          y: Type.px(3)
          spacing: 2
          Repeater {
            model: root.sections
            Rectangle {
              id: entry
              required property var modelData
              required property int index
              readonly property bool on: index === root.current
              width: entryRow.width + 2 * Type.px(9)
              height: entryRow.height + 2 * Type.px(4)
              radius: 2
              color: on ? Ink.bone : "transparent"
              Behavior on color { enabled: !Motion.still; ColorAnimation { duration: Motion.slide } }
              Row {
                id: entryRow
                anchors.centerIn: parent
                spacing: Type.px(5)
                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: entry.modelData.jp
                  color: entry.on ? Ink.boneInk : Ink.inkMuted
                  font.family: Type.jp
                  font.pixelSize: Type.px(10)
                }
                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: entry.modelData.no + " " + entry.modelData.label
                  color: entry.on ? Ink.boneInk : Ink.inkMuted
                  font.family: Type.mono
                  font.pixelSize: Type.label
                  font.weight: Type.labelWeight
                  font.letterSpacing: Type.trackLabel
                }
              }
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.picked(entry.index)
              }
            }
          }
        }
      }

      // ------------------------------------------------------ the foot
      Item {
        id: foot
        visible: root.guides === "both" || root.guides === "foot"
        x: Type.px(40)
        width: paper.width - 2 * x
        height: Type.px(16)
        y: root.atBottom ? Type.px(12) : paper.height - Type.px(12) - height
        opacity: root.ink

        Row {
          id: footLeft
          anchors.verticalCenter: parent.verticalCenter
          spacing: Type.px(4)
          Key { label: "H" }
          Key { label: "L" }
          Label { text: "Pan"; leftPadding: Type.px(10) }
        }
        Row {
          id: footRight
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          spacing: Type.px(14)
          Key { label: "Esc" }
          Label { text: "Roll up" }
        }
        Item {
          id: pos
          x: footLeft.width + Type.px(14)
          width: footRight.x - x - Type.px(14)
          height: parent.height
          readonly property var at: Scroll.position(root.current)
          Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 1; color: Ink.line }
          Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            x: Math.round(pos.at.x * pos.width)
            width: Math.round(pos.at.width * pos.width)
            height: 3
            radius: 1
            color: Ink.ink
            Behavior on x { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
          }
        }
      }
    }
  }

  component Key: Rectangle {
    id: key
    property string label: ""
    width: Math.max(Type.px(16), keyText.implicitWidth + Type.px(8))
    height: Type.px(16)
    radius: 3
    color: "transparent"
    border.width: 1
    border.color: Ink.lineStrong
    Text {
      id: keyText
      anchors.centerIn: parent
      text: key.label.toUpperCase()
      color: Ink.inkDim
      font.family: Type.mono
      font.pixelSize: Type.tag
    }
  }

  component Label: Text {
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    color: Ink.inkMuted
    font.family: Type.mono
    font.pixelSize: Type.label
    font.letterSpacing: Type.trackLabel
    font.capitalization: Font.AllUppercase
  }

  // Text set top to bottom, as on a spine.
  component Vertical: Item {
    id: vert
    property string text: ""
    property color color: Ink.inkMuted
    property string family: Type.mono
    property int size: Type.label
    property real tracking: 0
    property bool italic: false
    width: line.implicitHeight
    height: line.implicitWidth
    Text {
      id: line
      x: line.implicitHeight
      rotation: 90
      transformOrigin: Item.TopLeft
      text: vert.text
      color: vert.color
      font.family: vert.family
      font.pixelSize: vert.size
      font.letterSpacing: vert.tracking
      font.italic: vert.italic
    }
  }
}
