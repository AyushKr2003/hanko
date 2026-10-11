pragma ComponentBehavior: Bound
import QtQuick
import "../../core"

// Sound 音: the master as a large number on a ruler (red needle, the whole
// thing red when muted), the outputs with the live one inverted, a ruler
// per app that is playing, and the input at the foot.
// Keys: Up/Down step the master, M mutes.
Item {
  id: root

  // core/Sound.js sheet() shape, or null before the first reading.
  property var sound: null

  // what: master (value) | mute | output ({ id, name }) | stream ({ id, name,
  // value }) | streamMute ({ id, name }) | inputMute | nextOutput
  signal request(string what, var arg)

  readonly property var master: sound ? sound.master : null
  readonly property var outputs: sound ? sound.outputs : []
  readonly property var streams: sound ? sound.streams : []

  width: parent ? parent.width : 0
  implicitHeight: column.y + column.implicitHeight + foot.implicitHeight

  Column {
    id: column
    x: Type.px(24)
    y: Type.px(22)
    width: root.width - 2 * x
    // 4 px under the last group, then 16 more before the foot.
    bottomPadding: Type.px(4) + Type.px(16)

    SheetHead {
      sheet: "sound"
      jp: "音"
      label: "Sound · Pipewire"
      title: "Sound"
      blurb: "Where it plays, how loud, and who is talking."
    }

    GroupHead { title: "Master"; summary: "Scroll on bar · ±5" }

    Item {
      width: parent.width
      height: Type.px(12) + Type.px(40) + Type.px(6)

      Row {
        x: Type.px(2)
        y: Type.px(12)
        width: parent.width - Type.px(4)
        spacing: Type.px(16)

        Item {
          id: big
          width: Type.px(78)
          height: bigText.height
          anchors.verticalCenter: parent.verticalCenter
          Text {
            id: bigText
            text: root.master ? String(root.master.percent) : "—"
            color: root.master && root.master.muted ? Ink.seal : Ink.ink
            font.family: Type.display
            font.pixelSize: Type.title
            font.weight: Font.Normal
            font.variableAxes: Type.axes(Type.title)
            font.features: { "tnum": 1 }
          }
          // The unit set small and high, as a figure's superscript.
          Text {
            visible: !!root.master
            x: bigText.width + Type.px(3)
            y: Type.px(6)
            text: "%"
            color: Ink.inkMuted
            font.family: Type.mono
            font.pixelSize: Type.label
          }
        }
        Ruler {
          anchors.verticalCenter: parent.verticalCenter
          width: parent.width - big.width - mute.width - 2 * parent.spacing
          value: root.master ? root.master.level : 0
          red: true
          muted: !!(root.master && root.master.muted)
          onMoved: function(v) { root.request("master", v) }
        }
        SheetButton {
          id: mute
          anchors.verticalCenter: parent.verticalCenter
          text: "Mute"
          on: !!(root.master && root.master.muted)
          onClicked: root.request("mute", null)
        }
      }
    }

    GroupHead {
      title: "Output"
      summary: root.outputs.length + (root.outputs.length === 1 ? " device" : " devices")
    }

    Repeater {
      model: root.outputs
      SheetRow {
        id: output
        required property var modelData
        required property int index
        lead: true
        selected: modelData.current
        interactive: !modelData.current
        name: modelData.label
        detail: modelData.detail
        note: modelData.note
        last: index === root.outputs.length - 1
        onClicked: root.request("output", { id: output.modelData.id, name: output.modelData.name })
      }
    }

    GroupHead {
      title: "Mixer"
      summary: root.streams.length + (root.streams.length === 1 ? " stream" : " streams")
    }

    SheetRow {
      visible: root.streams.length === 0
      name: "Nothing is playing"
      last: true
    }

    Repeater {
      model: root.streams
      SheetRow {
        id: stream
        required property var modelData
        required property int index
        name: modelData.label
        nameWidth: Type.px(90)
        note: modelData.muted ? "Muted" : String(modelData.percent)
        last: index === root.streams.length - 1

        Ruler {
          width: stream.width - Type.px(90) - Type.px(12) - Type.px(20) - Type.px(10) - Type.px(46)
          height: Type.px(22)
          value: stream.modelData.level
          muted: stream.modelData.muted
          onMoved: function(v) {
            root.request("stream", { id: stream.modelData.id, name: stream.modelData.name, value: v })
          }
        }
      }
    }
  }

  ActionBar {
    id: foot
    anchors.top: column.bottom
    note: root.sound ? root.sound.input : ""

    SheetButton {
      ghost: true
      text: root.sound && root.sound.inputMuted ? "Unmute mic" : "Mute mic"
      onClicked: root.request("inputMute", null)
    }
    SheetButton {
      plate: true
      text: "Next output ›"
      onClicked: root.request("nextOutput", null)
    }
  }

  Keys.onUpPressed: if (root.master) root.request("master", Math.min(1, root.master.level + 0.05))
  Keys.onDownPressed: if (root.master) root.request("master", Math.max(0, root.master.level - 0.05))
  Keys.onPressed: function(event) {
    if (event.key === Qt.Key_M) { root.request("mute", null); event.accepted = true }
  }
}
