pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Scroll.js" as Scroll
import "../../core/Weather.js" as Wx

// The handscroll 巻 (docs/COMPONENTS.md, "Panels"; panels: scroll): one
// long paper held between two rollers, its eight sections side by side with
// dithered interludes between them; sections curl under the rollers at the
// edges so the neighbours always show. An index plate names every section
// (the one in the middle inverted), and a position bar runs along the foot.
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
  // The sheets' feed (now, zones, timeShift, sound, network, bluetooth,
  // power, display, letters, dnd) plus spaces, weather and weatherShown.
  property var feed: ({})

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
  readonly property int leafWidth: root.feed.weatherShown === false ? 0
    : Wx.leafWidth(view.width, layout.widths[0], interlude, Type.scale)

  implicitHeight: Type.px(460)

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

      Rectangle { anchors.fill: parent; color: Ink.paper }
      // Hairlines on the free sides, none against the bar.
      Rectangle { width: 1; height: parent.height; color: Ink.line }
      Rectangle { x: parent.width - 1; width: 1; height: parent.height; color: Ink.line }
      Rectangle { y: root.atBottom ? 0 : parent.height - 1; width: parent.width; height: 1; color: Ink.line }

      // ------------------------------------------------------ the paper
      Item {
        id: view
        x: Type.px(26)
        width: parent.width - 2 * x
        height: parent.height
        clip: true
        opacity: root.ink

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
            visible: root.leafWidth > 0
            x: root.layout.xs[0] - root.interlude - width
            width: root.leafWidth
            height: track.height
            weather: root.feed.weather || null
          }
          Interlude {
            visible: root.leafWidth > 0
            seed: 11
            x: root.layout.xs[0] - width
            y: Type.px(40)
            width: root.interlude
            height: track.height - Type.px(74)
          }

          TimeSection {
            x: root.layout.xs[0]; width: root.layout.widths[0]; height: track.height
            info: root.sections[0]
            now: root.feed.now || new Date()
            zones: root.feed.zones || []
            shift: root.feed.timeShift || 0
            onRequest: function(what, arg) { root.request("time", what, arg) }
          }
          SoundSection {
            x: root.layout.xs[1]; width: root.layout.widths[1]; height: track.height
            info: root.sections[1]
            sound: root.feed.sound || null
            onRequest: function(what, arg) { root.request("sound", what, arg) }
          }
          NetworkSection {
            x: root.layout.xs[2]; width: root.layout.widths[2]; height: track.height
            info: root.sections[2]
            net: root.feed.network || null
            onRequest: function(what, arg) { root.request("network", what, arg) }
          }
          BluetoothSection {
            x: root.layout.xs[3]; width: root.layout.widths[3]; height: track.height
            info: root.sections[3]
            blue: root.feed.bluetooth || null
            onRequest: function(what, arg) { root.request("bluetooth", what, arg) }
          }
          PowerSection {
            x: root.layout.xs[4]; width: root.layout.widths[4]; height: track.height
            info: root.sections[4]
            power: root.feed.power || null
            onRequest: function(what, arg) { root.request("power", what, arg) }
          }
          DisplaySection {
            x: root.layout.xs[5]; width: root.layout.widths[5]; height: track.height
            info: root.sections[5]
            display: root.feed.display || null
            onRequest: function(what, arg) { root.request("display", what, arg) }
          }
          SpacesSection {
            x: root.layout.xs[6]; width: root.layout.widths[6]; height: track.height
            info: root.sections[6]
            spaces: root.feed.spaces || []
            onRequest: function(what, arg) { root.request("spaces", what, arg) }
          }
          InboxSection {
            x: root.layout.xs[7]; width: root.layout.widths[7]; height: track.height
            info: root.sections[7]
            letters: root.feed.letters || []
            dnd: !!root.feed.dnd
            now: root.feed.now || new Date()
            onRequest: function(what, arg) { root.request("inbox", what, arg) }
          }

          // Interludes, in the gaps between sections.
          Repeater {
            model: root.sections.length - 1
            Interlude {
              id: sliver
              required property int index
              seed: sliver.index
              x: root.layout.xs[sliver.index] + root.layout.widths[sliver.index]
              y: Type.px(40)
              width: Math.round(Scroll.INTERLUDE * Type.scale)
              height: track.height - Type.px(74)
            }
          }
        }

        // Sections curl under the rollers: the paper fades into itself.
        Rectangle {
          width: Type.px(120)
          height: parent.height
          gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.08; color: Ink.paper }
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
            GradientStop { position: 0.92; color: Ink.paper }
          }
        }
      }

      // ------------------------------------------------------ the rollers
      Repeater {
        model: 2
        Item {
          id: roller
          required property int index
          x: index === 0 ? Type.px(10) : paper.width - Type.px(10) - width
          y: Type.px(18)
          width: Type.px(9)
          height: paper.height - Type.px(36)
          Rectangle {
            anchors.fill: parent
            radius: width / 2
            gradient: Gradient {
              orientation: Gradient.Horizontal
              GradientStop { position: 0; color: Ink.inkFaint }
              GradientStop { position: 0.45; color: Ink.ink }
              GradientStop { position: 1; color: Ink.inkMuted }
            }
          }
          Repeater {
            model: 2
            Rectangle {
              id: cap
              required property int index
              x: -Type.px(3)
              y: cap.index === 0 ? -Type.px(7) : roller.height + Type.px(1)
              width: Type.px(15)
              height: Type.px(6)
              radius: height / 2
              color: Ink.inkMuted
            }
          }
        }
      }

      // ------------------------------------------------------ index plate
      Rectangle {
        id: plate
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
                  color: entry.on ? Ink.boneInk : Ink.inkFaint
                  font.family: Type.mono
                  font.pixelSize: Type.px(9.5)
                  font.letterSpacing: Type.px(1.6)
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
      font.pixelSize: Type.px(8.5)
    }
  }

  component Label: Text {
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    color: Ink.inkFaint
    font.family: Type.mono
    font.pixelSize: Type.px(9)
    font.letterSpacing: Type.px(1.8)
    font.capitalization: Font.AllUppercase
  }
}
