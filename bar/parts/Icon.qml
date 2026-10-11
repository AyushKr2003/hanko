pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Shapes

// The Kata bar's few line icons (wifi, offline, volume, muted, bolt,
// bluetooth, bluetoothOff, sun for brightness), on one 24-unit grid with one stroke, drawn
// at `size`. State changes the drawing (Wi-Fi arcs fade, the speaker gains a
// cross), never adds a badge.
Item {
  id: root

  property string name: "wifi"
  property int level: 3            // Wi-Fi arcs lit, 0..3
  property color color: "white"
  property real size: 16

  implicitWidth: size
  implicitHeight: size

  readonly property var paths: ({
    arc3: "M 2.5 8.8 A 14 14 0 0 1 21.5 8.8",
    arc2: "M 5.6 12.1 A 9.5 9.5 0 0 1 18.4 12.1",
    arc1: "M 8.8 15.3 A 5 5 0 0 1 15.2 15.3",
    dot: "M 12 17.5 L 12 19.7",
    speaker: "M 4 9.5 L 7.2 9.5 L 12 5.5 L 12 18.5 L 7.2 14.5 L 4 14.5 Z",
    waves: "M 15.5 9 A 4 4 0 0 1 15.5 15 M 18.2 6.5 A 7.6 7.6 0 0 1 18.2 17.5",
    cross: "M 16 9.5 L 21 14.5 M 21 9.5 L 16 14.5",
    bolt: "M 13 3 L 5 13.5 L 11 13.5 L 10 21 L 18 10.5 L 12 10.5 Z",
    off: "M 4 4 L 20 20",
    rune: "M 6.5 7.8 L 17 16.4 L 12 20.6 L 12 3.4 L 17 7.6 L 6.5 16.2",
    core: "M 8 12 A 4 4 0 1 1 16 12 A 4 4 0 1 1 8 12",
    rays: "M 12 2.5 L 12 4.5 M 12 19.5 L 12 21.5 M 2.5 12 L 4.5 12 M 19.5 12 L 21.5 12 M 5.3 5.3 L 6.7 6.7 M 17.3 17.3 L 18.7 18.7 M 5.3 18.7 L 6.7 17.3 M 17.3 6.7 L 18.7 5.3"
  })

  readonly property var parts: name === "wifi" ? ["arc3", "arc2", "arc1", "dot"]
    : name === "offline" ? ["arc2", "arc1", "dot", "off"]
    : name === "volume" ? ["speaker", "waves"]
    : name === "muted" ? ["speaker", "cross"]
    : name === "bolt" ? ["bolt"]
    : name === "bluetooth" ? ["rune"]
    : name === "bluetoothOff" ? ["rune", "off"]
    : name === "sun" ? ["core", "rays"] : []

  Repeater {
    model: root.parts
    Shape {
      id: part
      required property string modelData
      required property int index
      width: 24; height: 24
      scale: root.size / 24
      transformOrigin: Item.TopLeft
      preferredRendererType: Shape.CurveRenderer
      // unlit arcs, by signal; the offline slash is always full
      opacity: root.name === "wifi" && part.index < 3 && 3 - part.index > root.level ? 0.3
        : (root.name === "offline" || root.name === "bluetoothOff") && part.modelData !== "off" ? 0.3 : 1
      ShapePath {
        strokeColor: root.color
        strokeWidth: 1.6
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap
        joinStyle: ShapePath.RoundJoin
        PathSvg { path: root.paths[part.modelData] }
      }
    }
  }
}
