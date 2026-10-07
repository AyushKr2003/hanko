pragma Singleton
import QtQuick

// Harness stand-in for Quickshell.Wayland's ToplevelManager: no windows.
QtObject {
  readonly property QtObject toplevels: QtObject { readonly property var values: [] }
}
