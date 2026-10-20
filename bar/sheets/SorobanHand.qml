pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Hands.js" as Hands

// Soroban 算盤, the abacus. The sheet's figures are counted out on rods,
// tens and units (and hundreds when a figure needs them): a bead counts
// when it is pushed to the beam, the heaven bead five and each earth bead
// one; a spare rod and a unit dot on the beam part the readings, and the
// sheet's own reading is lacquered red. A click on a bead of a reading you
// can set counts to it, as a finger flicks a bead. Every other level
// (a network, a device, a letter) is a wire of ten beads with as many
// pushed home as its level; each choice is one bead on its wire, slid
// across for the one in use. Beads are the soroban's double cones; one
// that does not count rests away from the beam, outlined.
HandSheet {
  id: root
  setHint: "Click a bead to count to it"

  // What the frame counts: the model's tally, else its rows.
  readonly property bool tallied: model.tally.length > 0
  readonly property var groups: {
    var g = []
    if (tallied) {
      for (var i = 0; i < model.tally.length && i < 3; i++)
        g.push({ name: model.tally[i].name, n: model.tally[i].n, red: !!model.tally[i].lead, muted: false, row: null })
    } else {
      var r = Hands.ranks(model)
      for (var j = 0; j < r.length && j < 3; j++)
        g.push({ name: r[j].name, n: r[j].muted ? 0 : r[j].count, red: (r[j].lead && !r[j].muted) || r[j].urgent,
                 muted: r[j].muted, row: r[j] })
    }
    return g
  }
  // Rods: one per digit (two at least), a spare rod between readings.
  readonly property var rods: {
    var out = []
    for (var i = 0; i < groups.length; i++) {
      var n = Math.max(0, Math.min(999, Math.round(groups[i].n)))
      var digits = Math.max(2, String(n).length)
      if (i > 0) out.push({ spare: true })
      for (var d = digits - 1; d >= 0; d--) {
        var place = Math.pow(10, d)
        out.push({ spare: false, digit: Math.floor(n / place) % 10, place: place, n: n, group: i,
                   red: groups[i].red, muted: groups[i].muted })
      }
    }
    return out
  }
  // Levels the frame does not count: a wire each.
  readonly property var wires: tallied ? model.levels : []
  readonly property int firstRods: rods.length > 0 ? rods.filter(function(r) { return !r.spare && r.group === 0 }).length : 0

  // A bead of a reading was clicked: the count it now stands at.
  function flick(rod, heaven, i) {
    var g = root.groups[rod.group]
    if (!g.row || !g.row.set) return
    var d = rod.digit
    var nd = heaven ? (d >= 5 ? d - 5 : d + 5) : (d >= 5 ? 5 : 0) + (i < d % 5 ? i : i + 1)
    root.pick(g.row, Math.min(100, rod.n - d * rod.place + nd * rod.place) / 100)
  }

  FigureHero {
    hero: root.hero
    caption: root.groups.length > 0 && root.groups[0].red
      ? root.groups[0].name + " · counted on the first " + (root.firstRods === 3 ? "three" : "two") + " rods"
      : root.hero.caption
  }
  Item { width: 1; height: Type.px(16); visible: root.rods.length > 0 }

  // The frame.
  Item {
    id: frame
    visible: root.rods.length > 0
    readonly property real pad: Type.px(10)
    readonly property real pitch: Math.min(Type.px(36), (root.inner - 2 * pad) / Math.max(1, root.rods.length))
    readonly property real bw: Math.min(Type.px(28), pitch - Type.px(4))
    readonly property real bh: Type.px(12)
    readonly property real heaven: pad + bh * 2 + Type.px(4)
    readonly property real beamH: Type.px(5)
    readonly property real earth: bh * 5 + Type.px(6)
    width: root.rods.length * pitch + 2 * pad
    height: heaven + beamH + earth + pad
    anchors.horizontalCenter: parent.horizontalCenter

    Rectangle {
      anchors.fill: parent
      color: Ink.alpha(Ink.bone, 0.03)
      border.width: Type.px(3)
      border.color: Ink.lineStrong
      radius: 2
    }
    Repeater {
      model: root.rods
      Rectangle {
        required property int index
        x: frame.pad + index * frame.pitch + frame.pitch / 2
        y: Type.px(3)
        width: 1
        height: frame.height - Type.px(6)
        color: Ink.line
      }
    }
    // The beam, with a unit dot on each spare rod.
    Rectangle {
      x: Type.px(3)
      y: frame.heaven
      width: frame.width - Type.px(6)
      height: frame.beamH
      color: Ink.lineStrong
      Repeater {
        model: root.rods
        Rectangle {
          required property var modelData
          required property int index
          visible: modelData.spare
          x: frame.pad - Type.px(3) + index * frame.pitch + frame.pitch / 2 - width / 2
          anchors.verticalCenter: parent.verticalCenter
          width: Type.px(4); height: width; radius: width / 2
          color: Ink.paper
        }
      }
    }
    Repeater {
      model: root.rods
      Item {
        id: rod
        required property var modelData
        required property int index
        readonly property var r: modelData
        readonly property int d: r.digit || 0
        readonly property int ones: d % 5
        readonly property color tint: r.red ? Ink.seal : r.muted ? Ink.inkFaint : Ink.ink
        readonly property bool live: !r.spare && !!root.groups[r.group].row && !!root.groups[r.group].row.set
        // Te 手 (core/Cursor.js): Up counts a bead more on this rod, Down
        // one less; Left/Right go along the frame.
        readonly property bool keyStop: live
        readonly property bool keyStep: true
        readonly property string keyAxis: "y"
        function keyAdjust(d) {
          root.pick(root.groups[rod.r.group].row, Math.max(0, Math.min(100, rod.r.n - d * rod.r.place)) / 100)
        }
        visible: !r.spare
        x: frame.pad + index * frame.pitch + (frame.pitch - frame.bw) / 2
        width: frame.bw
        height: frame.height

        Bead {
          width: frame.bw
          y: rod.d >= 5 ? frame.heaven - frame.bh : frame.pad
          counted: rod.d >= 5; tint: rod.tint
          Behavior on y { enabled: Motion.live; NumberAnimation { duration: Motion.ms(120); easing.type: Easing.OutCubic } }
          MouseArea {
            anchors.fill: parent
            enabled: rod.live
            cursorShape: Qt.PointingHandCursor
            onClicked: root.flick(rod.r, true, 0)
          }
        }
        Repeater {
          model: 4
          Bead {
            id: earth
            required property int index
            width: frame.bw
            y: index < rod.ones
              ? frame.heaven + frame.beamH + index * frame.bh
              : frame.height - frame.pad - (4 - index) * frame.bh
            counted: index < rod.ones; tint: rod.tint
            Behavior on y { enabled: Motion.live; NumberAnimation { duration: Motion.ms(120); easing.type: Easing.OutCubic } }
            MouseArea {
              anchors.fill: parent
              enabled: rod.live
              cursorShape: Qt.PointingHandCursor
              onClicked: root.flick(rod.r, false, earth.index)
            }
          }
        }
      }
    }
  }

  // The readings under their rods.
  Item {
    visible: root.rods.length > 0
    width: frame.width
    height: Type.px(40)
    anchors.horizontalCenter: parent.horizontalCenter
    Repeater {
      model: root.groups
      Column {
        id: reading
        required property var modelData
        required property int index
        readonly property var span: {
          var first = -1, last = -1
          for (var i = 0; i < root.rods.length; i++)
            if (!root.rods[i].spare && root.rods[i].group === index) { if (first < 0) first = i; last = i }
          return [first, last]
        }
        x: frame.pad + span[0] * frame.pitch - Type.px(20)
        width: (span[1] - span[0] + 1) * frame.pitch + Type.px(40)
        topPadding: Type.px(8)
        spacing: Type.px(2)
        Text {
          width: parent.width
          horizontalAlignment: Text.AlignHCenter
          elide: Text.ElideRight
          text: reading.modelData.name
          color: Ink.ink
          font.family: Type.text
          font.pixelSize: Type.px(12)
        }
        Text {
          width: parent.width
          horizontalAlignment: Text.AlignHCenter
          text: reading.modelData.muted ? "MUTED" : String(Math.round(reading.modelData.n))
          color: reading.modelData.red ? Ink.seal : Ink.inkMuted
          font.family: Type.mono
          font.pixelSize: Type.tag
          font.letterSpacing: Type.trackTag
        }
      }
    }
  }

  // Levels the frame does not count: ten beads on a wire, as many home as the level.
  Item { width: 1; height: Type.px(8); visible: root.wires.length > 0 }
  Repeater {
    model: root.wires
    Item {
      id: wire
      required property var modelData
      readonly property var r: modelData
      readonly property bool keyStop: !!(r.set || r.click)
      readonly property bool keyStep: !!r.set
      readonly property bool keyChosen: !!r.selected
      function keyAdjust(d) { root.nudge(wire.r, d, 0.1) }
      function keyPress() { root.act(wire.r.click) }
      readonly property int home: Math.round(Math.max(0, Math.min(1, r.level)) * 10)
      readonly property real beadW: Type.px(9)
      readonly property real wireW: Type.px(150)
      width: root.inner
      height: Type.px(34)

      Text {
        width: Type.px(24)
        anchors.verticalCenter: parent.verticalCenter
        text: wire.r.mark
        color: wire.r.urgent ? Ink.seal : Ink.inkMuted
        font.family: Type.brush
        font.pixelSize: Type.px(14)
      }
      Column {
        x: Type.px(28)
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - x - wire.wireW - Type.px(64)
        Text { width: parent.width; elide: Text.ElideRight; text: wire.r.name; color: wire.r.selected ? Ink.ink : Ink.inkDim; font.family: Type.text; font.pixelSize: Type.px(13) }
        Text { width: parent.width; elide: Text.ElideRight; visible: text !== ""; text: wire.r.detail; color: Ink.inkMuted; font.family: Type.text; font.pixelSize: Type.px(11) }
      }
      // The wire: a beam at the left, the counted beads pushed against it.
      Item {
        x: parent.width - wire.wireW - Type.px(56)
        width: wire.wireW
        height: parent.height
        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 1; color: Ink.line }
        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: Type.px(3); height: Type.px(18); color: Ink.lineStrong }
        Repeater {
          model: 10
          Bead {
            required property int index
            across: true
            width: wire.beadW
            height: Type.px(16)
            anchors.verticalCenter: parent.verticalCenter
            x: index < wire.home ? Type.px(4) + index * wire.beadW : wire.wireW - (10 - index) * wire.beadW
            counted: index < wire.home
            tint: wire.r.urgent || wire.r.selected ? Ink.seal : wire.r.dashed ? Ink.inkFaint : Ink.ink
            Behavior on x { enabled: Motion.live; NumberAnimation { duration: Motion.ms(140); easing.type: Easing.OutCubic } }
          }
        }
      }
      Text {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: (wire.r.figure || wire.r.note).toUpperCase()
        color: wire.r.selected || wire.r.urgent ? Ink.seal : Ink.inkMuted
        font.family: Type.mono
        font.pixelSize: Type.tag
        font.letterSpacing: Type.trackTag
      }
      MouseArea {
        anchors.fill: parent
        enabled: !!wire.r.click
        cursorShape: Qt.PointingHandCursor
        onClicked: root.act(wire.r.click)
      }
    }
  }

  // Choices: one bead on its own wire, slid across for the one in use.
  Item { width: 1; height: Type.px(10); visible: root.model.choices.length > 0 }
  Row {
    visible: root.model.choices.length > 0
    spacing: Type.px(10)
    Text { anchors.verticalCenter: parent.verticalCenter; text: root.model.choicesMark; color: Ink.inkMuted; font.family: Type.brush; font.pixelSize: Type.px(13) }
    Text { anchors.verticalCenter: parent.verticalCenter; text: root.model.choicesLabel.toUpperCase(); color: Ink.inkMuted; font.family: Type.mono; font.pixelSize: Type.tag; font.letterSpacing: Type.trackTag }
  }
  Item { width: 1; height: Type.px(6); visible: root.model.choices.length > 0 }

  // Inline (a week): one wire, the days gone and today pushed home.
  Item {
    id: week
    visible: root.model.inline && root.model.choices.length > 0
    readonly property real slot: Math.min(Type.px(52), (root.inner - Type.px(40)) / Math.max(1, root.model.choices.length))
    readonly property int home: root.model.choices.filter(function(c) { return c.dashed || c.selected }).length
    width: root.inner
    height: visible ? Type.px(74) : 0
    Rectangle { y: Type.px(37); width: parent.width; height: 1; color: Ink.line }
    Rectangle { y: Type.px(28); width: Type.px(3); height: Type.px(18); color: Ink.lineStrong }
    Repeater {
      model: root.model.inline ? root.model.choices : []
      Item {
        id: day
        required property var modelData
        required property int index
        readonly property bool keyStop: !!modelData.click
        readonly property bool keyChosen: !!modelData.selected
        function keyPress() { root.act(day.modelData.click) }
        readonly property bool home: index < week.home
        x: home ? Type.px(6) + index * week.slot : root.inner - (root.model.choices.length - index) * week.slot
        width: week.slot
        height: week.height
        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: day.modelData.mark
          color: day.modelData.selected ? Ink.seal : day.modelData.dashed ? Ink.inkMuted : Ink.ink
          font.family: Type.brush
          font.pixelSize: Type.px(14)
        }
        Bead {
          across: true
          anchors.horizontalCenter: parent.horizontalCenter
          y: Type.px(28)
          width: Type.px(14)
          height: Type.px(18)
          counted: day.home
          tint: day.modelData.selected ? Ink.seal : Ink.inkDim
        }
        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          y: Type.px(52)
          text: day.modelData.name
          color: day.modelData.selected ? Ink.ink : Ink.inkMuted
          font.family: Type.mono
          font.pixelSize: Type.tag
          font.letterSpacing: Type.trackTag
        }
        MouseArea {
          anchors.fill: parent
          enabled: !!day.modelData.click
          cursorShape: Qt.PointingHandCursor
          onClicked: root.act(day.modelData.click)
        }
      }
    }
  }

  // A line of choices: each one bead on a short wire.
  Repeater {
    model: root.model.inline ? [] : root.model.choices
    Item {
      id: choice
      required property var modelData
      readonly property var c: modelData
      readonly property bool keyStop: !!c.click
      readonly property bool keyChosen: !!c.selected
      function keyPress() { root.act(choice.c.click) }
      width: root.inner
      height: Type.px(c.detail !== "" ? 34 : 26)
      Rectangle { anchors.verticalCenter: parent.verticalCenter; width: Type.px(56); height: 1; color: Ink.line }
      Bead {
        width: Type.px(28)
        x: choice.c.selected ? Type.px(28) : 0
        anchors.verticalCenter: parent.verticalCenter
        counted: choice.c.selected
        tint: Ink.seal
        Behavior on x { enabled: Motion.live; NumberAnimation { duration: Motion.ms(140); easing.type: Easing.OutCubic } }
      }
      Column {
        x: Type.px(70)
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - x - Type.px(80)
        Text { width: parent.width; elide: Text.ElideRight; text: choice.c.name; color: choice.c.selected ? Ink.ink : choice.c.dashed ? Ink.inkMuted : Ink.inkDim; font.family: Type.text; font.pixelSize: Type.px(13) }
        Text { width: parent.width; elide: Text.ElideRight; visible: choice.c.detail !== ""; text: choice.c.detail; color: Ink.inkMuted; font.family: Type.text; font.pixelSize: Type.px(11) }
      }
      Text {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: choice.c.note.toUpperCase()
        color: Ink.inkMuted
        font.family: Type.mono
        font.pixelSize: Type.tag
        font.letterSpacing: Type.trackTag
      }
      MouseArea {
        anchors.fill: parent
        enabled: !!choice.c.click
        cursorShape: Qt.PointingHandCursor
        onClicked: root.act(choice.c.click)
      }
    }
  }

  // A soroban bead: two cones base to base, so a flattened hexagon (on a
  // wire across the sheet, `across`, the hexagon stands on end).
  component Bead: Canvas {
    property bool counted: false
    property bool across: false
    property color tint: Ink.ink
    width: Type.px(28)
    height: Type.px(12)
    onCountedChanged: requestPaint()
    onTintChanged: requestPaint()
    onPaint: {
      var g = getContext("2d"), w = width, h = height
      g.reset()
      g.beginPath()
      if (across) {
        g.moveTo(w / 2, 0.5); g.lineTo(w - 0.5, h * 0.3); g.lineTo(w - 0.5, h * 0.7)
        g.lineTo(w / 2, h - 0.5); g.lineTo(0.5, h * 0.7); g.lineTo(0.5, h * 0.3)
      } else {
        g.moveTo(0.5, h / 2); g.lineTo(w * 0.3, 0.5); g.lineTo(w * 0.7, 0.5)
        g.lineTo(w - 0.5, h / 2); g.lineTo(w * 0.7, h - 0.5); g.lineTo(w * 0.3, h - 0.5)
      }
      g.closePath()
      if (counted) { g.fillStyle = tint; g.fill() }
      else { g.fillStyle = Ink.alpha(Ink.bone, 0.06); g.fill(); g.strokeStyle = Ink.line; g.lineWidth = 1; g.stroke() }
      // The ridge where the cones meet.
      g.beginPath()
      if (across) { g.moveTo(w / 2, h * 0.12); g.lineTo(w / 2, h * 0.88) }
      else { g.moveTo(w * 0.12, h / 2); g.lineTo(w * 0.88, h / 2) }
      g.strokeStyle = counted ? Ink.alpha(Ink.paper, 0.35) : Ink.lineSoft
      g.stroke()
    }
  }
}
