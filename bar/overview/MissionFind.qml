pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Mission.js" as M

// The mission overview's search: the field (探 FIND, the query in Space
// Grotesk, an ink caret) and, while there is a query, the results set
// like a sheet's rows under a `──` head per kind (算 sum, 窓 windows,
// 具 apps, 品書 the Omarchy menu), the chosen one on a bone plate with a
// `//` lead. Text arrives through OverviewWindow's keys; this only draws
// it. Pure.
Item {
  id: root

  property string query: ""
  property var results: []
  property int index: 0
  property bool showResults: query.length > 0
  // How tall the results may grow.
  property real roomH: Type.px(400)
  readonly property real fieldH: Type.px(40)
  readonly property real rowH: Type.px(44)
  readonly property real headH: Type.px(28)

  signal picked(var result)
  signal hovered(int index)

  function showsHead(i) { return i === 0 || (results[i - 1] || {}).category !== (results[i] || {}).category }
  readonly property real listH: {
    var h = 0
    for (var i = 0; i < results.length; i++) h += rowH + (showsHead(i) ? headH : 0)
    return h
  }

  implicitHeight: fieldH

  // ---------------------------------------------- the field
  Rectangle {
    id: field
    width: parent.width
    height: root.fieldH
    color: Ink.paper
    border.width: 1
    border.color: root.query.length > 0 ? Ink.ink : Ink.line

    Row {
      id: lead
      x: Type.px(14)
      anchors.verticalCenter: parent.verticalCenter
      spacing: Type.px(7)
      Text { anchors.verticalCenter: parent.verticalCenter; text: "探"; color: Ink.inkMuted; font.family: Type.jp; font.pixelSize: Type.glossMid }
      Text { anchors.verticalCenter: parent.verticalCenter; text: "FIND"; color: Ink.inkFaint; font.family: Type.mono; font.pixelSize: Type.tag; font.letterSpacing: Type.trackEyebrow }
    }
    Rectangle { x: lead.x + lead.width + Type.px(12); anchors.verticalCenter: parent.verticalCenter; width: 1; height: parent.height - Type.px(16); color: Ink.line }

    Item {
      x: lead.x + lead.width + Type.px(26)
      width: parent.width - x - Type.px(14)
      height: parent.height
      clip: true
      Text {
        id: typed
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(implicitWidth, parent.width - Type.px(4))
        elide: Text.ElideLeft
        text: root.query.length > 0 ? root.query : "Type to find a window, an app, an action, a sum"
        color: root.query.length > 0 ? Ink.ink : Ink.inkFaint
        font.family: Type.text
        font.pixelSize: Type.row
      }
      Rectangle {
        id: caret
        visible: root.query.length > 0
        x: typed.width + 1
        anchors.verticalCenter: parent.verticalCenter
        width: 1
        height: typed.implicitHeight
        color: Ink.ink
        SequentialAnimation on opacity {
          running: caret.visible && !Motion.still
          loops: Animation.Infinite
          NumberAnimation { to: 0; duration: 530 }
          NumberAnimation { to: 1; duration: 530 }
        }
      }
    }
  }

  // ---------------------------------------------- the results
  Rectangle {
    id: panel
    visible: root.showResults
    y: field.height + Type.px(10)
    width: parent.width
    height: Math.min(root.roomH - y, root.results.length > 0 ? root.listH + Type.px(16) : Type.px(84))
    color: Ink.paper
    border.width: 1
    border.color: Ink.line
    clip: true

    Text {
      visible: root.results.length === 0
      anchors.centerIn: parent
      text: "Nothing by that name"
      color: Ink.inkFaint
      font.family: Type.display
      font.italic: true
      font.pixelSize: Type.px(18)
      font.variableAxes: Type.axes(Type.px(18))
    }

    ListView {
      id: list
      anchors.fill: parent
      anchors.margins: Type.px(8)
      model: root.results.length
      currentIndex: root.index
      boundsBehavior: Flickable.StopAtBounds
      interactive: contentHeight > height
      onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

      delegate: Item {
        id: row
        required property int index
        readonly property var r: root.results[row.index] || ({ title: "", subtitle: "", category: "" })
        readonly property bool head: root.showsHead(row.index)
        readonly property bool on: row.index === root.index
        readonly property var cat: M.CATEGORIES[row.r.category] || ({ jp: "", name: "" })
        width: list.width
        height: root.rowH + (row.head ? root.headH : 0)

        Row {
          visible: row.head
          x: Type.px(8)
          height: root.headH
          spacing: Type.px(8)
          Rectangle { anchors.verticalCenter: parent.verticalCenter; width: Type.px(14); height: 1; color: Ink.ink }
          Text { anchors.verticalCenter: parent.verticalCenter; text: row.cat.jp; color: Ink.inkDim; font.family: Type.jp; font.pixelSize: Type.label }
          Text { anchors.verticalCenter: parent.verticalCenter; text: "·"; color: Ink.inkFaint; font.family: Type.text; font.pixelSize: Type.label }
          Text { anchors.verticalCenter: parent.verticalCenter; text: row.cat.name; color: Ink.inkMuted; font.family: Type.mono; font.pixelSize: Type.eyebrow; font.letterSpacing: Type.trackEyebrow }
        }

        Rectangle {
          y: row.head ? root.headH : 0
          width: parent.width
          height: root.rowH
          color: row.on ? Ink.bone : rowArea.containsMouse ? Ink.alpha(Ink.ink, 0.05) : "transparent"

          Text {
            id: lead2
            x: Type.px(12)
            anchors.verticalCenter: parent.verticalCenter
            text: row.on ? "//" : String(row.index + 1).padStart(2, "0")
            color: row.on ? Ink.boneInk : Ink.inkFaint
            opacity: row.on ? 0.55 : 1
            font.family: Type.mono
            font.pixelSize: Type.tag
            font.letterSpacing: Type.trackFigure
          }
          Column {
            anchors.left: parent.left
            anchors.leftMargin: Type.px(44)
            anchors.right: parent.right
            anchors.rightMargin: Type.px(12)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Type.px(2)
            Text {
              width: parent.width
              elide: Text.ElideRight
              text: row.r.title
              color: row.on ? Ink.boneInk : Ink.ink
              font.family: row.r.kind === "calc" ? Type.display : Type.text
              font.pixelSize: Type.row
              font.weight: Type.valueWeight
            }
            Text {
              width: parent.width
              visible: text !== ""
              elide: Text.ElideMiddle
              text: String(row.r.subtitle || "").toUpperCase()
              color: row.on ? Ink.boneInk : Ink.inkMuted
              opacity: row.on ? 0.7 : 1
              font.family: Type.mono
              font.pixelSize: Type.tag
              font.letterSpacing: Type.trackTag
            }
          }
          MouseArea {
            id: rowArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: root.hovered(row.index)
            onClicked: root.picked(row.r)
          }
        }
      }
    }
  }
}
