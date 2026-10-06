pragma Singleton
import QtQuick

// Harness stand-in for Omarchy's qs.Commons.Style at the default base size.
QtObject {
  property string fontFamily: "JetBrains Mono"
  readonly property QtObject font: QtObject {
    readonly property string family: "JetBrains Mono"
    readonly property int body: 12
  }
  readonly property QtObject bar: QtObject {
    readonly property int sizeHorizontal: 26
  }
}
