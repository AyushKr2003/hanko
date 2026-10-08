import QtQuick
import QtQuick.Shapes

// One filled SVG path (core/Brush.js draws them): a brush stroke, an ensō,
// a carved seal. The path is rebuilt only when its inputs change.
Shape {
  id: root

  property string path: ""
  property color fill: "black"
  property color stroke: "transparent"
  property real strokeWidth: 0

  preferredRendererType: Shape.CurveRenderer
  antialiasing: true

  ShapePath {
    fillColor: root.fill
    strokeColor: root.stroke
    strokeWidth: root.strokeWidth
    PathSvg { path: root.path }
  }
}
