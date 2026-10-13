pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Style.js" as S
import "../../core/Settings.js" as Settings
import "../../core/Leaf.js" as LeafJs
import ".."
import "../scroll"

// Hanko's settings (docs/COMPONENTS.md §6), in the Ryoku Hub grammar: a
// numbered rail on the left, the page on the right, an action bar at the
// foot. Pure QtQuick: bar/SettingsWindow.qml feeds it Typeset's draft and
// live bar data; the harness renders it still.
//
// Presets 型 shows every preset as a live specimen (PresetsPage.qml).
// Typesetting 組版 is a proof (校正, docs/settings-kosei): the galley (your
// bar set large, each part numbered), an index of the ten parts, and the
// case of the open one: a specimen per way it can be set, then the few
// choices that are words. How panels open is on the Scroll 巻 page.
Rectangle {
  id: root

  // The draft document and what is saved (style.json shapes).
  property var draft: S.normalize({})
  property var saved: S.normalize({})
  // Rail page key (Settings.RAIL).
  property string page: "typesetting"
  property string query: ""
  property bool advanced: false
  // Screen names, for per-monitor overrides under Advanced.
  property var monitors: []
  // Live data for the preview bars: { now, spaces, activeWindow, home,
  // media, volume, network, battery, brightness, notifications, dnd,
  // timeFormat }.
  property var barData: ({})
  // The sheets' plain data, for the Sheets page's live preview.
  property var sheetFeed: ({})
  // For the plates: services/Machine.qml info, core/Dossier.qml doc, the
  // plugin's version and where Profile saves an image.
  property var machine: ({ user: "", host: "", kernel: "", uptime: 0, theme: "", omarchy: "", hyprland: "", packages: 0, since: "", machine: "" })
  property var profile: ({ name: "", tagline: "", hidden: [] })
  property string version: ""
  property string picturesDir: ""
  // Opens Profile in EDIT (the harness).
  property bool profileEditing: false
  readonly property bool onPlate: Settings.PLATES.indexOf(page) >= 0
  // What the Widgets page lists besides Hanko's own parts
  // (Settings.visibilityCards ctx: own, indicators, tray, hosted).
  property var visibility: ({})

  signal settingPicked(string key, string value)
  signal presetPicked(string name)
  signal resetToPreset()
  // Every change is saved as it is made; Undo walks this visit's back.
  property int undoCount: 0
  signal undo()
  signal pagePicked(string key)
  signal queryEdited(string text)
  signal advancedToggled(bool on)
  signal monitorCleared(string name)
  signal monitorPicked(string monitor, string key, string value)
  signal shuffle()
  // Profile 印影 (core/Dossier.qml): field name | tagline; block ids from
  // core/Profile.js BLOCKS.
  signal profileTextEdited(string field, string value)
  signal profileBlockToggled(string block)
  signal profileReset()
  signal showAll()

  readonly property var style: S.resolve(draft)

  // ---------------------------------------------------------- the proof
  // The open part (Settings.PROOF key). A click on the galley or the
  // index, Left/Right or 1-0 from the window change it.
  property string part: "seal"
  signal partPicked(string key)
  onPartPicked: function(key) { part = key }
  function stepPart(delta) { part = Settings.proofStep(partShown, delta) }
  function pickPartAt(n) { if (n >= 0 && n < Settings.PROOF.length) part = Settings.PROOF[n].key }
  // A specimen under the pointer is tried on the galley ({ key, value }).
  property var trial: null
  readonly property var proofStyle: {
    if (!trial) return style
    var s = Object.assign({}, style)
    s[trial.key] = trial.key === "height" ? Number(trial.value) : trial.value
    return s
  }
  // The parts a search leaves lit ([] when there is no search).
  readonly property var litParts: String(query).trim() === "" ? []
    : Settings.PROOF.filter(function(p) { return Settings.proofMatches(p, root.query, S.OPTIONS) }).map(function(p) { return p.key })
  // A search moves the case to the first part it lights.
  readonly property string partShown: litParts.length && litParts.indexOf(part) < 0 ? litParts[0] : part
  readonly property var editedParts: Settings.PROOF.filter(function(p) { return Settings.proofEdits(p, root.draft).length > 0 }).map(function(p) { return p.key })
  // The bar data, with indicators to show: yours when any is on, else two
  // lit for the specimens (night light, stay awake), so the part has a face.
  readonly property var proofData: {
    var d = Object.assign({}, barData)
    var inds = barData.indicators || []
    var anyOn = inds.some ? inds.some(function(i) { return i.on }) : false
    if (!anyOn) d.indicators = Settings.SAMPLE_INDICATORS
    return d
  }

  // Advanced: the monitor whose overrides are shown (the first by default),
  // how it resolves, and which settings it sets for itself.
  property string overrideMonitor: ""
  readonly property string monitorShown: monitors.indexOf(overrideMonitor) >= 0 ? overrideMonitor : (monitors[0] || "")
  readonly property var monitorStyle: S.resolve(draft, monitorShown)
  readonly property var monitorOwn: Object.keys(draft.monitors[monitorShown] || {})

  // Scroll the page to its foot (the Advanced card), as the harness does.
  function scrollToEnd() { scroller.contentY = Math.max(0, scroller.contentHeight - scroller.height) }

  // `/` from the window: put the cursor in the search field.
  function focusSearch() { (compact ? pageSearch : railSearch).input.forceActiveFocus() }
  readonly property int changes: Settings.changes(saved, draft, S.resolve)
  readonly property var rail: Settings.RAIL
  // Which rail entry the open page is; looked up in the whole rail, so the
  // title never depends on what the rail currently hides.
  readonly property var pageInfo: Settings.pageInfo(root.page)

  color: Ink.paper
  implicitWidth: Type.px(1600)
  implicitHeight: Type.px(900)

  // The window can be any size (a tiled window ignores the minimum), so the
  // page reflows: the rail narrows, then folds to its glyphs with the search
  // moving onto the page; cards, presets and overrides drop columns.
  readonly property bool compact: width < Type.px(760)
  // Side margin of the page and the action bar.
  readonly property int pad: compact ? Type.px(16) : Type.px(32)

  // ================================================================ rail
  Item {
    id: rail
    width: root.compact ? Type.px(60) : root.width < Type.px(1100) ? Type.px(224) : Type.px(268)
    height: parent.height

    Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: Ink.line }

    // The rail's own scroll, so a short window never runs the pages under
    // the Advanced switch.
    Flickable {
      id: railScroller
      x: root.compact ? Type.px(8) : Type.px(20)
      y: Type.px(22)
      width: parent.width - 2 * x
      height: railFoot.y - y - Type.px(4)
      contentHeight: railColumn.height + Type.px(8)
      interactive: contentHeight > height
      clip: true
      boundsBehavior: Flickable.StopAtBounds

    Column {
      id: railColumn
      width: railScroller.width

      // The masthead: a seal and HANKO //SETTINGS_
      Rectangle {
        width: parent.width
        height: mast.height + 2 * Type.px(root.compact ? 6 : 14)
        radius: 3
        color: "transparent"
        border.width: root.compact ? 0 : 1
        border.color: Ink.lineStrong
        Row {
          id: mast
          x: root.compact ? (parent.width - width) / 2 : Type.px(14)
          anchors.verticalCenter: parent.verticalCenter
          spacing: Type.px(12)
          Rectangle {
            width: Type.px(34)
            height: Type.px(34)
            radius: 3
            color: Ink.seal
            Text {
              anchors.centerIn: parent
              text: root.draft.sealGlyph || "鑑"
              color: Ink.paper
              font.family: Type.jpSerif
              font.pixelSize: Type.px(19)
            }
          }
          Column {
            visible: !root.compact
            anchors.verticalCenter: parent.verticalCenter
            spacing: Type.px(3)
            Text { text: "HANKO"; color: Ink.ink; font.family: Type.mono; font.pixelSize: Type.px(12); font.weight: Font.Medium; font.letterSpacing: Type.px(2.6) }
            Text { text: "//SETTINGS_"; color: Ink.inkMuted; font.family: Type.mono; font.pixelSize: Type.px(10); font.letterSpacing: Type.px(1.6) }
          }
        }
      }

      Item { width: 1; height: Type.px(16); visible: !root.compact }

      // Search: filters the rows of the cards and the pages of the rail.
      SearchField { id: railSearch; visible: !root.compact; width: parent.width }

      Item { width: 1; height: Type.px(2) }

      Repeater {
        model: root.rail
        Column {
          id: group
          required property var modelData
          readonly property var pages: !modelData ? [] : modelData.pages.filter(function(p) { return Settings.pageMatches(p, root.query) || root.query === "" })
          width: parent.width
          visible: pages.length > 0

          Item {
            width: parent.width
            height: Type.px(16) + groupName.height + Type.px(6)
            Text {
              id: groupName
              y: Type.px(16)
              // Folded, a group keeps only its number.
              text: !group.modelData ? "" : root.compact ? group.modelData.group.replace(/ .*/, "") : group.modelData.group
              color: group.modelData && group.modelData.group === root.pageInfo.group ? Ink.bone : Ink.inkFaint
              font.family: Type.mono
              font.pixelSize: Type.label
              font.letterSpacing: Type.trackLabel
            }
            Rectangle {
              x: groupName.width + Type.px(8)
              anchors.verticalCenter: groupName.verticalCenter
              width: parent.width - x
              height: 1
              color: Ink.lineSoft
            }
          }

          Repeater {
            model: group.pages
            Rectangle {
              id: item
              required property var modelData
              readonly property bool on: modelData.key === root.page
              width: group.width
              height: Type.px(40)
              radius: 3
              color: on ? Ink.bone : itemHover.containsMouse ? Ink.lineSoft : "transparent"
              Row {
                visible: !root.compact
                x: Type.px(14)
                anchors.verticalCenter: parent.verticalCenter
                spacing: Type.px(10)
                Text {
                  visible: item.on
                  anchors.verticalCenter: parent.verticalCenter
                  text: "//"
                  color: Ink.boneInk
                  opacity: 0.6
                  font.family: Type.mono
                  font.pixelSize: Type.px(12)
                }
                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: item.modelData.label
                  color: item.on ? Ink.boneInk : Ink.inkDim
                  font.family: Type.text
                  font.pixelSize: Type.row
                }
              }
              // Folded, the glyph alone names the page, centred.
              Text {
                x: root.compact ? (parent.width - width) / 2 : parent.width - width - Type.px(14)
                anchors.verticalCenter: parent.verticalCenter
                text: root.compact ? item.modelData.jp.charAt(0) : item.modelData.jp
                color: item.on ? Ink.boneInk : root.compact ? Ink.inkDim : Ink.inkFaint
                font.family: Type.jp
                font.pixelSize: Type.px(root.compact ? 15 : 12)
              }
              MouseArea {
                id: itemHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.pagePicked(item.modelData.key)
              }
            }
          }
        }
      }
    }
    }

    // Advanced: the seal glyph, per-monitor overrides and the raw document.
    Item {
      id: railFoot
      x: root.compact ? Type.px(8) : Type.px(20)
      width: parent.width - 2 * x
      height: Type.px(50)
      anchors.bottom: parent.bottom
      anchors.bottomMargin: Type.px(8)
      Rectangle { width: parent.width; height: 1; color: Ink.line }
      Text {
        visible: !root.compact
        anchors.verticalCenter: parent.verticalCenter
        text: "ADVANCED"
        color: Ink.ink
        font.family: Type.mono
        font.pixelSize: Type.px(11)
        font.letterSpacing: Type.px(1.6)
      }
      Rectangle {
        x: root.compact ? (parent.width - width) / 2 : parent.width - width
        anchors.verticalCenter: parent.verticalCenter
        width: Type.px(34)
        height: Type.px(18)
        radius: 3
        color: root.advanced ? Ink.alpha(Ink.ink, 0.14) : "transparent"
        border.width: 1
        border.color: Ink.lineStrong
        Rectangle {
          x: root.advanced ? parent.width - width - Type.px(3) : Type.px(3)
          anchors.verticalCenter: parent.verticalCenter
          width: Type.px(10)
          height: width
          radius: 1
          color: root.advanced ? Ink.ink : Ink.inkFaint
          Behavior on x { enabled: !Motion.still; NumberAnimation { duration: Motion.slide; easing.type: Easing.OutCubic } }
        }
        MouseArea {
          anchors.fill: parent
          anchors.margins: -Type.px(6)
          cursorShape: Qt.PointingHandCursor
          onClicked: root.advancedToggled(!root.advanced)
        }
      }
    }
  }

  // ================================================================ page
  Item {
    id: main
    x: rail.width
    width: parent.width - rail.width
    height: parent.height

    // Profile, About and Credits fill the page, as posters.
    Loader {
      id: plateLoader
      active: root.onPlate
      visible: active
      width: parent.width
      height: parent.height - (actions.visible ? actions.height : 0)
      sourceComponent: root.page === "profile" ? profilePlate : root.page === "about" ? aboutPlate : creditsPlate
    }

    Flickable {
      id: scroller
      visible: !root.onPlate
      width: parent.width
      height: parent.height - actions.height
      contentHeight: pageColumn.height + Type.px(40)
      clip: true
      boundsBehavior: Flickable.StopAtBounds

      Column {
        id: pageColumn
        x: root.pad
        y: Type.px(root.compact ? 16 : 26)
        width: scroller.width - 2 * x
        spacing: 0

        // Folded rail: the search sits at the top of the page instead.
        SearchField { id: pageSearch; visible: root.compact; width: parent.width }
        Item { width: 1; height: Type.px(14); visible: root.compact }

        // Eyebrow: 鑑 BAR ───── hanko.bar · omarchy
        Item {
          width: parent.width
          height: Type.px(16)
          Row {
            id: eyebrow
            anchors.verticalCenter: parent.verticalCenter
            spacing: Type.px(10)
            Text { anchors.verticalCenter: parent.verticalCenter; text: Typeset.current.sealGlyph || "鑑"; color: Ink.seal; font.family: Type.jp; font.pixelSize: Type.px(13) }
            Text {
              anchors.verticalCenter: parent.verticalCenter
              width: Math.min(implicitWidth, pageColumn.width - Type.px(24))
              elide: Text.ElideRight
              text: root.pageInfo.group.replace(/^\d+ /, "") + (root.page === "typesetting" || root.page === "presets" ? " · " + Settings.presetLine(root.draft) : "")
              color: Ink.inkMuted
              font.family: Type.mono
              font.pixelSize: Type.eyebrow
              font.letterSpacing: Type.trackEyebrow
              font.capitalization: Font.AllUppercase
            }
          }
          Text {
            id: where
            // Gives way when the eyebrow needs the room.
            visible: eyebrow.width + implicitWidth + Type.px(40) <= parent.width
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: "hanko.bar · omarchy"
            color: Ink.inkMuted
            font.family: Type.mono
            font.pixelSize: Type.eyebrow
            font.letterSpacing: Type.trackEyebrow
          }
          Rectangle {
            x: eyebrow.width + Type.px(10)
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(0, (where.visible ? where.x - Type.px(10) : parent.width) - x)
            height: 1
            color: Ink.lineSoft
          }
        }

        Item { width: 1; height: Type.px(10) }
        Item {
          width: parent.width
          height: pageTitle.height
          Text {
            id: pageTitle
            text: root.pageInfo.page.label
            color: Ink.ink
            font.family: Type.display
            font.pixelSize: Type.px(root.compact ? 34 : 44)
            font.weight: Font.Normal
            font.variableAxes: Type.axes(Type.px(root.compact ? 34 : 44))
            font.letterSpacing: -0.8
          }
          // Typesetting: the preset this bar starts from, and the way to
          // the others.
          Rectangle {
            visible: root.page === "typesetting" && !root.compact
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Type.px(6)
            width: presetChip.width + 2 * Type.px(12)
            height: Type.px(34)
            radius: 3
            color: presetLink.containsMouse ? Ink.lineSoft : "transparent"
            border.width: 1
            border.color: presetLink.containsMouse ? Ink.lineStrong : Ink.line
            Row {
              id: presetChip
              anchors.centerIn: parent
              spacing: Type.px(9)
              Text { anchors.verticalCenter: parent.verticalCenter; text: "FROM"; color: Ink.inkMuted; font.family: Type.mono; font.pixelSize: Type.tag; font.letterSpacing: Type.trackLabel }
              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.draft.preset
                color: Ink.ink
                font.family: Type.display
                font.pixelSize: Type.px(17)
                font.weight: Font.Normal
                font.variableAxes: Type.axes(Type.px(17))
              }
              Text { anchors.verticalCenter: parent.verticalCenter; text: Settings.PRESET_KANJI[root.draft.preset] || ""; color: Ink.inkMuted; font.family: Type.jp; font.pixelSize: Type.px(14) }
              Text {
                readonly property int n: Object.keys(root.draft.edits).length
                anchors.verticalCenter: parent.verticalCenter
                text: n === 0 ? "as set" : "+ " + n + (n === 1 ? " edit" : " edits")
                color: n ? Ink.seal : Ink.inkMuted
                font.family: Type.text
                font.pixelSize: Type.note
              }
              Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 1; height: Type.px(14); color: Ink.line }
              Text { anchors.verticalCenter: parent.verticalCenter; text: "PRESETS ›"; color: presetLink.containsMouse ? Ink.ink : Ink.inkDim; font.family: Type.mono; font.pixelSize: Type.tag; font.letterSpacing: Type.trackLabel }
            }
            MouseArea {
              id: presetLink
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.pagePicked("presets")
            }
          }
        }
        Item { width: 1; height: Type.px(6) }
        Text {
          width: parent.width
          wrapMode: Text.Wrap
          text: root.page === "typesetting"
            ? "Click a part of your bar, then pick how it is set. Hover a way to try it; a click keeps it, live on your desktop. Ctrl+Z puts it back."
            : root.page === "presets"
            ? "A preset sets all twenty-six settings at once; tune any of them afterwards on Typesetting. Each bar below is drawn live with your data, seal and type size. Your sheets, motion and hidden parts stay as they are."
            : root.placeholders[root.page] || ""
          color: Ink.inkMuted
          font.family: Type.text
          font.pixelSize: Type.row
        }

        // ------------------------------------------------ Presets
        PresetsPage {
          visible: root.page === "presets"
          width: parent.width
          doc: root.draft
          barData: root.barData
          query: root.query
          compact: root.compact
          onPresetPicked: function(name) { root.presetPicked(name) }
        }

        // ------------------------------------------------ Sheets
        SheetsPage {
          visible: root.page === "sheets"
          width: parent.width
          doc: root.draft
          feed: root.sheetFeed
          compact: root.compact
          onStylePicked: function(sheet, style) { root.settingPicked("sheetStyle:" + sheet, style) }
          onOpacityPicked: function(value) { root.settingPicked("panelOpacity", value) }
        }

        // ------------------------------------------------ Typesetting
        Column {
          visible: root.page === "typesetting"
          width: parent.width

          Item { width: 1; height: Type.px(18) }

          // The galley: your bar set large, its parts numbered.
          Galley {
            id: galley
            width: parent.width
            height: implicitHeight
            style: root.proofStyle
            barData: root.proofData
            part: root.partShown
            edited: root.editedParts
            lit: root.litParts
            compact: root.compact
            onPartPicked: function(key) { root.partPicked(key) }
          }

          Item { width: 1; height: Type.px(14) }

          // The index: every part by number and name, Edge and Frame too.
          Flow {
            width: parent.width
            spacing: Type.px(4)
            Repeater {
              model: Settings.PROOF
              Rectangle {
                id: tab
                required property var modelData
                readonly property bool open: modelData.key === root.partShown
                readonly property bool dim: (root.litParts.length > 0 && root.litParts.indexOf(modelData.key) < 0)
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
                    color: tab.open ? Ink.boneInk : Ink.inkDim
                    font.family: Type.text
                    font.pixelSize: Type.px(13)
                  }
                  Rectangle {
                    visible: root.editedParts.indexOf(tab.modelData.key) >= 0
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
            visible: String(root.query).trim() !== "" && root.litParts.length === 0
            width: parent.width
            bottomPadding: Type.px(18)
            wrapMode: Text.Wrap
            textFormat: Text.StyledText
            text: "Nothing on the bar answers to <b>" + String(root.query).trim().replace(/&/g, "&amp;").replace(/</g, "&lt;") + "</b>."
              + (Settings.PANELS_CARD.rows.some(function(r) { return Settings.matches(r, root.query, S.OPTIONS) }) || /interlude|divider|leaf|scroll/i.test(root.query)
                ? " How panels open, the scroll's dividers and its end leaf are on Scroll 巻." : "")
            color: Ink.inkMuted
            font.family: Type.text
            font.pixelSize: Type.row
          }

          // The case for the open part.
          TypeCase {
            width: parent.width
            height: implicitHeight
            part: Settings.proofPart(root.partShown)
            style: root.style
            doc: root.draft
            barData: root.proofData
            compact: root.compact
            onPicked: function(key, value) { root.trial = null; root.settingPicked(key, value) }
            onTried: function(key, value) { root.trial = { key: key, value: value } }
            onUntried: root.trial = null
            onGlyphAsked: root.advancedToggled(true)
          }

          // Advanced: what only some people want.
          Column {
            visible: root.advanced
            width: parent.width
            topPadding: Type.px(14)

            Rectangle {
              width: parent.width
              height: advancedColumn.height + 2 * Type.px(12)
              radius: 3
              color: "transparent"
              border.width: 1
              border.color: Ink.line

              Column {
                id: advancedColumn
                x: Type.px(14)
                y: Type.px(12)
                width: parent.width - 2 * x
                spacing: Type.px(10)

                Row {
                  spacing: Type.px(8)
                  Text { text: "//"; color: Ink.inkFaint; font.family: Type.mono; font.pixelSize: Type.eyebrow; font.letterSpacing: Type.trackEyebrow }
                  Text { text: "ADVANCED"; color: Ink.inkDim; font.family: Type.mono; font.pixelSize: Type.eyebrow; font.letterSpacing: Type.trackEyebrow }
                }
                Rectangle { width: parent.width; height: 1; color: Ink.line }

                // Any one character as the seal.
                Row {
                  spacing: Type.px(14)
                  Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Type.px(160)
                    text: "Seal glyph"
                    color: Ink.ink
                    font.family: Type.text
                    font.pixelSize: Type.row
                  }
                  Rectangle {
                    width: Type.px(44)
                    height: Type.px(28)
                    radius: 3
                    color: "transparent"
                    border.width: 1
                    border.color: glyphInput.activeFocus ? Ink.lineStrong : Ink.line
                    TextInput {
                      id: glyphInput
                      anchors.centerIn: parent
                      text: root.draft.sealGlyph
                      color: Ink.seal
                      font.family: Type.jpSerif
                      font.pixelSize: Type.px(16)
                      onTextEdited: if (text.trim() !== "") root.settingPicked("sealGlyph", text)
                    }
                  }
                  Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, advancedColumn.width - Type.px(160 + 44 + 28))
                    wrapMode: Text.Wrap
                    text: "One character, used when the seal is a stamp."
                    color: Ink.inkMuted
                    font.family: Type.text
                    font.pixelSize: Type.note
                  }
                }

                // Per-monitor overrides: pick a monitor, then set any setting
                // for it alone. Picking what the rest of your screens get drops
                // the override (Style.withMonitorSetting), so a marked row is
                // always one that differs.
                Column {
                  visible: root.monitors.length > 0
                  width: parent.width
                  spacing: Type.px(8)

                  Row {
                    spacing: Type.px(14)
                    Text {
                      anchors.verticalCenter: parent.verticalCenter
                      width: Type.px(160)
                      text: "Per monitor"
                      color: Ink.ink
                      font.family: Type.text
                      font.pixelSize: Type.row
                    }
                    Segmented {
                      anchors.verticalCenter: parent.verticalCenter
                      options: root.monitors
                      selected: root.monitorShown
                      onPicked: function(value) { root.overrideMonitor = value }
                    }
                    Text {
                      anchors.verticalCenter: parent.verticalCenter
                      text: root.monitorOwn.length
                        ? root.monitorOwn.length + (root.monitorOwn.length === 1 ? " override" : " overrides")
                        : "as the rest"
                      color: Ink.inkDim
                      font.family: Type.mono
                      font.pixelSize: Type.px(10)
                      font.letterSpacing: 1
                    }
                    SmallButton {
                      visible: root.monitorOwn.length > 0
                      label: "Clear"
                      onClicked: root.monitorCleared(root.monitorShown)
                    }
                  }

                  Grid {
                    id: perMonitor
                    width: parent.width
                    // Down each column, in the order the cards read.
                    flow: Grid.TopToBottom
                    readonly property int across: width >= Type.px(860) ? 2 : 1
                    rows: Math.ceil(S.KEYS.length / across)
                    columnSpacing: Type.px(28)
                    readonly property real cellWidth: (width - (across - 1) * columnSpacing) / across

                    Repeater {
                      model: S.KEYS
                      Item {
                        id: override
                        required property string modelData
                        required property int index
                        readonly property bool own: root.monitorOwn.indexOf(modelData) >= 0
                        width: perMonitor.cellWidth
                        height: Type.px(34)

                        Rectangle {
                          visible: override.index % perMonitor.rows > 0
                          width: parent.width
                          height: 1
                          color: Ink.lineSoft
                        }
                        // A red tick marks a setting this monitor sets for itself.
                        Rectangle {
                          visible: override.own
                          anchors.verticalCenter: parent.verticalCenter
                          width: 2
                          height: Type.px(14)
                          color: Ink.seal
                        }
                        Text {
                          anchors.verticalCenter: parent.verticalCenter
                          x: Type.px(10)
                          width: Math.max(0, parent.width - x - overrideSeg.width - Type.px(8))
                          elide: Text.ElideRight
                          text: Settings.nameOf(override.modelData)
                          color: override.own ? Ink.ink : Ink.inkMuted
                          font.family: Type.text
                          font.pixelSize: Type.px(12)
                        }
                        Segmented {
                          id: overrideSeg
                          anchors.right: parent.right
                          anchors.verticalCenter: parent.verticalCenter
                          options: Settings.optionsFor(override.modelData, S.OPTIONS)
                          selected: String(root.monitorStyle[override.modelData])
                          onPicked: function(value) { root.monitorPicked(root.monitorShown, override.modelData, value) }
                        }
                      }
                    }
                  }
                }

                // The document as style.json holds it.
                Text {
                  width: parent.width
                  text: JSON.stringify(root.draft, null, 2)
                  color: Ink.inkMuted
                  wrapMode: Text.WrapAnywhere
                  font.family: Type.mono
                  font.pixelSize: Type.px(10)
                }
              }
            }
          }
        }

        // ------------------------------------------------ Widgets
        // Every part the bar can show, each shown or hidden: Hanko's own,
        // its marks, the tray's apps and the widgets it hosts.
        Column {
          visible: root.page === "widgets"
          width: parent.width
          topPadding: Type.px(22)
          spacing: Type.px(14)

          Row {
            spacing: Type.px(12)
            SmallButton {
              label: "Show all"
              faint: root.style.hidden.length === 0
              onClicked: root.showAll()
            }
            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: root.style.hidden.length
                ? (root.style.hidden.length + (root.style.hidden.length === 1 ? " PART HIDDEN" : " PARTS HIDDEN"))
                : "EVERYTHING SHOWN"
              color: Ink.inkDim
              font.family: Type.mono
              font.pixelSize: Type.px(10)
              font.letterSpacing: Type.px(1.8)
            }
          }

          Grid {
            id: partCards
            width: parent.width
            columns: Math.max(1, Math.min(3, Math.floor((width + spacing) / (Type.px(400) + spacing))))
            spacing: Type.px(12)
            readonly property real cardWidth: (width - (columns - 1) * spacing) / columns
            readonly property var cardList: Settings.visibilityCards(root.visibility)

            Repeater {
              id: partRepeater
              model: partCards.cardList
              SettingsCard {
                required property var modelData
                required property int index
                width: partCards.cardWidth
                height: Math.max(implicitHeight, partCards.rowHeight(Math.floor(index / partCards.columns)))
                card: modelData
                style: root.style
                options: S.OPTIONS
                query: root.query
                onPicked: function(key, value) { root.settingPicked(key, value) }
              }
            }

            function rowHeight(r) {
              void partRepeater.count
              var h = 0
              for (var i = r * columns; i < (r + 1) * columns; i++) {
                var c = partRepeater.itemAt(i) as SettingsCard
                if (c && c.visible) h = Math.max(h, c.implicitHeight)
              }
              return h
            }
          }

          Text {
            width: parent.width
            wrapMode: Text.Wrap
            text: "Hiding a part takes it off this bar only; the widget stays in Omarchy's bar layout. Add or remove widgets there."
            color: Ink.inkMuted
            font.family: Type.text
            font.pixelSize: Type.note
          }
        }

        // ------------------------------------------------ Motion
        Column {
          visible: root.page === "motion"
          width: parent.width
          topPadding: Type.px(22)
          spacing: Type.px(18)

          SettingsCard {
            width: parent.width
            card: Settings.MOTION_CARD
            style: root.style
            options: ({})
            onPicked: function(key, value) { root.settingPicked(key, value) }
          }

          Text {
            visible: Motion.system
            width: parent.width
            wrapMode: Text.Wrap
            text: "Omarchy's animations are off, so Hanko is still whatever this says."
            color: Ink.seal
            font.family: Type.text
            font.pixelSize: Type.px(12)
          }

          // The timings, as Scroll's motion sheet gives them.
          Rectangle {
            width: parent.width
            height: timings.implicitHeight + Type.px(16)
            radius: 3
            color: "transparent"
            border.width: 1
            border.color: Ink.line

            Column {
              id: timings
              x: Type.px(14)
              y: Type.px(8)
              width: parent.width - 2 * x
              Repeater {
                model: Settings.MOTION_ROWS
                Item {
                  id: timing
                  required property var modelData
                  required property int index
                  readonly property int ms: Motion[modelData[2]]
                  width: timings.width
                  // A narrow page wraps the line instead of cutting it short.
                  height: Math.max(Type.px(36), timingLine.height + Type.px(16))
                  Rectangle {
                    visible: timing.index > 0
                    width: parent.width; height: 1; color: Ink.lineSoft
                  }
                  Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Type.px(120)
                    text: timing.modelData[0]
                    color: Ink.ink
                    font.family: Type.text
                    font.pixelSize: Type.row
                  }
                  Text {
                    id: timingLine
                    anchors.verticalCenter: parent.verticalCenter
                    x: Type.px(120)
                    width: parent.width - x - Type.px(root.compact ? 70 : 110)
                    wrapMode: Text.Wrap
                    text: timing.modelData[1]
                    color: Ink.inkMuted
                    font.family: Type.text
                    font.pixelSize: Type.note
                  }
                  Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    text: root.style.motion === "still" || Motion.system ? "cut" : timing.ms >= 1000 ? (timing.ms / 1000) + " s" : timing.ms + " ms"
                    color: root.style.motion === "still" || Motion.system ? Ink.inkFaint : Ink.inkDim
                    font.family: Type.mono
                    font.pixelSize: Type.px(10)
                    font.letterSpacing: 1
                  }
                }
              }
            }
          }
        }

        // ------------------------------------------------ Scroll
        // How panels open (sheets or the scroll), the scroll's frame and the
        // overview: what used to close Typesetting.
        Column {
          visible: root.page === "scroll"
          width: parent.width
          topPadding: Type.px(22)
          SettingsCard {
            width: parent.width
            height: implicitHeight
            card: Settings.PANELS_CARD
            style: root.style
            options: S.OPTIONS
            query: root.query
            onPicked: function(key, value) { root.settingPicked(key, value) }
          }
        }

        // What sits between the scroll's sections (the `interlude` setting):
        // each tile draws the real Interlude between two stub sections.
        Column {
          visible: root.page === "scroll"
          width: parent.width
          topPadding: Type.px(22)
          spacing: Type.px(12)

          Row {
            spacing: Type.px(8)
            Text { text: "//"; color: Ink.inkFaint; font.family: Type.mono; font.pixelSize: Type.eyebrow; font.letterSpacing: Type.trackEyebrow }
            Text { text: "BETWEEN PANELS"; color: Ink.inkDim; font.family: Type.mono; font.pixelSize: Type.eyebrow; font.letterSpacing: Type.trackEyebrow }
          }

          Grid {
            id: interludes
            width: parent.width
            spacing: Type.px(8)
            columns: width >= Type.px(760) ? 3 : 2
            Repeater {
              model: Settings.INTERLUDES
              Rectangle {
                id: tile
                required property var modelData
                readonly property bool on: modelData.key === root.style.interlude
                width: (interludes.width - (interludes.columns - 1) * interludes.spacing) / interludes.columns
                height: stage.height + caption.height + Type.px(20)
                radius: 3
                color: tileHover.containsMouse && !on ? Ink.lineSoft : "transparent"
                border.width: on ? 2 : 1
                border.color: on ? Ink.bone : Ink.line

                // Two stub sections either side of the interlude.
                Item {
                  id: stage
                  x: Type.px(8); y: Type.px(8)
                  width: parent.width - 2 * x
                  height: Type.px(150)
                  clip: true
                  Repeater {
                    model: [{ jp: "時", no: "01", left: true }, { jp: "音", no: "02", left: false }]
                    Column {
                      id: stub
                      required property var modelData
                      x: stub.modelData.left ? Type.px(10) : stage.width / 2 + Type.px(30)
                      y: Type.px(18)
                      width: stage.width / 2 - Type.px(42)
                      spacing: Type.px(6)
                      Text { text: stub.modelData.jp + "  " + stub.modelData.no; color: Ink.seal; font.family: Type.jp; font.pixelSize: Type.px(9) }
                      Rectangle { width: parent.width * 0.8; height: Type.px(7); radius: 1; color: Ink.inkDim; opacity: 0.55 }
                      Rectangle { width: parent.width * 0.55; height: Type.px(3); color: Ink.inkFaint; opacity: 0.6 }
                      Item { width: 1; height: Type.px(6) }
                      Repeater {
                        model: 4
                        Rectangle { required property int index; width: stub.width * (0.9 - index * 0.12); height: 1; color: Ink.line }
                      }
                    }
                  }
                  Interlude {
                    x: stage.width / 2 - width / 2
                    y: Type.px(8)
                    width: Type.px(46)
                    height: stage.height - Type.px(16)
                    s: Type.scale * 0.62
                    seed: 0
                    style: tile.modelData.key
                  }
                }

                Row {
                  id: caption
                  x: Type.px(12)
                  y: stage.y + stage.height + Type.px(6)
                  spacing: Type.px(8)
                  Text { text: tile.modelData.jp; color: tile.on ? Ink.seal : Ink.inkDim; font.family: Type.jp; font.pixelSize: Type.px(13) }
                  Column {
                    Text { text: tile.modelData.name.toUpperCase() + (tile.on ? "  · IN USE" : ""); color: Ink.ink; font.family: Type.mono; font.pixelSize: Type.px(10); font.letterSpacing: Type.px(1.6) }
                    Text { text: tile.modelData.detail; color: Ink.inkMuted; font.family: Type.text; font.pixelSize: Type.note }
                  }
                }

                MouseArea {
                  id: tileHover
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.settingPicked("interlude", tile.modelData.key)
                }
              }
            }
          }
        }

        // What sits after Inbox (the `endleaf` setting): each tile draws the
        // real end leaf, small, with a sample reading.
        Column {
          visible: root.page === "scroll"
          width: parent.width
          topPadding: Type.px(26)
          spacing: Type.px(12)

          Row {
            spacing: Type.px(8)
            Text { text: "//"; color: Ink.inkFaint; font.family: Type.mono; font.pixelSize: Type.eyebrow; font.letterSpacing: Type.trackEyebrow }
            Text { text: "AFTER INBOX"; color: Ink.inkDim; font.family: Type.mono; font.pixelSize: Type.eyebrow; font.letterSpacing: Type.trackEyebrow }
          }

          Grid {
            id: endleaves
            width: parent.width
            spacing: Type.px(8)
            columns: width >= Type.px(760) ? 3 : 2
            readonly property var reading: LeafJs.sample(new Date())
            Repeater {
              model: Settings.ENDLEAVES
              Rectangle {
                id: leafTile
                required property var modelData
                readonly property bool on: modelData.key === root.style.endleaf
                width: (endleaves.width - (endleaves.columns - 1) * endleaves.spacing) / endleaves.columns
                height: leafStage.height + leafCaption.height + Type.px(20)
                radius: 3
                color: leafHover.containsMouse && !on ? Ink.lineSoft : "transparent"
                border.width: on ? 2 : 1
                border.color: on ? Ink.bone : Ink.line

                Item {
                  id: leafStage
                  x: Type.px(8)
                  y: Type.px(8)
                  width: parent.width - 2 * x
                  height: Math.round(width * 0.82)
                  clip: true
                  EndLeaf {
                    width: Type.px(400)
                    height: Type.px(460)
                    x: (leafStage.width - width * scale) / 2
                    y: -Type.px(36) * scale
                    transformOrigin: Item.TopLeft
                    scale: leafStage.height / Type.px(390)
                    kind: leafTile.modelData.key
                    reading: endleaves.reading
                    version: "0.1.0"
                    preset: root.style.preset
                    sealGlyph: root.style.sealGlyph
                    enabled: false
                  }
                }

                Row {
                  id: leafCaption
                  x: Type.px(12)
                  y: leafStage.y + leafStage.height + Type.px(6)
                  spacing: Type.px(8)
                  Text { text: leafTile.modelData.jp; color: leafTile.on ? Ink.seal : Ink.inkDim; font.family: Type.jp; font.pixelSize: Type.px(13) }
                  Column {
                    Text { text: leafTile.modelData.name.toUpperCase() + (leafTile.on ? "  · IN USE" : ""); color: Ink.ink; font.family: Type.mono; font.pixelSize: Type.px(10); font.letterSpacing: Type.px(1.6) }
                    Text { text: leafTile.modelData.detail; color: Ink.inkMuted; font.family: Type.text; font.pixelSize: Type.note }
                  }
                }

                MouseArea {
                  id: leafHover
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.settingPicked("endleaf", leafTile.modelData.key)
                }
              }
            }
          }
        }
      }
    }

    // ------------------------------------------------ action bar
    Item {
      id: actions
      // On a plate only while there is something to undo.
      visible: !root.onPlate || root.undoCount > 0
      anchors.bottom: parent.bottom
      width: parent.width
      height: Type.px(56)
      Rectangle { width: parent.width; height: 1; color: Ink.line }
      Row {
        x: root.pad
        anchors.verticalCenter: parent.verticalCenter
        spacing: Type.px(12)
        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: Type.px(7); height: width; color: root.undoCount ? Ink.ink : Ink.inkFaint }
        Text {
          anchors.verticalCenter: parent.verticalCenter
          // Never under the buttons.
          width: Math.max(0, Math.min(implicitWidth, buttons.x - root.pad - Type.px(7 + 12 + 16)))
          elide: Text.ElideRight
          text: Settings.status(root.undoCount).toUpperCase()
          color: Ink.inkDim
          font.family: Type.mono
          font.pixelSize: Type.px(10)
          font.letterSpacing: Type.px(1.8)
        }
      }
      Row {
        id: buttons
        anchors.right: parent.right
        anchors.rightMargin: root.pad
        anchors.verticalCenter: parent.verticalCenter
        spacing: Type.px(root.compact ? 8 : 12)
        SmallButton { visible: root.page === "presets"; label: "Shuffle"; onClicked: root.shuffle() }
        SmallButton { visible: root.page === "typesetting" || root.page === "presets"; label: root.compact ? "Reset" : "Reset to preset"; faint: !root.style.edited; onClicked: root.resetToPreset() }
        SmallButton { label: "Undo"; plate: true; faint: root.undoCount === 0; onClicked: if (root.undoCount > 0) root.undo() }
      }
    }
  }

  // Honest words for the rail pages that are still to come.
  readonly property var placeholders: ({
    colour: "Hanko takes every colour from your Omarchy theme: one paper, four inks, one red. There is nothing to pick here yet; switch themes with Omarchy and the bar follows.",
    widgets: "Show or hide anything on the bar: Hanko's own parts, its marks, each tray app, and every Omarchy or third-party widget it hosts. Saved with the rest of your style.",
    sheets: "Sheets drop flush from the cell you click. Pick the hand that draws each one: the ledger's page, slips hung like tanzaku, a shōgi board, an abacus, armour lacing, bands of gold mist or Shōji's washi panels on their rail. Every change is kept at once.",
    scroll: "The handscroll unrolls from the rod. Choose what sits between its panels and what follows Inbox; open panels as a scroll just below, and bind a key with omarchy-shell hanko scroll.",
    motion: "No springs, no glow: paper drops with weight and settles, ink arrives after it, and only a new stamp overshoots. Still cuts every move to its end, as Omarchy's own animation switch does.",
    keys: "Esc closes, Tab moves between sheets, Backspace goes back to No. 00, H and L pan the scroll, / searches here, Ctrl+Z undoes the last change here. For Inkan, bind omarchy-shell hanko press to a key in your Hyprland bindings (see the README). Rebinding comes later."
  })

  Component {
    id: profilePlate
    ProfilePlate {
      style: root.style
      doc: root.draft
      machine: root.machine
      profile: root.profile
      barData: root.barData
      now: root.barData.now || new Date()
      version: root.version
      picturesDir: root.picturesDir
      editing: root.profileEditing
      onTextEdited: function(field, value) { root.profileTextEdited(field, value) }
      onBlockToggled: function(block) { root.profileBlockToggled(block) }
      onProfileReset: root.profileReset()
    }
  }
  Component {
    id: aboutPlate
    AboutPlate { version: root.version }
  }
  Component {
    id: creditsPlate
    CreditsPlate {}
  }

  component SmallButton: Rectangle {
    id: button
    property string label: ""
    property bool plate: false
    property bool faint: false
    signal clicked()
    width: buttonText.implicitWidth + 2 * Type.px(14)
    height: Type.px(32)
    radius: 3
    color: plate && !faint ? Ink.bone : buttonHover.containsMouse ? Ink.lineSoft : "transparent"
    border.width: 1
    border.color: plate && !faint ? Ink.bone : faint ? Ink.line : Ink.lineStrong
    Text {
      id: buttonText
      anchors.centerIn: parent
      text: button.label.toUpperCase()
      color: button.plate && !button.faint ? Ink.boneInk : button.faint ? Ink.inkFaint : Ink.ink
      font.family: Type.mono
      font.pixelSize: Type.px(10)
      font.letterSpacing: Type.px(1.8)
    }
    MouseArea {
      id: buttonHover
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: button.clicked()
    }
  }

  // The search field, in the rail or (folded) at the top of the page.
  component SearchField: Rectangle {
    id: field
    property alias input: search
    height: Type.px(36)
    radius: 3
    color: "transparent"
    border.width: 1
    border.color: search.activeFocus ? Ink.lineStrong : Ink.line
    TextInput {
      id: search
      x: Type.px(12)
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width - Type.px(40)
      text: root.query
      color: Ink.ink
      selectionColor: Ink.bone
      selectedTextColor: Ink.boneInk
      font.family: Type.text
      font.pixelSize: Type.px(13)
      clip: true
      onTextEdited: root.queryEdited(text)
      Keys.onEscapePressed: { root.queryEdited(""); focus = false }
      Text {
        visible: !search.text
        text: "Search settings…"
        color: Ink.inkFaint
        font: search.font
      }
    }
    Text {
      anchors.right: parent.right
      anchors.rightMargin: Type.px(12)
      anchors.verticalCenter: parent.verticalCenter
      text: "/"
      color: Ink.inkMuted
      font.family: Type.mono
      font.pixelSize: Type.px(10)
    }
  }
}
