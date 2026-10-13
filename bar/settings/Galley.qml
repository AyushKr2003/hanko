pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Settings.js" as Settings
import "../../core/Inkan.js" as Inkan
import ".."

// Typesetting's galley (校正, docs/settings-kosei): your bar pulled as a
// proof. It is laid out at your screen's width, as it is on your desktop,
// and set in two lines, the way a galley runs a long line over: the left
// zone, then from just before the clock to the right end, each at close to
// its real size. Each part is numbered in the margin under it; hover one
// and it is bracketed, click it and its case opens below. The bar's foot
// is the Edge, the paper around it the Frame. Under form: inkan there is
// no strip: a screen in small, the seal in its corner.
//
// The bar here never acts: one MouseArea over it takes every click.
Item {
  id: root

  property var style: ({})
  property var barData: ({})
  // The part whose case is open (Settings.PROOF key).
  property string part: "seal"
  // Parts that differ from the preset (red ticks: red is you).
  property var edited: []
  // Parts a search leaves lit; [] lights them all.
  property var lit: []
  property bool compact: false
  // false: a plain proof (Presets): no numbers, brackets or clicks.
  property bool marks: true
  // The head's words, when not the proof's own.
  property string label: ""
  // The width the bar is laid out at: your screen's (logical px).
  property real screenWidth: barData.screenWidth || Type.px(1920)

  signal partPicked(string key)

  readonly property bool inkan: style.form === "inkan"
  readonly property int pad: Type.px(compact ? 12 : 20)
  readonly property int bandHeight: marks ? Type.px(compact ? 28 : 32) : Type.px(10)
  readonly property string hovered: marks && hover.containsMouse ? partAt(hover.mouseX - body.x, hover.mouseY - body.y) : ""

  implicitHeight: body.y + body.height + Type.px(compact ? 8 : 10)

  Rectangle {
    anchors.fill: parent
    radius: 3
    color: "transparent"
    border.width: 1
    border.color: Ink.line
  }

  // Head: what this is, and how to use it.
  Item {
    id: head
    x: root.pad
    y: Type.px(12)
    width: root.width - 2 * root.pad
    height: Type.px(14)
    Row {
      id: headLeft
      anchors.verticalCenter: parent.verticalCenter
      spacing: Type.px(8)
      Text { anchors.verticalCenter: parent.verticalCenter; text: "校正"; color: Ink.seal; font.family: Type.jp; font.pixelSize: Type.px(12) }
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.label !== "" ? root.label : root.inkan ? "PROOF · YOUR SEAL, LIVE" : "PROOF · YOUR BAR, LIVE, SET IN TWO LINES"
        color: Ink.inkMuted
        font.family: Type.mono
        font.pixelSize: Type.tag
        font.letterSpacing: Type.trackLabel
      }
    }
    Text {
      // Gives way when the head needs the room.
      visible: root.marks && headLeft.width + implicitWidth + Type.px(32) <= head.width
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      text: "CLICK A PART  ·  ← →  ·  1–0"
      color: Ink.inkFaint
      font.family: Type.mono
      font.pixelSize: Type.tag
      font.letterSpacing: Type.trackLabel
    }
  }

  // ------------------------------------------------------------ the body
  Item {
    id: body
    x: root.pad
    y: head.y + head.height + Type.px(16)
    width: root.width - 2 * root.pad
    height: root.inkan ? desk.height + root.bandHeight : lineTwo.y + lineTwo.height + root.bandHeight

    // The bar, measured: never seen, laid out at your screen's width. The
    // two lines draw the same bar, cropped.
    BarSurface {
      id: bar
      // Not `visible: false`: a hidden Row places nothing, and this one is
      // here to be measured.
      opacity: 0
      enabled: false
      width: root.screenWidth
      height: implicitHeight
      style: root.style
      now: root.barData.now || new Date()
      spaces: root.barData.spaces || []
      activeWindow: root.barData.activeWindow || null
      home: root.barData.home || ""
      media: root.barData.media || null
      timeFormat: root.barData.timeFormat || "HH:mm"
      volume: root.barData.volume || null
      network: root.barData.network || null
      bluetooth: root.barData.bluetooth || null
      battery: root.barData.battery || null
      brightness: root.barData.brightness || null
      notifications: root.barData.notifications || []
      dnd: !!root.barData.dnd
      indicators: root.barData.indicators || []
    }

    // Where the line runs over: just before the centre clock (or a little
    // before the middle when the clock sits at the right).
    property real split: root.screenWidth * 0.45
    // One scale for both lines, never above life size.
    readonly property real k: Math.min(1, width / Math.max(split, root.screenWidth - split))

    Line { id: lineOne; from: 0; to: body.split }
    Line { id: lineTwo; y: lineOne.height + root.bandHeight + Type.px(6); from: body.split; to: root.screenWidth }

    // Inkan: a screen in small, two windows outlined, the seal in its corner.
    Rectangle {
      id: desk
      visible: root.inkan
      width: parent.width
      height: Math.round(Math.min(width * 0.28, Type.px(210)))
      radius: 3
      color: "transparent"
      border.width: 1
      border.color: root.part === "frame" ? Ink.inkMuted : Ink.lineSoft
      Repeater {
        model: [[0.035, 0.12, 0.44, 0.76], [0.5, 0.12, 0.3, 0.76]]
        Rectangle {
          required property var modelData
          x: desk.width * modelData[0]
          y: desk.height * modelData[1]
          width: desk.width * modelData[2]
          height: desk.height * modelData[3]
          radius: 3
          color: "transparent"
          border.width: 1
          border.color: Ink.lineSoft
        }
      }
      readonly property bool west: String(root.style.inkanAt).indexOf("left") > 0
      readonly property bool high: String(root.style.inkanAt).indexOf("top") === 0
      InkanSeal {
        id: seal
        x: desk.west ? Type.px(14) : desk.width - Type.px(14) - width
        y: desk.high ? Type.px(14) : desk.height - Type.px(14) - height
        hovered: root.hovered === "seal"
        carving: Inkan.carving(root.style, {
          battery: root.barData.battery || null,
          network: root.barData.network || null,
          notifications: root.barData.notifications || [],
          dnd: !!root.barData.dnd,
          workspace: 1
        })
      }
      InkanReading {
        parts: Inkan.reading(root.barData, Qt.formatTime(root.barData.now || new Date(), root.barData.timeFormat || "HH:mm"))
        y: seal.y + (seal.height - height) / 2
        x: desk.west ? seal.x + seal.width + Type.px(14) : seal.x - Type.px(14) - width
      }
    }

    // Brackets: the hovered part faint, the open one in ink.
    Repeater {
      model: root.hovered !== root.part ? root.rectsOf(root.hovered) : []
      Bracket { required property rect modelData; target: modelData; strong: false }
    }
    Repeater {
      model: root.marks ? root.rectsOf(root.part) : []
      Bracket { required property rect modelData; target: modelData; strong: true }
    }

    // The margin: a number under each part that has a place on the bar,
    // joined to it by a leader; the open one inverted with its name, an
    // edited one ticked red.
    Repeater {
      model: Settings.PROOF
      Item {
        id: mark
        required property var modelData
        readonly property var where: root.rectsOf(modelData.key)
        readonly property rect r: where.length ? where[0] : Qt.rect(0, 0, 0, 0)
        readonly property bool placed: modelData.key !== "edge" && modelData.key !== "frame" && r.width > 0
        readonly property bool open: modelData.key === root.part
        readonly property bool hot: modelData.key === root.hovered
        readonly property bool dim: root.lit.length > 0 && root.lit.indexOf(modelData.key) < 0
        visible: placed && root.marks
        x: Math.round(r.x + r.width / 2)
        y: r.y + r.height + 1
        width: 1
        height: root.bandHeight
        opacity: dim ? 0.3 : 1

        Rectangle { width: 1; height: Type.px(8); color: mark.open ? Ink.ink : mark.hot ? Ink.inkMuted : Ink.line }
        Rectangle {
          x: -width / 2
          y: Type.px(9)
          width: tagText.implicitWidth + Type.px(mark.open ? 12 : 6)
          height: Type.px(17)
          radius: 2
          color: mark.open ? Ink.bone : "transparent"
          Text {
            id: tagText
            anchors.centerIn: parent
            text: mark.modelData.no + (mark.open ? "  " + mark.modelData.name.toUpperCase() : "")
            color: mark.open ? Ink.boneInk : mark.hot ? Ink.ink : Ink.inkMuted
            font.family: Type.mono
            font.pixelSize: Type.tag
            font.letterSpacing: Type.trackLabel
          }
          Rectangle {
            visible: root.edited.indexOf(mark.modelData.key) >= 0
            x: parent.width + Type.px(2)
            y: Type.px(2)
            width: Type.px(4)
            height: width
            radius: width / 2
            color: Ink.seal
          }
        }
      }
    }
  }

  MouseArea {
    id: hover
    enabled: root.marks
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: root.hovered !== "" ? Qt.PointingHandCursor : Qt.ArrowCursor
    onClicked: function(mouse) {
      var p = root.partAt(mouse.x - body.x, mouse.y - body.y)
      if (p !== "") root.partPicked(p)
    }
  }

  // ------------------------------------------------------- measuring
  // Each part's rects on the galley (a list: the edge and the frame run
  // along both lines), measured once the bar's rows have placed their
  // children (a binding can catch a Row half way).
  property var rects: ({})
  readonly property real tick: bar.layoutTick + body.width + root.screenWidth + desk.height + seal.x + seal.y + (inkan ? 1 : 0)
  onTickChanged: settle.restart()
  Timer { id: settle; interval: 30; onTriggered: root.measure() }
  Component.onCompleted: settle.restart()
  function measure() {
    var c = bar.partRect("clock")
    body.split = !bar.clockRight && c.width > 0 ? Math.max(Type.px(200), c.x - Type.px(28)) : root.screenWidth * 0.45
    var out = {}
    var keys = ["seal", "spaces", "title", "clock", "media", "status", "indicators", "notif", "edge", "frame"]
    for (var i = 0; i < keys.length; i++) out[keys[i]] = place(keys[i])
    rects = out
  }
  // Bar coordinates -> the line the part is set on.
  function onLine(r) {
    var k = body.k
    var two = r.x + r.width / 2 >= body.split
    var line = two ? lineTwo : lineOne
    return Qt.rect(line.x + 1 + (r.x - line.from) * k, line.y + 1 + r.y * k, r.width * k, r.height * k)
  }
  function place(key) {
    if (inkan) {
      if (key === "seal") return [Qt.rect(seal.x, seal.y, seal.width, seal.height)]
      if (key === "frame") return [Qt.rect(0, 0, desk.width, desk.height)]
      return []
    }
    if (key === "frame") return [Qt.rect(lineOne.x, lineOne.y, lineOne.width, lineOne.height),
                                 Qt.rect(lineTwo.x, lineTwo.y, lineTwo.width, lineTwo.height)]
    if (key === "edge") {
      if (bar.partRect("edge").width <= 0) return []
      var band = Math.max(3, Type.px(6) * body.k)
      return [lineOne, lineTwo].map(function(l) {
        return bar.atBottom ? Qt.rect(l.x, l.y, l.width, band) : Qt.rect(l.x, l.y + l.height - band, l.width, band)
      })
    }
    var r = bar.partRect(key)
    return r.width > 0 ? [onLine(r)] : []
  }
  function rectsOf(key) { return key === "" ? [] : rects[key] || [] }

  // The part under a point of the body, "" over nothing that can be set;
  // the galley's margin is the Frame.
  function partAt(x, y) {
    if (x < 0 || y < 0 || x > body.width || y > body.height) return "frame"
    var order = inkan ? ["seal"] : ["edge", "seal", "spaces", "title", "clock", "media", "status", "indicators", "notif"]
    for (var i = 0; i < order.length; i++) {
      var list = rectsOf(order[i])
      for (var j = 0; j < list.length; j++) {
        var r = list[j]
        if (x >= r.x && x < r.x + r.width && y >= r.y - Type.px(2) && y < r.y + r.height + Type.px(2)) return order[i]
      }
    }
    return "frame"
  }

  // One line of the galley: the bar from `from` to `to`, in a hairline
  // slug frame.
  component Line: Rectangle {
    id: line
    property real from: 0
    property real to: 0
    visible: !root.inkan
    width: Math.round((to - from) * body.k) + 2
    height: Math.round(bar.height * body.k) + 2
    color: "transparent"
    border.width: 1
    border.color: root.part === "frame" ? Ink.inkMuted : Ink.lineSoft
    Item {
      x: 1
      y: 1
      width: parent.width - 2
      height: parent.height - 2
      clip: true
      BarSurface {
        x: -line.from * body.k
        width: root.screenWidth
        height: implicitHeight
        scale: body.k
        transformOrigin: Item.TopLeft
        style: root.style
        now: root.barData.now || new Date()
        spaces: root.barData.spaces || []
        activeWindow: root.barData.activeWindow || null
        home: root.barData.home || ""
        media: root.barData.media || null
        timeFormat: root.barData.timeFormat || "HH:mm"
        volume: root.barData.volume || null
        network: root.barData.network || null
        bluetooth: root.barData.bluetooth || null
        battery: root.barData.battery || null
        brightness: root.barData.brightness || null
        notifications: root.barData.notifications || []
        dnd: !!root.barData.dnd
        indicators: root.barData.indicators || []
      }
    }
  }

  // Four corner marks around a part, 3 px off it.
  component Bracket: Item {
    id: br
    property rect target: Qt.rect(0, 0, 0, 0)
    property bool strong: false
    readonly property int out: Type.px(3)
    readonly property int arm: Type.px(7)
    visible: target.width > 0
    x: target.x - out
    y: target.y - out
    width: target.width + 2 * out
    height: target.height + 2 * out
    Repeater {
      model: 4
      Item {
        id: corner
        required property int index
        readonly property bool east: index % 2 === 1
        readonly property bool low: index >= 2
        x: east ? br.width - br.arm : 0
        y: low ? br.height - br.arm : 0
        width: br.arm
        height: br.arm
        Rectangle { x: corner.east ? parent.width - width : 0; width: br.strong ? 2 : 1; height: parent.height; color: br.strong ? Ink.ink : Ink.inkMuted }
        Rectangle { y: corner.low ? parent.height - height : 0; width: parent.width; height: br.strong ? 2 : 1; color: br.strong ? Ink.ink : Ink.inkMuted }
      }
    }
  }
}
