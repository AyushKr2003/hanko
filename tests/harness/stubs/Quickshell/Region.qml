import QtQuick
// Lint-only stand-in for a window input mask region.
QtObject {
  default property list<QtObject> regions
  property int x
  property int y
  property int width
  property int height
  property int intersection
  property Item item
}
