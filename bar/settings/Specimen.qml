pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Settings.js" as Settings
import "../../core/Edge.js" as EdgeJs
import "../../core/Inkan.js" as Inkan
import ".."

// One way a part can be set, as a specimen (docs/settings-kosei): the real
// bar, set that way with your data, cropped to the part and enlarged a
// little, over its name and a line. The one in use is inverted (emphasis is
// inversion); the preset's own way says so in the corner. Hovering tries it
// on the galley above; a click sets it.
Rectangle {
  id: root

  // Your resolved style; this specimen changes `key` to `value` in it.
  property var style: ({})
  property var barData: ({})
  // Settings.PROOF part key the specimen crops to.
  property string part: "seal"
  property string key: "seal"
  property string value: ""
  // The value the preset sets, for the PRESET tag.
  property string presetValue: ""
  property string presetName: ""
  property real stageHeight: Type.px(82)

  signal picked(string key, string value)
  signal tried(string key, string value)
  signal untried()

  readonly property bool on: String(style[key]) === value
  readonly property var way: Settings.wayOf(key, value)
  readonly property var set: {
    var s = Object.assign({}, style)
    s[key] = isNaN(Number(value)) || key !== "height" ? value : Number(value)
    // A specimen of a hidden or bar-less part still shows the part.
    s.form = key === "form" ? value : "bar"
    s.hidden = (style.hidden || []).filter(function(h) { return h !== root.part && h !== "edge" })
    return s
  }

  implicitHeight: stage.height + caption.height + 2
  radius: 3
  color: hover.containsMouse && !on ? Ink.alpha(Ink.bone, Ink.light ? 0.05 : 0.04) : "transparent"
  border.width: 1
  border.color: on ? Ink.bone : hover.containsMouse ? Ink.lineStrong : Ink.line
  clip: true

  // ------------------------------------------------------------ the stage
  Item {
    id: stage
    x: 1
    y: 1
    width: root.width - 2
    height: root.stageHeight
    clip: true
    // Cuts brush strokes too (Shape ignores clip).
    layer.enabled: true

    // Glass shows only over something: a faint hatch, as a window behind.
    Canvas {
      id: hatch
      anchors.fill: parent
      visible: root.key === "surface"
      onPaint: {
        var c = getContext("2d")
        c.reset()
        c.strokeStyle = Ink.lineStrong
        c.lineWidth = 1
        for (var x = -height; x < width; x += Type.px(7)) {
          c.beginPath(); c.moveTo(x, height); c.lineTo(x + height, 0); c.stroke()
        }
      }
      onWidthChanged: requestPaint()
      Connections { target: Ink; function onLineStrongChanged() { hatch.requestPaint() } }
    }

    // Form: the screen in small, with a strip across its top or a seal in
    // its corner.
    Rectangle {
      id: screen
      visible: root.key === "form"
      anchors.centerIn: parent
      height: parent.height - Type.px(18)
      width: Math.min(parent.width - Type.px(24), height * 1.78)
      radius: 2
      color: "transparent"
      border.width: 1
      border.color: Ink.lineStrong
      Repeater {
        model: [[0.05, 0.3, 0.42, 0.62], [0.52, 0.3, 0.43, 0.62]]
        Rectangle {
          id: pane
          required property var modelData
          x: screen.width * pane.modelData[0]; y: screen.height * pane.modelData[1]
          width: screen.width * pane.modelData[2]; height: screen.height * pane.modelData[3]
          radius: 1
          color: "transparent"
          border.width: 1
          border.color: Ink.lineSoft
        }
      }
      // The strip, drawn as a strip: at this size a real bar is a smudge.
      Rectangle {
        visible: root.value === "bar"
        x: 1
        y: root.set.position === "bottom" ? screen.height - height - 1 : 1
        width: screen.width - 2
        height: Type.px(9)
        color: Ink.alpha(Ink.ink, 0.12)
        Rectangle { width: parent.width; height: 1; y: root.set.position === "bottom" ? 0 : parent.height - 1; color: Ink.lineStrong }
        Rectangle { x: Type.px(3); anchors.verticalCenter: parent.verticalCenter; width: Type.px(5); height: width; color: Ink.seal }
        Repeater {
          model: 4
          Rectangle { required property int index; x: Type.px(12) + index * Type.px(5); anchors.verticalCenter: parent.verticalCenter; width: Type.px(3); height: width; color: index === 2 ? Ink.ink : Ink.inkFaint }
        }
        Rectangle { anchors.centerIn: parent; width: Type.px(12); height: Type.px(3); color: Ink.inkDim }
        Rectangle { anchors.right: parent.right; anchors.rightMargin: Type.px(4); anchors.verticalCenter: parent.verticalCenter; width: Type.px(20); height: Type.px(3); color: Ink.inkFaint }
      }
      InkanSeal {
        visible: root.value === "inkan"
        size: Type.px(22)
        x: screen.width - width - Type.px(6)
        y: screen.height - height - Type.px(6)
        carving: Inkan.carving(root.set, { battery: root.barData.battery || null, notifications: [], workspace: 1 })
      }
    }

    // Every other part: the bar set this way, cropped to the part.
    Item {
      id: crop
      visible: root.key !== "form"
      anchors.fill: parent

      // The region of the bar shown, in bar coordinates, with room around.
      readonly property real room: Type.px(root.part === "edge" ? 0 : 16)
      // Measured once the bar's rows have placed their children (a Row
      // lays out in a later pass, so a binding can catch it half way).
      property rect region: Qt.rect(0, 0, 0, 0)
      function measure() {
        if (root.part === "edge") {
          // A close-up of the foot, around the hour, at twice the size.
          var nowX = EdgeJs.dayFraction(root.barData.now || new Date()) * bar.width
          var w = stage.width / 2.2
          var x0 = Math.max(0, Math.min(bar.width - w, nowX - w / 2))
          region = Qt.rect(x0, 0, w, bar.height)
        } else if (root.part === "frame") {
          region = Qt.rect(0, 0, Type.px(300), bar.height)
        } else {
          var r = bar.partRect(root.part)
          region = r.width <= 0 ? Qt.rect(0, 0, 0, 0) : Qt.rect(r.x - room, 0, r.width + 2 * room, bar.height)
        }
      }
      readonly property real tick: bar.layoutTick
      onTickChanged: settle.restart()
      Timer { id: settle; interval: 30; onTriggered: crop.measure() }
      Component.onCompleted: settle.restart()
      readonly property real k: region.width <= 0 ? 1
        : root.part === "edge" ? stage.width / region.width
        : Math.min(1.6, stage.width / region.width, (stage.height - Type.px(12)) / Math.max(1, bar.height))

      // Laid out a screen wide, as the bar is: each crop then has the room
      // it has on your desktop (a narrow bar folds the marks away).
      BarSurface {
        id: bar
        width: Type.px(1920)
        height: implicitHeight
        scale: crop.k
        transformOrigin: Item.TopLeft
        // The region's centre on the stage's centre; the edge sits on the
        // stage's foot so the rule reads as a foot.
        x: stage.width / 2 - (crop.region.x + crop.region.width / 2) * crop.k
        y: root.part === "edge" ? (bar.atBottom ? Type.px(26) : stage.height - Type.px(26) - height * crop.k) : (stage.height - height * crop.k) / 2
        opacity: crop.region.width > 0 ? 1 : 0
        style: root.set
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

      // The crop's own edges fade into the stage, so a cut part reads as
      // a part of something longer.
      // Edge: the bar above its foot fades away, so only the foot is read.
      Rectangle {
        visible: root.part === "edge"
        z: 5
        readonly property real foot: bar.atBottom ? bar.y : bar.y + bar.height * crop.k
        readonly property real keep: Type.px(9) * crop.k
        x: 0
        width: parent.width
        y: bar.atBottom ? foot + keep : 0
        height: bar.atBottom ? parent.height - y : Math.max(0, foot - keep)
        gradient: Gradient {
          GradientStop { position: 0; color: Ink.paper }
          GradientStop { position: 0.75; color: Ink.paper }
          GradientStop { position: 1; color: Ink.alpha(Ink.paper, 0.2) } }
        rotation: bar.atBottom ? 180 : 0
      }
      Rectangle {
        visible: root.key !== "surface"
        z: 5
        width: Type.px(18); height: parent.height
        gradient: Gradient { orientation: Gradient.Horizontal
          GradientStop { position: 0; color: Ink.paper }
          GradientStop { position: 1; color: Ink.alpha(Ink.paper, 0) } }
      }
      Rectangle {
        visible: root.key !== "surface"
        z: 5
        anchors.right: parent.right
        width: Type.px(18); height: parent.height
        gradient: Gradient { orientation: Gradient.Horizontal
          GradientStop { position: 0; color: Ink.alpha(Ink.paper, 0) }
          GradientStop { position: 1; color: Ink.paper } }
      }

      // Nothing to show this way (none): say so, quietly.
      Text {
        visible: crop.region.width <= 0
        anchors.centerIn: parent
        text: "—  left out  —"
        color: Ink.inkFaint
        font.family: Type.mono
        font.pixelSize: Type.tag
        font.letterSpacing: Type.trackLabel
      }
    }

    // The preset's own way.
    Text {
      visible: root.presetValue === root.value && root.presetName !== ""
      anchors.right: parent.right
      anchors.rightMargin: Type.px(8)
      y: Type.px(6)
      text: root.presetName.toUpperCase()
      color: Ink.inkMuted
      font.family: Type.mono
      font.pixelSize: Type.tag
      font.letterSpacing: Type.trackLabel
    }
  }

  // ---------------------------------------------------------- the caption
  Rectangle {
    id: caption
    x: 1
    y: stage.y + stage.height
    width: root.width - 2
    height: captionColumn.height + 2 * Type.px(8)
    color: root.on ? Ink.bone : "transparent"
    Rectangle { visible: !root.on; width: parent.width; height: 1; color: Ink.lineSoft }
    Column {
      id: captionColumn
      x: Type.px(10)
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width - 2 * x
      spacing: Type.px(1)
      Row {
        spacing: Type.px(6)
        Text {
          visible: root.on
          anchors.baseline: name.baseline
          text: "//"
          color: Ink.boneInk
          opacity: 0.6
          font.family: Type.mono
          font.pixelSize: Type.px(11)
        }
        Text {
          id: name
          text: root.way.name
          color: root.on ? Ink.boneInk : Ink.ink
          font.family: Type.text
          font.pixelSize: Type.px(14)
          font.weight: Font.Medium
          font.variableAxes: Type.valueAxes
        }
      }
      Text {
        width: parent.width
        elide: Text.ElideRight
        text: root.way.line
        color: root.on ? Ink.alpha(Ink.boneInk, 0.72) : Ink.inkMuted
        font.family: Type.text
        font.pixelSize: Type.note
      }
    }
  }

  MouseArea {
    id: hover
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onContainsMouseChanged: containsMouse ? root.tried(root.key, root.value) : root.untried()
    onClicked: root.picked(root.key, root.value)
  }
}
