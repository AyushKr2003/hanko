pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Leaf.js" as LeafJs

// 09 // the end leaf: on the bare paper right of 08 // INBOX, the twin of
// the weather leaf left of 01 // TIME. Not a section of its own (the index
// plate and the keys skip it); it shows while Inbox is in the middle. The
// `endleaf` setting picks one of nine (core/Leaf.js; docs/revision2 on the
// docs branch):
//   okugaki 奥書 colophon   koyomi 暦 almanac    kiki 機 machine
//   shimai  終 session      iro    色 themes     dougu 具 tools
//   shuchu  集 focus        hikae  控 notes      batsu 跋 afterword
Item {
  id: root

  property string kind: "koyomi"
  property date now: new Date()
  // services/Leaf.qml reading (the harness passes the same shape).
  property var reading: ({})
  // From the bar: the mono font, Hanko's version and preset, the switches
  // the tools show, the seal glyph, and how many sections the scroll has.
  property string font: ""
  property string version: ""
  property string preset: ""
  property var switches: ({})
  property string sealGlyph: "判"
  property int sections: 8

  signal request(string what, var arg)

  readonly property var d: reading || {}
  readonly property var info: LeafJs.kindOf(kind)

  // Each kind's view, worked out only while it is the one shown.
  readonly property var colophon: kind === "okugaki" ? LeafJs.colophon(d.colophon || "", { font: font, version: version, preset: preset }) : null
  readonly property var almanac: kind === "koyomi" ? LeafJs.almanac(now) : null
  readonly property var machine: kind === "kiki" ? LeafJs.machine(d.machine || null) : null
  readonly property var themes: kind === "iro" ? LeafJs.themesView(d.themes || [], d.theme || "", 6) : null
  readonly property var focusView: kind === "shuchu" ? LeafJs.focusView(LeafJs.focusState(JSON.stringify(d.focus || {})), d.clockNow || now.getTime()) : null
  readonly property var noteItems: kind === "hikae" ? LeafJs.notes(d.notes || "") : []
  readonly property var notesView: kind === "hikae" ? LeafJs.notesView(noteItems, !!d.notesExist) : null
  readonly property var clips: kind === "hikae" ? LeafJs.clipboard(d.clipboard || "") : []
  readonly property var toolState: ({
    recording: !!d.recording, awake: !!switches.awake, night: !!switches.night, dnd: !!switches.dnd
  })

  readonly property string title: kind === "okugaki" ? colophon.title
    : kind === "koyomi" ? almanac.title
    : kind === "kiki" ? machine.title
    : kind === "shimai" ? "Until <i>later</i>"
    : kind === "iro" ? themes.title
    : kind === "dougu" ? "Tools, <i>at hand</i>"
    : kind === "shuchu" ? focusView.title
    : kind === "hikae" ? notesView.title : ""
  readonly property string caption: kind === "okugaki" ? colophon.caption
    : kind === "koyomi" ? almanac.caption
    : kind === "kiki" ? machine.caption
    : kind === "shimai" ? (d.uptime ? "Up " + LeafJs.uptime(d.uptime) : "Hold a seal to press it")
    : kind === "iro" ? themes.caption
    : kind === "dougu" ? "Omarchy's utilities · one click each"
    : kind === "shuchu" ? focusView.caption
    : kind === "hikae" ? (d.notesExist ? "~" + LeafJs.NOTES_PATH : "Click to start ~" + LeafJs.NOTES_PATH) : ""

  // ------------------------------------------------------------ sections
  ScrollSection {
    anchors.fill: parent
    visible: root.kind !== "batsu"
    info: ({ no: "09", jp: root.info.jp, label: root.info.label })
    title: root.title
    caption: root.caption

    // ---------------------------------------------- okugaki 奥書 colophon
    Column {
      visible: root.kind === "okugaki"
      width: parent.width
      topPadding: Type.px(18)
      Repeater {
        model: root.colophon ? root.colophon.rows : []
        Fact {
          required property var modelData
          k: modelData.k
          v: modelData.v
          italic: !!modelData.italic
        }
      }
      Item { width: 1; height: Type.px(22) }
      Row {
        visible: !!root.colophon && root.colophon.ready
        spacing: Type.px(14)
        Repeater {
          model: root.colophon ? root.colophon.seals : []
          Seal {
            required property var modelData
            required property int index
            anchors.verticalCenter: parent.verticalCenter
            glyph: modelData.glyph
            size: [34, 28, 24][index]
            tilt: [-2, 1.5, -1][index]
            hollow: !modelData.solid
          }
        }
        Mono {
          anchors.verticalCenter: parent.verticalCenter
          text: "You · theme · Hanko"
          color: Ink.inkFaint
        }
      }
    }

    // ---------------------------------------------- koyomi 暦 almanac
    Column {
      visible: root.kind === "koyomi"
      width: parent.width
      topPadding: Type.px(16)
      spacing: Type.px(12)
      Item {
        width: parent.width
        height: month.height
        Grid {
          id: month
          columns: 7
          rowSpacing: Type.px(2)
          readonly property real cell: Math.min(Type.px(28), (parent.width - Type.px(86)) / 7)
          Repeater {
            model: ["M", "T", "W", "T", "F", "S", "S"]
            Mono {
              required property string modelData
              width: month.cell
              height: Type.px(16)
              horizontalAlignment: Text.AlignHCenter
              text: modelData
              color: Ink.inkFaint
            }
          }
          Repeater {
            model: root.almanac ? root.almanac.cells : []
            Item {
              id: day
              required property var modelData
              width: month.cell
              height: Type.px(20)
              Rectangle {
                anchors.centerIn: parent
                visible: day.modelData.today
                width: Type.px(20)
                height: width
                radius: 2
                color: Ink.seal
              }
              Text {
                anchors.centerIn: parent
                text: day.modelData.label
                color: day.modelData.today ? Ink.paper : day.modelData.past ? Ink.inkFaint
                  : day.modelData.weekend ? Ink.inkMuted : Ink.inkDim
                font.family: Type.mono
                font.pixelSize: Type.label
              }
              // The day the next solar term starts.
              Rectangle {
                visible: day.modelData.term
                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height - 2
                width: 3
                height: 3
                radius: 1.5
                color: Ink.inkDim
              }
            }
          }
        }
        // The moon, lit from the side it is lit from.
        Column {
          anchors.right: parent.right
          y: Type.px(20)
          spacing: Type.px(8)
          Moon {
            anchors.horizontalCenter: parent.horizontalCenter
            size: Type.px(46)
            lit: root.almanac ? root.almanac.moon.lit : 0
            waxing: root.almanac ? root.almanac.moon.waxing : true
          }
          Mono { anchors.horizontalCenter: parent.horizontalCenter; text: root.almanac ? "Moon " + root.almanac.moon.percent + "%" : ""; color: Ink.inkMuted }
          Mono { anchors.horizontalCenter: parent.horizontalCenter; text: root.almanac ? root.almanac.moon.next : ""; color: Ink.inkFaint }
        }
      }
      Mono {
        width: parent.width
        elide: Text.ElideRight
        text: root.almanac ? "● " + (root.almanac.next.day < 10 ? "0" : "") + root.almanac.next.day + " · " + root.almanac.next.name + " " + root.almanac.next.jp + ", " + root.almanac.next.english : ""
        color: Ink.inkMuted
      }
      // The year, a tick a month.
      Item {
        width: parent.width
        height: Type.px(26)
        readonly property real at: root.almanac ? root.almanac.yearDone : 0
        Rectangle { y: Type.px(8); width: parent.width; height: 1; color: Ink.line }
        Rectangle { y: Type.px(7); width: Math.round(parent.width * parent.at); height: 3; radius: 1; color: Ink.ink }
        Repeater {
          model: 13
          Rectangle {
            required property int index
            x: Math.round(index / 12 * (parent.width - 1))
            y: Type.px(10)
            width: 1
            height: index % 3 === 0 ? Type.px(5) : Type.px(3)
            color: index % 3 === 0 ? Ink.lineStrong : Ink.line
          }
        }
        Rectangle { x: Math.round(parent.width * parent.at); y: Type.px(2); width: 2; height: Type.px(12); color: Ink.seal }
        Mono { y: Type.px(16); text: root.almanac ? "Day " + root.almanac.day + " of " + root.almanac.days : ""; color: Ink.inkFaint }
        Mono { anchors.right: parent.right; y: Type.px(16); text: Math.floor(parent.at * 100) + "%"; color: Ink.inkDim }
      }
    }

    // ---------------------------------------------- kiki 機 machine
    Column {
      visible: root.kind === "kiki"
      width: parent.width
      topPadding: Type.px(18)
      spacing: Type.px(10)
      Item {
        id: hourBox
        width: parent.width
        height: Type.px(56)
        readonly property var hist: root.machine ? root.machine.history : []
        Canvas {
          id: hour
          anchors.fill: parent
          antialiasing: true
          onPaint: {
            var c = getContext("2d")
            c.reset()
            var v = hourBox.hist
            if (v.length < 2) return
            // The last hour, a point a minute, ending at the right edge.
            var step = width / 59
            var x0 = width - (v.length - 1) * step
            c.beginPath()
            for (var i = 0; i < v.length; i++) {
              var x = x0 + i * step, y = height - 2 - Math.min(1, v[i]) * (height - 12)
              if (i === 0) c.moveTo(x, y); else c.lineTo(x, y)
            }
            c.lineWidth = 1.4
            c.lineJoin = "round"
            c.strokeStyle = Ink.ink
            c.stroke()
            c.lineTo(width, height)
            c.lineTo(x0, height)
            c.closePath()
            c.fillStyle = Qt.rgba(Ink.ink.r, Ink.ink.g, Ink.ink.b, 0.06)
            c.fill()
          }
          Connections {
            target: hourBox
            function onHistChanged() { hour.requestPaint() }
          }
          Connections {
            target: Ink
            function onInkChanged() { hour.requestPaint() }
          }
          onWidthChanged: requestPaint()
        }
        Rectangle { y: parent.height - 1; width: parent.width; height: 1; color: Ink.line }
        Rectangle { x: parent.width - 2; width: 2; height: parent.height; color: Ink.seal }
        Mono {
          visible: hourBox.hist.length < 2
          anchors.verticalCenter: parent.verticalCenter
          text: "The hour fills in a minute at a time"
          color: Ink.inkFaint
        }
        Mono {
          visible: !!root.machine && root.machine.peakLabel !== ""
          x: root.machine && root.machine.peakAt >= 0
            ? Math.max(0, Math.min(parent.width - width - Type.px(6), parent.width - (hourBox.hist.length - 1 - root.machine.peakAt) * parent.width / 59 - width / 2))
            : 0
          text: root.machine ? root.machine.peakLabel : ""
          color: Ink.inkMuted
        }
      }
      Item {
        width: parent.width
        height: Type.px(10)
        Mono { text: "−60 min"; color: Ink.inkFaint }
        Mono { anchors.right: parent.right; text: "Now"; color: Ink.inkFaint }
      }
      Column {
        width: parent.width
        Repeater {
          model: root.machine ? root.machine.rows : []
          Item {
            id: meter
            required property var modelData
            width: parent.width
            height: Type.px(22)
            Mono { anchors.verticalCenter: parent.verticalCenter; width: Type.px(62); text: meter.modelData.k; color: Ink.inkMuted }
            Row {
              x: Type.px(66)
              anchors.verticalCenter: parent.verticalCenter
              spacing: Type.px(2)
              Repeater {
                model: 24
                Rectangle {
                  required property int index
                  width: Type.px(3)
                  height: Type.px(10)
                  color: index < Math.round(meter.modelData.at * 24)
                    ? (meter.modelData.hot ? Ink.seal : Ink.ink) : Ink.lineSoft
                }
              }
            }
            Mono {
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              text: meter.modelData.v
              color: Ink.ink
            }
            Rectangle { y: parent.height - 1; width: parent.width; height: 1; color: Ink.lineSoft }
          }
        }
      }
      Mono {
        width: parent.width
        elide: Text.ElideRight
        visible: text !== ""
        text: root.machine && root.machine.top ? "Top · " + root.machine.top : ""
        color: Ink.inkFaint
      }
    }

    // ---------------------------------------------- shimai 終 session
    Column {
      visible: root.kind === "shimai"
      width: parent.width
      topPadding: Type.px(22)
      spacing: Type.px(18)
      Grid {
        columns: 3
        columnSpacing: Type.px(16)
        rowSpacing: Type.px(16)
        Repeater {
          model: LeafJs.SESSION
          Column {
            id: act
            required property var modelData
            required property int index
            property real held: 0
            spacing: Type.px(6)
            Rectangle {
              id: stamp
              width: Type.px(62)
              height: width
              radius: 3
              rotation: [-1.5, 1, -0.5, 1.5, -2][act.index]
              color: act.modelData.key === "shutdown" ? Ink.seal : "transparent"
              border.width: act.modelData.key === "shutdown" ? 0 : 1.5
              border.color: Ink.seal
              clip: true
              // Holding fills the seal with ink from the bottom.
              Rectangle {
                y: parent.height * (1 - act.held)
                width: parent.width
                height: parent.height * act.held
                color: act.modelData.key === "shutdown" ? Ink.boneInk : Ink.seal
                opacity: act.modelData.key === "shutdown" ? 0.35 : 0.3
              }
              Text {
                anchors.centerIn: parent
                text: act.modelData.jp
                color: act.modelData.key === "shutdown" ? Ink.paper : Ink.seal
                font.family: Type.jpSerif
                font.pixelSize: Type.px(28)
              }
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onPressed: fill.restart()
                onReleased: { fill.stop(); act.held = 0 }
                onCanceled: { fill.stop(); act.held = 0 }
              }
              NumberAnimation {
                id: fill
                target: act
                property: "held"
                from: 0
                to: 1
                duration: 700
                onFinished: {
                  if (act.held >= 1) root.request("session", act.modelData.key)
                  act.held = 0
                }
              }
            }
            Mono { text: act.modelData.name; color: Ink.inkDim }
          }
        }
      }
      Mono { text: "Hold a seal to press it · Esc rolls up"; color: Ink.inkFaint }
    }

    // ---------------------------------------------- iro 色 themes
    Column {
      visible: root.kind === "iro"
      width: parent.width
      topPadding: Type.px(14)
      Repeater {
        model: root.themes ? root.themes.shown : []
        Item {
          id: theme
          required property var modelData
          readonly property bool on: modelData.slug === root.d.theme
          width: parent.width
          height: Type.px(34)
          Rectangle {
            anchors.fill: parent
            radius: 2
            color: themeHover.containsMouse && !theme.on ? Ink.lineSoft : "transparent"
          }
          Rectangle {
            id: chip
            anchors.verticalCenter: parent.verticalCenter
            width: Type.px(78)
            height: Type.px(22)
            radius: 2
            color: theme.modelData.bg
            border.width: theme.on ? 2 : 1
            border.color: theme.on ? Ink.bone : Ink.line
            Row {
              x: Type.px(7)
              anchors.verticalCenter: parent.verticalCenter
              spacing: Type.px(3)
              Repeater {
                model: [1, 0.72, 0.5, 0.32]
                Rectangle {
                  required property real modelData
                  width: Type.px(9)
                  height: Type.px(3)
                  radius: 1
                  color: theme.modelData.fg
                  opacity: modelData
                }
              }
            }
            Rectangle {
              anchors.right: parent.right
              anchors.rightMargin: Type.px(7)
              anchors.verticalCenter: parent.verticalCenter
              width: Type.px(7)
              height: width
              radius: 1
              color: theme.modelData.red
            }
          }
          Serif {
            x: chip.width + Type.px(14)
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - x - Type.px(70)
            elide: Text.ElideRight
            text: theme.modelData.name
            color: theme.on ? Ink.ink : Ink.inkDim
            font.italic: theme.on
          }
          Mono {
            anchors.right: parent.right
            anchors.rightMargin: Type.px(4)
            anchors.verticalCenter: parent.verticalCenter
            text: theme.on ? "鑑 In use" : theme.modelData.light ? "Light" : ""
            color: theme.on ? Ink.seal : Ink.inkFaint
          }
          Rectangle { y: parent.height - 1; width: parent.width; height: 1; color: Ink.lineSoft }
          MouseArea {
            id: themeHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: theme.on ? Qt.ArrowCursor : Qt.PointingHandCursor
            onClicked: if (!theme.on) root.request("theme", theme.modelData.name)
          }
        }
      }
      Item { width: 1; height: Type.px(10) }
      Link {
        text: root.themes && root.themes.more > 0 ? root.themes.more + " more · open the picker" : "Open the picker"
        onClicked: root.request("themes", null)
      }
    }

    // ---------------------------------------------- dougu 具 tools
    Column {
      visible: root.kind === "dougu"
      width: parent.width
      topPadding: Type.px(18)
      spacing: Type.px(14)
      Grid {
        id: tools
        columns: 3
        columnSpacing: Type.px(8)
        rowSpacing: Type.px(8)
        readonly property real w: (parent.width - 2 * columnSpacing) / 3
        Repeater {
          model: LeafJs.TOOLS
          Rectangle {
            id: tool
            required property var modelData
            readonly property bool on: !!modelData.state && !!root.toolState[modelData.state]
            width: tools.w
            height: Type.px(58)
            radius: 3
            color: tool.on ? Ink.bone : toolHover.containsMouse ? Ink.lineSoft : "transparent"
            border.width: 1
            border.color: tool.on ? Ink.bone : Ink.line
            Text {
              x: Type.px(10)
              y: Type.px(8)
              text: tool.modelData.jp
              color: Ink.seal
              font.family: Type.jpSerif
              font.pixelSize: Type.px(18)
            }
            Rectangle {
              visible: tool.on
              x: parent.width - Type.px(14)
              y: Type.px(10)
              width: Type.px(5)
              height: width
              radius: width / 2
              color: Ink.seal
            }
            Mono {
              x: Type.px(10)
              y: parent.height - height - Type.px(8)
              width: parent.width - 2 * x
              elide: Text.ElideRight
              text: tool.modelData.name
              color: tool.on ? Ink.boneInk : Ink.inkDim
            }
            MouseArea {
              id: toolHover
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.request("tool", tool.modelData.key)
            }
          }
        }
      }
      Mono { text: LeafJs.toolsLine(root.toolState); color: Ink.inkFaint }
    }

    // ---------------------------------------------- shuchu 集 focus
    Column {
      visible: root.kind === "shuchu"
      width: parent.width
      topPadding: Type.px(22)
      spacing: Type.px(14)
      // This part on a ruler, a tick a minute: spent in ink, now in red.
      Item {
        id: ruler
        width: parent.width
        height: Type.px(40)
        readonly property real at: root.focusView ? root.focusView.at : 0
        readonly property int minutes: root.focusView ? root.focusView.minutes : 25
        Repeater {
          model: ruler.minutes + 1
          Rectangle {
            required property int index
            x: Math.round(index / ruler.minutes * (ruler.width - 1))
            y: ruler.height - height - Type.px(12)
            width: 1
            height: index % 5 === 0 ? Type.px(16) : Type.px(8)
            color: index / ruler.minutes <= ruler.at && ruler.at > 0 ? Ink.ink : (index % 5 === 0 ? Ink.lineStrong : Ink.line)
          }
        }
        Rectangle { y: ruler.height - Type.px(12); width: ruler.width; height: 1; color: Ink.line }
        Rectangle { y: ruler.height - Type.px(13); width: Math.round(ruler.width * ruler.at); height: 3; color: Ink.ink }
        Rectangle {
          visible: root.focusView && root.focusView.kind !== "idle"
          x: Math.round(ruler.width * ruler.at)
          width: 2
          height: ruler.height - Type.px(10)
          color: Ink.seal
        }
        Repeater {
          model: Math.floor(ruler.minutes / 5) + 1
          Mono {
            required property int index
            x: Math.min(ruler.width - width, Math.round(index * 5 / ruler.minutes * ruler.width) - (index ? width / 2 : 0))
            y: ruler.height - height
            text: index * 5
            color: Ink.inkFaint
          }
        }
      }
      Row {
        spacing: Type.px(10)
        Mono { anchors.verticalCenter: parent.verticalCenter; text: "Today"; color: Ink.inkMuted; width: Type.px(50) }
        Repeater {
          model: root.focusView ? root.focusView.goal : 4
          Rectangle {
            id: mark
            required property int index
            readonly property bool done: root.focusView && index < root.focusView.done
            readonly property bool now: root.focusView && root.focusView.kind === "focus" && index === root.focusView.done
            width: Type.px(22)
            height: width
            radius: 2
            rotation: [-2, 1.5, -1, 0.5][index % 4]
            color: mark.done ? Ink.seal : "transparent"
            border.width: 1
            border.color: mark.done || mark.now ? Ink.seal : Ink.lineStrong
            Text {
              anchors.centerIn: parent
              text: "集"
              color: mark.done ? Ink.paper : mark.now ? Ink.seal : Ink.inkFaint
              font.family: Type.jpSerif
              font.pixelSize: Type.px(11)
            }
          }
        }
      }
      Row {
        spacing: Type.px(8)
        Pill {
          visible: !!root.focusView && root.focusView.kind === "idle"
          label: "Start"
          on: true
          onClicked: root.request("focus", "start")
        }
        Pill {
          visible: !!root.focusView && root.focusView.kind !== "idle"
          label: root.focusView && root.focusView.paused ? "Resume" : "Pause"
          on: true
          onClicked: root.request("focus", root.focusView.paused ? "resume" : "pause")
        }
        Pill {
          visible: !!root.focusView && root.focusView.kind !== "idle"
          label: "+5 min"
          onClicked: root.request("focus", "more")
        }
        Pill {
          visible: !!root.focusView && root.focusView.kind !== "idle"
          label: root.focusView && root.focusView.kind === "break" ? "End break" : "Stop"
          onClicked: root.request("focus", "skip")
        }
      }
    }

    // ---------------------------------------------- hikae 控 notes
    Column {
      visible: root.kind === "hikae"
      width: parent.width
      topPadding: Type.px(14)
      Repeater {
        model: root.notesView ? root.notesView.shown : []
        Item {
          id: note
          required property var modelData
          width: parent.width
          height: Type.px(32)
          Rectangle {
            visible: note.modelData.box
            anchors.verticalCenter: parent.verticalCenter
            width: Type.px(12)
            height: width
            radius: 2
            color: note.modelData.done ? Ink.inkMuted : "transparent"
            border.width: 1
            border.color: Ink.lineStrong
          }
          Serif {
            x: note.modelData.box ? Type.px(24) : 0
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - x
            elide: Text.ElideRight
            text: note.modelData.text
            color: note.modelData.done ? Ink.inkFaint : Ink.ink
            font.strikeout: note.modelData.done
          }
          Rectangle { y: parent.height - 1; width: parent.width; height: 1; color: Ink.lineSoft }
          MouseArea {
            anchors.fill: parent
            enabled: note.modelData.box
            cursorShape: Qt.PointingHandCursor
            onClicked: root.request("note", note.modelData.line)
          }
        }
      }
      Item { width: 1; height: Type.px(8) }
      Link {
        text: !root.d.notesExist ? "+ Start a list" : root.notesView && root.notesView.more > 0 ? "+ " + root.notesView.more + " more · edit" : "+ Add a line"
        onClicked: root.request("notes", null)
      }
      Item { width: 1; height: Type.px(18); visible: root.clips.length > 0 }
      Mono { visible: root.clips.length > 0; text: "板 Clipboard"; color: Ink.inkMuted }
      Item { width: 1; height: Type.px(6); visible: root.clips.length > 0 }
      Repeater {
        model: root.clips
        Item {
          id: clip
          required property var modelData
          width: parent.width
          height: Type.px(20)
          Text {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            elide: Text.ElideRight
            text: clip.modelData.text
            color: clipHover.containsMouse ? Ink.ink : clip.modelData.image ? Ink.inkMuted : Ink.inkDim
            font.family: Type.mono
            font.pixelSize: Type.label
            font.italic: clip.modelData.image
          }
          MouseArea {
            id: clipHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.request("clip", clip.modelData.index)
          }
        }
      }
    }
  }

  // ------------------------------------------------ batsu 跋 afterword
  Item {
    anchors.fill: parent
    visible: root.kind === "batsu"
    Column {
      anchors.centerIn: parent
      anchors.verticalCenterOffset: Type.px(10)
      spacing: Type.px(14)
      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: "終"
        color: Ink.ink
        font.family: Type.jpSerif
        font.weight: Font.Light
        font.pixelSize: Type.px(120)
      }
      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: "<i>the end of the scroll</i>"
        textFormat: Text.StyledText
        color: Ink.inkMuted
        font.family: Type.display
        font.variableAxes: Type.axes(Type.px(20))
        font.pixelSize: Type.px(20)
        font.weight: Font.Normal
      }
      Mono {
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.kind === "batsu" ? LeafJs.afterword(root.now, root.sections).line : ""
        color: Ink.inkFaint
      }
      Item { width: 1; height: Type.px(6) }
      Seal { anchors.horizontalCenter: parent.horizontalCenter; glyph: root.sealGlyph; size: 30; tilt: -3 }
    }
  }

  // ---------------------------------------------------------- pieces
  component Mono: Text {
    font.family: Type.mono
    font.pixelSize: Type.label
    font.letterSpacing: Type.trackLabel
    font.capitalization: Font.AllUppercase
  }

  component Serif: Text {
    font.family: Type.display
    font.variableAxes: Type.axes(Type.label)
    font.pixelSize: Type.byline
    font.weight: Font.Normal
  }

  component Link: Text {
    id: link
    signal clicked()
    color: linkArea.containsMouse ? Ink.ink : Ink.inkMuted
    font.family: Type.mono
    font.pixelSize: Type.label
    font.letterSpacing: Type.trackLabel
    font.capitalization: Font.AllUppercase
    MouseArea {
      id: linkArea
      anchors.fill: parent
      anchors.margins: -Type.px(4)
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: link.clicked()
    }
  }

  component Fact: Item {
    id: fact
    property string k: ""
    property string v: ""
    property bool italic: false
    width: parent ? parent.width : 0
    height: Type.px(28)
    Text {
      id: factKey
      anchors.verticalCenter: parent.verticalCenter
      text: fact.k
      color: Ink.inkMuted
      font.family: Type.mono
      font.pixelSize: Type.label
      font.letterSpacing: Type.trackLabel
      font.capitalization: Font.AllUppercase
    }
    Text {
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      width: Math.min(implicitWidth, parent.width - factKey.width - Type.px(16))
      horizontalAlignment: Text.AlignRight
      elide: Text.ElideLeft
      text: fact.v
      color: Ink.inkDim
      font.family: Type.display
      font.variableAxes: Type.axes(Type.px(14))
      font.pixelSize: Type.px(14)
      font.weight: Font.Normal
      font.italic: fact.italic
    }
    Rectangle { y: parent.height - 1; width: parent.width; height: 1; color: Ink.lineSoft }
  }

  component Seal: Rectangle {
    id: seal
    property string glyph: ""
    property real size: 30
    property real tilt: 0
    property bool hollow: false
    width: Type.px(size)
    height: width
    radius: 2
    rotation: tilt
    color: hollow ? "transparent" : Ink.seal
    border.width: hollow ? 1.5 : 0
    border.color: Ink.seal
    Text {
      anchors.centerIn: parent
      text: seal.glyph
      color: seal.hollow ? Ink.seal : Ink.paper
      font.family: /[　-鿿]/.test(seal.glyph) ? Type.jpSerif : Type.display
      font.pixelSize: Type.px(seal.size * 0.56)
    }
  }

  // The moon as a lit disc: an ink disc with a paper disc over it, slid
  // across as it waxes or wanes (a crescent and a gibbous both read).
  component Moon: Item {
    id: moonItem
    property real size: 46
    property real lit: 0
    property bool waxing: true
    width: size
    height: size
    clip: true
    Rectangle { anchors.fill: parent; radius: width / 2; color: moonItem.lit > 0.02 ? Ink.ink : "transparent" }
    Rectangle {
      // Lit 0 covers it all, 1 covers none.
      readonly property real shift: Math.min(1, moonItem.lit * 1.25) * moonItem.size
      x: moonItem.waxing ? -shift : shift
      width: moonItem.size
      height: width
      radius: width / 2
      color: Ink.paper
      visible: moonItem.lit < 0.98
    }
    Rectangle { anchors.fill: parent; radius: width / 2; color: "transparent"; border.width: 1; border.color: Ink.lineStrong }
  }

  component Pill: Rectangle {
    id: pill
    property string label: ""
    property bool on: false
    signal clicked()
    width: pillText.implicitWidth + Type.px(22)
    height: Type.px(26)
    radius: 2
    color: on ? Ink.bone : pillArea.containsMouse ? Ink.lineSoft : "transparent"
    border.width: 1
    border.color: on ? Ink.bone : Ink.line
    Text {
      id: pillText
      anchors.centerIn: parent
      text: pill.label
      color: pill.on ? Ink.boneInk : Ink.inkDim
      font.family: Type.mono
      font.pixelSize: Type.label
      font.letterSpacing: Type.trackLabel
      font.capitalization: Font.AllUppercase
    }
    MouseArea {
      id: pillArea
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: pill.clicked()
    }
  }
}
