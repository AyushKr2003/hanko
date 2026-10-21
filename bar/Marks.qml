pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import "../core"
import "../core/Status.js" as StatusJs

// Hanko's own small marks in the right zone, for what Omarchy shows as
// widgets: indicators as small stamps carrying Omarchy's own icons
// (recording, dictation, reminder, stay awake, night light, do not
// disturb; what is on is pressed and slightly askew, solid red only for
// "now"; the ones that are off stay as faint outlines, a click switching
// them on; hovering one names it), the keyboard layout as a mono code, the microphone as 声 (red when muted),
// and the tray, every icon inked in the dim tier. Pure: data in, signals
// out.
Item {
  id: root

  // core/Extras.js shapes.
  property var indicators: []
  // What is on an indicator stamp (Style.js indicatorStyle): icon or kanji,
  // and with iconname/kanjiname an indicator that is on has its name
  // beside it (the off ones are named on hover, as always).
  property string markStyle: "icon"
  readonly property bool kanjiMarks: markStyle === "kanji" || markStyle === "kanjiname"
  readonly property bool namedMarks: markStyle === "iconname" || markStyle === "kanjiname"
  property var keyboard: null      // { label, count } or null
  property var mic: null           // { muted, percent } or null
  property var tray: []
  property int barHeight: 40
  // Short of room, the tray folds into one mark (盆 and a count) that a
  // click unfolds.
  property bool compactTray: false
  property bool trayOpen: false
  readonly property bool trayFolded: compactTray && !trayOpen && tray.length > 1
  onTrayOpenChanged: if (trayOpen) refold.restart()
  Timer { id: refold; interval: 8000; onTriggered: root.trayOpen = false }

  // how: click | middle | right | up | down
  signal indicatorAction(string key, string how)
  signal keyboardAction(string how)
  signal micAction(string how)
  // The tray item's cell is passed so a menu can open under it.
  signal trayAction(string id, string how, Item cell)

  readonly property bool showKeyboard: !!keyboard && keyboard.count > 1
  // How wide the marks are with the tray unfolded.
  readonly property real fullWidth: fixedPart.implicitWidth + tray.length * (Type.px(16) + row.spacing)
  // The name hovering opens is drawn left of the marks, outside them; the
  // bar keeps a blank of nameWidth there (BarSurface). Were it inside, the
  // stamps would shift a frame before the bar moved them back, the pointer
  // would leave the stamp and the name would flicker. nameRoom is what the
  // bar has spare for it.
  property real nameRoom: 100000
  readonly property real nameWidth: nameClip.width
  readonly property int glyphSize: Type.px(13)

  // Hovering the stamps straightens them, like the inbox's.
  HoverHandler { id: hover }
  // The indicator under the pointer, named in small caps beside the stamps.
  property var named: null

  visible: indicators.length > 0 || showKeyboard || !!mic || tray.length > 0
  implicitWidth: visible ? row.implicitWidth : 0
  implicitHeight: barHeight

  function how(mouse) {
    return mouse.button === Qt.MiddleButton ? "middle" : mouse.button === Qt.RightButton ? "right" : "click"
  }

  Row {
    id: row
    anchors.verticalCenter: parent.verticalCenter
    spacing: Type.px(12)

    // Everything but the tray, measured apart so folding the tray never
    // feeds back into the decision to fold it.
    Row {
      id: fixedPart
      anchors.verticalCenter: parent.verticalCenter
      spacing: Type.px(12)

      // Indicators: a stamp each, a small count for reminders, the name of
      // the one under the pointer to their left.
      Item {
        id: stampsCell
        visible: root.indicators.length > 0
        width: stampsRow.width
        height: root.barHeight

        // The name opens out to the left of the stamps, over the bar's blank.
        Item {
          id: nameClip
          anchors.verticalCenter: parent.verticalCenter
          anchors.right: stampsRow.left
          clip: true
          height: nameText.implicitHeight
          width: root.named ? Math.max(0, Math.min(nameText.implicitWidth + Type.px(8), root.nameRoom)) : 0
          Behavior on width { enabled: !Motion.still; NumberAnimation { duration: Motion.slide; easing.type: Easing.OutCubic } }
          Text {
            id: nameText
            anchors.right: parent.right
            anchors.rightMargin: Type.px(8)
            text: root.named ? (root.named.title + (root.named.on ? "" : " · off")).toUpperCase() : ""
            color: Ink.inkMuted
            font.family: Type.mono
            font.pixelSize: Type.label
            font.weight: Type.labelWeight
            font.letterSpacing: Type.trackLabel
          }
        }

        Row {
          id: stampsRow
          anchors.verticalCenter: parent.verticalCenter
          spacing: Type.px(5)

          Repeater {
            model: root.indicators
            IndicatorStamp {
              required property var modelData
              mark: modelData
            }
          }
        }
      }
      // Keyboard layout: "US", "DE"; a click goes to the next layout.
      Item {
        visible: root.showKeyboard
        width: kbFrame.width
        height: root.barHeight
        // Te 手 (bar focus, bar/parts/KeyCursor.qml): Enter is a click,
        // Menu a right-click, on every mark here.
        readonly property bool keyStop: true
        function keyPress() { root.keyboardAction("click") }
        function keyMenu() { root.keyboardAction("right") }
        Rectangle {
          id: kbFrame
          anchors.verticalCenter: parent.verticalCenter
          width: kbText.implicitWidth + Type.px(10)
          height: Type.px(17)
          radius: 2
          color: "transparent"
          border.width: 1
          border.color: Ink.line
          Text {
            id: kbText
            anchors.centerIn: parent
            text: root.keyboard ? root.keyboard.label : ""
            color: Ink.inkDim
            font.family: Type.mono
            font.pixelSize: Type.label
            font.letterSpacing: 1
          }
        }
        MouseArea {
          anchors.fill: parent
          acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
          cursorShape: Qt.PointingHandCursor
          onClicked: function(mouse) { root.keyboardAction(root.how(mouse)) }
        }
      }

      // Microphone: 声, red with a stroke through it when muted.
      Item {
        visible: !!root.mic
        width: micText.implicitWidth
        height: root.barHeight
        readonly property bool keyStop: true
        function keyPress() { root.micAction("click") }
        function keyMenu() { root.micAction("right") }
        Text {
          id: micText
          anchors.verticalCenter: parent.verticalCenter
          text: "声"
          color: root.mic && root.mic.muted ? Ink.seal : Ink.inkDim
          font.family: Type.jp
          font.pixelSize: root.glyphSize
        }
        Rectangle {
          visible: !!(root.mic && root.mic.muted)
          anchors.centerIn: micText
          width: micText.implicitWidth + 2
          height: 1
          rotation: -35
          color: Ink.seal
        }
        MouseArea {
          anchors.fill: parent
          acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
          cursorShape: Qt.PointingHandCursor
          onClicked: function(mouse) { root.micAction(root.how(mouse)) }
          onWheel: function(wheel) { root.micAction(wheel.angleDelta.y > 0 ? "up" : "down") }
        }
      }
    }

    // The folded tray.
    Item {
      visible: root.trayFolded
      width: foldRow.implicitWidth
      height: root.barHeight
      readonly property bool keyStop: true
      function keyPress() { root.trayOpen = true }
      Row {
        id: foldRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: Type.px(2)
        Text { anchors.verticalCenter: parent.verticalCenter; text: "盆"; color: Ink.inkDim; font.family: Type.jp; font.pixelSize: root.glyphSize }
        Text { anchors.bottom: parent.bottom; text: String(root.tray.length); color: Ink.inkMuted; font.family: Type.mono; font.pixelSize: Type.label }
      }
      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.trayOpen = true
      }
    }

    // The tray: each icon inked in the dim tier; a letter when there's no
    // icon to ink.
    Repeater {
      model: root.trayFolded ? [] : root.tray
      Item {
        id: cell
        required property var modelData
        readonly property bool keyStop: true
        function keyPress() { root.trayAction(cell.modelData.id, "click", cell) }
        function keyMenu() { root.trayAction(cell.modelData.id, "right", cell) }
        width: Type.px(16)
        height: root.barHeight

        Image {
          id: icon
          visible: false
          anchors.centerIn: parent
          width: Type.px(15)
          height: width
          sourceSize: Qt.size(width * 2, height * 2)
          source: cell.modelData.icon
          fillMode: Image.PreserveAspectFit
          smooth: true
        }
        MultiEffect {
          visible: icon.status === Image.Ready
          anchors.fill: icon
          source: icon
          colorization: 1
          colorizationColor: Ink.inkDim
          brightness: 0.25
        }
        Text {
          visible: icon.status !== Image.Ready
          anchors.centerIn: parent
          text: cell.modelData.letter
          color: Ink.inkMuted
          font.family: Type.text
          font.pixelSize: Type.note
        }
        MouseArea {
          anchors.fill: parent
          acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
          cursorShape: Qt.PointingHandCursor
          onClicked: function(mouse) { root.trayAction(cell.modelData.id, root.how(mouse), cell) }
          onWheel: function(wheel) { root.trayAction(cell.modelData.id, wheel.angleDelta.y > 0 ? "up" : "down", cell) }
        }
      }
    }
  }

  // One indicator: a small square seal with Omarchy's icon in it. On, it is
  // pressed, askew and inked (solid red for "now"); off, it is a faint
  // outline that a click switches on.
  component IndicatorStamp: Item {
    id: ind
    property var mark: ({})
    readonly property bool keyStop: true
    function keyPress() { root.indicatorAction(ind.mark.key, "click") }
    function keyMenu() { root.indicatorAction(ind.mark.key, "right") }
    readonly property bool on: mark.on !== false
    // Kanji stamps are small seals, like the one at the far left, when on;
    // off, they are faint outlines like the icon stamps. A seal is carved in
    // ink, and only one that means "now" (recording) is red: with the seal,
    // the letters and a few marks on, red everywhere stopped meaning anything.
    readonly property bool seal: root.kanjiMarks || !mark.icon
    readonly property bool solid: on && (seal || !!mark.red)
    readonly property color plate: mark.red ? Ink.seal : Ink.bone
    readonly property color plateInk: mark.red ? Ink.paper : Ink.boneInk
    // 0 = held above the bar, oversized and tilted; 1 = pressed and settled.
    property real press: 1

    width: stamp.width + (badge.visible ? badge.implicitWidth + 1 : 0)
      + (label.visible ? label.implicitWidth + Type.px(5) : 0)
    height: root.barHeight
    opacity: on ? 1 : (pointer.hovered ? 0.85 : 0.4)
    Behavior on opacity { enabled: !Motion.still; NumberAnimation { duration: Motion.fade } }

    onOnChanged: if (on && Motion.live) pressing.start()
    NumberAnimation {
      id: pressing
      target: ind
      property: "press"
      from: 0
      to: 1
      duration: Motion.stamp
      easing.type: Easing.BezierSpline
      easing.bezierCurve: Motion.stampCurve
    }

    Rectangle {
      id: stamp
      anchors.verticalCenter: parent.verticalCenter
      width: Type.px(18)
      height: width
      radius: 2
      antialiasing: true
      color: ind.solid ? ind.plate : "transparent"
      border.width: 1.5
      border.color: ind.solid ? ind.plate : ind.on ? Ink.inkMuted : Ink.line

      // The inner rule of a carved seal, as on bar/Seal.qml.
      Rectangle {
        visible: ind.solid && ind.seal
        anchors.fill: parent
        anchors.margins: 2
        radius: 1
        color: "transparent"
        border.width: 1
        border.color: Ink.alpha(ind.plateInk, 0.45)
      }
      rotation: ind.on && !hover.hovered ? StatusJs.tilt(ind.mark.key) : 0
      Behavior on rotation { enabled: !Motion.still; NumberAnimation { duration: Motion.slide; easing.type: Easing.OutCubic } }
      transform: [
        Scale {
          origin.x: stamp.width / 2; origin.y: stamp.height / 2
          xScale: 1 + 0.45 * (1 - ind.press); yScale: xScale
        },
        Rotation { origin.x: stamp.width / 2; origin.y: stamp.height / 2; angle: -12 * (1 - ind.press) }
      ]

      Text {
        readonly property bool kanji: ind.seal
        anchors.centerIn: parent
        anchors.verticalCenterOffset: kanji ? -0.5 : 0
        text: kanji ? ind.mark.glyph || "" : ind.mark.icon
        color: ind.solid ? ind.plateInk : ind.on ? Ink.ink : Ink.inkFaint
        font.family: kanji ? Type.jpSerif : Type.mono
        font.weight: kanji ? Font.Medium : Font.Normal
        font.pixelSize: Type.px(kanji ? 10.5 : 11)
      }
    }

    // iconname, kanjiname: the name in small caps after the stamp, while
    // it is on.
    Text {
      id: label
      visible: root.namedMarks && ind.on
      anchors.verticalCenter: parent.verticalCenter
      anchors.right: parent.right
      text: String(ind.mark.title || "").toUpperCase()
      color: ind.mark.red ? Ink.seal : Ink.inkDim
      font.family: Type.mono
      font.pixelSize: Type.label
      font.weight: Type.labelWeight
      font.letterSpacing: Type.trackLabel
    }

    // How many reminders wait, when more than one.
    Text {
      id: badge
      visible: ind.on && ind.mark.count > 1
      anchors.left: stamp.right
      anchors.leftMargin: 1
      anchors.bottom: stamp.bottom
      anchors.bottomMargin: -Type.px(2)
      text: String(ind.mark.count)
      color: Ink.inkMuted
      font.family: Type.mono
      font.pixelSize: Type.label
    }

    HoverHandler {
      id: pointer
      onHoveredChanged: {
        if (hovered && !label.visible) root.named = ind.mark
        else if (root.named && root.named.key === ind.mark.key) root.named = null
      }
    }
    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
      cursorShape: Qt.PointingHandCursor
      onClicked: function(mouse) { root.indicatorAction(ind.mark.key, root.how(mouse)) }
    }
  }
}
