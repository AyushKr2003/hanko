pragma Singleton
import QtQuick
QtObject {
  property var screens: []
  property int processId: 0
  function execDetached(command) {}
  function env(name) { return name === "HOME" ? "/tmp/hanko-harness-home" : "" }
}
