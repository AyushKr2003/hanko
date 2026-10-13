pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Style.js" as S
import "../../core/Settings.js" as Settings

// Settings › Screens 画面 (docs/settings-kosei): your monitors drawn to
// scale where Hyprland places them, each with the bar it carries (a strip
// along its edge, or Inkan's seal in its corner). Pick one: what it sets
// for itself, then every setting as that screen has it, a click away;
// picking what the other screens get drops the override. style.json at the
// foot, as it is on disk. (This was the Advanced switch.)
Column {
  id: root

  property var draft: S.normalize({})
  // [{ name, x, y, width, height }] (Quickshell.screens).
  property var screens: []
  property string monitor: ""
  property bool compact: false

  signal monitorPicked(string monitor, string key, string value)
  signal monitorCleared(string name)
  signal monitorSelected(string name)

  readonly property string shown: {
    for (var i = 0; i < screens.length; i++) if (screens[i].name === monitor) return monitor
    return screens.length ? screens[0].name : ""
  }
  readonly property var shownScreen: {
    for (var i = 0; i < screens.length; i++) if (screens[i].name === shown) return screens[i]
    return null
  }
  readonly property var shownStyle: S.resolve(draft, shown)
  readonly property var generalStyle: S.resolve(draft)
  readonly property var own: Object.keys(draft.monitors[shown] || {})
  // The open row (a setting key), one at a time.
  property string openKey: ""

  width: parent ? parent.width : 0
  spacing: 0
  topPadding: Type.px(22)

  // ------------------------------------------------------- the arrangement
  Rectangle {
    id: plate
    width: parent.width
    height: Type.px(root.compact ? 200 : 250)
    radius: 3
    color: "transparent"
    border.width: 1
    border.color: Ink.line

    readonly property var bounds: {
      var x0 = 1e9, y0 = 1e9, x1 = -1e9, y1 = -1e9
      for (var i = 0; i < root.screens.length; i++) {
        var s = root.screens[i]
        x0 = Math.min(x0, s.x); y0 = Math.min(y0, s.y)
        x1 = Math.max(x1, s.x + s.width); y1 = Math.max(y1, s.y + s.height)
      }
      return root.screens.length ? { x: x0, y: y0, w: x1 - x0, h: y1 - y0 } : { x: 0, y: 0, w: 1, h: 1 }
    }
    readonly property real pad: Type.px(28)
    readonly property real k: Math.min((width - 2 * pad) / bounds.w, (height - 2 * pad - Type.px(14)) / bounds.h)
    readonly property real ox: (width - bounds.w * k) / 2
    readonly property real oy: (height - Type.px(14) - bounds.h * k) / 2

    Repeater {
      model: root.screens
      Rectangle {
        id: scr
        required property var modelData
        readonly property bool on: modelData.name === root.shown
        readonly property var st: S.resolve(root.draft, modelData.name)
        readonly property int owns: Object.keys(root.draft.monitors[modelData.name] || {}).length
        x: plate.ox + (modelData.x - plate.bounds.x) * plate.k
        y: plate.oy + (modelData.y - plate.bounds.y) * plate.k
        width: modelData.width * plate.k - Type.px(6)
        height: modelData.height * plate.k - Type.px(6)
        radius: 3
        color: scrHover.containsMouse && !on ? Ink.lineSoft : "transparent"
        border.width: on ? 2 : 1
        border.color: on ? Ink.ink : Ink.lineStrong

        // The bar this screen carries.
        Rectangle {
          visible: scr.st.form !== "inkan"
          x: scr.st.float === "inset" ? Type.px(5) : 2
          width: parent.width - 2 * x
          height: Math.max(Type.px(5), scr.st.height * plate.k * 2.2)
          y: scr.st.position === "bottom" ? parent.height - height - (scr.st.float === "inset" ? Type.px(5) : 2) : (scr.st.float === "inset" ? Type.px(5) : 2)
          radius: scr.st.float === "inset" ? 2 : 0
          color: Ink.alpha(Ink.ink, 0.13)
          Rectangle { x: Type.px(3); anchors.verticalCenter: parent.verticalCenter; width: Math.max(Type.px(3), parent.height - Type.px(3)); height: width; color: Ink.seal; visible: scr.st.seal !== "none" }
        }
        Rectangle {
          visible: scr.st.form === "inkan"
          readonly property string at: String(scr.st.inkanAt)
          width: Type.px(14)
          height: width
          radius: 2
          color: Ink.seal
          x: at.indexOf("left") > 0 ? Type.px(7) : parent.width - width - Type.px(7)
          y: at.indexOf("top") === 0 ? Type.px(7) : parent.height - height - Type.px(7)
        }

        Column {
          anchors.centerIn: parent
          spacing: Type.px(2)
          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: scr.modelData.name
            color: scr.on ? Ink.ink : Ink.inkDim
            font.family: Type.mono
            font.pixelSize: Type.px(11)
            font.letterSpacing: Type.px(1)
          }
          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: scr.modelData.width + " × " + scr.modelData.height
            color: Ink.inkMuted
            font.family: Type.text
            font.pixelSize: Type.note
          }
          Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Type.px(5)
            visible: scr.owns > 0
            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: Type.px(4); height: width; radius: width / 2; color: Ink.seal }
            Text { text: scr.owns + " OWN"; color: Ink.inkDim; font.family: Type.mono; font.pixelSize: Type.tag; font.letterSpacing: Type.trackLabel }
          }
        }
        MouseArea {
          id: scrHover
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.monitorSelected(scr.modelData.name)
        }
      }
    }
    Text {
      anchors.left: parent.left
      anchors.leftMargin: Type.px(14)
      anchors.bottom: parent.bottom
      anchors.bottomMargin: Type.px(10)
      text: "画面  DRAWN TO SCALE, WHERE HYPRLAND PLACES THEM  ·  CLICK ONE"
      color: Ink.inkFaint
      font.family: Type.mono
      font.pixelSize: Type.tag
      font.letterSpacing: Type.trackLabel
    }
  }

  Item { width: 1; height: Type.px(26) }

  // ------------------------------------------------------- the one picked
  Item {
    width: parent.width
    height: Math.max(screenName.height, clearRow.height)
    Row {
      id: screenName
      spacing: Type.px(12)
      Text {
        id: nameText
        text: root.shown || "No screen"
        color: Ink.ink
        font.family: Type.display
        font.pixelSize: Type.px(28)
        font.weight: Font.Normal
        font.variableAxes: Type.axes(Type.px(28))
      }
      Text {
        anchors.baseline: nameText.baseline
        text: root.shownScreen ? root.shownScreen.width + " × " + root.shownScreen.height : ""
        color: Ink.inkMuted
        font.family: Type.text
        font.pixelSize: Type.row
      }
    }
    Row {
      id: clearRow
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      spacing: Type.px(12)
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.own.length ? root.own.length + (root.own.length === 1 ? " SETTING OF ITS OWN" : " SETTINGS OF ITS OWN") : "FOLLOWS TYPESETTING"
        color: root.own.length ? Ink.ink : Ink.inkMuted
        font.family: Type.mono
        font.pixelSize: Type.tag
        font.letterSpacing: Type.trackLabel
      }
      SmallButton {
        visible: root.own.length > 0
        label: "Clear"
        onClicked: root.monitorCleared(root.shown)
      }
    }
  }

  Item { width: 1; height: Type.px(8) }
  Text {
    width: Math.min(parent.width, Type.px(720))
    wrapMode: Text.Wrap
    text: "Every setting below reads as this screen has it. Change one and only this screen changes; set it back to what the others have and the override goes. A red tick marks what this screen sets for itself."
    color: Ink.inkMuted
    font.family: Type.text
    font.pixelSize: Type.row
  }
  Item { width: 1; height: Type.px(18) }

  // ------------------------------------------------- every setting, by part
  // Settings that a monitor can carry (Style.js KEYS), grouped by the
  // proof's parts; each row reads "name ……… value", and opens to its choices.
  Grid {
    id: groups
    width: parent.width
    columns: width >= Type.px(860) ? 2 : 1
    columnSpacing: Type.px(28)
    rowSpacing: Type.px(18)
    readonly property real cellWidth: (width - (columns - 1) * columnSpacing) / columns

    Repeater {
      model: Settings.PROOF
      Column {
        id: group
        required property var modelData
        readonly property var keys: modelData.cast.concat(modelData.also).filter(function(k) { return S.KEYS.indexOf(k) >= 0 })
        visible: keys.length > 0
        width: groups.cellWidth
        spacing: 0

        SectionLabel { text: group.modelData.no + "  " + group.modelData.name; jp: group.modelData.jp }
        Item { width: 1; height: Type.px(4) }

        Repeater {
          model: group.keys
          Column {
            id: row
            required property string modelData
            readonly property bool own: root.own.indexOf(modelData) >= 0
            readonly property bool open: root.openKey === modelData
            width: group.width

            Item {
              width: parent.width
              height: Type.px(32)
              Rectangle {
                visible: row.own
                anchors.verticalCenter: parent.verticalCenter
                width: 2
                height: Type.px(14)
                color: Ink.seal
              }
              Text {
                id: rowName
                x: Type.px(10)
                anchors.verticalCenter: parent.verticalCenter
                text: Settings.nameOf(row.modelData)
                color: row.own ? Ink.ink : Ink.inkDim
                font.family: Type.text
                font.pixelSize: Type.px(13)
              }
              // Leader dots to the value.
              Rectangle {
                x: rowName.x + rowName.width + Type.px(8)
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: Type.px(4)
                width: Math.max(0, rowValue.x - x - Type.px(8))
                height: 1
                color: Ink.lineSoft
              }
              Text {
                id: rowValue
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: String(root.shownStyle[row.modelData]) + (row.open ? "  ▴" : "  ▾")
                color: row.own ? Ink.ink : Ink.inkMuted
                font.family: Type.mono
                font.pixelSize: Type.px(11)
                font.letterSpacing: 1
              }
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.openKey = row.open ? "" : row.modelData
              }
            }
            Item {
              visible: row.open
              width: parent.width
              height: visible ? seg.height + Type.px(12) : 0
              Segmented {
                id: seg
                anchors.right: parent.right
                options: Settings.optionsFor(row.modelData, S.OPTIONS)
                selected: String(root.shownStyle[row.modelData])
                onPicked: function(value) { root.monitorPicked(root.shown, row.modelData, value) }
              }
              Text {
                anchors.left: parent.left
                anchors.leftMargin: Type.px(10)
                anchors.verticalCenter: seg.verticalCenter
                visible: seg.x > width + Type.px(24)
                text: "others: " + String(root.generalStyle[row.modelData])
                color: Ink.inkFaint
                font.family: Type.mono
                font.pixelSize: Type.tag
                font.letterSpacing: 1
              }
            }
            Rectangle { width: parent.width; height: 1; color: Ink.lineSoft }
          }
        }
      }
    }
  }

  Item { width: 1; height: Type.px(30) }

  // ------------------------------------------------------------ style.json
  SectionLabel { text: "style.json · ~/.config/hanko/style.json"; jp: "控" }
  Item { width: 1; height: Type.px(10) }
  Rectangle {
    width: parent.width
    height: json.height + 2 * Type.px(14)
    radius: 3
    color: "transparent"
    border.width: 1
    border.color: Ink.line
    Text {
      id: json
      x: Type.px(16)
      y: Type.px(14)
      width: parent.width - 2 * x
      text: JSON.stringify(root.draft, null, 2)
      color: Ink.inkMuted
      wrapMode: Text.WrapAnywhere
      font.family: Type.mono
      font.pixelSize: Type.px(11)
      lineHeight: 1.1
    }
  }
  Item { width: 1; height: Type.px(8) }
  Text {
    width: parent.width
    wrapMode: Text.Wrap
    text: "The same from a terminal: hanko style set --monitor " + (root.shown || "NAME") + " height 32"
    color: Ink.inkFaint
    font.family: Type.mono
    font.pixelSize: Type.px(11)
  }
}
