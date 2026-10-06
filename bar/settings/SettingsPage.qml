pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Style.js" as S
import "../../core/Settings.js" as Settings
import ".."

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

  signal settingPicked(string key, string value)
  signal presetPicked(string name)
  signal resetToPreset()
  signal revert()
  signal save()
  signal pagePicked(string key)
  signal queryEdited(string text)
  signal advancedToggled(bool on)
  signal monitorCleared(string name)
  signal shuffle()

  readonly property var style: S.resolve(draft)

  // `/` from the window: put the cursor in the search field.
  function focusSearch() { search.forceActiveFocus() }
  readonly property int changes: Settings.changes(saved, draft, S.resolve)
  readonly property var pageInfo: {
    for (var g = 0; g < Settings.RAIL.length; g++)
      for (var p = 0; p < Settings.RAIL[g].pages.length; p++)
        if (Settings.RAIL[g].pages[p].key === root.page) return { group: Settings.RAIL[g].group, page: Settings.RAIL[g].pages[p] }
    return { group: "01 BAR", page: Settings.RAIL[0].pages[0] }
  }

  color: Ink.paper
  implicitWidth: Type.px(1600)
  implicitHeight: Type.px(900)

  // ================================================================ rail
  Item {
    id: rail
    width: Type.px(268)
    height: parent.height

    Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: Ink.line }

    Column {
      x: Type.px(20)
      y: Type.px(22)
      width: parent.width - 2 * x

      // The masthead: a seal and HANKO //SETTINGS_
      Rectangle {
        width: parent.width
        height: mast.height + 2 * Type.px(14)
        radius: 3
        color: "transparent"
        border.width: 1
        border.color: Ink.lineStrong
        Row {
          id: mast
          x: Type.px(14)
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
            anchors.verticalCenter: parent.verticalCenter
            spacing: Type.px(3)
            Text { text: "HANKO"; color: Ink.ink; font.family: Type.mono; font.pixelSize: Type.px(12); font.weight: Font.Medium; font.letterSpacing: Type.px(2.6) }
            Text { text: "//SETTINGS_"; color: Ink.inkMuted; font.family: Type.mono; font.pixelSize: Type.px(10); font.letterSpacing: Type.px(1.6) }
          }
        }
      }

      Item { width: 1; height: Type.px(16) }

      // Search: filters the rows of the cards and the pages of the rail.
      Rectangle {
        width: parent.width
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
          color: Ink.inkFaint
          font.family: Type.mono
          font.pixelSize: Type.px(10)
        }
      }

      Item { width: 1; height: Type.px(2) }

      Repeater {
        model: Settings.RAIL
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
              text: group.modelData.group
              color: group.modelData.group === root.pageInfo.group ? Ink.inkDim : Ink.inkFaint
              font.family: Type.mono
              font.pixelSize: Type.px(9.5)
              font.letterSpacing: Type.px(2)
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
                  font.pixelSize: Type.px(14.5)
                }
              }
              Text {
                anchors.right: parent.right
                anchors.rightMargin: Type.px(14)
                anchors.verticalCenter: parent.verticalCenter
                text: item.modelData.jp
                color: item.on ? Ink.boneInk : Ink.inkFaint
                font.family: Type.jp
                font.pixelSize: Type.px(12)
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

    // Advanced: the seal glyph, per-monitor overrides and the raw document.
    Item {
      x: Type.px(20)
      width: parent.width - 2 * x
      height: Type.px(50)
      anchors.bottom: parent.bottom
      anchors.bottomMargin: Type.px(8)
      Rectangle { width: parent.width; height: 1; color: Ink.line }
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "ADVANCED"
        color: Ink.ink
        font.family: Type.mono
        font.pixelSize: Type.px(11)
        font.letterSpacing: Type.px(1.6)
      }
      Rectangle {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: Type.px(34)
        height: Type.px(18)
        radius: height / 2
        color: root.advanced ? Ink.alpha(Ink.ink, 0.14) : "transparent"
        border.width: 1
        border.color: Ink.lineStrong
        Rectangle {
          x: root.advanced ? parent.width - width - Type.px(3) : Type.px(3)
          anchors.verticalCenter: parent.verticalCenter
          width: Type.px(10)
          height: width
          radius: width / 2
          color: root.advanced ? Ink.ink : Ink.inkFaint
          Behavior on x { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
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

    Flickable {
      id: scroller
      width: parent.width
      height: parent.height - actions.height
      contentHeight: pageColumn.height + Type.px(40)
      clip: true
      boundsBehavior: Flickable.StopAtBounds

      Column {
        id: pageColumn
        x: Type.px(32)
        y: Type.px(26)
        width: scroller.width - 2 * x
        spacing: 0

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
              text: root.pageInfo.group.replace(/^\d+ /, "") + (root.page === "typesetting" ? " · " + Settings.presetLine(root.draft) : "")
              color: Ink.inkMuted
              font.family: Type.mono
              font.pixelSize: Type.px(10)
              font.letterSpacing: Type.px(2.2)
              font.capitalization: Font.AllUppercase
            }
          }
          Text {
            id: where
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: "hanko.bar · omarchy"
            color: Ink.inkMuted
            font.family: Type.mono
            font.pixelSize: Type.px(10)
            font.letterSpacing: Type.px(2.2)
          }
          Rectangle {
            x: eyebrow.width + Type.px(10)
            anchors.verticalCenter: parent.verticalCenter
            width: where.x - x - Type.px(10)
            height: 1
            color: Ink.lineSoft
          }
        }

        Item { width: 1; height: Type.px(10) }
        Text {
          text: root.pageInfo.page.label
          color: Ink.ink
          font.family: Type.display
          font.pixelSize: Type.px(44)
          font.weight: Font.Normal
          font.variableAxes: { "opsz": 144, "wght": 400 }
          font.letterSpacing: -0.8
        }
        Item { width: 1; height: Type.px(6) }
        Text {
          width: parent.width
          wrapMode: Text.Wrap
          text: root.page === "typesetting"
            ? "Choose how each part of the bar is set. Every change prints live on your desktop; Save keeps it."
            : root.page === "presets"
              ? "A preset is a starting point: pick one, then change any single setting on Typesetting."
              : root.placeholders[root.page] || ""
          color: Ink.inkMuted
          font.family: Type.text
          font.pixelSize: Type.px(13.5)
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
              color: Ink.inkFaint
              font.family: Type.mono
              font.pixelSize: Type.px(8.5)
              font.letterSpacing: Type.px(1.8)
            }
          }

          Item { width: 1; height: Type.px(14) }

          // The six presets; the one in use inverted, `*` when edited.
          Row {
            id: presetRow
            width: parent.width
            spacing: Type.px(8)
            Repeater {
              model: S.PRESET_NAMES
              Rectangle {
                id: preset
                required property string modelData
                readonly property bool on: modelData === root.draft.preset
                width: (presetRow.width - 5 * presetRow.spacing) / 6
                height: presetText.height + 2 * Type.px(10)
                radius: 3
                color: on ? Ink.bone : presetHover.containsMouse ? Ink.lineSoft : "transparent"
                border.width: 1
                border.color: on ? Ink.bone : Ink.line
                Column {
                  id: presetText
                  x: Type.px(12)
                  anchors.verticalCenter: parent.verticalCenter
                  spacing: Type.px(4)
                  Text {
                    text: preset.modelData.toUpperCase() + (preset.on && root.style.edited ? " *" : "")
                    color: preset.on ? Ink.boneInk : Ink.ink
                    font.family: Type.mono
                    font.pixelSize: Type.px(11)
                    font.weight: Font.Medium
                    font.letterSpacing: Type.px(1.8)
                  }
                  Text {
                    text: Settings.PRESET_BLURBS[preset.modelData]
                    color: preset.on ? Ink.boneInk : Ink.inkMuted
                    opacity: preset.on ? 0.7 : 1
                    font.family: Type.text
                    font.pixelSize: Type.px(11)
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

          // Six cards, two rows of three, each row as tall as its tallest.
          Grid {
            id: cards
            width: parent.width
            columns: 3
            spacing: Type.px(12)
            readonly property real cardWidth: (width - 2 * spacing) / 3
            property var heights: [0, 0]

            Repeater {
              id: cardRepeater
              model: Settings.CARDS
              SettingsCard {
                id: settingsCard
                required property var modelData
                required property int index
                width: cards.cardWidth
                height: Math.max(implicitHeight, cards.rowHeight(Math.floor(index / 3)))
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
              for (var i = r * 3; i < r * 3 + 3; i++) {
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
                  Text { text: "//"; color: Ink.inkFaint; font.family: Type.mono; font.pixelSize: Type.px(10); font.letterSpacing: Type.px(2) }
                  Text { text: "ADVANCED"; color: Ink.inkDim; font.family: Type.mono; font.pixelSize: Type.px(10); font.letterSpacing: Type.px(2) }
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
                    font.pixelSize: Type.px(13.5)
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
                    text: "One character, used when the seal is a stamp."
                    color: Ink.inkMuted
                    font.family: Type.text
                    font.pixelSize: Type.px(11)
                  }
                }

                // Per-monitor overrides (set them with `hanko style set --monitor`).
                Repeater {
                  model: root.monitors
                  Row {
                    id: mon
                    required property string modelData
                    readonly property var own: root.draft.monitors[modelData] || ({})
                    spacing: Type.px(14)
                    Text {
                      anchors.verticalCenter: parent.verticalCenter
                      width: Type.px(160)
                      text: "Monitor " + mon.modelData
                      color: Ink.ink
                      font.family: Type.text
                      font.pixelSize: Type.px(13.5)
                    }
                    Text {
                      anchors.verticalCenter: parent.verticalCenter
                      text: Object.keys(mon.own).length
                        ? Object.keys(mon.own).map(function(k) { return k + " " + mon.own[k] }).join(" · ")
                        : "as the rest"
                      color: Ink.inkDim
                      font.family: Type.mono
                      font.pixelSize: Type.px(10)
                      font.letterSpacing: 1
                    }
                    SmallButton {
                      visible: Object.keys(mon.own).length > 0
                      label: "Clear"
                      onClicked: root.monitorCleared(mon.modelData)
                    }
                  }
                }

                // The document Save would write.
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
                  font.variableAxes: { "opsz": 36, "wght": 400 }
                }
                Text {
                  id: blurbText
                  text: Settings.PRESET_BLURBS[strip.modelData].toUpperCase()
                  color: Ink.inkFaint
                  font.family: Type.mono
                  font.pixelSize: Type.px(9)
                  font.letterSpacing: Type.px(1.8)
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
            label: "Shuffle · one of 2,985,984"
            onClicked: root.shuffle()
          }
        }
      }
    }

    // ------------------------------------------------ action bar
    Item {
      id: actions
      anchors.bottom: parent.bottom
      width: parent.width
      height: Type.px(56)
      Rectangle { width: parent.width; height: 1; color: Ink.line }
      Row {
        x: Type.px(32)
        anchors.verticalCenter: parent.verticalCenter
        spacing: Type.px(12)
        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: Type.px(7); height: width; color: root.changes ? Ink.ink : Ink.inkFaint }
        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: Settings.status(root.changes).toUpperCase()
          color: Ink.inkDim
          font.family: Type.mono
          font.pixelSize: Type.px(10)
          font.letterSpacing: Type.px(1.8)
        }
      }
      Row {
        anchors.right: parent.right
        anchors.rightMargin: Type.px(32)
        anchors.verticalCenter: parent.verticalCenter
        spacing: Type.px(12)
        SmallButton { label: "Reset to preset"; faint: !root.style.edited; onClicked: root.resetToPreset() }
        SmallButton { label: "Revert"; faint: root.changes === 0; onClicked: root.revert() }
        SmallButton { label: "Save"; plate: true; faint: root.changes === 0; onClicked: root.save() }
      }
    }
  }

  // Honest words for the rail pages that are still to come.
  readonly property var placeholders: ({
    colour: "Hanko takes every colour from your Omarchy theme: one paper, four inks, one red. There is nothing to pick here yet; switch themes with Omarchy and the bar follows.",
    widgets: "Third-party bar widgets and the tray, drawn in Hanko's ink. Coming with Phase 9.",
    sheets: "Sheets drop flush from the cell you click. Choose them under Panels on Typesetting; their own settings come later.",
    scroll: "The handscroll unrolls from the rod. Choose it under Panels on Typesetting; bind a key with omarchy-shell hanko scroll.",
    motion: "Hanko follows Omarchy's animation switch: with animations off, every move cuts to its end. A switch of its own comes with Phase 10.",
    keys: "Esc closes, Tab moves between sheets, H and L pan the scroll, / searches here, Ctrl+S saves. Rebinding comes later."
  })

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

  // A bar on the page, drawn from the live data with a given style.
  component PreviewBar: BarSurface {
    height: implicitHeight
    now: root.barData.now || new Date()
    spaces: root.barData.spaces || []
    activeWindow: root.barData.activeWindow || null
    home: root.barData.home || ""
    media: root.barData.media || null
    timeFormat: root.barData.timeFormat || "HH:mm"
    volume: root.barData.volume || null
    network: root.barData.network || null
    battery: root.barData.battery || null
    brightness: root.barData.brightness || null
    notifications: root.barData.notifications || []
    dnd: !!root.barData.dnd
  }
}
