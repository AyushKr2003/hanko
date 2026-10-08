pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../parts"

// Sound 音: the level as a hero figure you scroll, the slider part under
// it, where it plays, each app's own slider, and the microphone.
// Requests as SoundSheet's: master (0..1) | mute | output | stream | inputMute.
Column {
  id: root

  property var skin: ({})
  property var sound: null
  signal request(string sheet, string what, var arg)

  readonly property var master: sound ? sound.master : null
  readonly property var outputs: sound ? sound.outputs : []
  readonly property var streams: sound ? sound.streams : []
  readonly property bool muted: !!(master && master.muted)

  spacing: Type.px(10)

  Item {
    width: parent.width; height: hero.height
    Figure {
      id: hero
      skin: root.skin
      value: root.master ? String(root.master.percent) : "—"
      unit: "%"
      color: root.muted ? Ink.seal : Ink.ink
      MouseArea {
        anchors.fill: parent
        onWheel: function(w) { if (root.master) root.request("sound", "master", Math.max(0, Math.min(1, root.master.level + (w.angleDelta.y > 0 ? 0.02 : -0.02)))) }
        onClicked: root.request("sound", "mute", null)
      }
    }
    Text {
      anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.bottomMargin: Type.px(10)
      horizontalAlignment: Text.AlignRight
      text: root.muted ? "Muted · click the figure" : "Scroll the figure\nor drag below"
      color: root.muted ? Ink.seal : Ink.ink3
      font.family: Type.text; font.pixelSize: Type.px(12)
    }
  }
  KataSlider {
    width: parent.width
    skin: root.skin
    value: root.master ? root.master.percent : 0
    muted: root.muted
    onMoved: function(v) { root.request("sound", "master", v / 100) }
  }
  Divider { skin: root.skin; width: parent.width; bleed: Type.px(20) }
  Heading { skin: root.skin; text: "Plays on" }
  KataList {
    width: parent.width
    skin: root.skin
    rows: root.outputs.map(function(o) { return { title: o.label, detail: o.detail, note: o.current ? "" : o.note, chosen: o.current } })
    onPicked: function(i) { var o = root.outputs[i]; if (!o.current) root.request("sound", "output", { id: o.id, name: o.name }) }
  }
  Divider { visible: root.streams.length > 0; skin: root.skin; width: parent.width; bleed: Type.px(20) }
  Heading { visible: root.streams.length > 0; skin: root.skin; text: "Apps" }
  Repeater {
    model: root.streams
    Item {
      id: app
      required property var modelData
      width: root.width; height: Type.px(40)
      Text {
        anchors.verticalCenter: parent.verticalCenter
        width: Type.px(110); elide: Text.ElideRight
        text: app.modelData.label
        color: Ink.ink2
        font.family: Type.text; font.pixelSize: Type.px(13.5)
      }
      KataSlider {
        x: Type.px(120); anchors.verticalCenter: parent.verticalCenter
        width: parent.width - Type.px(120) - Type.px(40); height: Type.px(18)
        skin: root.skin; thin: true; seed: 11 + app.modelData.id % 7
        value: app.modelData.percent; muted: app.modelData.muted
        onMoved: function(v) { root.request("sound", "stream", { id: app.modelData.id, name: app.modelData.name, value: v / 100 }) }
      }
      Text {
        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
        text: app.modelData.muted ? "—" : String(app.modelData.percent)
        color: Ink.ink
        font.family: Type.display; font.pixelSize: Type.px(17); font.weight: Font.Normal
        font.variableAxes: Type.axes(Type.px(17), 400, root.skin.soft)
      }
    }
  }
  Divider { skin: root.skin; width: parent.width; bleed: Type.px(20) }
  Item {
    width: parent.width; height: Type.px(40)
    Column {
      anchors.verticalCenter: parent.verticalCenter
      Text { text: "Microphone"; color: Ink.ink2; font.family: Type.text; font.pixelSize: Type.px(13.5) }
      Text { text: root.sound ? root.sound.input : ""; color: Ink.ink3; font.family: Type.text; font.pixelSize: Type.px(12) }
    }
    KataSwitch {
      anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
      skin: root.skin
      on: !!(root.sound && !root.sound.inputMuted)
      onToggled: root.request("sound", "inputMute", null)
    }
  }
}
