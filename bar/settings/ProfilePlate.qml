pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Style.js" as S
import "../../core/Edge.js" as E
import "../../core/Profile.js" as P

// Profile 印影, the seal register: the plate people screenshot to show their
// desk, laid out like the certificate a seal is registered on (印鑑登録証明書)
// on a modular grid. Left, the holder: your name monumental in Fraunces, the
// line under it and the register's small print. Right, the work: your seal
// glyph written large in ink on a calligraphy practice grid (田字格) and
// signed with a rakkan, two small seals under your name (Shikishi.qml), in
// a ruled box with crop marks and its caption. Along the foot, the bar's live readings as
// a row of stats (a game's status screen, kept to ink), then the edition and
// the day as a rule. Ink on paper; the seal is the only red. EDIT lets you
// rename it, give it a line and hide any block (core/Dossier.qml).
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
  //  poster   the certificate: holder left, impression right, readings in
  //           a row across the foot, edition and day under them;
  //  stacked  one column, the seal set beside (or above) the readings, for
  //           narrow windows and when the impression would come out small.
  // A window too short for either scrolls instead of piling blocks up.
  readonly property int margin: poster ? Type.px(56) : width < Type.px(560) ? Type.px(20) : Type.px(32)
  readonly property int posterMargin: Type.px(56)
  readonly property real vitalsW: Type.px(170)
  // EDIT's strip takes its own band under the page, so nothing scrolls
  // beneath it.
  readonly property real stripRoom: editing && !grabbing ? Type.px(46) + 2 * Type.px(12) : 0

  // The poster's grid: two columns over a band of readings and a foot.
  readonly property real contentW: width - 2 * posterMargin
  readonly property real gutter: Type.px(64)
  readonly property real leftW: Math.min(Type.px(640), contentW * 0.54)
  readonly property real boxTop: posterMargin + Type.px(58)
  readonly property real captionH: Type.px(30)
  readonly property real leftBottom: posterMargin + posterHead.height + Type.px(40) + posterFoot.height
  readonly property real posterBox: Math.floor(Math.max(Type.px(240), Math.min(contentW - leftW - gutter, leftBottom - boxTop - captionH, Type.px(560))))
  readonly property real liveH: Type.px(124)
  readonly property real footH: Type.px(52)
  readonly property real posterNeed: Math.max(leftBottom, boxTop + posterBox + captionH) + Type.px(48) + liveH + Type.px(32) + footH + posterMargin
  readonly property real posterH: Math.max(flick.height, posterNeed)
  // The band and the foot sit on the page's floor; extra height opens up
  // above them, between the holder and the readings.
  readonly property real liveTop: posterH - posterMargin - footH - Type.px(32) - liveH
  readonly property bool poster: width >= Type.px(1000) && contentW - leftW - gutter >= Type.px(260)

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

      PlateSpine {
        visible: root.visibleBlock("spine") && length <= root.posterH - 2 * Type.px(24)
        opacity: root.blockOpacity("spine")
        x: Type.px(22)
        anchors.verticalCenter: parent.verticalCenter
        text: root.spineText
      }

      // The holder.
      Head {
        id: posterHead
        x: root.posterMargin
        y: root.posterMargin
        width: root.leftW
        nameSize: Type.px(104)
        nameHeight: Type.px(112)
      }

      // The register's small print, under the holder.
      Column {
        id: posterFoot
        x: root.posterMargin
        y: posterHead.y + posterHead.height + Type.px(40)
        width: Math.min(Type.px(520), root.leftW)
        spacing: root.editing ? Type.px(34) : Type.px(18)
        SectionLabel { jp: "登録"; text: "Register" }
        SpecsBlock { width: parent.width; beside: true }
        PaletteBlock { width: parent.width; beside: true }
      }

      // The impression, right.
      Impression {
        x: root.width - root.posterMargin - width
        y: root.boxTop
        side: root.posterBox
      }

      // The bar's live readings, a row across the foot.
      LiveBand {
        x: root.posterMargin
        y: root.liveTop
        width: root.contentW
        height: root.liveH
      }

      // The foot: the edition left, the day right.
      Rectangle { x: root.posterMargin; y: root.posterH - root.posterMargin - root.footH - Type.px(14); width: root.contentW; height: 1; color: Ink.lineSoft }
      EditionLine {
        x: root.posterMargin
        y: root.posterH - root.posterMargin - root.footH
        width: root.contentW - Type.px(340)
      }
      DayRule {
        x: root.width - root.posterMargin - width
        y: root.posterH - root.posterMargin - height
        width: Type.px(300)
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

      // The impression, then the readings as stats, two to a row.
      Impression {
        side: Math.min(stack.width, Type.px(stack.twoUp ? 360 : 300))
      }

      Column {
        visible: root.visibleBlock("vitals")
        width: parent.width
        spacing: Type.px(14)
        Row {
          spacing: Type.px(10)
          LiveHead { }
          EyeChip { block: "vitals"; anchors.verticalCenter: parent.verticalCenter }
        }
        Grid {
          id: stackStats
          opacity: root.blockOpacity("vitals")
          columns: stack.twoUp ? 3 : 2
          rowSpacing: Type.px(18)
          Repeater {
            model: root.vitals
            StatCell {
              required property var modelData
              required property int index
              width: stack.width / stackStats.columns
              height: Type.px(96)
              reading: modelData
              first: index % stackStats.columns === 0
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

  // The work: your glyph written in ink and signed with two small seals,
  // in a ruled square on a calligraphy practice grid (田字格: a frame, its
  // halves dashed), crop marks set off its corners, its caption under.
  component Impression: Item {
    id: imp
    property real side: Type.px(400)
    width: side
    height: side + root.captionH
    visible: root.visibleBlock("seal")

    Item {
      id: box
      width: imp.side
      height: imp.side
      opacity: root.blockOpacity("seal")

      Rectangle { anchors.fill: parent; color: "transparent"; border.width: 1; border.color: Ink.line }

      // The practice grid: two dashed halves and two dotted diagonals,
      // as on the paper a hand learns its strokes on.
      Item {
        anchors.fill: parent
        visible: root.visibleBlock("watermark")
        opacity: root.blockOpacity("watermark")
        Repeater {
          model: Math.floor(box.width / Type.px(10))
          Rectangle { required property int index; x: index * Type.px(10); y: box.height / 2; width: Type.px(5); height: 1; color: Ink.lineSoft }
        }
        Repeater {
          model: Math.floor(box.height / Type.px(10))
          Rectangle { required property int index; y: index * Type.px(10); x: box.width / 2; width: 1; height: Type.px(5); color: Ink.lineSoft }
        }
        Canvas {
          anchors.fill: parent
          readonly property var key: [width, height, Ink.ink]
          onKeyChanged: requestPaint()
          onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            ctx.strokeStyle = Ink.alpha(Ink.ink, 0.08)
            ctx.lineWidth = 1
            ctx.setLineDash([1, 6])
            ctx.beginPath(); ctx.moveTo(0, 0); ctx.lineTo(width, height); ctx.moveTo(width, 0); ctx.lineTo(0, height); ctx.stroke()
          }
        }
      }

      Shikishi {
        anchors.fill: parent
        glyph: root.style.sealGlyph || "印"
        name: root.name
        date: root.machine.since || ""
      }

      // Crop marks, set off each corner.
      Repeater {
        model: 4
        Item {
          id: mark
          required property int index
          readonly property int sx: index % 2 === 0 ? -1 : 1
          readonly property int sy: index < 2 ? -1 : 1
          x: sx < 0 ? 0 : box.width - 1
          y: sy < 0 ? 0 : box.height - 1
          Rectangle { x: mark.sx < 0 ? -Type.px(16) : Type.px(6); width: Type.px(10); height: 1; color: Ink.lineStrong }
          Rectangle { y: mark.sy < 0 ? -Type.px(16) : Type.px(6); width: 1; height: Type.px(10); color: Ink.lineStrong }
        }
      }
    }
    Row {
      visible: root.editing && !root.grabbing
      x: 0
      y: imp.height + Type.px(8)
      spacing: Type.px(8)
      EyeChip { block: "seal"; x: 0; y: 0 }
      EyeChip { block: "watermark"; x: 0; y: 0 }
    }

    // The caption under the impression.
    Text {
      y: imp.side + Type.px(12)
      width: imp.side - impNo.implicitWidth - Type.px(14)
      elide: Text.ElideRight
      text: "書  ·  INK ON PAPER  ·  SIGNED WITH TWO SEALS"
      color: Ink.inkMuted
      font.family: Type.mono
      font.pixelSize: Type.tag
      font.letterSpacing: Type.trackTag
    }
    Text {
      id: impNo
      y: imp.side + Type.px(12)
      anchors.right: parent.right
      text: "NO. " + root.edition
      color: Ink.inkDim
      font.family: Type.mono
      font.pixelSize: Type.tag
      font.letterSpacing: Type.trackTag
    }
  }

  // The live readings as a row of stats, each with its gauge.
  component LiveBand: Item {
    id: band
    visible: root.visibleBlock("vitals")
    readonly property int n: Math.max(1, root.vitals.length)
    Item {
      anchors.fill: parent
      opacity: root.blockOpacity("vitals")
      LiveHead { id: bandHead }
      Rectangle {
        x: bandHead.width + Type.px(14)
        y: bandHead.height / 2
        width: Math.max(0, band.width - x)
        height: 1
        color: Ink.lineSoft
      }
      Repeater {
        model: root.vitals
        StatCell {
          required property var modelData
          required property int index
          x: index * band.width / band.n
          y: Type.px(30)
          width: band.width / band.n
          height: band.height - Type.px(30)
          reading: modelData
          first: index === 0
        }
      }
    }
    EyeChip { block: "vitals"; x: band.width - width; y: -height - Type.px(8) }
  }

  // One stat: kanji and name, the figure in Fraunces, a note, a gauge.
  component StatCell: Item {
    id: stat
    property var reading: ({})
    property bool first: false
    Rectangle { visible: !stat.first; width: 1; height: parent.height; color: Ink.lineSoft }
    Column {
      x: stat.first ? 0 : Type.px(20)
      width: parent.width - x - Type.px(20)
      spacing: Type.px(4)
      Row {
        spacing: Type.px(7)
        Text { text: stat.reading.jp || ""; color: Ink.inkMuted; font.family: Type.jp; font.pixelSize: Type.label }
        Text { anchors.verticalCenter: parent.verticalCenter; text: stat.reading.name || ""; color: Ink.inkMuted; font.family: Type.mono; font.pixelSize: Type.tag; font.letterSpacing: Type.trackEyebrow }
      }
      Text {
        width: parent.width
        elide: Text.ElideRight
        text: stat.reading.big || ""
        color: Ink.ink
        font.family: Type.display
        font.pixelSize: Type.px(40)
        font.weight: Font.Normal
        font.variableAxes: Type.axes(Type.px(40))
        font.features: ({ "tnum": 1, "lnum": 1 })
        lineHeight: 1.05
      }
      Text {
        width: parent.width
        elide: Text.ElideRight
        text: stat.reading.sub || ""
        color: Ink.inkDim
        font.family: Type.mono
        font.pixelSize: Type.tag
      }
    }
    // The gauge: a hairline track, the level inked.
    Item {
      visible: (stat.reading.level === undefined ? -1 : stat.reading.level) >= 0
      x: stat.first ? 0 : Type.px(20)
      anchors.bottom: parent.bottom
      width: Math.min(Type.px(140), parent.width - x - Type.px(20))
      height: 2
      Rectangle { y: 1; width: parent.width; height: 1; color: Ink.line }
      Rectangle { width: parent.width * Math.max(0, stat.reading.level || 0); height: 2; color: Ink.inkDim }
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
