pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../parts"

// One Kata part drawn small, in the variant the skin carries, for the
// Design page's borrow rows: the part's own component wherever there is one,
// so what you pick is what the bar and panels will draw.
Item {
  id: root

  property var skin: ({})
  property string part: ""

  implicitWidth: Type.px(150)
  implicitHeight: Type.px(70)
  clip: true

  readonly property var sampleLetter: ({ app: "Signal", summary: "Mika", body: "", timestamp: Date.now() - 120000, urgent: false })

  Surface { visible: root.part === "surface"; skin: root.skin; x: Type.px(14); y: Type.px(10); width: root.width - Type.px(28); height: root.height - Type.px(22) }

  // arrive: a bar's line and the panel where it lands
  Item {
    visible: root.part === "arrive"
    anchors.fill: parent
    Rectangle { x: Type.px(10); y: Type.px(10); width: parent.width - Type.px(20); height: Type.px(12); color: Ink.paper2; border.width: 1; border.color: Ink.kLine }
    Rectangle {
      x: Type.px(root.skin.arrive === "slide" ? 52 : 34)
      y: Type.px(22) + (root.skin.arrive === "slide" ? Type.px(5) : root.skin.arrive === "fold" ? -1 : 0)
      width: Type.px(64); height: root.height - y - Type.px(8)
      radius: root.skin.arrive === "fold" ? Type.px(5) : 0
      color: Ink.paper; border.width: 1; border.color: Ink.kLine
    }
    Text {
      visible: root.skin.arrive === "slide"
      x: Type.px(18); y: Type.px(36)
      text: "→"; color: Ink.ink3; font.family: Type.text; font.pixelSize: Type.px(14)
    }
    Rectangle { visible: root.skin.arrive === "fold"; x: Type.px(34); y: Type.px(34); width: Type.px(64); height: 1; color: Ink.alpha(Ink.ink, 0.12) }
  }

  Item {
    visible: root.part === "pointer"
    anchors.fill: parent
    Rectangle { x: Type.px(8); y: Type.px(12); width: parent.width - Type.px(16); height: Type.px(28); color: Ink.paper2 }
    Row {
      x: Type.px(8); y: Type.px(12)
      Repeater {
        model: ["Wi-Fi", "62", "91"]
        Text { required property string modelData; width: (root.width - Type.px(16)) / 3; height: Type.px(28); text: modelData; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; color: Ink.ink2; font.family: Type.text; font.pixelSize: Type.px(11) }
      }
    }
    PointerMark { anchors.fill: parent; skin: root.skin; target: Qt.rect(Type.px(8) + (root.width - Type.px(16)) / 3, Type.px(12), (root.width - Type.px(16)) / 3, Type.px(28)); lineY: Type.px(40) }
  }

  Item {
    visible: root.part === "select"
    x: Type.px(10); y: Type.px(16); width: root.width - Type.px(20); height: Type.px(36)
    Selection { id: sel; skin: root.skin; width: parent.width; height: parent.height }
    Text { x: Type.px(10); anchors.verticalCenter: parent.verticalCenter; text: "Studio Monitors"; color: sel.inverts ? Ink.paper : Ink.ink; font.family: Type.text; font.pixelSize: Type.px(12); font.weight: Font.Medium; font.variableAxes: Type.valueAxes }
  }

  KataSlider { visible: root.part === "slider"; skin: root.skin; x: Type.px(12); y: Type.px(22); width: root.width - Type.px(24); height: Type.px(26); value: 62 }

  Row {
    visible: root.part === "ring"
    anchors.centerIn: parent
    spacing: Type.px(14)
    Ring { skin: root.skin; value: 91; size: Type.px(16); anchors.verticalCenter: parent.verticalCenter }
    Ring { skin: root.skin; value: 64; size: Type.px(46); anchors.verticalCenter: parent.verticalCenter }
  }

  KataSeal { visible: root.part === "seal"; anchors.centerIn: parent; skin: root.skin; size: Type.px(30); on: true }

  Rectangle {
    visible: root.part === "unread"
    x: Type.px(14); y: Type.px(12); width: root.width - Type.px(28); height: root.height - Type.px(24)
    radius: root.skin.radiusRow || 0
    color: "transparent"; border.width: 1; border.color: Ink.kLine
    Text { x: Type.px(12); anchors.verticalCenter: parent.verticalCenter; text: "Signal · 2m"; color: Ink.ink3; font.family: Type.text; font.pixelSize: Type.px(11) }
    UnreadMark { anchors.fill: parent; skin: root.skin }
  }

  Item {
    visible: root.part === "sign"
    anchors.fill: parent
    Sign { visible: root.skin.sign === "eyebrow"; skin: root.skin; x: Type.px(12); y: Type.px(24); name: "Sound"; detail: "Monitors" }
    Sign { visible: root.skin.sign === "tabs"; skin: root.skin; x: Type.px(8); y: Type.px(22); current: "sound"; tabs: [{ key: "time", name: "Time" }, { key: "sound", name: "Sound" }, { key: "power", name: "Power" }] }
    Sign { visible: root.skin.sign === "tategaki"; skin: root.skin; x: (root.width - Type.px(40)) / 2; width: Type.px(40); height: root.height; kanji: "音"; name: "Sound" }
  }

  // notify: a letter, drawn at its own size and scaled into the tile
  Item {
    visible: root.part === "notify"
    anchors.fill: parent
    Letter {
      x: Type.px(8); y: Type.px(4)
      width: Type.px(260)
      scale: (root.width - Type.px(16)) / Type.px(260)
      transformOrigin: Item.TopLeft
      skin: root.skin
      letter: root.sampleLetter
      first: true
      enabled: false
    }
  }

  // overview: two desks in the part's frame
  Row {
    visible: root.part === "overview"
    x: Type.px(10); y: Type.px(12)
    spacing: Type.px(8)
    Repeater {
      model: [1, 2]
      Rectangle {
        id: page
        required property int modelData
        readonly property string v: root.skin.overview || ""
        width: (root.width - Type.px(28)) / 2; height: root.height - Type.px(24)
        radius: v === "miniatures" ? (root.skin.radiusChip || 0) : 0
        color: v === "contact" ? Ink.paper2 : Ink.paper
        border.width: page.modelData === 1 ? 2 : 1
        border.color: page.modelData === 1 ? Ink.ink : Ink.kLine
        Text {
          x: Type.px(page.v === "contact" ? 12 : 6); y: Type.px(3)
          text: page.v === "contact" ? "0" + page.modelData + "A" : page.v === "framed" ? ["", "壱 1", "弐 2"][page.modelData] : String(page.modelData)
          color: Ink.ink2
          font.family: page.v === "contact" ? Type.mono : page.v === "framed" ? Type.jp : Type.display
          font.pixelSize: Type.px(10)
        }
        Column {
          visible: page.v === "contact"
          x: Type.px(3); y: Type.px(4); spacing: Type.px(4)
          Repeater { model: 4; Rectangle { width: Type.px(4); height: Type.px(4); color: Ink.alpha(Ink.ink, 0.14) } }
        }
        Rectangle { visible: page.v === "framed"; x: Type.px(3); y: Type.px(3); width: parent.width - Type.px(6); height: parent.height - Type.px(6); color: "transparent"; border.width: 1; border.color: Ink.kLine }
      }
    }
  }

  Hold { visible: root.part === "hold"; x: Type.px(24); y: Type.px(14); width: root.width - Type.px(48); height: root.height - Type.px(28); skin: root.skin; label: "Restart"; progress: 0.6 }
}
