import QtQuick
QtObject {
  property string path
  property bool watchChanges
  property bool printErrors
  property bool atomicWrites
  property bool blockLoading
  signal fileChanged()
  signal loaded()
  signal loadFailed(var error)
  function reload() { loadFailed(0) }
  function text() { return "" }
  function setText(t) {}
  Component.onCompleted: loadFailed(0)
}
