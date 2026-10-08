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

  readonly property string edition: P.edition(machine.machine + machine.since)
  readonly property var vitals: P.vitals(barData)
  readonly property var specs: P.specs(style, doc, machine, version, S.OPTIONS, S.KEYS, S.combinations())
  readonly property string name: profile.name || machine.user || "you"
  readonly property string tagline: profile.tagline || ("Set in ink on " + (machine.theme || "your theme") + ".")

  // Two layouts, and nothing ever sits on top of the type in either:
  //  poster   the identity top left, the small print bottom left, the live
  //           readings beside it and the seal in the room left on the right,
  //           sized to that room (never under the readings, EDIT or the day);
  //  stacked  one column, the seal set beside (or above) the readings, for
  //           narrow windows and when the seal would come out too small.
  // A window too short for either scrolls instead of piling blocks up.
  readonly property int margin: poster ? Type.px(56) : width < Type.px(560) ? Type.px(20) : Type.px(32)
  readonly property int posterMargin: Type.px(56)
  readonly property real vitalsX: posterMargin + Type.px(420)
  readonly property real vitalsW: Type.px(170)
  readonly property real vitalsTop: posterMargin + posterHead.height + Type.px(40)
  // EDIT's strip takes its own band under the page, so nothing scrolls
  // beneath it.
  readonly property real stripRoom: editing && !grabbing ? Type.px(46) + 2 * Type.px(12) : 0
  readonly property real posterNeed: vitalsTop + Math.max(posterFoot.height, vitals.length * Type.px(56)) + posterMargin
  readonly property real posterH: Math.max(flick.height, posterNeed)
  // The seal's room: right of the readings and their leaders, under EDIT,
  // over the day rule. Turned 5°, its box is about 9% bigger than its face.
  readonly property real sealLeft: vitalsX + vitalsW + Type.px(64)
  readonly property real sealTop: posterMargin + Type.px(30) + Type.px(28)
  readonly property real sealBottom: posterH - posterMargin - (shown("day") || editing ? Type.px(52) + Type.px(36) : Type.px(8))
  readonly property real posterSeal: Math.floor(Math.min((width - sealLeft) / 0.84, (sealBottom - sealTop) / 1.09, Type.px(720)))
  readonly property bool poster: width >= Type.px(1000) && posterSeal >= Type.px(280)

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
      // The whole page, also what is scrolled out of view.
      page.grabToImage(function(result) {
        var ok = result.saveToFile(path)
        root.grabbing = false
        root.savedTo = ok ? "SAVED  ·  " + path : "COULD NOT WRITE " + path
        savedTimer.restart()
      })
    }
  }
  Timer { id: savedTimer; interval: 4000; onTriggered: root.savedTo = "" }

  Rectangle { anchors.fill: parent; color: Ink.paper }

  Flickable {
    id: flick
    width: parent.width
    height: parent.height - root.stripRoom
    contentWidth: width
    contentHeight: page.height
    interactive: contentHeight > height
    clip: true
    boundsBehavior: Flickable.StopAtBounds

  Item {
    id: page
    width: flick.width
    height: root.poster ? root.posterH : stack.y + stack.height + root.margin

    Rectangle { anchors.fill: parent; color: Ink.paper }

    // ============================================== poster
    Item {
      id: posterLayer
      visible: root.poster
      anchors.fill: parent

      // The glyph's watermark, between the columns.
      Text {
        visible: root.visibleBlock("watermark")
        opacity: root.blockOpacity("watermark")
        x: root.width * 0.42 - width / 2
        anchors.verticalCenter: parent.verticalCenter
        text: root.style.sealGlyph || "印"
        color: Ink.alpha(Ink.ink, 0.05)
        font.family: Type.jpSerif
        font.pixelSize: Math.min(root.posterH * 0.66, Type.px(560))
      }

      SealImpression {
        id: seal
        visible: root.visibleBlock("seal")
        readonly property real size: Math.max(0, root.posterSeal)
        width: size
        height: size
        x: root.width - size * 0.8
        y: (root.sealTop + root.sealBottom) / 2 - size / 2
        rotation: -5
        opacity: root.blockOpacity("seal")
        glyph: root.style.sealGlyph || "印"
        seed: Number(root.edition) / 1000
        // A point on the impression, as the page sees it (the seal is turned).
        function at(fx, fy) {
          var a = rotation * Math.PI / 180
          var dx = (fx - 0.5) * width, dy = (fy - 0.5) * height
          return { x: x + width / 2 + dx * Math.cos(a) - dy * Math.sin(a), y: y + height / 2 + dx * Math.sin(a) + dy * Math.cos(a) }
        }
      }
      EyeChip { block: "seal"; x: Math.max(root.sealLeft, seal.x + Type.px(20)); y: seal.y - height - Type.px(4) }

      PlateSpine {
        visible: root.visibleBlock("spine") && length <= root.posterH - 2 * Type.px(24)
        opacity: root.blockOpacity("spine")
        x: Type.px(22)
        anchors.verticalCenter: parent.verticalCenter
        text: root.spineText
      }

      Head {
        id: posterHead
        x: root.posterMargin
        y: root.posterMargin
        // Clear of EDIT, and of the seal where the window is narrow.
        width: Math.min(Type.px(600), root.width - 2 * root.posterMargin - Type.px(120))
        nameSize: Type.px(104)
        nameHeight: Type.px(112)
      }

      // The live readings, pinned to the seal by hairline leaders.
      Item {
        id: live
        visible: root.visibleBlock("vitals")
        opacity: root.blockOpacity("vitals")
        anchors.fill: parent
        readonly property real gap: Math.max(Type.px(56), Math.min(Type.px(78), (root.posterH - root.posterMargin - root.vitalsTop) / Math.max(1, root.vitals.length)))
        // Where each reading touches the seal.
        readonly property var pins: [[0.30, 0.22], [0.22, 0.42], [0.30, 0.62], [0.46, 0.80], [0.62, 0.30]]

        LiveHead {
          id: liveHead
          x: root.vitalsX
          y: root.vitalsTop - Type.px(24)
        }
        EyeChip { block: "vitals"; x: root.vitalsX + liveHead.width + Type.px(10); anchors.verticalCenter: liveHead.verticalCenter }

        Canvas {
          id: leaders
          visible: seal.visible && seal.size > 0
          anchors.fill: parent
          readonly property var key: [root.vitalsTop, live.gap, seal.x, seal.y, seal.size, root.vitals.length, Ink.ink]
          onKeyChanged: requestPaint()
          onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            for (var i = 0; i < root.vitals.length && i < live.pins.length; i++) {
              var p = seal.at(live.pins[i][0], live.pins[i][1])
              var sx = root.vitalsX + root.vitalsW, sy = root.vitalsTop + i * live.gap + Type.px(26)
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
          Callout {
            required property var modelData
            required property int index
            x: root.vitalsX
            y: root.vitalsTop + index * live.gap
            width: root.vitalsW
            reading: modelData
            sub: live.gap >= Type.px(66)
          }
        }
      }

      // The small print, bottom left.
      Column {
        id: posterFoot
        x: root.posterMargin
        y: root.posterH - root.posterMargin - height
        width: Math.min(Type.px(380), root.vitalsX - root.posterMargin - Type.px(40))
        // The readings sit right beside it, so EDIT's eyes go on the
        // blocks' corners, with room made for them.
        spacing: root.editing ? Type.px(34) : Type.px(14)
        SpecsBlock { width: parent.width; beside: false }
        PaletteBlock { width: parent.width; beside: false }
        EditionLine { width: parent.width }
      }

      DayRule {
        x: root.width - root.posterMargin - width
        y: root.posterH - root.posterMargin - height
        width: Type.px(260)
      }
    }

    // ============================================== stacked
    Column {
      id: stack
      visible: !root.poster
      x: root.margin
      y: root.margin
      width: page.width - 2 * root.margin
      spacing: Type.px(32)
      readonly property bool twoUp: width >= Type.px(520)

      Head {
        // Clear of EDIT, which stays top right.
        width: parent.width - editButton.width - Type.px(16)
        nameSize: Type.px(stack.twoUp ? 72 : 52)
        nameHeight: Type.px(stack.twoUp ? 80 : 60)
      }

      // The readings beside the seal when there is room, under it if not.
      Item {
        id: art
        visible: root.visibleBlock("vitals") || root.visibleBlock("seal")
        width: parent.width
        readonly property real sealSize: !root.visibleBlock("seal") ? 0
          : stack.twoUp ? Math.min(Type.px(340), width - root.vitalsW - Type.px(48))
          : Math.min(width, Type.px(280)) / 1.1
        readonly property real sealBox: sealSize * 1.1
        height: stack.twoUp ? Math.max(sealBox, stackLive.visible ? stackLive.height : 0)
                            : (sealSize > 0 ? sealBox + Type.px(24) : 0) + (stackLive.visible ? stackLive.height : 0)

        Item {
          visible: art.sealSize > 0
          x: stack.twoUp ? art.width - width : (art.width - width) / 2
          width: art.sealBox
          height: art.sealBox
          SealImpression {
            anchors.centerIn: parent
            width: art.sealSize
            height: art.sealSize
            rotation: -5
            opacity: root.blockOpacity("seal")
            glyph: root.style.sealGlyph || "印"
            seed: Number(root.edition) / 1000
          }
          EyeChip { block: "seal"; anchors.right: parent.right; y: -height - Type.px(4) }
        }

        Column {
          id: stackLive
          visible: root.visibleBlock("vitals")
          opacity: root.blockOpacity("vitals")
          y: stack.twoUp ? Math.max(0, (art.sealBox - height) / 2) : (art.sealSize > 0 ? art.sealBox + Type.px(24) : 0)
          width: stack.twoUp ? root.vitalsW : art.width
          spacing: Type.px(14)
          Row {
            spacing: Type.px(10)
            LiveHead { id: stackLiveHead }
            EyeChip { block: "vitals"; anchors.verticalCenter: parent.verticalCenter }
          }
          Grid {
            columns: stack.twoUp ? 1 : 2
            columnSpacing: Type.px(24)
            rowSpacing: Type.px(10)
            Repeater {
              model: root.vitals
              Callout {
                required property var modelData
                width: stack.twoUp ? root.vitalsW : (stackLive.width - Type.px(24)) / 2
                reading: modelData
                sub: true
              }
            }
          }
        }
      }

      Column {
        width: Math.min(parent.width, Type.px(520))
        spacing: Type.px(32)
        SpecsBlock { width: parent.width; beside: false }
        PaletteBlock { width: parent.width; beside: false }
        EditionLine { width: parent.width }
      }

      DayRule { width: Math.min(parent.width, Type.px(380)) }
    }

    // ------------------------------------------------ edit
    Rectangle {
      id: editButton
      visible: !root.grabbing
      x: page.width - root.margin - width
      y: root.margin
      width: editLabel.implicitWidth + 2 * Type.px(14)
      height: Type.px(30)
      radius: 3
      color: root.editing ? Ink.bone : editHover.hovered ? Ink.lineSoft : Ink.paper
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
  }
  }

  // The edit strip: what EDIT can do besides the fields and the eyes, in
  // its band under the page.
  Rectangle {
    visible: root.stripRoom > 0
    width: parent.width
    height: root.stripRoom
    anchors.bottom: parent.bottom
    color: Ink.paper
    Rectangle { width: parent.width; height: 1; color: Ink.line }
  }
  Rectangle {
    visible: root.stripRoom > 0
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: Type.px(12)
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
      readonly property real room: root.width - 2 * Type.px(12) - 2 * Type.px(10) - buttons.width - spacing
      Text {
        // Gives way to the buttons on a narrow window.
        visible: strip.room >= Type.px(140)
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(implicitWidth, strip.room)
        elide: Text.ElideRight
        text: "CLICK YOUR NAME OR LINE TO REWRITE IT  ·  ◉ HIDES A BLOCK"
        color: Ink.inkMuted
        font.family: Type.mono
        font.pixelSize: Type.tag
        font.letterSpacing: Type.trackTag
        rightPadding: Type.px(8)
      }
      Row {
        id: buttons
        anchors.verticalCenter: parent.verticalCenter
        spacing: Type.px(8)
        StripButton { visible: root.picturesDir !== ""; label: "Save image"; onClicked: root.saveImage() }
        StripButton { label: "Reset"; onClicked: root.profileReset() }
        StripButton { label: "Done"; plate: true; onClicked: root.editing = false }
      }
    }
  }

  Rectangle {
    visible: root.savedTo !== "" && !root.grabbing
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    anchors.topMargin: Type.px(14)
    width: Math.min(savedText.implicitWidth, root.width - 2 * Type.px(24)) + 2 * Type.px(10)
    height: Type.px(26)
    radius: 3
    color: Ink.paper
    border.width: 1
    border.color: Ink.line
    Text {
      id: savedText
      anchors.centerIn: parent
      width: parent.width - 2 * Type.px(10)
      horizontalAlignment: Text.AlignHCenter
      elide: Text.ElideMiddle
      text: root.savedTo
      color: Ink.inkDim
      font.family: Type.mono
      font.pixelSize: Type.tag
    }
  }

  readonly property string spineText: ("HANKO  ·  印影 SEAL REGISTER  ·  " + machine.user + (machine.host ? "@" + machine.host : "")
                                       + (machine.kernel ? "  ·  KERNEL " + machine.kernel : "") + "  ·  SET IN INK").toUpperCase()

  // ------------------------------------------------ blocks
  // The identity: register line, name, host and time, the line.
  component Head: Column {
    id: headBlock
    property real nameSize: Type.px(104)
    property real nameHeight: Type.px(112)
    spacing: Type.px(12)
    PlateEyebrow { jp: "印影"; label: "Seal register  ·  No. " + root.edition }
    InlineText {
      width: parent.width
      height: headBlock.nameHeight
      field: "name"
      value: root.name
      color: Ink.ink
      family: Type.display
      size: headBlock.nameSize
      fit: true
    }
    Text {
      width: parent.width
      elide: Text.ElideRight
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

  // 脈 · LIVE FROM THE BAR, with its pulse.
  component LiveHead: Row {
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

  // One live reading: its kanji and name, the figure, a line under it.
  component Callout: Column {
    id: callout
    property var reading: ({})
    property bool sub: true
    spacing: 0
    Row {
      spacing: Type.px(6)
      Text { text: callout.reading.jp || ""; color: Ink.inkFaint; font.family: Type.jp; font.pixelSize: Type.tag }
      Text { text: callout.reading.name || ""; color: Ink.inkMuted; font.family: Type.mono; font.pixelSize: Type.tag; font.letterSpacing: Type.trackLabel }
    }
    Text {
      width: parent.width
      elide: Text.ElideRight
      text: callout.reading.big || ""
      color: Ink.ink
      font.family: Type.text
      font.pixelSize: Type.px(28)
      font.weight: Font.Medium
      font.features: ({ "tnum": 1 })
    }
    Text {
      visible: callout.sub
      width: parent.width
      elide: Text.ElideRight
      text: callout.reading.sub || ""
      color: Ink.inkDim
      font.family: Type.mono
      font.pixelSize: Type.tag
    }
  }

  // The dossier: label, leader, value.
  component SpecsBlock: Item {
    id: specsBlock
    property bool beside: true
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
    EyeChip { block: "specs"; beside: specsBlock.beside }
  }

  // The six inks this desk is set in, with their names.
  component PaletteBlock: Item {
    id: paletteBlock
    property bool beside: true
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
            elide: Text.ElideRight
            text: modelData
            color: Ink.inkFaint
            font.family: Type.mono
            font.pixelSize: Type.tag
            font.letterSpacing: Type.trackTag
          }
        }
      }
    }
    EyeChip { block: "palette"; beside: paletteBlock.beside }
  }

  component EditionLine: Text {
    wrapMode: Text.Wrap
    text: "NO. " + root.edition + (root.machine.since ? "  ·  SET SINCE " + root.machine.since : "")
          + (root.machine.packages ? "  ·  " + root.machine.packages + " PACKAGES" : "")
    color: Ink.inkDim
    font.family: Type.mono
    font.pixelSize: Type.tag
    font.letterSpacing: Type.trackTag
    lineHeight: 1.3
  }

  // The day, as a rule: hours ticked, what is spent inked, now in red.
  component DayRule: Item {
    id: day
    visible: root.visibleBlock("day")
    opacity: root.blockOpacity("day")
    height: Type.px(52)
    readonly property real fraction: E.dayFraction(root.now)

    EyeChip { block: "day"; anchors.right: parent.right; anchors.bottom: parent.top; anchors.bottomMargin: Type.px(8) }
    Text {
      width: parent.width - spent.implicitWidth - Type.px(12)
      elide: Text.ElideRight
      text: "TODAY  ·  " + Qt.formatDate(root.now, "ddd d MMM").toUpperCase()
      color: Ink.inkMuted
      font.family: Type.mono
      font.pixelSize: Type.tag
      font.letterSpacing: Type.trackLabel
    }
    Text {
      id: spent
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

  // ------------------------------------------------ parts
  // A corner eye on a block, in EDIT only: ◉ shown, ○ hidden.
  component EyeChip: Rectangle {
    id: chip
    property string block: ""
    // On a block: beside its middle, or on its top right corner (a stacked
    // page has no room beside). Chips placed by hand set x and y instead.
    property bool beside: true
    readonly property bool on: root.shown(chip.block)
    x: beside ? parent.width + Type.px(10) : parent.width - width
    y: beside ? (parent.height - height) / 2 : -height - Type.px(6)
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
