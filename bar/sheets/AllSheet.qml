pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Spaces.js" as SpacesJs
import "../../core/Title.js" as TitleJs

// No. 00 鑑, every sheet on one (Inkan 印, docs/shell-concepts/inkan): what
// a press on the seal prints. The time and the date; the workspaces with the
// window you are in; now playing; then a row for each sheet with its
// reading (core/Inkan.js rows()), red where it needs you. A row opens that
// sheet in its own hand where this one was; the clock opens Time, a numeral
// goes to that workspace. Keys: the cursor (SheetView) walks the clock, the
// numerals, the song, the rows and the links; Enter opens, 1–9 go
// to a workspace, P plays or pauses. Always the ledger hand.
Item {
  id: root

  property date now: new Date()
  property string timeFormat: "HH:mm"
  property string glyph: "鑑"
  // core/Inkan.js rows(): [{ key, jp, name, value, red }]
  property var rows: []
  // Spaces.list() entries for this screen, the active window
  // ({ cls, title }) and $HOME, and now playing ({ title, artist,
  // progress, playing }) or null.
  property var spaces: []
  property var window: null
  property string home: ""
  property var media: null

  // what: open (sheet key) | workspace (id) | media (playPause) | menu | settings
  signal request(string what, var arg)

  width: parent ? parent.width : 0
  implicitHeight: column.y + column.implicitHeight
  focus: true

  readonly property var title: window ? TitleJs.describe(window.cls, window.title) : null
  Keys.onPressed: function(event) {
    if (event.text === "p" && media) { request("media", "playPause"); event.accepted = true; return }
    var n = parseInt(event.text, 10)
    if (n >= 1 && n <= 9) { request("workspace", n); event.accepted = true }
  }

  Column {
    id: column
    x: Type.px(24)
    y: Type.px(22)
    width: root.width - 2 * x

    SheetHead {
      sheet: "all"
      jp: root.glyph
      label: "Hanko · all sheets"
      compact: true
    }

    Item { width: 1; height: Type.px(16) }

    // The time, large, then the date in italic: a click opens Time.
    Item {
      width: clockRow.width
      height: clockRow.height
      readonly property bool keyStop: true
      function keyPress() { root.request("open", "time") }
      Row {
        id: clockRow
        spacing: Type.px(14)
        Text {
          id: time
          text: Qt.formatTime(root.now, root.timeFormat).replace(/ ?(AM|PM)$/i, "")
          color: Ink.ink
          font.family: Type.display
          font.pixelSize: Type.px(52)
          font.weight: Font.Normal
          font.variableAxes: Type.axes(Type.px(52))
          font.features: ({ "tnum": 1 })
          lineHeight: 1
        }
        Text {
          anchors.baseline: time.baseline
          text: (/AM|PM/i.test(Qt.formatTime(root.now, root.timeFormat)) ? Qt.formatTime(root.now, "AP") + " · " : "")
            + Qt.formatDate(root.now, "dddd, d MMMM")
          color: Ink.inkDim
          font.family: Type.display
          font.italic: true
          font.pixelSize: Type.px(18)
          font.weight: Font.Normal
          font.variableAxes: Type.axes(Type.px(18), 360)
        }
      }
      MouseArea {
        width: clockRow.width
        height: clockRow.height
        cursorShape: Qt.PointingHandCursor
        onClicked: root.request("open", "time")
      }
    }

    Item { width: 1; height: Type.px(16) }
    Rectangle { width: parent.width; height: 1; color: Ink.lineSoft }

    // The workspaces as numerals, and the window you are in.
    Item {
      width: parent.width
      height: Type.px(46)

      Row {
        id: pages
        anchors.verticalCenter: parent.verticalCenter
        spacing: Type.px(6)
        Repeater {
          model: root.spaces
          Item {
            id: page
            required property var modelData
            readonly property bool keyStop: true
            readonly property bool keyChosen: !!modelData.active
            function keyPress() { root.request("workspace", page.modelData.id) }
            width: Type.px(24)
            height: Type.px(24)
            Rectangle {
              anchors.fill: parent
              radius: 2
              color: page.modelData.active ? Ink.bone : hit.containsMouse ? Ink.alpha(Ink.bone, 0.08) : "transparent"
            }
            Text {
              anchors.centerIn: parent
              text: SpacesJs.numeral(page.modelData.id)
              color: page.modelData.active ? Ink.boneInk : Ink.inkDim
              font.family: Type.jp
              font.pixelSize: Type.px(15)
            }
            Rectangle {
              visible: page.modelData.urgent || (page.modelData.windows || []).length > 0
              anchors.horizontalCenter: parent.horizontalCenter
              anchors.top: parent.bottom
              anchors.topMargin: Type.px(2)
              width: Type.px(3)
              height: width
              radius: width / 2
              color: page.modelData.urgent ? Ink.seal : Ink.inkMuted
            }
            MouseArea {
              id: hit
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.request("workspace", page.modelData.id)
            }
          }
        }
      }
      Rectangle {
        id: rule
        visible: root.title !== null
        x: pages.width + Type.px(12)
        anchors.verticalCenter: parent.verticalCenter
        width: 1
        height: Type.px(20)
        color: Ink.lineSoft
      }
      Row {
        visible: root.title !== null
        x: rule.x + Type.px(14)
        width: parent.width - x
        anchors.verticalCenter: parent.verticalCenter
        spacing: Type.px(7)
        clip: true
        Text {
          id: app
          anchors.baseline: head.baseline
          text: root.title ? (root.title.app || root.title.head) : ""
          color: Ink.ink
          font.family: Type.display
          font.italic: true
          font.pixelSize: Type.byline
          font.weight: Font.Normal
          font.variableAxes: Type.axes(Type.byline)
        }
        Text {
          id: head
          width: Math.max(0, parent.width - app.width - parent.spacing)
          elide: Text.ElideRight
          text: !root.title || !root.title.app ? "" : [root.title.leaf || root.title.head, root.title.dir].filter(function(x) { return !!x }).join(" · ")
          color: Ink.inkDim
          font.family: Type.text
          font.pixelSize: Type.px(12.5)
        }
      }
    }

    // Now playing: a click plays or pauses.
    Item {
      visible: root.media !== null
      width: parent.width
      readonly property bool keyStop: true
      function keyPress() { root.request("media", "playPause") }
      height: visible ? Type.px(28) : 0
      Row {
        anchors.top: parent.top
        spacing: Type.px(10)
        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: "曲"
          color: Ink.inkMuted
          font.family: Type.jp
          font.pixelSize: Type.glossMid
        }
        Text {
          anchors.verticalCenter: parent.verticalCenter
          width: Math.min(implicitWidth, column.width - Type.px(120))
          elide: Text.ElideRight
          text: root.media ? root.media.title + (root.media.artist ? "  · " + root.media.artist : "") : ""
          color: root.media && root.media.playing ? Ink.inkDim : Ink.inkMuted
          font.family: Type.text
          font.pixelSize: Type.px(13)
        }
        Rectangle {
          anchors.verticalCenter: parent.verticalCenter
          width: Type.px(60)
          height: 1
          color: Ink.line
          Rectangle {
            y: -0.5
            width: parent.width * (root.media ? root.media.progress : 0)
            height: 2
            color: Ink.ink
          }
        }
      }
      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.request("media", "playPause")
      }
    }

    Rectangle { width: parent.width; height: 1; color: Ink.lineSoft }

    // A row per sheet: its kanji, its name, its reading.
    Repeater {
      model: root.rows
      Item {
        id: row
        required property var modelData
        required property int index
        readonly property bool hot: rowHit.containsMouse
        readonly property bool keyStop: true
        function keyPress() { root.request("open", row.modelData.key) }
        width: column.width
        height: Type.px(48)

        Rectangle {
          anchors.fill: parent
          radius: 2
          color: row.hot ? Ink.alpha(Ink.bone, 0.06) : "transparent"
        }
        Rectangle {
          anchors.verticalCenter: parent.verticalCenter
          width: 2
          height: row.hot ? parent.height - Type.px(16) : 0
          color: Ink.ink
          Behavior on height { enabled: !Motion.still; NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        }
        Rectangle {
          anchors.bottom: parent.bottom
          width: parent.width
          height: 1
          color: Ink.lineSoft
        }
        Text {
          id: mark
          x: Type.px(4)
          width: Type.px(20)
          anchors.verticalCenter: parent.verticalCenter
          horizontalAlignment: Text.AlignHCenter
          text: row.modelData.jp
          color: row.modelData.red ? Ink.seal : Ink.inkDim
          font.family: Type.jp
          font.pixelSize: Type.px(17)
        }
        Text {
          x: mark.x + mark.width + Type.px(14)
          anchors.verticalCenter: parent.verticalCenter
          text: row.modelData.name
          color: Ink.ink
          font.family: Type.text
          font.pixelSize: Type.row
        }
        Text {
          anchors.right: parent.right
          anchors.rightMargin: Type.px(2)
          anchors.verticalCenter: parent.verticalCenter
          width: Math.min(implicitWidth, column.width * 0.6)
          horizontalAlignment: Text.AlignRight
          elide: Text.ElideLeft
          text: String(row.modelData.value).toUpperCase() + (row.hot ? "  ›" : "")
          color: row.modelData.red ? Ink.seal : row.hot ? Ink.inkDim : Ink.inkMuted
          font.family: Type.mono
          font.pixelSize: Type.label
          font.weight: Type.labelWeight
          font.letterSpacing: Type.trackLabel
        }
        MouseArea {
          id: rowHit
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.request("open", row.modelData.key)
        }
      }
    }

    // The foot: the keys, then Omarchy's menu and Hanko's settings.
    Item {
      width: parent.width
      height: Type.px(46)
      Text {
        anchors.verticalCenter: parent.verticalCenter
        textFormat: Text.StyledText
        text: "<font color='" + Ink.ink + "'>⏎</font> OPEN · <font color='" + Ink.ink + "'>TAB</font> NEXT · <font color='"
          + Ink.ink + "'>ESC</font> LIFT OFF"
        color: Ink.inkMuted
        font.family: Type.mono
        font.pixelSize: Type.tag
        font.letterSpacing: Type.trackTag
      }
      Row {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: Type.px(4)
        Repeater {
          model: [{ key: "menu", text: "MENU" }, { key: "settings", text: "SETTINGS" }]
          Text {
            id: link
            required property var modelData
            required property int index
            text: (index ? "· " : "") + modelData.text
            readonly property bool keyStop: true
            function keyPress() { root.request(link.modelData.key, "") }
            color: linkHit.containsMouse ? Ink.ink : Ink.inkDim
            font.family: Type.mono
            font.pixelSize: Type.tag
            font.weight: Type.labelWeight
            font.letterSpacing: Type.trackTag
            MouseArea {
              id: linkHit
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.request(link.modelData.key, "")
            }
          }
        }
      }
    }
  }
}
