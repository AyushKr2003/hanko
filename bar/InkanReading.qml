pragma ComponentBehavior: Bound
import QtQuick
import "../core"

// The one line Inkan's seal sets beside itself on hover (core/Inkan.js
// reading()): the time in the serif, then the battery, the network, the
// letters, each a kanji and a mono value; what needs you in red. Pure.
Row {
  id: root

  property var parts: []

  spacing: Type.px(10)

  Repeater {
    model: root.parts

    Row {
      id: part
      required property var modelData
      required property int index
      anchors.verticalCenter: parent ? parent.verticalCenter : undefined
      spacing: Type.px(5)

      Text {
        visible: part.index > 0
        anchors.verticalCenter: parent.verticalCenter
        text: "·"
        color: Ink.inkFaint
        font.family: Type.mono
        font.pixelSize: Type.label
      }
      Text {
        visible: !!part.modelData.jp
        anchors.verticalCenter: parent.verticalCenter
        text: part.modelData.jp || ""
        color: part.modelData.red ? Ink.seal : Ink.inkMuted
        font.family: Type.jp
        font.pixelSize: Type.glossMid
      }
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: part.modelData.time ? part.modelData.text : String(part.modelData.text).toUpperCase()
        color: part.modelData.red ? Ink.seal : part.modelData.time ? Ink.ink : Ink.inkDim
        font.family: part.modelData.time ? Type.display : Type.mono
        font.pixelSize: part.modelData.time ? Type.px(17) : Type.label
        font.weight: part.modelData.time ? Font.Normal : Type.labelWeight
        font.letterSpacing: part.modelData.time ? 0 : Type.trackLabel
        font.variableAxes: part.modelData.time ? Type.axes(Type.px(17)) : ({})
        font.features: ({ "tnum": 1 })
      }
    }
  }
}
