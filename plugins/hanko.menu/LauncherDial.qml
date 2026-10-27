pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Shapes
import "core"
import "core/Brush.js" as Brush
import "core/Iai.js" as Iai

// LauncherDial 抜刀 · 輪: A Japanese rotary wheel launcher.
// The wheel rolls in from the left margin with the apps riding its rim.
// Turning it brings an app to the pointer at three o'clock (horizontal right),
// where its icon swells and its name is set large in Fraunces serif.
// Features two authentic Japanese dial faces:
//   "enso"  - Wabi-sabi: washi disc, brushed ensō, cinnabar seal ("選"), gold seam
//   "tsuba" - Sekiro: hammered antique iron sword guard, nanako gold inlay, habaki blade
Item {
  id: dial

  property var model: null
  readonly property int count: model ? (model.count !== undefined ? model.count : model.length) : 0
  property string face: "enso" // "enso" or "tsuba"
  property string query: ""
  property var appLibrary: null

  property real position: 0
  property real target: 0
  readonly property int current: count > 0 ? wrap(Math.round(target)) : -1
  readonly property var activeItem: count > 0 && current >= 0 ? (model.get ? model.get(current) : model[current]) : null

  // 0..1 roll animation: the wheel rolls out of the left edge into view
  property real roll: 1
  property bool live: true

  signal launched(int index, var item)
  signal closed()

  function wrap(i) {
    return count > 0 ? ((i % count) + count) % count : 0
  }

  function stepTo(delta) {
    if (count <= 0) return
    target = wrap(Math.round(target + delta))
  }

  function launchCurrent() {
    if (count > 0 && current >= 0 && current < count) {
      dial.launched(current, activeItem)
    }
  }

  function angleOf(index) {
    if (count <= 0) return 0
    var diff = index - position
    if (count > 16) {
      if (diff > count / 2) diff -= count
      else if (diff < -count / 2) diff += count
    }
    return diff * step
  }

  // ── Geometry ──────────────────────────────────────────────────────────────
  readonly property real radius: Math.round(Math.max(Type.px(240), Math.min(height * 0.42, Type.px(480))))
  readonly property real track: radius + Type.px(54)
  readonly property real step: 11 // degrees per item

  // Hub sits slightly past screen edge so the wheel appears as a crescent/arc
  readonly property real cx: -radius * 0.22 - (1 - roll) * radius * 1.35
  readonly property real cy: height / 2

  // The spin it rolls in with
  readonly property real spin: (1 - roll) * -140
  readonly property real turn: -position * step + spin

  Behavior on target {
    NumberAnimation {
      duration: 220
      easing.type: Easing.OutCubic
    }
  }

  // Smooth position tracking to target
  Timer {
    interval: 16
    running: Math.abs(dial.position - dial.target) > 0.005
    repeat: true
    onTriggered: {
      var d = dial.target - dial.position
      dial.position += d * 0.28
      if (Math.abs(dial.position - dial.target) <= 0.005) {
        dial.position = dial.target
      }
    }
  }

  // ── The Dial Face ──────────────────────────────────────────────────────────
  Item {
    id: faceContainer
    x: dial.cx - dial.radius
    y: dial.cy - dial.radius
    width: dial.radius * 2
    height: dial.radius * 2
    rotation: dial.turn

    // ==================== ENSŌ FACE (Wabi-sabi) ====================
    Item {
      id: ensoFace
      anchors.fill: parent
      visible: dial.face === "enso"

      // Washi parchment disc
      Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: Ink.paper
        border.width: 1
        border.color: Ink.line

        // Deckle paper fibre ring
        Rectangle {
          anchors.fill: parent
          anchors.margins: Type.px(4)
          radius: width / 2
          color: "transparent"
          border.width: Type.px(4)
          border.color: Ink.lineSoft
        }
      }

      // Brushed Ensō Circle
      Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
          strokeColor: "transparent"
          fillColor: Ink.ink
          PathSvg {
            path: Brush.enso(1, ensoFace.width, Type.px(38), 7)
          }
        }
      }
    }

    // ==================== TSUBA FACE (Sekiro) ====================
    Item {
      id: tsubaFace
      anchors.fill: parent
      visible: dial.face === "tsuba"

      // Forged iron plate with radial depth
      Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
          strokeColor: "#050405"
          strokeWidth: 1.5
          fillGradient: RadialGradient {
            centerX: dial.radius
            centerY: dial.radius
            centerRadius: dial.radius
            focalX: dial.radius
            focalY: dial.radius
            GradientStop { position: 0; color: "#363033" }
            GradientStop { position: 0.7; color: "#241f21" }
            GradientStop { position: 0.94; color: "#161214" }
            GradientStop { position: 1; color: "#0c090a" }
          }
          PathAngleArc {
            centerX: dial.radius
            centerY: dial.radius
            radiusX: dial.radius - 1
            radiusY: dial.radius - 1
            startAngle: 0
            sweepAngle: 360
          }
        }

        // Mimi: Raised forged rim
        ShapePath {
          fillColor: "transparent"
          strokeColor: "#0a0708"
          strokeWidth: Type.px(7)
          PathAngleArc {
            centerX: dial.radius
            centerY: dial.radius
            radiusX: dial.radius - Type.px(4)
            radiusY: dial.radius - Type.px(4)
            startAngle: 0
            sweepAngle: 360
          }
        }

        // Gold inlay rings
        ShapePath {
          fillColor: "transparent"
          strokeColor: Qt.rgba(0.78, 0.62, 0.28, 0.65)
          strokeWidth: 1.5
          PathAngleArc {
            centerX: dial.radius
            centerY: dial.radius
            radiusX: dial.radius * 0.85
            radiusY: dial.radius * 0.85
            startAngle: 0
            sweepAngle: 360
          }
        }

        ShapePath {
          fillColor: "transparent"
          strokeColor: Qt.rgba(0.78, 0.62, 0.28, 0.3)
          strokeWidth: 1
          PathAngleArc {
            centerX: dial.radius
            centerY: dial.radius
            radiusX: dial.radius * 0.82
            radiusY: dial.radius * 0.82
            startAngle: 0
            sweepAngle: 360
          }
        }
      }

      // Nanako: Gold dot bead ring
      Repeater {
        model: 36
        Rectangle {
          required property int index
          readonly property real a: index * 10 * Math.PI / 180
          x: dial.radius + Math.cos(a) * dial.radius * 0.78 - width / 2
          y: dial.radius + Math.sin(a) * dial.radius * 0.78 - height / 2
          width: index % 4 === 0 ? Type.px(4) : Type.px(2.5)
          height: width
          radius: width / 2
          color: Qt.rgba(0.78, 0.62, 0.28, index % 4 === 0 ? 0.8 : 0.45)
        }
      }

      // Hitsu-ana (tang clearance openings)
      Repeater {
        model: [-1, 1]
        Rectangle {
          required property var modelData
          x: dial.radius - width / 2
          y: dial.radius + modelData * dial.radius * 0.4 - height / 2
          width: dial.radius * 0.1
          height: dial.radius * 0.22
          radius: width / 2
          color: "#080607"
          border.width: 1
          border.color: Qt.rgba(0.78, 0.62, 0.28, 0.35)
        }
      }
    }
  }

  // ── Pointers at 3 o'clock ──────────────────────────────────────────────────
  // 1. Vermilion square seal ("選") for Ensō face
  Rectangle {
    visible: dial.face === "enso"
    x: dial.cx + dial.radius - width - Type.px(8)
    y: dial.cy - height / 2
    width: Type.px(30)
    height: Type.px(30)
    radius: Type.px(3)
    rotation: -3
    color: Ink.seal

    Text {
      anchors.centerIn: parent
      text: "選"
      font.family: Type.jp
      font.pixelSize: Type.px(18)
      font.weight: Font.Bold
      color: Ink.paper
    }
  }

  // Gold seam line from seal toward active name
  Rectangle {
    visible: dial.face === "enso"
    x: dial.cx + dial.radius + Type.px(6)
    y: dial.cy - height / 2
    width: Type.px(64)
    height: 1.5
    gradient: Gradient {
      orientation: Gradient.Horizontal
      GradientStop { position: 0; color: "#c29a48" }
      GradientStop { position: 1; color: "transparent" }
    }
  }

  // 2. Habaki blade collar pointer for Tsuba face
  Item {
    visible: dial.face === "tsuba"
    x: dial.cx + dial.radius - Type.px(6)
    y: dial.cy - Type.px(10)
    width: Type.px(80)
    height: Type.px(20)

    // Habaki collar
    Rectangle {
      x: 0
      y: Type.px(4)
      width: Type.px(18)
      height: Type.px(12)
      radius: 1
      color: "#c9a55c"
      border.width: 1
      border.color: "#8c6b2d"
    }

    // Steel temper line
    Rectangle {
      x: Type.px(18)
      y: Type.px(8)
      width: Type.px(62)
      height: 2
      color: Ink.seal
    }
  }

  // ── Wheel Scroll Backdrop ──────────────────────────────────────────────────
  MouseArea {
    anchors.fill: parent
    onWheel: function(wheel) {
      if (wheel.angleDelta.y > 0) dial.stepTo(-1)
      else if (wheel.angleDelta.y < 0) dial.stepTo(1)
    }
    onClicked: function(mouse) {
      var dx = mouse.x - dial.cx
      var dy = mouse.y - dial.cy
      var dist = Math.sqrt(dx * dx + dy * dy)
      if (dist > dial.track + Type.px(80) && mouse.x > dial.cx + dial.track + Type.px(200)) {
        dial.closed()
      }
    }
  }

  // ── Apps Riding the Rim ────────────────────────────────────────────────────
  Repeater {
    model: dial.count

    Item {
      id: appItem
      required property int index

      readonly property var itemData: dial.model.get ? dial.model.get(index) : dial.model[index]
      readonly property string itemName: itemData ? (itemData.label || itemData.name || "") : ""
      readonly property bool isApp: itemData ? (itemData.kind === "app" || !!itemData.appIcon) : false
      readonly property string appIconName: itemData ? (itemData.appIcon || "") : ""
      readonly property string rawIcon: itemData ? (itemData.icon || "") : ""
      readonly property string iconFontName: itemData ? (itemData.iconFont || "") : ""

      readonly property real angle: dial.angleOf(index)
      readonly property real away: Math.abs(angle)
      readonly property real rad: angle * Math.PI / 180

      // Near 0 degrees (3 o'clock): swells up
      readonly property real near: Math.max(0, 1 - away / (dial.step * 1.6))
      readonly property real itemSize: Type.px(34) + Type.px(38) * near

      visible: away < 94
      x: dial.cx + dial.track * Math.cos(rad) - itemSize / 2
      y: dial.cy + dial.track * Math.sin(rad) - itemSize / 2
      width: itemSize
      height: itemSize
      z: near * 10

      // Fading toward ends of arc
      opacity: Math.max(0, Math.min(1, (92 - away) / 28))

      Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: near > 0.6 ? Ink.alpha(Ink.seal, 0.14) : (hoverMouse.containsMouse ? Ink.lineSoft : "transparent")
        border.width: near > 0.8 ? 1.5 : (hoverMouse.containsMouse ? 1 : 0)
        border.color: near > 0.8 ? Ink.seal : Ink.line
      }

      Image {
        visible: appItem.isApp && (appItem.appIconName !== "" || appItem.rawIcon.indexOf("/") === 0)
        anchors.centerIn: parent
        width: parent.width * 0.72
        height: width
        source: appItem.rawIcon.indexOf("/") === 0 ? ("file://" + appItem.rawIcon) : (dial.appLibrary && appItem.appIconName ? dial.appLibrary.iconSource(appItem.appIconName) : (appItem.appIconName ? ("image://icon/" + appItem.appIconName) : ""))
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        smooth: true
        mipmap: true
      }

      Text {
        visible: !appItem.isApp || (appItem.appIconName === "" && appItem.rawIcon.indexOf("/") < 0 && appItem.rawIcon !== "")
        anchors.centerIn: parent
        text: appItem.rawIcon
        color: appItem.near > 0.6 ? Ink.seal : Ink.ink
        font.family: appItem.iconFontName !== "" ? appItem.iconFontName : Type.display
        font.pixelSize: Math.round(parent.width * 0.48)
      }

      // Small name tag beside off-center apps
      Text {
        visible: appItem.away >= 16 && appItem.away < 75 && hoverMouse.containsMouse
        x: appItem.width + Type.px(8)
        anchors.verticalCenter: parent.verticalCenter
        text: appItem.itemName
        color: Ink.ink
        font.family: Type.text
        font.pixelSize: Type.label
      }

      MouseArea {
        id: hoverMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          if (appItem.near > 0.7) dial.launched(appItem.index, appItem.itemData)
          else dial.target = appItem.index
        }
      }
    }
  }

  // ── Active Item Display at 3 o'clock ───────────────────────────────────────
  Item {
    id: activeDisplay
    x: dial.cx + dial.track + Type.px(68)
    anchors.verticalCenter: parent.verticalCenter
    width: Math.min(dial.width - x - Type.px(40), Type.px(420))
    height: activeColumn.implicitHeight
    visible: dial.activeItem !== null

    property string aName: ""
    property string aDetail: ""
    property string aCategory: "APP"

    Connections {
      target: dial
      function onActiveItemChanged() {
        var it = dial.activeItem
        if (!it) {
          activeDisplay.aName = ""
          activeDisplay.aDetail = ""
          activeDisplay.aCategory = "APP"
          return
        }
        activeDisplay.aName = String(it.label || it.name || "")
        activeDisplay.aDetail = String(it.detail || it.desc || it.command || "")
        activeDisplay.aCategory = String(it.section || it.category || "APP")
      }
    }

    Column {
      id: activeColumn
      width: parent.width
      spacing: Type.px(6)

      // Search Filter Tag when query is active
      Row {
        visible: dial.query !== ""
        spacing: Type.px(6)
        bottomPadding: Type.px(4)
        Rectangle {
          anchors.verticalCenter: parent.verticalCenter
          width: Type.px(6); height: Type.px(6)
          radius: 3
          color: Ink.seal
        }
        Text {
          text: "SEARCH // " + dial.query.toUpperCase()
          color: Ink.seal
          font.family: Type.mono
          font.pixelSize: Type.tag
          font.letterSpacing: Type.trackTag
          font.weight: Font.DemiBold
        }
      }

      Row {
        spacing: Type.px(10)

        // Category / Section tag
        Rectangle {
          anchors.verticalCenter: parent.verticalCenter
          height: Type.px(18)
          width: tagText.contentWidth + Type.px(12)
          radius: 2
          color: Ink.lineSoft

          Text {
            id: tagText
            anchors.centerIn: parent
            text: activeDisplay.aCategory.toUpperCase()
            color: Ink.inkDim
            font.family: Type.mono
            font.pixelSize: Type.tag
            font.letterSpacing: Type.trackTag
          }
        }

        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: "//"
          color: Ink.seal
          font.family: Type.mono
          font.pixelSize: Type.eyebrow
        }
      }

      // Hero title in Fraunces serif
      Text {
        width: parent.width
        text: activeDisplay.aName
        color: Ink.ink
        font.family: Type.display
        font.pixelSize: Type.px(32)
        font.weight: Font.DemiBold
        elide: Text.ElideRight
      }

      // Description / Subtext
      Text {
        width: parent.width
        visible: activeDisplay.aDetail !== ""
        text: activeDisplay.aDetail
        color: Ink.inkMuted
        font.family: Type.text
        font.pixelSize: Type.note
        wrapMode: Text.Wrap
        maximumLineCount: 2
        elide: Text.ElideRight
      }

      // Launch hint
      Row {
        spacing: Type.px(8)
        topPadding: Type.px(6)

        Rectangle {
          anchors.verticalCenter: parent.verticalCenter
          width: enterTag.contentWidth + Type.px(10)
          height: Type.px(18)
          radius: 2
          color: Ink.bone
          Text {
            id: enterTag
            anchors.centerIn: parent
            text: "ENTER"
            color: Ink.boneInk
            font.family: Type.mono
            font.pixelSize: Type.tag
            font.weight: Font.Medium
          }
        }

        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: "to launch"
          color: Ink.inkFaint
          font.family: Type.mono
          font.pixelSize: Type.tag
        }
      }
    }
  }

  // ── Keyboard Navigation ───────────────────────────────────────────────────
  Keys.onPressed: function(event) {
    var k = event.key
    var t = event.text
    if (k === Qt.Key_Down || t === "j") { dial.stepTo(1); event.accepted = true }
    else if (k === Qt.Key_Up || t === "k") { dial.stepTo(-1); event.accepted = true }
    else if (k === Qt.Key_PageDown) { dial.stepTo(5); event.accepted = true }
    else if (k === Qt.Key_PageUp) { dial.stepTo(-5); event.accepted = true }
    else if (k === Qt.Key_Return || k === Qt.Key_Enter) {
      if (dial.current >= 0) dial.launched(dial.current, dial.activeItem)
      event.accepted = true
    }
    else if (k === Qt.Key_Escape) {
      dial.closed()
      event.accepted = true
    }
  }
}
