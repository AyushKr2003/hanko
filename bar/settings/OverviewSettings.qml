pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Overview.js" as O
import "../overview"

// Settings › Overview 一覧 (docs/settings-kosei): the workspace overview
// three ways, each drawn live with your spaces and windows, a screen in
// small: printed pages in a grid, Ryoku's busy spaces with a +, or the
// live space's windows spread out under a strip and a search field
// (omarchy-overview's mission control). A click keeps it; a right-click on the
// workspaces (or `hanko overview`) opens it.
Column {
  id: root

  property var style: ({})
  property var barData: ({})
  property bool compact: false

  signal settingPicked(string key, string value)

  // Each window with a name and an address, as the overview reads them.
  readonly property var spaces: (barData.spaces || []).map(function(sp) {
    var wins = (sp.all || sp.windows || []).map(function(w, i) {
      return Object.assign({ name: "", address: "0x" + sp.id + "" + i, title: "", floating: false, fullscreen: false }, w)
    })
    return Object.assign({}, sp, { all: wins })
  })
  readonly property int activeId: {
    for (var i = 0; i < spaces.length; i++) if (spaces[i].active) return spaces[i].id
    return 1
  }
  readonly property int across: compact ? 1 : width >= Type.px(900) ? 3 : 2
  readonly property real tileWidth: Math.floor((width - (across - 1) * Type.px(10)) / across)
  // Each view is laid out a screen wide and scaled into its tile.
  readonly property real deskW: Type.px(1600)
  readonly property real deskH: Type.px(900)

  width: parent ? parent.width : 0
  spacing: 0
  topPadding: Type.px(22)

  SectionLabel { jp: "一覧"; text: "The overview · 3 ways · drawn with your spaces" }
  Item { width: 1; height: Type.px(12) }

  Grid {
    width: parent.width
    columns: root.across
    spacing: Type.px(10)

    Repeater {
      model: [
        { key: "grid", jp: "頁", name: "Pages", line: "Printed pages in a grid, the live one inverted" },
        { key: "dynamic", jp: "動", name: "Busy spaces", line: "Ryoku's: only the spaces in use, and a + for a new one" },
        { key: "mission", jp: "見開", name: "Spread", line: "This space's windows spread out, a strip of spaces, type to search" }
      ]
      Tile {
        id: way
        required property var modelData
        readonly property real k: (root.tileWidth - 2) / root.deskW
        width: root.tileWidth
        height: implicitHeight
        stageHeight: Math.round(root.deskH * k)
        on: (root.style.overview || "grid") === modelData.key
        jp: modelData.jp
        name: modelData.name
        line: modelData.line
        onClicked: root.settingPicked("overview", way.modelData.key)

        Item {
          width: root.deskW
          height: root.deskH
          scale: way.k
          transformOrigin: Item.TopLeft
          enabled: false
          Rectangle { anchors.fill: parent; color: Ink.paper }
          Loader {
            anchors.fill: parent
            sourceComponent: way.modelData.key === "dynamic" ? dynamicView : way.modelData.key === "mission" ? missionView : pagesView
          }
          Component {
            id: pagesView
            OverviewView {
              pages: O.pages(root.spaces, root.activeId, O.ROWS, O.COLUMNS, true)
              columns: O.COLUMNS
              aspect: 0.5625
              screenName: "DP-1"
              now: root.barData.now || new Date()
            }
          }
          Component {
            id: missionView
            MissionView {
              spaces: root.spaces
              allIds: root.spaces.map(function(s) { return s.id })
              activeId: root.activeId
              aspect: 0.5625
              screenName: "DP-1"
            }
          }
          Component {
            id: dynamicView
            DynamicView {
              spaces: root.spaces
              allIds: root.spaces.map(function(s) { return s.id })
              activeId: root.activeId
              aspect: 0.5625
              animateIn: false
              Component.onCompleted: seed()
            }
          }
        }
      }
    }
  }

  Item { width: 1; height: Type.px(16) }
  Text {
    width: Math.min(parent.width, Type.px(820))
    wrapMode: Text.Wrap
    text: "Open it with a right-click on the workspaces, or omarchy-shell hanko overview (bind it to Super+Tab: see the README). Arrows switch, a click goes there, dragging a window moves it, a middle-click closes one."
    color: Ink.inkMuted
    font.family: Type.text
    font.pixelSize: Type.note
  }
}
