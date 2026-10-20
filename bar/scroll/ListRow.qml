import QtQuick
import "../../core"

// A list row in the scroll (fresh, not the sheets' rows): a mono index, a
// name (with an optional line under it), a mono note on the right, and a
// bone plate when it is the one in use. `leading` takes a stamp; `trailing`
// signal bars.
Item {
  id: root

  property int position: 0
  property string name: ""
  property string detail: ""
  property string note: ""
  // Ages and values with units keep their own case.
  property bool upperNote: true
  property bool on: false
  property bool interactive: false
  // Draw the hairline above this row (not next to a plate).
  property bool ruled: false
  property int rowHeight: Type.px(detail ? 52 : 40)
  property Component leading: null
  property Component trailing: null
  // letters: sealed (aburidashi 炙出): the detail is written in secret ink,
  // a faint impression, until the pointer rests on the row and warms it;
  // the words darken outward from the pointer and fade a few seconds after
  // it leaves. `warmed` (0..1) fixes the warmth, for the harness.
  property bool sealed: false
  property real warmed: -1
  readonly property real warmth: warmed >= 0 ? warmed : heat
  property real heat: 0
  property real warmX: Type.px(160)

  signal clicked()

  width: parent ? parent.width : 0
  height: rowHeight

  Rectangle {
    anchors.fill: parent
    radius: 3
    color: root.on ? Ink.bone : hover.containsMouse && root.interactive ? Ink.lineSoft : "transparent"
  }
  Rectangle {
    visible: root.ruled && !root.on
    width: parent.width
    height: 1
    color: Ink.lineSoft
  }

  Row {
    id: textRow
    anchors.left: parent.left
    anchors.leftMargin: Type.px(10)
    anchors.verticalCenter: parent.verticalCenter
    spacing: Type.px(12)

    Text {
      visible: !root.leading
      width: Type.px(16)
      anchors.verticalCenter: parent.verticalCenter
      text: (root.position < 9 ? "0" : "") + (root.position + 1)
      color: root.on ? Ink.boneInk : Ink.inkMuted
      font.family: Type.mono
      font.pixelSize: Type.label
      font.letterSpacing: 1
    }
    Loader {
      active: !!root.leading
      visible: active
      anchors.verticalCenter: parent.verticalCenter
      sourceComponent: root.leading
    }
    Column {
      id: textColumn
      anchors.verticalCenter: parent.verticalCenter
      spacing: Type.px(2)
      Text {
        text: root.name
        color: root.on ? Ink.boneInk : Ink.ink
        font.family: Type.text
        font.pixelSize: Type.row
      }
      Item {
        visible: root.detail !== ""
        width: detailText.implicitWidth
        height: detailText.implicitHeight
        Text {
          id: detailText
          text: root.detail
          color: root.on ? Ink.boneInk : Ink.inkMuted
          opacity: root.sealed ? 0.09 : 1
          font.family: Type.text
          font.pixelSize: Type.note
        }
        // Sealed: the warmed part, the same words in full ink, uncovered
        // from the pointer outward.
        Item {
          id: warmPart
          visible: root.sealed && root.warmth > 0
          readonly property real reach: root.warmth * (detailText.width + Type.px(80))
          readonly property real centre: root.warmX - textRow.x - textColumn.x
          x: Math.max(0, centre - reach / 2)
          width: Math.max(0, Math.min(detailText.width, centre + reach / 2) - x)
          height: detailText.height
          clip: true
          Text {
            x: -warmPart.x
            text: root.detail
            color: root.on ? Ink.boneInk : Ink.ink
            font: detailText.font
          }
        }
      }
    }
  }

  Row {
    anchors.right: parent.right
    anchors.rightMargin: Type.px(10)
    anchors.verticalCenter: parent.verticalCenter
    spacing: Type.px(8)
    Text {
      anchors.verticalCenter: parent.verticalCenter
      visible: text !== ""
      text: root.upperNote ? root.note.toUpperCase() : root.note
      color: root.on ? Ink.boneInk : Ink.inkMuted
      font.family: Type.mono
      font.pixelSize: Type.label
      font.weight: Type.labelWeight
      font.letterSpacing: Type.trackLabel
    }
    Loader {
      active: !!root.trailing
      visible: active
      anchors.verticalCenter: parent.verticalCenter
      sourceComponent: root.trailing
    }
  }

  MouseArea {
    id: hover
    anchors.fill: parent
    enabled: root.interactive || root.sealed
    hoverEnabled: true
    cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
    onClicked: if (root.interactive) root.clicked()
    onPositionChanged: function(mouse) { if (root.heat < 0.05) root.warmX = mouse.x }
    onContainsMouseChanged: {
      if (!root.sealed) return
      if (containsMouse) { cool.stop(); root.heat = 1 }
      else cool.restart()
    }
  }
  // It cools a few seconds after the pointer leaves.
  Timer { id: cool; interval: 2500; onTriggered: root.heat = 0 }
  Behavior on heat {
    enabled: !Motion.still
    NumberAnimation { duration: 700; easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.inkCurve }
  }
}
