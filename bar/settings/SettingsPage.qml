pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Style.js" as S
import "../../core/Settings.js" as Settings
import "../../core/Kata.js" as K
import "../../core/Leaf.js" as LeafJs
import ".."
import "../scroll"

// Hanko's settings (docs/COMPONENTS.md §6), in the Ryoku Hub grammar: a
// numbered rail on the left, the page on the right, an action bar at the
// foot. Pure QtQuick: bar/SettingsWindow.qml feeds it Typeset's draft and
// live bar data; the harness renders it still.
//
// Typesetting 組版 holds every setting: a live preview of the bar over a
// sample plate, the six presets, and six cards of segmented controls.
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
  // Settings › Design (DesignPage.qml).
  signal designPicked(string name)
  signal borrowPicked(string part, string value)
  signal touchPicked(string key, string value)
  signal surprise()
  signal backToDesign()
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
  // Typesetting, Sheets, Scroll and Presets belong to the Hanko design alone.
  readonly property bool hanko: K.resolve(draft).classic
  readonly property var rail: Settings.rail(hanko)
  readonly property var pageInfo: {
    for (var g = 0; g < rail.length; g++)
      for (var p = 0; p < rail[g].pages.length; p++)
        if (rail[g].pages[p].key === root.page) return { group: rail[g].group, page: rail[g].pages[p] }
    return { group: "01 BAR", page: rail[0].pages[0] }
  }

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
              text: root.draft.sealGlyph || "印"
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
          readonly property var pages: modelData.pages.filter(function(p) { return Settings.pageMatches(p, root.query) || root.query === "" })
          width: parent.width
          visible: pages.length > 0

          Item {
            width: parent.width
            height: Type.px(16) + groupName.height + Type.px(6)
            Text {
              id: groupName
              y: Type.px(16)
              // Folded, a group keeps only its number.
              text: root.compact ? group.modelData.group.replace(/ .*/, "") : group.modelData.group
              color: group.modelData.group === root.pageInfo.group ? Ink.bone : Ink.inkFaint
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

        // Eyebrow: 印 BAR ───── hanko.bar · omarchy
        Item {
          width: parent.width
          height: Type.px(16)
          Row {
            id: eyebrow
            anchors.verticalCenter: parent.verticalCenter
            spacing: Type.px(10)
            Text { anchors.verticalCenter: parent.verticalCenter; text: "印"; color: Ink.seal; font.family: Type.jp; font.pixelSize: Type.px(13) }
            Text {
              anchors.verticalCenter: parent.verticalCenter
              width: Math.min(implicitWidth, pageColumn.width - Type.px(24))
              elide: Text.ElideRight
              text: root.pageInfo.group.replace(/^\d+ /, "") + (root.page === "typesetting" ? " · " + Settings.presetLine(root.draft) : "")
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
        Text {
          text: root.pageInfo.page.label
          color: Ink.ink
          font.family: Type.display
          font.pixelSize: Type.px(root.compact ? 34 : 44)
          font.weight: Font.Normal
          font.variableAxes: Type.axes(Type.px(root.compact ? 34 : 44))
          font.letterSpacing: -0.8
        }
        Item { width: 1; height: Type.px(6) }
        Text {
          width: parent.width
          wrapMode: Text.Wrap
          text: root.page === "typesetting"
            ? "Choose how each part of the bar is set. Every change prints live on your desktop and is kept at once; Undo puts the last one back."
            : root.page === "design"
              ? "Pick the design that draws your bar, then borrow any part from another. Every change prints live and is kept at once."
            : root.page === "presets"
              ? "A preset is a starting point: pick one, then change any single setting on Typesetting."
              : root.placeholders[root.page] || ""
          color: Ink.inkMuted
          font.family: Type.text
          font.pixelSize: Type.row
        }

        // ------------------------------------------------ Design
        DesignPage {
          visible: root.page === "design"
          width: parent.width
          doc: root.draft
          barData: root.barData
          compact: root.compact
          onDesignPicked: function(name) { root.designPicked(name) }
          onBorrowPicked: function(part, value) { root.borrowPicked(part, value) }
          onTouchPicked: function(key, value) { root.touchPicked(key, value) }
          onSurprise: root.surprise()
          onBackToDesign: root.backToDesign()
          onOpacityPicked: function(value) { root.settingPicked("panelOpacity", value) }
        }

        // ------------------------------------------------ Typesetting
        Column {
          visible: root.page === "typesetting"
          width: parent.width

          Item { width: 1; height: Type.px(16) }

          // The live preview: your bar over a sample plate.
          Rectangle {
            width: parent.width
            height: Math.max(Type.px(108), preview.height + Type.px(40) + preview.y)
            radius: 3
            color: "transparent"
            border.width: 1
            border.color: Ink.line
            clip: true
            Plate {
              anchors.fill: parent
              anchors.margins: 1
            }
            Item {
              id: preview
              readonly property int gap: root.style.surface === "inset" ? Type.px(8) : 0
              x: 1 + gap
              y: 1 + gap
              width: parent.width - 2 - 2 * gap
              height: previewBar.height
              PreviewBar {
                id: previewBar
                width: parent.width
                style: root.style
              }
            }
            Text {
              anchors.right: parent.right
              anchors.rightMargin: Type.px(10)
              anchors.bottom: parent.bottom
              anchors.bottomMargin: Type.px(8)
              text: "LIVE PREVIEW · YOUR THEME"
              color: Ink.inkMuted
              font.family: Type.mono
              font.pixelSize: Type.label
              font.letterSpacing: Type.trackLabel
            }
          }

          Item { width: 1; height: Type.px(14) }

          // The six presets; the one in use inverted, `*` when edited. One
          // row of six, or two of three, or three of two on a narrow page.
          Grid {
            id: presetRow
            width: parent.width
            spacing: Type.px(8)
            columns: width >= Type.px(900) ? 6 : width >= Type.px(440) ? 3 : 2
            Repeater {
              model: S.PRESET_NAMES
              Rectangle {
                id: preset
                required property string modelData
                readonly property bool on: modelData === root.draft.preset
                width: (presetRow.width - (presetRow.columns - 1) * presetRow.spacing) / presetRow.columns
                height: presetText.height + 2 * Type.px(10)
                radius: 3
                color: on ? Ink.bone : presetHover.containsMouse ? Ink.lineSoft : "transparent"
                border.width: 1
                border.color: on ? Ink.bone : Ink.line
                Column {
                  id: presetText
                  x: Type.px(12)
                  width: parent.width - 2 * x
                  anchors.verticalCenter: parent.verticalCenter
                  spacing: Type.px(4)
                  Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: preset.modelData.toUpperCase() + (preset.on && root.style.edited ? " *" : "")
                    color: preset.on ? Ink.boneInk : Ink.ink
                    font.family: Type.mono
                    font.pixelSize: Type.px(11)
                    font.weight: Font.Medium
                    font.letterSpacing: Type.px(1.8)
                  }
                  Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: Settings.PRESET_BLURBS[preset.modelData]
                    color: preset.on ? Ink.boneInk : Ink.inkMuted
                    opacity: preset.on ? 0.7 : 1
                    font.family: Type.text
                    font.pixelSize: Type.note
                  }
                }
                MouseArea {
                  id: presetHover
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.presetPicked(preset.modelData)
                }
              }
            }
          }

          Item { width: 1; height: Type.px(14) }

          // Six cards, two rows of three, each row as tall as its tallest;
          // two or one to a row when a card would be too narrow to read.
          Grid {
            id: cards
            width: parent.width
            columns: Math.max(1, Math.min(3, Math.floor((width + spacing) / (Type.px(400) + spacing))))
            spacing: Type.px(12)
            readonly property real cardWidth: (width - (columns - 1) * spacing) / columns

            Repeater {
              id: cardRepeater
              model: Settings.CARDS
              SettingsCard {
                id: settingsCard
                required property var modelData
                required property int index
                width: cards.cardWidth
                height: Math.max(implicitHeight, cards.rowHeight(Math.floor(index / cards.columns)))
                card: modelData
                style: root.style
                options: S.OPTIONS
                query: root.query
                onPicked: function(key, value) { root.settingPicked(key, value) }
              }
            }

            function rowHeight(r) {
              void cardRepeater.count
              var h = 0
              for (var i = r * columns; i < (r + 1) * columns; i++) {
                var c = cardRepeater.itemAt(i) as SettingsCard
                if (c && c.visible) h = Math.max(h, c.implicitHeight)
              }
              return h
            }
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

        // ------------------------------------------------ Presets
        Column {
          visible: root.page === "presets"
          width: parent.width
          topPadding: Type.px(22)
          spacing: Type.px(24)

          Repeater {
            model: S.PRESET_NAMES
            Column {
              id: strip
              required property string modelData
              width: parent.width
              spacing: Type.px(6)
              Row {
                spacing: Type.px(12)
                Text {
                  anchors.baseline: blurbText.baseline
                  text: strip.modelData
                  color: Ink.ink
                  font.family: Type.display
                  font.pixelSize: Type.px(22)
                  font.weight: Font.Normal
                  font.variableAxes: Type.axes(Type.px(22))
                }
                Text {
                  id: blurbText
                  text: Settings.PRESET_BLURBS[strip.modelData].toUpperCase()
                  color: Ink.inkMuted
                  font.family: Type.mono
                  font.pixelSize: Type.label
                  font.letterSpacing: Type.trackLabel
                }
              }
              Rectangle {
                width: parent.width
                height: stripBar.height + 2
                radius: 3
                color: "transparent"
                border.width: 1
                border.color: strip.modelData === root.draft.preset ? Ink.ink : Ink.line
                PreviewBar {
                  id: stripBar
                  x: 1; y: 1
                  width: parent.width - 2
                  style: S.resolve({ preset: strip.modelData, sealGlyph: root.draft.sealGlyph })
                }
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.presetPicked(strip.modelData)
                }
              }
            }
          }
          SmallButton {
            label: "Shuffle · one of " + S.combinations().toLocaleString(Qt.locale("en_US"), "f", 0)
            onClicked: root.shuffle()
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
        SmallButton { visible: root.page === "typesetting"; label: root.compact ? "Reset" : "Reset to preset"; faint: !root.style.edited; onClicked: root.resetToPreset() }
        SmallButton { label: "Undo"; plate: true; faint: root.undoCount === 0; onClicked: if (root.undoCount > 0) root.undo() }
      }
    }
  }

  // Honest words for the rail pages that are still to come.
  readonly property var placeholders: ({
    colour: "Hanko takes every colour from your Omarchy theme: one paper, four inks, one red. There is nothing to pick here yet; switch themes with Omarchy and the bar follows.",
    widgets: "Show or hide anything on the bar: Hanko's own parts, its marks, each tray app, and every Omarchy or third-party widget it hosts. Saved with the rest of your style.",
    sheets: "Sheets drop flush from the cell you click. Choose them under Panels on Typesetting; their own settings come later.",
    scroll: "The handscroll unrolls from the rod. Choose what sits between its panels and what follows Inbox; open panels as a scroll under Panels on Typesetting, and bind a key with omarchy-shell hanko scroll.",
    motion: "No springs, no glow: paper drops with weight and settles, ink arrives after it, and only a new stamp overshoots. Still cuts every move to its end, as Omarchy's own animation switch does.",
    keys: "Esc closes, Tab moves between sheets, H and L pan the scroll, / searches here, Ctrl+Z undoes the last change here. Rebinding comes later."
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

  // A bar on the page, drawn from the live data with a given style. It is
  // laid out at least a desktop's width and scaled down to fit, so a narrow
  // page shows the bar as it looks on a screen instead of a crushed one.
  component PreviewBar: Item {
    id: previewItem
    property var style: ({})
    readonly property real design: Math.max(width, Type.px(1240))
    height: Math.round(surface.implicitHeight * width / design)
    BarSurface {
      id: surface
      width: previewItem.design
      height: implicitHeight
      scale: previewItem.width / previewItem.design
      transformOrigin: Item.TopLeft
      style: previewItem.style
      now: root.barData.now || new Date()
      spaces: root.barData.spaces || []
      activeWindow: root.barData.activeWindow || null
      home: root.barData.home || ""
      media: root.barData.media || null
      timeFormat: root.barData.timeFormat || "HH:mm"
      volume: root.barData.volume || null
      network: root.barData.network || null
      bluetooth: root.barData.bluetooth || null
      battery: root.barData.battery || null
      brightness: root.barData.brightness || null
      notifications: root.barData.notifications || []
      dnd: !!root.barData.dnd
    }
  }
}
