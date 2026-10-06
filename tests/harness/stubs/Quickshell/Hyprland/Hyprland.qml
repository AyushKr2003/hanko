pragma Singleton
import QtQuick
QtObject {
  property var focusedMonitor: null
  property var focusedWorkspace: null
  property var activeToplevel: null
  property QtObject workspaces: QtObject { property var values: [] }
  property QtObject toplevels: QtObject { property var values: [] }
  property QtObject monitors: QtObject { property var values: [] }
  signal rawEvent(var event)
  function monitorFor(screen) { return null }
  function dispatch(request) {}
  function refreshToplevels() {}
  function refreshWorkspaces() {}
  function refreshMonitors() {}
}
