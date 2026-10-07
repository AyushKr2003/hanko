import QtQuick
// Lint-only stand-in: real PanelWindow is a layer-shell window.
Item {
  property var screen
  property color color
  property int exclusionMode
  property int exclusiveZone
  property var mask
  property QtObject margins: QtObject { property int top; property int bottom; property int left; property int right }
}
