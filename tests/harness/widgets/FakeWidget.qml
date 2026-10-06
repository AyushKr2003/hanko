import QtQuick

// Stands in for an Omarchy bar widget in renders: it takes `bar`,
// `moduleName` and `settings` like Ui/BarWidget.qml and draws its label
// with the bar's foreground and font, as Omarchy's widgets do.
Item {
  id: root
  property QtObject bar: null
  property string moduleName: ""
  property var settings: ({})

  implicitWidth: label.implicitWidth + 8
  implicitHeight: label.implicitHeight

  Text {
    id: label
    anchors.centerIn: parent
    text: root.settings.label || root.moduleName
    color: root.bar ? root.bar.barForeground : "magenta"
    font.family: root.bar ? root.bar.fontFamily : "monospace"
    font.pixelSize: 13
  }
}
