pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Style.js" as S
import "../../core/Settings.js" as Settings
import ".."

// Hanko's settings (docs/COMPONENTS.md §6; docs/settings-kosei): a numbered
// rail on the left, the open page on the right, an action bar at the foot.
// Every page is its own file, built only while it is open, and keeps one
// rule: the thing itself first, pictures of its choices second, words last.
// Pure QtQuick: bar/SettingsWindow.qml feeds it Typeset's draft and live
// bar data; the harness renders it still.
Rectangle {
  id: root

  // The draft document and what is saved (style.json shapes).
  property var draft: S.normalize({})
  property var saved: S.normalize({})
  // Rail page key (Settings.RAIL; old keys through PAGE_ALIASES).
  property string page: "typesetting"
  readonly property string pageKey: Settings.pageInfo(page).page.key
  property string query: ""
  // Screen names, and the screens with their geometry (Screens 画面).
  property var monitors: []
  property var screens: []
  // Live data for the bars drawn here: { now, spaces, activeWindow, home,
  // media, volume, network, bluetooth, battery, brightness, notifications,
  // dnd, timeFormat, indicators, screenWidth }.
  property var barData: ({})
  // The sheets' plain data, for the Sheets page's live preview.
  property var sheetFeed: ({})
  // Omarchy's themes and the one in use (Colour 色): [{ slug, name, bg, fg, red, light }].
  property var themes: []
  property string theme: ""
  // For the plates: services/Machine.qml info, core/Dossier.qml doc, the
  // plugin's version and where Profile saves an image.
  property var machine: ({ user: "", host: "", kernel: "", uptime: 0, theme: "", omarchy: "", hyprland: "", packages: 0, since: "", machine: "" })
  property var profile: ({ name: "", tagline: "", hidden: [] })
  property string version: ""
  property string picturesDir: ""
  // Opens Profile in EDIT (the harness).
  property bool profileEditing: false
  readonly property bool onPlate: Settings.PLATES.indexOf(pageKey) >= 0
  // What the Parts page lists besides Hanko's own parts
  // (Settings.visibilityCards ctx: own, indicators, tray, hosted).
  property var visibility: ({})
  // How many changes Undo can walk back, and the last one in words.
  property int undoCount: 0
  property string lastChange: ""
  // Kaze 風: kaze.json, and whether the desk and Sumi are on (services/Kaze.qml).
  property var kaze: ({})
  property bool kazeDesk: false
  property bool kazeSumi: false
  property string kazeBusy: ""

  signal settingPicked(string key, string value)
  signal presetPicked(string name)
  signal resetToPreset()
  signal undo()
  signal pagePicked(string key)
  signal queryEdited(string text)
  signal monitorCleared(string name)
  signal monitorPicked(string monitor, string key, string value)
  signal shuffle()
  signal showAll()
  signal themePicked(string slug)
  // Keys: a binding to put on the clipboard.
  signal copyText(string text)
  signal kazePicked(string key, string value)
  signal deskPicked(bool on)
  signal sumiPicked(bool on)
  signal windSpeedPicked(int speed)
  // Profile 印影 (core/Dossier.qml): field name | tagline; block ids from
  // core/Profile.js BLOCKS.
  signal profileTextEdited(string field, string value)
  signal profileBlockToggled(string block)
  signal profileReset()

  readonly property var style: S.resolve(draft)

  // ------------------------------------------------- Typesetting's proof
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
  readonly property var litParts: String(query).trim() === "" ? []
    : Settings.PROOF.filter(function(p) { return Settings.proofMatches(p, root.query, S.OPTIONS) }).map(function(p) { return p.key })
  readonly property string partShown: litParts.length && litParts.indexOf(part) < 0 ? litParts[0] : part
  readonly property var editedParts: Settings.PROOF.filter(function(p) { return Settings.proofEdits(p, root.draft).length > 0 }).map(function(p) { return p.key })
  // The bar data, with indicators to show: yours when any is on, else two
  // lit, so the part has a face.
  readonly property var proofData: {
    var d = Object.assign({}, barData)
    var inds = barData.indicators || []
    var anyOn = false
    for (var i = 0; i < inds.length; i++) if (inds[i].on) anyOn = true
    if (!anyOn) d.indicators = Settings.SAMPLE_INDICATORS
    return d
  }

  // Presets: the pattern open in the book ("" = the one in use).
  property string presetView: ""
  // Screens: the one picked (the first by default).
  property string overrideMonitor: ""

  // Scroll the page to its foot, as the harness does.
  function scrollToEnd() { scroller.contentY = Math.max(0, scroller.contentHeight - scroller.height) }
  // `/` from the window: put the cursor in the search field.
  function focusSearch() { (compact ? pageSearch : railSearch).input.forceActiveFocus() }
  readonly property var rail: Settings.RAIL
  readonly property var pageInfo: Settings.pageInfo(root.page)

  color: Ink.paper
  implicitWidth: Type.px(1600)
  implicitHeight: Type.px(900)

  // The window can be any size, so the page reflows: the rail narrows, then
  // folds to its glyphs with the search moving onto the page.
  readonly property bool compact: width < Type.px(760)
  readonly property int pad: compact ? Type.px(16) : Type.px(32)

  // ================================================================ rail
  Item {
    id: rail
    width: root.compact ? Type.px(60) : root.width < Type.px(1100) ? Type.px(224) : Type.px(268)
    height: parent.height

    Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: Ink.line }

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

        // The masthead: your seal and HANKO //SETTINGS_
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
                readonly property bool on: modelData.key === root.pageKey
                width: group.width
                height: Type.px(38)
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

    // The foot: the keys that work everywhere here.
    Item {
      id: railFoot
      x: root.compact ? Type.px(8) : Type.px(20)
      width: parent.width - 2 * x
      height: root.compact ? Type.px(8) : footKeys.height + Type.px(22)
      anchors.bottom: parent.bottom
      anchors.bottomMargin: Type.px(8)
      Rectangle { width: parent.width; height: 1; color: Ink.line; visible: !root.compact }
      Grid {
        id: footKeys
        visible: !root.compact
        y: Type.px(14)
        columns: 2
        columnSpacing: Type.px(10)
        rowSpacing: Type.px(6)
        Repeater {
          model: [["/", "search"], ["CTRL Z", "undo"], ["ESC", "close"], ["← →", "parts, on the proof"]]
          Row {
            id: hint
            required property var modelData
            spacing: Type.px(8)
            Rectangle {
              width: Math.max(Type.px(22), keyCap.implicitWidth + Type.px(10))
              height: Type.px(18)
              radius: 2
              color: "transparent"
              border.width: 1
              border.color: Ink.line
              Text { id: keyCap; anchors.centerIn: parent; text: hint.modelData[0]; color: Ink.inkDim; font.family: Type.mono; font.pixelSize: Type.tag; font.letterSpacing: 1 }
            }
            Text { anchors.verticalCenter: parent.verticalCenter; text: hint.modelData[1]; color: Ink.inkMuted; font.family: Type.text; font.pixelSize: Type.note }
          }
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
      sourceComponent: root.pageKey === "profile" ? profilePlate : root.pageKey === "about" ? aboutPlate : creditsPlate
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

        // Eyebrow: 鑑 BAR · PRESET · MA + EDITS ───── hanko.bar · omarchy
        Item {
          width: parent.width
          height: Type.px(16)
          Row {
            id: eyebrow
            anchors.verticalCenter: parent.verticalCenter
            spacing: Type.px(10)
            Text { anchors.verticalCenter: parent.verticalCenter; text: root.draft.sealGlyph || "鑑"; color: Ink.seal; font.family: Type.jp; font.pixelSize: Type.px(13) }
            Text {
              anchors.verticalCenter: parent.verticalCenter
              width: Math.min(implicitWidth, pageColumn.width - Type.px(24))
              elide: Text.ElideRight
              text: root.pageInfo.group.replace(/^\d+ /, "") + " · " + root.pageInfo.page.jp
                + (root.pageKey === "typesetting" || root.pageKey === "presets" ? " · " + Settings.presetLine(root.draft) : "")
              color: Ink.inkMuted
              font.family: Type.mono
              font.pixelSize: Type.eyebrow
              font.letterSpacing: Type.trackEyebrow
              font.capitalization: Font.AllUppercase
            }
          }
          Text {
            id: where
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
            visible: root.pageKey === "typesetting" && !root.compact
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
          width: Math.min(parent.width, Type.px(900))
          wrapMode: Text.Wrap
          text: Settings.PAGE_LINES[root.pageKey] || ""
          color: Ink.inkMuted
          font.family: Type.text
          font.pixelSize: Type.row
          lineHeight: 1.1
        }

        // The page itself, built only while it is open.
        Loader {
          id: pageLoader
          width: parent.width
          active: !root.onPlate
          sourceComponent: ({
            typesetting: typesettingPage, presets: presetsPage, parts: partsPage,
            colour: colourPage, screens: screensPage, sheets: sheetsPage,
            scroll: scrollPage, overview: overviewPage, motion: motionPage, keys: keysPage, kaze: kazePage
          })[root.pageKey] || typesettingPage
        }
      }
    }

    // ------------------------------------------------ action bar
    // Left, what was last kept, in words; right, what you can do about it.
    Item {
      id: actions
      visible: !root.onPlate || root.undoCount > 0
      anchors.bottom: parent.bottom
      width: parent.width
      height: Type.px(56)
      Rectangle { width: parent.width; height: 1; color: Ink.line }
      Row {
        x: root.pad
        anchors.verticalCenter: parent.verticalCenter
        spacing: Type.px(12)
        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: Type.px(7); height: width; color: root.lastChange !== "" ? Ink.seal : Ink.inkFaint }
        Text {
          anchors.verticalCenter: parent.verticalCenter
          width: Math.max(0, Math.min(implicitWidth, buttons.x - root.pad - Type.px(7 + 12 + 16)))
          elide: Text.ElideRight
          textFormat: Text.StyledText
          text: root.lastChange !== ""
            ? "KEPT · <font color=\"" + Ink.ink + "\">" + root.lastChange.replace(/&/g, "&amp;").replace(/</g, "&lt;").toUpperCase() + "</font>"
              + (root.undoCount > 1 ? " · " + root.undoCount + " TO UNDO" : "")
            : Settings.status(root.undoCount).toUpperCase()
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
        SmallButton { visible: root.pageKey === "presets"; label: "Shuffle"; onClicked: root.shuffle() }
        SmallButton { visible: root.pageKey === "parts"; label: "Show all"; faint: (root.draft.hidden || []).length === 0; onClicked: root.showAll() }
        SmallButton { visible: root.pageKey === "typesetting" || root.pageKey === "presets"; label: root.compact ? "Reset" : "Reset to preset"; faint: !root.style.edited; onClicked: root.resetToPreset() }
        SmallButton { label: "Undo"; plate: true; faint: root.undoCount === 0; onClicked: if (root.undoCount > 0) root.undo() }
      }
    }
  }

  // ================================================================ pages
  Component {
    id: typesettingPage
    TypesettingPage {
      draft: root.draft
      style: root.style
      barData: root.proofData
      query: root.query
      compact: root.compact
      part: root.partShown
      lit: root.litParts
      edited: root.editedParts
      proofStyle: root.proofStyle
      onSettingPicked: function(key, value) { root.settingPicked(key, value) }
      onPartPicked: function(key) { root.partPicked(key) }
      onTried: function(key, value) { root.trial = { key: key, value: value } }
      onUntried: root.trial = null
    }
  }
  Component {
    id: presetsPage
    PresetsPage {
      viewed: root.presetView
      onViewedChanged: root.presetView = viewed
      doc: root.draft
      barData: root.barData
      query: root.query
      compact: root.compact
      onPresetPicked: function(name) { root.presetPicked(name) }
    }
  }
  Component {
    id: partsPage
    PartsPage {
      barData: root.proofData
      style: root.style
      draft: root.draft
      query: root.query
      compact: root.compact
      visibility: root.visibility
      onSettingPicked: function(key, value) { root.settingPicked(key, value) }
      onShowAll: root.showAll()
    }
  }
  Component {
    id: screensPage
    ScreensPage {
      draft: root.draft
      screens: root.screens
      monitor: root.overrideMonitor
      compact: root.compact
      onMonitorSelected: function(name) { root.overrideMonitor = name }
      onMonitorPicked: function(monitor, key, value) { root.monitorPicked(monitor, key, value) }
      onMonitorCleared: function(name) { root.monitorCleared(name) }
    }
  }
  Component {
    id: sheetsPage
    SheetsPage {
      doc: root.draft
      feed: root.sheetFeed
      compact: root.compact
      onStylePicked: function(sheet, style) { root.settingPicked("sheetStyle:" + sheet, style) }
      onOpacityPicked: function(value) { root.settingPicked("panelOpacity", value) }
    }
  }
  Component {
    id: scrollPage
    ScrollPage {
      style: root.style
      draft: root.draft
      query: root.query
      compact: root.compact
      onSettingPicked: function(key, value) { root.settingPicked(key, value) }
    }
  }
  Component {
    id: motionPage
    MotionPage {
      style: root.style
      draft: root.draft
      compact: root.compact
      onSettingPicked: function(key, value) { root.settingPicked(key, value) }
    }
  }
  Component {
    id: colourPage
    ColourPage {
      themes: root.themes
      theme: root.theme
      glyph: root.draft.sealGlyph || "鑑"
      compact: root.compact
      onThemePicked: function(slug) { root.themePicked(slug) }
    }
  }
  Component {
    id: overviewPage
    OverviewSettings {
      style: root.style
      barData: root.barData
      compact: root.compact
      onSettingPicked: function(key, value) { root.settingPicked(key, value) }
    }
  }
  Component {
    id: kazePage
    KazePage {
      draft: root.draft
      kaze: root.kaze
      desk: root.kazeDesk
      sumi: root.kazeSumi
      busy: root.kazeBusy
      compact: root.compact
      onSettingPicked: function(key, value) { root.settingPicked(key, value) }
      onKazePicked: function(key, value) { root.kazePicked(key, value) }
      onDeskPicked: function(on) { root.deskPicked(on) }
      onSumiPicked: function(on) { root.sumiPicked(on) }
      onWindSpeedPicked: function(speed) { root.windSpeedPicked(speed) }
    }
  }
  Component {
    id: keysPage
    KeysPage {
      compact: root.compact
      onCopyText: function(text) { root.copyText(text) }
    }
  }

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
  Component { id: aboutPlate; AboutPlate { version: root.version } }
  Component { id: creditsPlate; CreditsPlate {} }

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
