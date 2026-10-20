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
  // How the sections lie (Style.js `fold`): expanded side by side, or
  // collapsed: the open one whole, its neighbours folded into spines, the
  // rest wound on the rollers (docs/densho sheet 01).
  property string fold: "expanded"

  readonly property bool folded: fold === "collapsed"
  readonly property var foldInfo: Densho.fold(sections.length, current, view.width, Type.scale)
  // guides: map, the whole scroll as a strip of cells (docs/densho sheet 06).
  readonly property bool mapped: guides === "map"
  readonly property int mapHeight: mapped ? Type.px(mokuroku ? 112 : 98) : 0
  // Collapsed, the open section comes in each time it changes: its ink
  // (and its brush, under arrival: brush).
  property real foldInk: 1
  function sx(i) { return folded ? foldInfo.open.x : layout.xs[i] }
  function sw(i) { return folded ? foldInfo.open.width : layout.widths[i] }
  function shows(i) { return !folded || i === current }
  function spineOf(i) {
    var all = foldInfo.spines
    for (var k = 0; k < all.length; k++) if (all[k].index === i) return all[k]
    return null
  }
  // A section that needs you: an unread letter, or a fault.
  function flagged(i) {
    var key = sections[i].key
    if (key === "inbox") return (feed.letters || []).length > 0 && !feed.dnd
    return Densho.faultOf(key, feed)
  }
  onCurrentChanged: if (folded && Motion.live) arriving.restart()
  ParallelAnimation {
    id: arriving
    NumberAnimation { target: root; property: "foldInk"; from: 0; to: 1; duration: Motion.ink; easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.inkCurve }
    NumberAnimation { target: root; property: "writeIn"; from: root.brush ? 0 : 1; to: 1; duration: root.brush ? 520 : 0; easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.inkCurve }
  }

  readonly property bool brush: arrival === "brush"
  readonly property bool mokuroku: order === "mokuroku"
  // How far the brush has written what sits at track x `x`, `w` wide.
  function writeAtX(x, w) {
    if (!brush) return 1
    if (folded) return writeIn
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

  implicitHeight: Type.px(460) + mapHeight

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
        y: root.atBottom ? 0 : root.mapHeight
        width: parent.width - 2 * x
        height: parent.height - root.mapHeight
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
          x: root.folded ? 0 : Math.round(root.trackX)
          width: root.layout.width
          height: view.height

          // Before Time, on paper that is otherwise bare: the weather leaf
          // and an interlude between it and the day.
          WeatherLeaf {
            visible: root.leafWidth > 0 && !root.mokuroku && !root.folded
            x: root.layout.xs[0] - root.interlude - width
            width: root.leafWidth
            height: track.height
            weather: root.feed.weather || null
            brush: root.brush
            write: root.writeAtX(x, width)
          }
          DenshoLeaf {
            visible: root.leafWidth > 0 && root.mokuroku && !root.folded
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
            visible: root.leafWidth > 0 && !root.folded
            seed: 11
            style: root.divider
            x: root.layout.xs[0] - width
            y: Type.px(64)
            width: root.interlude
            height: track.height - Type.px(98)
          }

          TimeSection {
            x: root.sx(0); width: root.sw(0); height: track.height
            visible: root.shows(0); opacity: root.folded ? root.foldInk : 1
            brush: root.brush; write: root.writeOf(0); poem: root.poemOf(0)
            info: root.sections[0]
            now: root.feed.now || new Date()
            zones: root.feed.zones || []
            shift: root.feed.timeShift || 0
            onRequest: function(what, arg) { root.request("time", what, arg) }
          }
          SoundSection {
            x: root.sx(1); width: root.sw(1); height: track.height
            visible: root.shows(1); opacity: root.folded ? root.foldInk : 1
            brush: root.brush; write: root.writeOf(1); poem: root.poemOf(1)
            info: root.sections[1]
            sound: root.feed.sound || null
            onRequest: function(what, arg) { root.request("sound", what, arg) }
          }
          NetworkSection {
            x: root.sx(2); width: root.sw(2); height: track.height
            visible: root.shows(2); opacity: root.folded ? root.foldInk : 1
            brush: root.brush; write: root.writeOf(2); poem: root.poemOf(2)
            fault: root.faultOf("network")
            info: root.sections[2]
            net: root.feed.network || null
            onRequest: function(what, arg) { root.request("network", what, arg) }
          }
          BluetoothSection {
            x: root.sx(3); width: root.sw(3); height: track.height
            visible: root.shows(3); opacity: root.folded ? root.foldInk : 1
            brush: root.brush; write: root.writeOf(3); poem: root.poemOf(3)
            info: root.sections[3]
            blue: root.feed.bluetooth || null
            onRequest: function(what, arg) { root.request("bluetooth", what, arg) }
          }
          PowerSection {
            x: root.sx(4); width: root.sw(4); height: track.height
            visible: root.shows(4); opacity: root.folded ? root.foldInk : 1
            brush: root.brush; write: root.writeOf(4); poem: root.poemOf(4)
            fault: root.faultOf("power")
            info: root.sections[4]
            power: root.feed.power || null
            onRequest: function(what, arg) { root.request("power", what, arg) }
          }
          DisplaySection {
            x: root.sx(5); width: root.sw(5); height: track.height
            visible: root.shows(5); opacity: root.folded ? root.foldInk : 1
            brush: root.brush; write: root.writeOf(5); poem: root.poemOf(5)
            info: root.sections[5]
            display: root.feed.display || null
            onRequest: function(what, arg) { root.request("display", what, arg) }
          }
          SpacesSection {
            x: root.sx(6); width: root.sw(6); height: track.height
            visible: root.shows(6); opacity: root.folded ? root.foldInk : 1
            brush: root.brush; write: root.writeOf(6); poem: root.poemOf(6)
            info: root.sections[6]
            spaces: root.feed.spaces || []
            onRequest: function(what, arg) { root.request("spaces", what, arg) }
          }
          InboxSection {
            x: root.sx(7); width: root.sw(7); height: track.height
            visible: root.shows(7); opacity: root.folded ? root.foldInk : 1
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
            visible: root.endWidth > 0 && !root.folded
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
            visible: root.endWidth > 0 && root.mokuroku && !root.folded
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
            visible: root.endWidth > 0 && !root.mokuroku && !root.folded
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
              visible: !root.folded
              seed: sliver.index
              style: root.divider
              x: root.layout.xs[sliver.index] + root.layout.widths[sliver.index]
              y: Type.px(64)
              width: Math.round(Scroll.INTERLUDE * Type.scale)
              height: track.height - Type.px(98)
            }
          }
        }

        // Collapsed: the spines, the rollers and two mist bands at the seams.
        Item {
          id: folds
          visible: root.folded
          anchors.fill: parent

          Repeater {
            model: root.sections.length
            Spine {
              required property int index
              at: root.spineOf(index)
              no: index
            }
          }

          Roller { onLeft: true; count: root.foldInfo.left }
          Roller { onLeft: false; count: root.foldInfo.right }

          // Kasumi 霞: long pale bands across the seams, as emaki part scenes.
          Repeater {
            model: [
              { x: root.foldInfo.open.x + root.foldInfo.open.width - Type.px(360), y: folds.height - Type.px(92), w: Type.px(520), h: Type.px(18), a: 0.045 },
              { x: root.foldInfo.open.x + root.foldInfo.open.width - Type.px(180), y: folds.height - Type.px(66), w: Type.px(300), h: Type.px(11), a: 0.03 },
              { x: root.foldInfo.open.x + root.foldInfo.open.width - Type.px(240), y: Type.px(26), w: Type.px(460), h: Type.px(16), a: 0.04 },
              { x: Type.px(18), y: folds.height - Type.px(58), w: root.foldInfo.open.x, h: Type.px(13), a: 0.035 }
            ]
            Rectangle {
              required property var modelData
              x: modelData.x; y: modelData.y
              width: modelData.w; height: modelData.h
              radius: height / 2
              color: Ink.alpha(Ink.ink, modelData.a)
            }
          }
        }

        // Sections fade out at the side edges: the paper fades into itself.
        Rectangle {
          visible: !root.folded
          width: Type.px(120)
          height: parent.height
          gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.08; color: Ink.alpha(Ink.paper, root.paperOpacity) }
            GradientStop { position: 1; color: Ink.alpha(Ink.paper, 0) }
          }
        }
        Rectangle {
          visible: !root.folded
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

      // ------------------------------------------------------ the map
      // guides: map (docs/densho sheet 06): every part of the scroll in one
      // ruled strip, left to right, the open section inverted, the leaves
      // (the weather or the house, the end leaf or the colophon) at the
      // ends on lifted paper. A click opens a section.
      Item {
        id: map
        visible: root.mapped
        opacity: root.ink
        x: Type.px(26)
        y: root.atBottom ? paper.height - height - Type.px(10) : Type.px(12)
        width: paper.width - 2 * x
        height: root.mapHeight - Type.px(32)

        readonly property var cells: {
          var out = []
          if (root.leafWidth > 0)
            out.push(root.mokuroku ? { jp: "序", no: "00", name: "Opening", poem: "The house", leaf: true, to: 0 }
                                   : { jp: "天", no: "00", name: "Weather", poem: "", leaf: true, to: 0 })
          for (var i = 0; i < root.sections.length; i++) {
            var sc = root.sections[i]
            out.push({ jp: sc.jp, no: sc.no, name: sc.label.charAt(0) + sc.label.slice(1).toLowerCase(), poem: sc.poem, index: i, to: i })
          }
          if (root.endWidth > 0) {
            var k = LeafJs.kindOf(root.endleaf)
            out.push(root.mokuroku ? { jp: "奥", no: "09", name: "Colophon", poem: "Signed and sealed", leaf: true, seal: true, to: root.sections.length - 1 }
                                   : { jp: k.jp, no: "09", name: k.name, poem: "", leaf: true, to: root.sections.length - 1 })
          }
          return out
        }
        readonly property real cellWidth: Math.min(Type.px(170), width / Math.max(1, cells.length))

        Row {
          id: cellRow
          anchors.horizontalCenter: parent.horizontalCenter
          height: parent.height
          Repeater {
            model: map.cells
            Rectangle {
              id: cell
              required property var modelData
              required property int index
              readonly property bool on: cell.modelData.index === root.current
              width: map.cellWidth
              height: cellRow.height
              clip: true
              color: on ? Ink.bone : cell.modelData.leaf ? Ink.lift : "transparent"
              Behavior on color { enabled: Motion.live; ColorAnimation { duration: Motion.slide } }
              Rectangle { width: 1; height: parent.height; color: Ink.line }
              Rectangle { visible: cell.index === map.cells.length - 1; x: parent.width - 1; width: 1; height: parent.height; color: Ink.line }
              Column {
                x: Type.px(12)
                y: Type.px(7)
                width: parent.width - 2 * x
                spacing: 0
                Text {
                  text: cell.modelData.jp
                  color: cell.on ? Ink.boneInk : cell.modelData.leaf ? Ink.ink : Ink.inkDim
                  font.family: Type.brush
                  font.pixelSize: Type.px(20)
                }
                Text {
                  text: cell.modelData.no
                  color: cell.on ? Ink.boneInk : Ink.inkFaint
                  font.family: Type.mono
                  font.pixelSize: Type.tag
                  font.letterSpacing: Type.trackLabel
                }
                Text {
                  width: parent.width
                  elide: Text.ElideRight
                  text: cell.modelData.name
                  color: cell.on ? Ink.boneInk : Ink.ink
                  font.family: Type.text
                  font.pixelSize: Type.note
                }
                Text {
                  visible: root.mokuroku && cell.modelData.poem !== ""
                  width: parent.width
                  elide: Text.ElideRight
                  text: cell.modelData.poem
                  color: cell.on ? Ink.boneInk : Ink.inkFaint
                  font.family: Type.display
                  font.italic: true
                  font.pixelSize: Type.px(11)
                }
              }
              // The colophon's seal, in its corner.
              Rectangle {
                visible: !!cell.modelData.seal
                anchors.right: parent.right
                anchors.rightMargin: Type.px(10)
                y: Type.px(10)
                width: Type.px(16)
                height: width
                radius: 2
                rotation: -4
                color: Ink.seal
                Text { anchors.centerIn: parent; text: root.feed.sealGlyph || "鑑"; color: Ink.paper; font.family: Type.jpSerif; font.pixelSize: Type.px(10) }
              }
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.picked(cell.modelData.to)
              }
            }
          }
        }
        // Where the scroll opens and closes, under its two ends.
        Text {
          x: cellRow.x
          y: parent.height + Type.px(4)
          text: "OPENS HERE"
          color: Ink.inkFaint
          font.family: Type.mono
          font.pixelSize: Type.tag
          font.letterSpacing: Type.trackLabel
        }
        Text {
          x: cellRow.x + cellRow.width - width
          y: parent.height + Type.px(4)
          text: "CLOSES HERE · ESC"
          color: Ink.seal
          font.family: Type.mono
          font.pixelSize: Type.tag
          font.letterSpacing: Type.trackLabel
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

  // A section folded into a spine (fold: collapsed): its sign, its number
  // and name set vertically, its poetic name under order: mokuroku, a red
  // dot when it needs you. Nearer spines are wider and darker. It slides as
  // the open section changes, and opens when clicked.
  component Spine: Item {
    id: spine
    property var at: null
    property int no: 0
    readonly property int depth: at ? at.depth : 3
    readonly property bool shown: !!at
    readonly property var info: root.sections[no]
    x: at ? at.x : no < root.current ? root.foldInfo.rollers : view.width - root.foldInfo.rollers
    width: at ? at.width : 0
    height: parent ? parent.height : 0
    opacity: shown ? 1 : 0
    clip: true
    Behavior on x { enabled: Motion.live; NumberAnimation { duration: Motion.pan; easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.panCurve } }
    Behavior on width { enabled: Motion.live; NumberAnimation { duration: Motion.pan; easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.panCurve } }
    Behavior on opacity { enabled: Motion.live; NumberAnimation { duration: Motion.fade } }

    Rectangle {
      x: spine.at && spine.at.side === "left" ? spine.width - 1 : 0
      y: Type.px(40)
      width: 1
      height: Math.max(0, spine.height - Type.px(80))
      color: Ink.line
    }
    Rectangle {
      visible: root.flagged(spine.no)
      anchors.horizontalCenter: parent.horizontalCenter
      y: Type.px(30)
      width: Type.px(6)
      height: width
      radius: width / 2
      color: Ink.seal
    }
    Column {
      anchors.horizontalCenter: parent.horizontalCenter
      y: Type.px(56)
      spacing: Type.px(16)
      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: spine.info.jp
        color: hover.containsMouse ? Ink.ink : spine.depth === 1 ? Ink.inkDim : spine.depth === 2 ? Ink.inkMuted : Ink.inkFaint
        font.family: Type.brush
        font.pixelSize: Type.px(spine.depth === 1 ? 46 : spine.depth === 2 ? 30 : 22)
        lineHeight: 1
        lineHeightMode: Text.ProportionalHeight
      }
      Vertical {
        visible: spine.depth < 3
        anchors.horizontalCenter: parent.horizontalCenter
        text: spine.info.no + "  " + spine.info.label
        color: spine.depth === 1 ? Ink.inkMuted : Ink.inkFaint
        size: Type.px(11)
        tracking: Type.px(3)
      }
      Vertical {
        visible: spine.depth === 1 && root.mokuroku
        anchors.horizontalCenter: parent.horizontalCenter
        text: spine.info.poem
        color: Ink.inkFaint
        family: Type.display
        italic: true
        size: Type.px(15)
      }
    }
    MouseArea {
      id: hover
      anchors.fill: parent
      enabled: spine.shown
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: root.picked(spine.no)
    }
  }

  // A roller (fold: collapsed): one hairline for each section on its side,
  // the outermost first; the lines of the spines in view are darker, and a
  // wound section that needs you is red.
  component Roller: Item {
    id: roller
    property bool onLeft: true
    property int count: 0
    x: onLeft ? 0 : view.width - width
    y: Type.px(26)
    width: root.foldInfo.rollers
    height: view.height - Type.px(52)
    Repeater {
      model: roller.count
      Rectangle {
        id: line
        required property int index
        // The section this line stands for.
        readonly property int section: roller.onLeft ? line.index : root.sections.length - 1 - line.index
        readonly property bool near: line.index >= roller.count - Math.min(3, roller.count)
        readonly property bool red: !line.near && root.flagged(line.section)
        x: roller.onLeft ? Type.px(4) + line.index * Type.px(3) : roller.width - Type.px(5) - line.index * Type.px(3)
        width: line.red ? 2 : 1
        height: roller.height
        color: line.red ? Ink.seal : line.near ? Ink.inkMuted : Ink.lineStrong
      }
    }
  }
}
