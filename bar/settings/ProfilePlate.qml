pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Style.js" as S
import "../../core/Edge.js" as E
import "../../core/Profile.js" as P

// Profile 印影, the seal register: the plate people screenshot to show their
// desk. Your seal glyph pressed large and worn, bleeding off the right; your
// name monumental in Fraunces over the glyph's own watermark; the bar's live
// readings pinned to the impression by hairline leaders; the dossier's
// small print (preset, which of the combinations this bar is, theme,
// kernel, uptime) at the foot with the six inks you are set in, and the day
// as a rule. Ink on paper; the seal is the only red. EDIT lets you rename
// it, give it a line and hide any block (core/Dossier.qml).
Item {
  id: root

  // The resolved style and its document (Typeset's draft).
  property var style: S.resolve({})
  property var doc: S.normalize({})
  // services/Machine.qml info, core/Dossier.qml doc, the bar's live data.
  property var machine: P.parseMachine("")
  property var profile: ({ name: "", tagline: "", hidden: [] })
  property var barData: ({})
  property string version: ""
  property date now: new Date()
  // Where SAVE IMAGE writes (~/Pictures); empty hides it.
  property string picturesDir: ""

  signal textEdited(string field, string value)
  signal blockToggled(string block)
  signal profileReset()

  property bool editing: false
  property bool grabbing: false
  property string savedTo: ""

  readonly property bool wide: width >= Type.px(1000)
  readonly property int margin: Type.px(wide ? 56 : 28)
  readonly property string edition: P.edition(machine.machine + machine.since)
  readonly property var vitals: P.vitals(barData)
  readonly property var specs: P.specs(style, doc, machine, version, S.OPTIONS, S.KEYS, S.combinations())
  readonly property string name: profile.name || machine.user || "you"
  readonly property string tagline: profile.tagline || ("Set in ink on " + (machine.theme || "your theme") + ".")

  function shown(block) { return (profile.hidden || []).indexOf(block) < 0 }
  function visibleBlock(block) { return shown(block) || editing }
  function blockOpacity(block) { return shown(block) ? 1 : 0.25 }

  function saveImage() {
    if (!picturesDir) return
    grabbing = true
    grabTimer.start()
  }
  Timer {
    id: grabTimer
    interval: 60
    onTriggered: {
      var path = root.picturesDir + "/hanko-profile-" + Qt.formatDate(new Date(), "yyyyMMdd") + ".png"
      root.grabToImage(function(result) {
        var ok = result.saveToFile(path)
        root.grabbing = false
        root.savedTo = ok ? "SAVED  ·  " + path : "COULD NOT WRITE " + path
        savedTimer.restart()
      })
    }
  }
  Timer { id: savedTimer; interval: 4000; onTriggered: root.savedTo = "" }

  Rectangle { anchors.fill: parent; color: Ink.paper }

  // ------------------------------------------------ the glyph's watermark
  Text {
    visible: root.visibleBlock("watermark")
    opacity: root.blockOpacity("watermark")
    x: root.width * 0.42 - width / 2
    anchors.verticalCenter: parent.verticalCenter
    text: root.style.sealGlyph || "印"
    color: Ink.alpha(Ink.ink, 0.05)
    font.family: Type.jpSerif
    font.pixelSize: Math.min(root.height * 0.66, Type.px(560))
  }

  // ------------------------------------------------ the impression
  SealImpression {
    id: seal
    visible: root.visibleBlock("seal")
    readonly property real size: Math.round(Math.min(root.height * 0.68, root.width * (root.wide ? 0.46 : 0.62)))
    width: size
    height: size
    x: root.width - size * 0.8
    y: root.height * 0.47 - size / 2
    rotation: -5
    opacity: root.blockOpacity("seal") * (root.wide ? 1 : 0.4)
    glyph: root.style.sealGlyph || "印"
    seed: Number(root.edition) / 1000
    // A point on the impression, as the page sees it (the seal is turned).
    function at(fx, fy) {
      var a = rotation * Math.PI / 180
      var dx = (fx - 0.5) * width, dy = (fy - 0.5) * height
      return { x: x + width / 2 + dx * Math.cos(a) - dy * Math.sin(a), y: y + height / 2 + dx * Math.sin(a) + dy * Math.cos(a) }
    }
  }
  EyeChip { block: "seal"; x: seal.x + Type.px(20); y: seal.y - height - Type.px(10) }

  // ------------------------------------------------ the spine
  PlateSpine {
    visible: root.visibleBlock("spine")
    opacity: root.blockOpacity("spine")
    x: Type.px(22)
    anchors.verticalCenter: parent.verticalCenter
    text: ("HANKO  ·  印影 SEAL REGISTER  ·  " + root.machine.user + (root.machine.host ? "@" + root.machine.host : "")
           + (root.machine.kernel ? "  ·  KERNEL " + root.machine.kernel : "") + "  ·  SET IN INK").toUpperCase()
  }

  // ------------------------------------------------ the identity
  Column {
    id: head
    x: root.margin
    y: root.margin
    width: Math.min(Type.px(600), root.width - 2 * root.margin)
    spacing: Type.px(12)

    PlateEyebrow { jp: "印影"; label: "Seal register  ·  No. " + root.edition }
    InlineText {
      width: parent.width
      height: Type.px(root.wide ? 112 : 64)
      field: "name"
      value: root.name
      color: Ink.ink
      family: Type.display
      size: Type.px(root.wide ? 104 : 56)
      fit: true
    }
    Text {
      text: "@" + P.fv(root.machine.host) + "   ·   " + Qt.formatTime(root.now, "HH:mm")
      color: Ink.inkMuted
      font.family: Type.mono
      font.pixelSize: Type.note
    }
    InlineText {
      width: Math.min(parent.width, Type.px(420))
      height: Type.px(24)
      field: "tagline"
      value: root.tagline
      color: Ink.inkDim
      family: Type.display
      size: Type.px(17)
      italic: true
    }
  }

  // ------------------------------------------------ the live readings
  Item {
    id: live
    visible: root.wide && root.visibleBlock("vitals")
    opacity: root.blockOpacity("vitals")
    anchors.fill: parent
    readonly property real cx: root.margin + Type.px(420)
    readonly property real topY: head.y + head.height + Type.px(40)
    readonly property real gap: Math.max(Type.px(56), Math.min(Type.px(78), (foot.y - topY - Type.px(30)) / Math.max(1, root.vitals.length)))
    // Where each reading touches the seal.
    readonly property var pins: [[0.30, 0.22], [0.22, 0.42], [0.30, 0.62], [0.46, 0.80], [0.62, 0.30]]

    EyeChip { block: "vitals"; x: live.cx; y: live.topY - Type.px(56) }

    Row {
      x: live.cx
      y: live.topY - Type.px(24)
      spacing: Type.px(8)
      Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: Type.px(6); height: width; radius: width / 2
        color: Ink.seal
        SequentialAnimation on opacity {
          running: !Motion.still
          loops: Animation.Infinite
          NumberAnimation { to: 0.25; duration: 900; easing.type: Easing.InOutQuad }
          NumberAnimation { to: 1; duration: 900; easing.type: Easing.InOutQuad }
        }
      }
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "脈 · LIVE FROM THE BAR"
        color: Ink.inkMuted
        font.family: Type.mono
        font.pixelSize: Type.tag
        font.letterSpacing: Type.trackEyebrow
      }
    }

    Canvas {
      id: leaders
      anchors.fill: parent
      readonly property var key: [live.topY, live.gap, seal.x, seal.y, seal.size, root.vitals.length, Ink.ink]
      onKeyChanged: requestPaint()
      onPaint: {
        var ctx = getContext("2d")
        ctx.reset()
        for (var i = 0; i < root.vitals.length && i < live.pins.length; i++) {
          var p = seal.at(live.pins[i][0], live.pins[i][1])
          var sx = live.cx + Type.px(170), sy = live.topY + i * live.gap + Type.px(26)
          ctx.strokeStyle = Ink.alpha(Ink.ink, 0.3)
          ctx.lineWidth = 1
          ctx.beginPath(); ctx.moveTo(sx, sy); ctx.lineTo(p.x, p.y); ctx.stroke()
          ctx.fillStyle = Ink.ink
          ctx.beginPath(); ctx.arc(p.x, p.y, Type.px(2.6), 0, 2 * Math.PI); ctx.fill()
        }
      }
    }

    Repeater {
      model: root.vitals
      Column {
        id: callout
        required property var modelData
        required property int index
        x: live.cx
        y: live.topY + callout.index * live.gap
        width: Type.px(170)
        spacing: 0
        Row {
          spacing: Type.px(6)
          Text { text: callout.modelData.jp; color: Ink.inkFaint; font.family: Type.jp; font.pixelSize: Type.tag }
          Text { text: callout.modelData.name; color: Ink.inkMuted; font.family: Type.mono; font.pixelSize: Type.tag; font.letterSpacing: Type.trackLabel }
        }
        Text {
          width: parent.width
          elide: Text.ElideRight
          text: callout.modelData.big
          color: Ink.ink
          font.family: Type.text
          font.pixelSize: Type.px(28)
          font.weight: Font.Medium
          font.features: ({ "tnum": 1 })
        }
        Text {
          visible: live.gap >= Type.px(66)
          width: parent.width
          elide: Text.ElideRight
          text: callout.modelData.sub
          color: Ink.inkDim
          font.family: Type.mono
          font.pixelSize: Type.tag
        }
      }
    }
  }

  // ------------------------------------------------ the small print
  Column {
    id: foot
    x: root.margin
    anchors.bottom: parent.bottom
    anchors.bottomMargin: root.margin
    width: Math.min(Type.px(380), root.width - 2 * root.margin)
    spacing: Type.px(14)

    Item {
      width: parent.width
      height: specsColumn.height
      visible: root.visibleBlock("specs")
      Column {
        id: specsColumn
        width: parent.width
        opacity: root.blockOpacity("specs")
        Repeater {
          model: root.specs
          LeaderRow {
            required property var modelData
            width: specsColumn.width
            kind: "spec"
            name: modelData[0]
            value: modelData[1]
          }
        }
      }
      EyeChip { block: "specs"; anchors.left: parent.right; anchors.leftMargin: Type.px(10); anchors.verticalCenter: parent.verticalCenter }
    }

    // The six inks this desk is set in, with their names.
    Item {
      width: parent.width
      height: palette.height
      visible: root.visibleBlock("palette")
      Column {
        id: palette
        width: parent.width
        opacity: root.blockOpacity("palette")
        spacing: Type.px(5)
        Rectangle {
          width: parent.width
          height: Type.px(18)
          radius: 3
          color: "transparent"
          border.width: 1
          border.color: Ink.line
          clip: true
          Row {
            anchors.fill: parent
            anchors.margins: 1
            Repeater {
              model: [Ink.paper, Ink.ink, Ink.inkDim, Ink.inkMuted, Ink.inkFaint, Ink.seal]
              Rectangle {
                required property var modelData
                width: parent.width / 6
                height: parent.height
                color: modelData
              }
            }
          }
        }
        Row {
          Repeater {
            model: ["PAPER", "INK", "DIM", "MUTED", "FAINT", "SEAL"]
            Text {
              required property var modelData
              width: palette.width / 6
              text: modelData
              color: Ink.inkFaint
              font.family: Type.mono
              font.pixelSize: Type.tag
              font.letterSpacing: Type.trackTag
            }
          }
        }
      }
      EyeChip { block: "palette"; anchors.left: parent.right; anchors.leftMargin: Type.px(10); anchors.verticalCenter: parent.verticalCenter }
    }

    Text {
      text: "NO. " + root.edition + (root.machine.since ? "  ·  SET SINCE " + root.machine.since : "")
            + (root.machine.packages ? "  ·  " + root.machine.packages + " PACKAGES" : "")
      color: Ink.inkDim
      font.family: Type.mono
      font.pixelSize: Type.tag
      font.letterSpacing: Type.trackTag
    }
  }

  // ------------------------------------------------ the day, as a rule
  Item {
    id: day
    visible: root.wide && root.visibleBlock("day")
    opacity: root.blockOpacity("day")
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.rightMargin: root.margin
    anchors.bottomMargin: root.margin
    width: Type.px(260)
    height: Type.px(52)
    readonly property real fraction: E.dayFraction(root.now)

    EyeChip { block: "day"; anchors.right: parent.right; anchors.bottom: parent.top; anchors.bottomMargin: Type.px(8) }
    Text {
      text: "TODAY  ·  " + Qt.formatDate(root.now, "ddd d MMM").toUpperCase()
      color: Ink.inkMuted
      font.family: Type.mono
      font.pixelSize: Type.tag
      font.letterSpacing: Type.trackLabel
    }
    Text {
      anchors.right: parent.right
      text: Math.round(day.fraction * 100) + "% SPENT"
      color: Ink.inkDim
      font.family: Type.mono
      font.pixelSize: Type.tag
    }
    Item {
      anchors.bottom: parent.bottom
      width: parent.width
      height: Type.px(22)
      Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Ink.line }
      Rectangle { anchors.bottom: parent.bottom; width: parent.width * day.fraction; height: 2; color: Ink.inkDim }
      Repeater {
        model: 25
        Rectangle {
          required property int index
          x: Math.round(index / 24 * (day.width - 1))
          anchors.bottom: parent.bottom
          width: 1
          height: index % 6 === 0 ? Type.px(9) : Type.px(4)
          color: index % 6 === 0 ? Ink.inkMuted : Ink.inkFaint
        }
      }
      Rectangle {
        x: Math.round(day.fraction * (day.width - 2))
        anchors.bottom: parent.bottom
        width: 2
        height: Type.px(16)
        color: Ink.seal
      }
    }
  }

  // ------------------------------------------------ edit
  Rectangle {
    id: editButton
    visible: !root.grabbing
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.rightMargin: root.margin
    anchors.topMargin: root.margin
    width: editLabel.implicitWidth + 2 * Type.px(14)
    height: Type.px(30)
    radius: 3
    color: root.editing ? Ink.bone : editHover.hovered ? Ink.lineSoft : "transparent"
    border.width: 1
    border.color: root.editing ? Ink.bone : Ink.lineStrong
    Text {
      id: editLabel
      anchors.centerIn: parent
      text: root.editing ? "DONE" : "EDIT"
      color: root.editing ? Ink.boneInk : Ink.ink
      font.family: Type.mono
      font.pixelSize: Type.label
      font.letterSpacing: Type.px(1.8)
    }
    HoverHandler { id: editHover; cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: root.editing = !root.editing }
  }

  // The edit strip: what EDIT can do besides the fields and the eyes.
  Rectangle {
    visible: root.editing && !root.grabbing
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: Type.px(18)
    width: strip.width + 2 * Type.px(10)
    height: Type.px(46)
    radius: 3
    color: Ink.paper
    border.width: 1
    border.color: Ink.lineStrong
    Row {
      id: strip
      anchors.centerIn: parent
      spacing: Type.px(8)
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "CLICK YOUR NAME OR LINE TO REWRITE IT  ·  ◉ HIDES A BLOCK"
        color: Ink.inkMuted
        font.family: Type.mono
        font.pixelSize: Type.tag
        font.letterSpacing: Type.trackTag
        rightPadding: Type.px(8)
      }
      StripButton { visible: root.picturesDir !== ""; label: "Save image"; onClicked: root.saveImage() }
      StripButton { label: "Reset"; onClicked: root.profileReset() }
      StripButton { label: "Done"; plate: true; onClicked: root.editing = false }
    }
  }

  Text {
    visible: root.savedTo !== "" && !root.grabbing
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    anchors.topMargin: Type.px(18)
    text: root.savedTo
    color: Ink.inkDim
    font.family: Type.mono
    font.pixelSize: Type.tag
  }

  // ------------------------------------------------ parts
  // A corner eye on a block, in EDIT only: ◉ shown, ○ hidden.
  component EyeChip: Rectangle {
    id: chip
    property string block: ""
    readonly property bool on: root.shown(chip.block)
    visible: root.editing && !root.grabbing
    z: 50
    width: chipRow.width + 2 * Type.px(8)
    height: Type.px(22)
    radius: 3
    color: chip.on ? Ink.bone : Ink.paper
    border.width: 1
    border.color: chip.on ? Ink.bone : Ink.lineStrong
    Row {
      id: chipRow
      anchors.centerIn: parent
      spacing: Type.px(5)
      Text { anchors.verticalCenter: parent.verticalCenter; text: chip.on ? "◉" : "○"; color: chip.on ? Ink.boneInk : Ink.inkDim; font.pixelSize: Type.label }
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: chip.block.toUpperCase()
        color: chip.on ? Ink.boneInk : Ink.inkDim
        font.family: Type.mono
        font.pixelSize: Type.tag
        font.letterSpacing: Type.trackTag
      }
    }
    HoverHandler { cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: root.blockToggled(chip.block) }
  }

  // Text you can click to rewrite in EDIT; Enter or leaving keeps it,
  // Esc drops it.
  component InlineText: Item {
    id: inline
    property string field: ""
    property string value: ""
    property color color: Ink.ink
    property string family: Type.text
    property real size: Type.row
    property bool italic: false
    property bool fit: false
    property bool armed: false

    function commit() {
      if (!armed) return
      armed = false
      if (input.text.trim() !== value) root.textEdited(field, input.text.trim())
    }
    onArmedChanged: if (armed) { input.text = value; input.forceActiveFocus(); input.selectAll() }
    Connections {
      target: root
      function onEditingChanged() { if (!root.editing) inline.commit() }
    }

    Text {
      anchors.fill: parent
      visible: !inline.armed
      text: inline.value
      color: inline.color
      verticalAlignment: Text.AlignVCenter
      elide: Text.ElideRight
      fontSizeMode: inline.fit ? Text.HorizontalFit : Text.FixedSize
      minimumPixelSize: Type.px(28)
      font.family: inline.family
      font.pixelSize: inline.size
      font.italic: inline.italic
      font.variableAxes: inline.family === Type.display ? Type.axes(inline.size) : ({})
    }
    Rectangle {
      anchors.fill: parent
      anchors.margins: -Type.px(4)
      visible: root.editing && !inline.armed && !root.grabbing
      radius: 3
      color: area.containsMouse ? Ink.lineSoft : "transparent"
      border.width: 1
      border.color: area.containsMouse ? Ink.lineStrong : Ink.line
    }
    TextInput {
      id: input
      anchors.fill: parent
      visible: inline.armed
      enabled: inline.armed
      verticalAlignment: TextInput.AlignVCenter
      clip: true
      color: inline.color
      selectionColor: Ink.bone
      selectedTextColor: Ink.boneInk
      font.family: inline.family
      font.pixelSize: inline.fit ? Math.min(inline.size, Type.px(64)) : inline.size
      font.italic: inline.italic
      onAccepted: inline.commit()
      onActiveFocusChanged: if (!activeFocus) inline.commit()
      Keys.onEscapePressed: function(event) { inline.armed = false; event.accepted = true }
    }
    MouseArea {
      id: area
      anchors.fill: parent
      enabled: root.editing && !inline.armed
      hoverEnabled: root.editing
      cursorShape: Qt.IBeamCursor
      onClicked: inline.armed = true
    }
  }

  component StripButton: Rectangle {
    id: sb
    property string label: ""
    property bool plate: false
    signal clicked()
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    width: sbText.implicitWidth + 2 * Type.px(12)
    height: Type.px(28)
    radius: 3
    color: plate ? Ink.bone : sbHover.hovered ? Ink.lineSoft : "transparent"
    border.width: 1
    border.color: plate ? Ink.bone : Ink.lineStrong
    Text {
      id: sbText
      anchors.centerIn: parent
      text: sb.label.toUpperCase()
      color: sb.plate ? Ink.boneInk : Ink.ink
      font.family: Type.mono
      font.pixelSize: Type.label
      font.letterSpacing: Type.px(1.6)
    }
    HoverHandler { id: sbHover; cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: sb.clicked() }
  }
}
