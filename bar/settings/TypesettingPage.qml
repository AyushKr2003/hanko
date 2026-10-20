pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Style.js" as S
import "../../core/Settings.js" as Settings

// Settings › Typesetting 組版 as a proof (校正, docs/settings-kosei): the
// galley (your bar set large, each part numbered), the index of the ten
// parts, and the case of the open one.
Column {
  id: root

  property var draft: S.normalize({})
  property var style: ({})
  property var barData: ({})
  property string query: ""
  property bool compact: false
  // The open part and what the search lights (SettingsPage works them out).
  property string part: "seal"
  property var lit: []
  property var edited: []
  // The style the galley shows: yours, or a specimen being tried.
  property var proofStyle: style

  signal settingPicked(string key, string value)
  signal partPicked(string key)
  signal tried(string key, string value)
  signal untried()
  // The galley grew or shrank (a specimen tried on, a window resized), by
  // `by` px, so the page can hold what's under the pointer still. `held`:
  // the pointer is over the case, trying.
  signal galleyResized(Item galley, real by, bool held)

  // While the pointer is in the case the galley only grows (Inkan's sketch
  // and the two lines differ a lot), and it gives the room back a moment
  // after the pointer leaves: stepping from one specimen to the next never
  // reflows the page under it.
  readonly property bool holding: caseHover.hovered || release.running
  Timer { id: release; interval: 300 }
  Connections {
    target: caseHover
    function onHoveredChanged() { if (!caseHover.hovered) release.restart() }
  }

  width: parent ? parent.width : 0

  Item { width: 1; height: Type.px(18) }

  Galley {
    id: galley
    property real held: 0
    width: parent.width
    height: root.holding ? Math.max(implicitHeight, held) : implicitHeight
    onHeightChanged: {
      if (held > 0 && height !== held) root.galleyResized(galley, height - held, root.holding)
      held = height
    }
    style: root.proofStyle
    barData: root.barData
    part: root.part
    edited: root.edited
    lit: root.lit
    compact: root.compact
    onPartPicked: function(key) { root.partPicked(key) }
  }

  Item { width: 1; height: Type.px(14) }

  // The index: every part by number and name, Edge and Frame too. A part
  // set aside reads faint, struck through.
  Flow {
    width: parent.width
    spacing: Type.px(4)
    Repeater {
      model: Settings.PROOF
      Rectangle {
        id: tab
        required property var modelData
        readonly property bool open: modelData.key === root.part
        readonly property bool aside: !!modelData.show && !S.shows(root.style, modelData.show)
        readonly property bool dim: (root.lit.length > 0 && root.lit.indexOf(modelData.key) < 0)
          || (root.style.form === "inkan" && modelData.bar)
        width: tabRow.width + Type.px(20)
        height: Type.px(30)
        radius: 3
        color: open ? Ink.bone : tabHover.containsMouse ? Ink.lineSoft : "transparent"
        opacity: dim && !open ? 0.4 : 1
        Row {
          id: tabRow
          anchors.centerIn: parent
          spacing: Type.px(7)
          Text {
            anchors.baseline: tabName.baseline
            text: tab.open ? "//" : tab.modelData.no
            color: tab.open ? Ink.boneInk : Ink.inkFaint
            opacity: tab.open ? 0.6 : 1
            font.family: Type.mono
            font.pixelSize: Type.tag
            font.letterSpacing: 1
          }
          Text {
            id: tabName
            text: tab.modelData.name
            color: tab.open ? Ink.boneInk : tab.aside ? Ink.inkFaint : Ink.inkDim
            font.family: Type.text
            font.pixelSize: Type.px(13)
            font.strikeout: tab.aside
          }
          Rectangle {
            visible: root.edited.indexOf(tab.modelData.key) >= 0
            anchors.verticalCenter: parent.verticalCenter
            width: Type.px(4)
            height: width
            radius: width / 2
            color: Ink.seal
          }
        }
        MouseArea {
          id: tabHover
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          readonly property bool keyStop: enabled
          readonly property bool keyChosen: tab.open
          function keyPress() { root.partPicked(tab.modelData.key) }
          onClicked: root.partPicked(tab.modelData.key)
        }
      }
    }
  }

  Item { width: 1; height: Type.px(14) }
  Rectangle { width: parent.width; height: 1; color: Ink.line }
  Item { width: 1; height: Type.px(22) }

  // A search that lights nothing on the bar says where to look.
  Text {
    visible: String(root.query).trim() !== "" && root.lit.length === 0
    width: parent.width
    bottomPadding: Type.px(18)
    wrapMode: Text.Wrap
    textFormat: Text.StyledText
    text: "Nothing on the bar answers to <b>" + String(root.query).trim().replace(/&/g, "&amp;").replace(/</g, "&lt;") + "</b>."
    color: Ink.inkMuted
    font.family: Type.text
    font.pixelSize: Type.row
  }

  TypeCase {
    width: parent.width
    height: implicitHeight
    part: Settings.proofPart(root.part)
    style: root.style
    doc: root.draft
    barData: root.barData
    compact: root.compact
    onPicked: function(key, value) { root.untried(); root.settingPicked(key, value) }
    onTried: function(key, value) { root.tried(key, value) }
    onUntried: root.untried()
    HoverHandler { id: caseHover }
  }
}
