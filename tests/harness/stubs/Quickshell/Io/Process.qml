import QtQuick
QtObject {
  property var command: []
  property bool running
  property QtObject stdout
  signal exited(int exitCode, int exitStatus)
}
