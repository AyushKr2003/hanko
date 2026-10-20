pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Style.js" as S
import "../../core/Settings.js" as Settings

// Settings › Parts 部品 as a sorts tray (docs/settings-kosei): a compositor
// keeps every sort in a case and sets aside what a page doesn't use. Your
// bar as it stands, then every part it can carry, in the order it sits, as
// a sort: the real part cropped from your bar, an indicator's stamp, a tray
// app's icon, a widget's name. One click sets a sort aside (it goes faint,
// in a dashed outline) and the bar above loses it; one more puts it back.
// Show all, in the action bar, puts everything back.
Column {
  id: root

  property var style: ({})
  property var draft: S.normalize({})
  property var barData: ({})
  property string query: ""
  property bool compact: false
  // Settings.visibilityCards ctx: own, indicators, tray, hosted.
  property var visibility: ({})

  signal settingPicked(string key, string value)
  signal showAll()

  readonly property var groups: Settings.partsTray(visibility)
  readonly property int total: {
    var n = 0
    for (var i = 0; i < groups.length; i++) n += groups[i].sorts.length
    return n
  }
  readonly property int aside: (style.hidden || []).length

  function matches(sort) {
    var q = String(query).trim().toLowerCase()
    return !q || (sort.name + " " + sort.part + " " + sort.detail + " " + sort.glyph).toLowerCase().indexOf(q) >= 0
  }

  width: parent ? parent.width : 0
  spacing: 0
  topPadding: Type.px(22)

  Galley {
    width: parent.width
    height: implicitHeight
    marks: false
    label: "YOUR BAR · AS IT STANDS"
    style: root.style
    barData: root.barData
    compact: root.compact
  }

  Item { width: 1; height: Type.px(14) }
  Row {
    spacing: Type.px(10)
    Text {
      text: (root.total - root.aside) + " OF " + root.total + " ON THE BAR"
      color: Ink.ink
      font.family: Type.mono
      font.pixelSize: Type.tag
      font.letterSpacing: Type.trackLabel
    }
    Text {
      visible: root.aside > 0
      text: "·  " + root.aside + " SET ASIDE"
      color: Ink.inkMuted
      font.family: Type.mono
      font.pixelSize: Type.tag
      font.letterSpacing: Type.trackLabel
    }
  }

  // ------------------------------------------------------------ the case
  Repeater {
    model: root.groups
    Column {
      id: group
      required property var modelData
      readonly property var sorts: modelData.sorts.filter(function(s) { return root.matches(s) })
      visible: sorts.length > 0
      width: root.width
      topPadding: Type.px(24)
      spacing: Type.px(10)

      SectionLabel { jp: group.modelData.jp; text: group.modelData.title }

      Flow {
        id: flow
        width: parent.width
        spacing: Type.px(8)
        // Crops are wide, stamps narrow; both fill the row evenly.
        readonly property real unit: (width - 5 * spacing) / 6
        Repeater {
          model: group.sorts
          Rectangle {
            id: sortTile
            required property var modelData
            readonly property bool shown: S.shows(root.style, modelData.part)
            readonly property bool wide: modelData.kind === "crop"
            width: Math.floor(wide ? 2 * flow.unit + flow.spacing : flow.unit)
            height: Type.px(104)
            radius: 3
            color: hover.containsMouse ? Ink.lineSoft : "transparent"
            border.width: shown ? 1 : 0
            border.color: hover.containsMouse ? Ink.lineStrong : Ink.line

            // Set aside: a dashed outline, the sort itself faint.
            Canvas {
              id: dashes
              visible: !sortTile.shown
              anchors.fill: parent
              onPaint: {
                var c = getContext("2d")
                c.reset()
                c.strokeStyle = Ink.lineStrong
                c.lineWidth = 1
                c.setLineDash([3, 3])
                c.strokeRect(0.5, 0.5, width - 1, height - 1)
              }
              onWidthChanged: requestPaint()
              onVisibleChanged: requestPaint()
            }

            Item {
              id: stage
              x: 1
              y: 1
              width: parent.width - 2
              height: Type.px(60)
              opacity: sortTile.shown ? 1 : 0.28

              BarCrop {
                id: crop
                visible: sortTile.modelData.kind === "crop"
                anchors.fill: parent
                style: root.style
                barData: root.barData
                part: sortTile.modelData.part
              }
              Text {
                visible: crop.visible && crop.empty
                anchors.centerIn: parent
                text: "— not drawn here now —"
                color: Ink.inkFaint
                font.family: Type.mono
                font.pixelSize: Type.tag
                font.letterSpacing: 1
              }
              // An indicator's stamp, as the bar presses it.
              Rectangle {
                visible: sortTile.modelData.kind === "stamp"
                anchors.centerIn: parent
                width: Type.px(30)
                height: width
                radius: 2
                rotation: -3
                color: "transparent"
                border.width: 1
                border.color: Ink.seal
                Text {
                  anchors.centerIn: parent
                  text: sortTile.modelData.glyph
                  color: Ink.seal
                  font.family: Type.jp
                  font.pixelSize: Type.px(17)
                }
              }
              // A tray app's icon, or its letter.
              Image {
                id: trayIcon
                visible: sortTile.modelData.kind === "tray" && status === Image.Ready
                anchors.centerIn: parent
                width: Type.px(22)
                height: width
                sourceSize: Qt.size(width * 2, height * 2)
                source: sortTile.modelData.kind === "tray" ? sortTile.modelData.icon : ""
              }
              Text {
                visible: (sortTile.modelData.kind === "tray" && !trayIcon.visible) || sortTile.modelData.kind === "text"
                anchors.centerIn: parent
                text: sortTile.modelData.kind === "tray" ? sortTile.modelData.letter : sortTile.modelData.glyph
                color: Ink.ink
                font.family: /[　-鿿]/.test(text) ? Type.jp : Type.display
                font.pixelSize: Type.px(26)
              }
            }

            Rectangle { x: 1; y: stage.height + 1; width: parent.width - 2; height: 1; color: Ink.lineSoft; visible: sortTile.shown }
            Column {
              x: Type.px(10)
              y: stage.height + Type.px(8)
              width: parent.width - 2 * x
              spacing: Type.px(1)
              Item {
                width: parent.width
                height: sortName.height
                Text {
                  id: sortName
                  width: parent.width - asideTag.width - Type.px(6)
                  elide: Text.ElideRight
                  text: sortTile.modelData.name
                  color: sortTile.shown ? Ink.ink : Ink.inkMuted
                  font.family: Type.text
                  font.pixelSize: Type.px(13)
                  font.strikeout: !sortTile.shown
                }
                Text {
                  id: asideTag
                  anchors.right: parent.right
                  anchors.verticalCenter: sortName.verticalCenter
                  text: hover.containsMouse ? (sortTile.shown ? "SET ASIDE" : "PUT BACK") : sortTile.shown ? "" : "ASIDE"
                  color: hover.containsMouse ? Ink.ink : Ink.inkMuted
                  font.family: Type.mono
                  font.pixelSize: Type.tag
                  font.letterSpacing: 1
                }
              }
              Text {
                width: parent.width
                elide: Text.ElideRight
                text: sortTile.modelData.detail
                color: Ink.inkFaint
                font.family: Type.text
                font.pixelSize: Type.note
              }
            }

            MouseArea {
              id: hover
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              readonly property bool keyStop: enabled
              function keyPress() { root.settingPicked("show:" + sortTile.modelData.part, sortTile.shown ? "hidden" : "shown") }
              onClicked: root.settingPicked("show:" + sortTile.modelData.part, sortTile.shown ? "hidden" : "shown")
            }
          }
        }
      }
    }
  }

  Item { width: 1; height: Type.px(18) }
  Text {
    width: Math.min(parent.width, Type.px(820))
    wrapMode: Text.Wrap
    text: "Setting a part aside takes it off this bar only; an Omarchy widget stays in Omarchy's own bar layout, where it is added or removed."
    color: Ink.inkMuted
    font.family: Type.text
    font.pixelSize: Type.note
  }
}
