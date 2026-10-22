pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Settings.js" as Settings
import "../../core/Wind.js" as Wind

// Settings › Kaze 風 (docs/kaze, mockup 14): the desk beyond the bar, one
// card per switch, each a small picture of what it does over its words. The
// desk itself, Sumi and the three tools after them (the brush cursor, btop
// and Neovim, the Hanko theme) run the `hanko` CLI; motion is style.json's;
// the rest are kaze.json's, kept at once (Undo puts them back). Turning the desk on
// can restart the shell (when its parts are new), so On asks for a second
// click; Off never does, and goes at once.
Column {
  id: root

  property var draft: ({})
  property var kaze: ({})
  property bool desk: false
  property bool sumi: false
  // The tools beside the desk: { cursor, tools, theme }, true when on (the
  // boot screen is in the same object, but has a page of its own, Boot).
  property var tools: ({ cursor: false, tools: false, theme: false })
  readonly property var toolKeys: ["cursor", "tools", "theme"]
  // The brush cursor's size in pixels (16 to 48).
  property int cursorSize: 22
  property string busy: ""
  property bool compact: false

  signal settingPicked(string key, string value)
  signal kazePicked(string key, string value)
  signal deskPicked(bool on)
  signal sumiPicked(bool on)
  signal toolPicked(string key, bool on)
  // The virtual wind's speed, km/h (one drag is one step of Undo).
  signal windSpeedPicked(int speed)
  signal cursorSizePicked(int size)

  readonly property var wind: Settings.kazeWind(kaze)

  readonly property bool still: (draft.motion || "paper") === "still"
  readonly property var count: Settings.kazeOn(kaze, desk, still, sumi, { cursor: !!tools.cursor, tools: !!tools.tools, theme: !!tools.theme })
  readonly property int columns: compact ? 2 : 4
  readonly property real gap: Type.px(10)
  readonly property real cardWidth: (width - (columns - 1) * gap) / columns

  // The desk's On waiting for its second click ("on" | ""); long enough to
  // read the warning before it lapses.
  property string armed: ""
  Timer { id: disarm; interval: 10000; onTriggered: root.armed = "" }

  function value(key) {
    if (key === "desk") return desk ? "on" : "off"
    if (key === "motion") return still ? "still" : "paper"
    if (key === "sumi") return sumi ? "on" : "off"
    if (toolKeys.indexOf(key) >= 0) return tools[key] ? "on" : "off"
    return Settings.kazeValue(kaze, key)
  }
  function pick(key, v) {
    if (v === value(key)) { if (key === "desk") armed = ""; return }
    if (key === "desk") {
      if (v === "on" && armed !== v) { armed = v; disarm.restart(); return }
      armed = ""
      deskPicked(v === "on")
    }
    else if (key === "motion") settingPicked("motion", v)
    else if (key === "sumi") sumiPicked(v === "on")
    else if (toolKeys.indexOf(key) >= 0) toolPicked(key, v === "on")
    else kazePicked(key, v)
  }

  readonly property var cards: [
    { key: "desk", name: "Desk", jp: "風", line: "Windows, the print, the OSD, letters, the menu, the lock",
      options: ["on", "off"], labels: { on: "On", off: "Off" } },
    { key: "motion", name: "Motion", jp: "居合", line: "Draw, cut, sheathe: every move on Iai's beats",
      options: ["paper", "still"], labels: { paper: "Iai", still: "Still" } }
  ].concat(Settings.KAZE_SWITCHES).concat([
    { key: "sumi", name: "Sumi", jp: "墨", line: "The screen in ink, your red kept, letters held, the bar riding",
      options: ["on", "off"], labels: { on: "On", off: "Off" } },
    { key: "cursor", name: "Cursor", jp: "筆", line: "A brush-tip pointer in your theme's ink, red only for not-allowed",
      options: ["on", "off"], labels: { on: "On", off: "Off" } },
    { key: "tools", name: "Tools", jp: "道具", line: "btop and Neovim on the same paper and inks",
      options: ["on", "off"], labels: { on: "On", off: "Off" } },
    { key: "theme", name: "Theme", jp: "判子", line: "The Hanko theme for all of Omarchy; Off goes back to yours",
      options: ["on", "off"], labels: { on: "On", off: "Off" } }
  ])

  width: parent ? parent.width : 0
  spacing: 0
  topPadding: Type.px(22)

  SectionLabel { jp: "風"; text: "Desk · " + root.count.on + " of " + root.count.of + " on · a click on a word keeps it" }
  Item { width: 1; height: Type.px(12) }

  Grid {
    columns: root.columns
    spacing: root.gap
    Repeater {
      model: root.cards
      Rectangle {
        id: card
        required property var modelData
        readonly property string key: modelData.key
        readonly property string current: root.value(key)
        readonly property bool lit: current !== "off" && current !== "original" && current !== "calm" && current !== "still"
        readonly property bool hovered: cardHover.hovered
        width: root.cardWidth
        height: stage.height + words.height + 2
        radius: 3
        color: "transparent"
        border.width: 1
        border.color: card.hovered ? Ink.lineStrong : Ink.line
        clip: true

        HoverHandler { id: cardHover }

        // ------------------------------------------------ the picture
        Item {
          id: stage
          x: 1; y: 1
          width: card.width - 2
          height: Type.px(92)
          clip: true
          opacity: card.lit ? 1 : 0.32
          Behavior on opacity { enabled: Motion.live; NumberAnimation { duration: Motion.nuki; easing.type: Easing.OutCubic } }

          Loader {
            anchors.fill: parent
            sourceComponent: ({ desk: deskArt, motion: motionArt, wallpaper: printArt, grass: grassArt,
                                gusts: grassArt, wind: windArt, sound: soundArt, sumi: sumiArt, osdCard: osdArt,
                                cursor: cursorArt, tools: toolsArt, theme: themeArt })[card.key] || null
            onLoaded: {
              item.key = card.key
              item.current = Qt.binding(function() { return card.current })
              item.hovered = Qt.binding(function() { return card.hovered })
            }
          }
          Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Ink.lineSoft }
        }

        // ------------------------------------------------ the words
        Column {
          id: words
          x: Type.px(10)
          y: stage.y + stage.height + Type.px(9)
          width: card.width - 2 * x
          spacing: Type.px(6)
          bottomPadding: Type.px(10)
          Row {
            spacing: Type.px(6)
            Text {
              id: cardName
              text: card.modelData.name
              color: Ink.ink
              font.family: Type.text
              font.pixelSize: Type.px(14)
              font.weight: Font.Medium
              font.variableAxes: Type.valueAxes
            }
            Text { anchors.baseline: cardName.baseline; text: card.modelData.jp; color: Ink.inkMuted; font.family: Type.jp; font.pixelSize: Type.px(13) }
          }
          // Two lines, always, so the switches line up along a row.
          Item {
            width: parent.width
            height: Math.ceil(lineMetrics.lineSpacing * 2) + 2
            FontMetrics { id: lineMetrics; font.family: Type.text; font.pixelSize: Type.note }
            Text {
              visible: !(card.key === "wind" && card.current === "virtual") && !(card.key === "cursor" && card.current === "on")
              width: parent.width
              wrapMode: Text.WordWrap
              maximumLineCount: 2
              elide: Text.ElideRight
              readonly property bool warn: card.key === "desk" && root.armed !== ""
              text: card.key === root.busy ? "Working…"
                : warn ? "May restart the shell and close this window. Click On again."
                : card.modelData.line
              color: warn ? Ink.seal : Ink.inkMuted
              font.family: Type.text
              font.pixelSize: Type.note
            }
            // Wind on Virtual: your own speed, dragged or scrolled along a
            // hairline (0 to 60 km/h), and the side it blows from.
            Row {
              visible: card.key === "wind" && card.current === "virtual"
              anchors.verticalCenter: parent.verticalCenter
              width: parent.width
              spacing: Type.px(8)
              Item {
                id: speedRule
                width: parent.width - speedFigure.width - sideSwitch.width - 2 * parent.spacing
                height: Type.px(22)
                readonly property real share: root.wind.speed / Settings.KAZE_WIND_MAX
                function pickAt(x) { root.windSpeedPicked(Math.round(Math.max(0, Math.min(1, x / width)) * Settings.KAZE_WIND_MAX)) }
                // Ticks every 10 km/h, the run of the wind in ink.
                Repeater {
                  model: 7
                  Rectangle {
                    required property int index
                    x: Math.round(index * (speedRule.width - 1) / 6)
                    y: speedRule.height / 2 + Type.px(3)
                    width: 1; height: Type.px(index % 3 === 0 ? 5 : 3)
                    color: Ink.inkFaint
                  }
                }
                Rectangle { y: speedRule.height / 2; width: parent.width; height: 1; color: Ink.line }
                Rectangle {
                  y: speedRule.height / 2 - 1
                  width: Math.max(1, speedRule.share * parent.width)
                  height: 3
                  color: Ink.ink
                }
                Rectangle {
                  x: speedRule.share * (parent.width - width)
                  y: speedRule.height / 2 - height / 2 + 0.5
                  width: Type.px(3); height: Type.px(13)
                  color: Ink.bone
                }
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  preventStealing: true
                  // Te 手 (bar/parts/KeyCursor.qml): Left/Right set the wind.
                  readonly property bool keyStop: true
                  readonly property bool keyStep: true
                  function keyAdjust(d) { root.windSpeedPicked(Math.max(0, Math.min(Settings.KAZE_WIND_MAX, root.wind.speed + d))) }
                  onPressed: function(m) { speedRule.pickAt(m.x) }
                  onPositionChanged: function(m) { if (pressed) speedRule.pickAt(m.x) }
                  onWheel: function(w) {
                    root.windSpeedPicked(Math.max(0, Math.min(Settings.KAZE_WIND_MAX, root.wind.speed + (w.angleDelta.y > 0 ? 1 : -1))))
                  }
                }
              }
              Text {
                id: speedFigure
                anchors.verticalCenter: parent.verticalCenter
                width: Type.px(56)
                horizontalAlignment: Text.AlignRight
                text: root.wind.speed + "<font color=\"" + Ink.inkMuted + "\"> km/h</font>"
                textFormat: Text.StyledText
                color: Ink.ink
                font.family: Type.mono
                font.pixelSize: Type.label
                font.features: { "tnum": 1 }
              }
              Segmented {
                id: sideSwitch
                anchors.verticalCenter: parent.verticalCenter
                options: ["east", "west"]
                labels: ({ east: "←", west: "→" })
                selected: root.wind.from
                onPicked: function(v) { root.kazePicked("windFrom", v) }
              }
            }
            // Cursor on: its size, dragged or scrolled along a hairline
            // (16 to 48 px), a tick every 8.
            Row {
              visible: card.key === "cursor" && card.current === "on"
              anchors.verticalCenter: parent.verticalCenter
              width: parent.width
              spacing: Type.px(8)
              Item {
                id: sizeRule
                width: parent.width - sizeFigure.width - parent.spacing
                height: Type.px(22)
                readonly property int low: 16
                readonly property int high: 48
                readonly property real share: (root.cursorSize - low) / (high - low)
                function pick(px) { root.cursorSizePicked(Math.max(low, Math.min(high, px))) }
                function pickAt(x) { pick(Math.round(low + Math.max(0, Math.min(1, x / width)) * (high - low))) }
                Repeater {
                  model: 5
                  Rectangle {
                    required property int index
                    x: Math.round(index * (sizeRule.width - 1) / 4)
                    y: sizeRule.height / 2 + Type.px(3)
                    width: 1; height: Type.px(index % 2 === 0 ? 5 : 3)
                    color: Ink.inkFaint
                  }
                }
                Rectangle { y: sizeRule.height / 2; width: parent.width; height: 1; color: Ink.line }
                Rectangle {
                  y: sizeRule.height / 2 - 1
                  width: Math.max(1, sizeRule.share * parent.width)
                  height: 3
                  color: Ink.ink
                }
                Rectangle {
                  x: sizeRule.share * (parent.width - width)
                  y: sizeRule.height / 2 - height / 2 + 0.5
                  width: Type.px(3); height: Type.px(13)
                  color: Ink.bone
                }
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  preventStealing: true
                  // Te 手 (bar/parts/KeyCursor.qml): Left/Right set the size.
                  readonly property bool keyStop: true
                  readonly property bool keyStep: true
                  function keyAdjust(d) { sizeRule.pick(root.cursorSize + d) }
                  onPressed: function(m) { sizeRule.pickAt(m.x) }
                  onPositionChanged: function(m) { if (pressed) sizeRule.pickAt(m.x) }
                  onWheel: function(w) { sizeRule.pick(root.cursorSize + (w.angleDelta.y > 0 ? 1 : -1)) }
                }
              }
              Text {
                id: sizeFigure
                anchors.verticalCenter: parent.verticalCenter
                width: Type.px(48)
                horizontalAlignment: Text.AlignRight
                text: root.cursorSize + "<font color=\"" + Ink.inkMuted + "\"> px</font>"
                textFormat: Text.StyledText
                color: Ink.ink
                font.family: Type.mono
                font.pixelSize: Type.label
                font.features: { "tnum": 1 }
              }
            }
          }
          Segmented {
            fill: parent.width
            options: card.modelData.options
            labels: card.modelData.labels
            selected: card.current
            onPicked: function(v) { root.pick(card.key, v) }
          }
        }
      }
    }
  }

  Item { width: 1; height: Type.px(24) }

  // What has no switch of its own.
  Text {
    width: parent.width
    wrapMode: Text.WordWrap
    text: "The ceremonies (終 退 危 新), the lock's standoff, letters and the menu's draw come and go with the desk; "
      + "the cursor, the tools and the theme work with or without it, and so does the boot screen, on a page of its own (Boot 押印). "
      + "The bar rides, stepping back to its rule, while Sumi is on. Everything here is also in ~/.config/hanko/kaze.json and the hanko command."
    color: Ink.inkFaint
    font.family: Type.text
    font.pixelSize: Type.note
    lineHeight: 1.2
  }

  // ------------------------------------------------------------ pictures
  // Each is told its key, its current value and whether it is hovered.

  // The OSD: a hairline filling from its centre, on its sheet of paper or bare.
  Component {
    id: osdArt
    Item {
      id: o
      property string key
      property string current
      property bool hovered
      readonly property bool card: o.current !== "off"
      Rectangle {
        anchors.centerIn: parent
        width: parent.width * 0.62; height: Type.px(46)
        color: Ink.paper
        border.width: 1; border.color: Ink.lineSoft
        opacity: o.card ? 1 : 0
        Behavior on opacity { enabled: Motion.live; NumberAnimation { duration: Motion.nuki } }
      }
      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height / 2 - Type.px(20)
        text: "VOL 音 62"
        color: Ink.inkDim
        font.family: Type.mono
        font.pixelSize: Type.px(10)
        font.letterSpacing: 1.6
      }
      Rectangle { anchors.horizontalCenter: parent.horizontalCenter; y: parent.height / 2 + Type.px(8); width: parent.width * 0.5; height: 1; color: Ink.lineStrong }
      Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter; y: parent.height / 2 + Type.px(7)
        width: parent.width * 0.5 * (o.hovered ? 0.8 : 0.62); height: 3; color: Ink.ink
        Behavior on width { enabled: Motion.live; NumberAnimation { duration: Motion.nuki; easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.nukiCurve } }
      }
    }
  }

  // Two windows, the focused one's top edge lit.
  Component {
    id: deskArt
    Item {
      property string key
      property string current
      property bool hovered
      Rectangle {
        x: parent.width / 2 - width - Type.px(4); y: Type.px(16)
        width: Type.px(72); height: Type.px(56)
        color: "transparent"; border.width: 1; border.color: Ink.inkDim
        Rectangle { width: parent.width; height: 2; color: Ink.ink }
      }
      Rectangle {
        x: parent.width / 2 + Type.px(4); y: Type.px(16)
        width: Type.px(72); height: Type.px(56)
        color: "transparent"; border.width: 1; border.color: Ink.line
      }
    }
  }

  // A line drawn out from the left, as a sheet draws open.
  Component {
    id: motionArt
    Item {
      id: m
      property string key
      property string current
      property bool hovered
      readonly property bool still: m.current === "still"
      Rectangle { x: Type.px(18); y: parent.height / 2; width: parent.width - 2 * x; height: 1; color: Ink.lineSoft }
      Rectangle {
        x: Type.px(18); y: parent.height / 2 - 1
        height: 3
        color: Ink.ink
        width: (parent.width - 2 * x) * (m.still ? 1 : (m.hovered ? 0.92 : 0.62))
        Behavior on width { enabled: Motion.live; NumberAnimation { duration: Motion.nuki; easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.nukiCurve } }
      }
    }
  }

  // The print: a ridge and its sky in five flat tones.
  Component {
    id: printArt
    Canvas {
      property string key
      property string current
      property bool hovered
      onWidthChanged: requestPaint()
      onPaint: {
        var c = getContext("2d")
        c.reset()
        var w = width, h = height
        var tones = [0.05, 0.12, 0.2, 0.3, 0.45]
        for (var band = 0; band < 5; band++) {
          c.fillStyle = Ink.alpha(Ink.ink, tones[band])
          c.beginPath()
          c.moveTo(0, h)
          for (var x = 0; x <= w; x += 4) {
            var y = h * (0.25 + band * 0.15) + Math.sin(x / w * 5 + band * 1.7) * h * 0.08 + Math.sin(x / w * 13 + band) * h * 0.03
            c.lineTo(x, y)
          }
          c.lineTo(w, h)
          c.closePath()
          c.fill()
        }
      }
    }
  }

  // The grass, from the wind's own model; it leans harder under the
  // pointer, and Gusts shows one running through the middle.
  Component {
    id: grassArt
    Canvas {
      id: g
      property string key
      property string current
      property bool hovered
      readonly property bool gusty: g.key === "gusts"
      readonly property real lean: g.hovered ? 0.55 : 0.18
      readonly property var blades: Wind.field(Math.max(1, width), height * 0.95, 18)
      onLeanChanged: requestPaint()
      onBladesChanged: requestPaint()
      onPaint: {
        var c = getContext("2d")
        c.reset()
        var gust = g.gusty ? { x: 0.5, width: 0.12, strength: 1.1 } : null
        for (var i = 0; i < blades.length; i++) {
          var b = Wind.blade(blades[i], height, width, g.lean, 0, gust)
          c.strokeStyle = Ink.alpha(Ink.ink, 0.35 + 0.5 * b.alpha)
          c.lineWidth = b.w
          c.beginPath()
          c.moveTo(b.root[0], b.root[1])
          c.quadraticCurveTo(b.ctrl[0], b.ctrl[1], b.tip[0], b.tip[1])
          c.stroke()
        }
      }
    }
  }

  // Wind lines: long and leaning when it blows, flat and short when calm.
  Component {
    id: windArt
    Canvas {
      id: wa
      property string key
      property string current
      property bool hovered
      readonly property bool calm: wa.current === "calm"
      onCalmChanged: requestPaint()
      onWidthChanged: requestPaint()
      onPaint: {
        var c = getContext("2d")
        c.reset()
        var rows = [0.28, 0.42, 0.56, 0.7]
        for (var i = 0; i < rows.length; i++) {
          var y = height * rows[i], x0 = width * (0.12 + (i % 2) * 0.1), len = width * (0.45 + 0.1 * ((i * 7) % 3))
          c.strokeStyle = Ink.alpha(Ink.ink, 0.35 + 0.15 * i)
          c.lineWidth = 1.2
          c.beginPath()
          c.moveTo(x0, y)
          c.bezierCurveTo(x0 + len * 0.4, y - height * 0.06, x0 + len * 0.7, y + height * 0.04, x0 + len, y - height * 0.05)
          if (!wa.calm) {
            c.arc(x0 + len - 6, y - height * 0.05 - 6, 6, Math.PI / 2, -Math.PI * 0.6, true)
          }
          c.stroke()
        }
      }
    }
  }

  // A struck bell: a waveform that dies away.
  Component {
    id: soundArt
    Canvas {
      property string key
      property string current
      property bool hovered
      onWidthChanged: requestPaint()
      onPaint: {
        var c = getContext("2d")
        c.reset()
        var mid = height / 2, x0 = Type.px(18), span = width - 2 * x0
        c.strokeStyle = Ink.inkDim
        c.lineWidth = 1
        c.beginPath()
        c.moveTo(x0, mid)
        for (var x = 0; x <= span; x += 1.5) {
          var t = x / span
          c.lineTo(x0 + x, mid + Math.sin(x * 0.9) * height * 0.38 * Math.exp(-t * 5))
        }
        c.stroke()
      }
    }
  }

  // Ink only: grey on grey, and the one red left.
  Component {
    id: sumiArt
    Item {
      property string key
      property string current
      property bool hovered
      Rectangle {
        anchors.fill: parent
        gradient: Gradient {
          GradientStop { position: 0; color: Ink.alpha(Ink.ink, 0.04) }
          GradientStop { position: 1; color: Ink.alpha(Ink.ink, 0.22) }
        }
      }
      Text {
        anchors.centerIn: parent
        text: "墨"
        color: Ink.inkDim
        font.family: Type.jp
        font.pixelSize: Type.px(40)
      }
      Rectangle {
        x: parent.width - Type.px(30); y: Type.px(14)
        width: Type.px(12); height: width
        color: Ink.seal
      }
    }
  }

  // The brush-tip pointer: an arrow cut as a brush's tip, ink with a paper rim,
  // drawn larger or smaller with the size picked (32 px is as drawn).
  Component {
    id: cursorArt
    Item {
      id: c
      property string key
      property string current
      property bool hovered
      Canvas {
        id: tip
        width: Type.px(30); height: Type.px(42)
        x: parent.width / 2 - width / 2 + (c.hovered ? Type.px(10) : 0)
        y: parent.height / 2 - height / 2 + (c.hovered ? Type.px(-4) : 0)
        scale: c.current === "on" ? root.cursorSize / 32 : 1
        Behavior on scale { enabled: Motion.live; NumberAnimation { duration: Motion.nuki; easing.type: Easing.OutCubic } }
        Behavior on x { enabled: Motion.live; NumberAnimation { duration: Motion.nuki; easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.nukiCurve } }
        Behavior on y { enabled: Motion.live; NumberAnimation { duration: Motion.nuki; easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.nukiCurve } }
        onPaint: {
          var g = getContext("2d")
          g.reset()
          var w = width, h = height
          g.beginPath()
          g.moveTo(2, 2)
          g.quadraticCurveTo(w * 0.9, h * 0.45, w - 2, h * 0.62)
          g.quadraticCurveTo(w * 0.55, h * 0.62, w * 0.38, h - 2)
          g.quadraticCurveTo(w * 0.2, h * 0.5, 2, 2)
          g.closePath()
          g.fillStyle = Ink.ink
          g.fill()
          g.lineWidth = 1.5
          g.strokeStyle = Ink.paper
          g.stroke()
        }
        Connections { target: Ink; function onInkChanged() { tip.requestPaint() } }
      }
    }
  }

  // btop's meters and an editor's lines, in the paper's inks.
  Component {
    id: toolsArt
    Item {
      id: t
      property string key
      property string current
      property bool hovered
      Rectangle {
        x: parent.width / 2 - width - Type.px(4); y: Type.px(16)
        width: Type.px(72); height: Type.px(56)
        color: "transparent"; border.width: 1; border.color: Ink.inkDim
        Repeater {
          model: [0.7, 0.45, 0.85, 0.3]
          Rectangle {
            required property int index
            required property real modelData
            x: Type.px(6); y: Type.px(9) + index * Type.px(11)
            width: (parent.width - Type.px(12)) * modelData * (t.hovered ? 0.8 : 1); height: Type.px(3)
            color: index === 2 ? Ink.seal : Ink.ink
            Behavior on width { enabled: Motion.live; NumberAnimation { duration: Motion.nuki } }
          }
        }
      }
      Rectangle {
        x: parent.width / 2 + Type.px(4); y: Type.px(16)
        width: Type.px(72); height: Type.px(56)
        color: "transparent"; border.width: 1; border.color: Ink.line
        Repeater {
          model: [0.55, 0.8, 0.4, 0.65, 0.3]
          Rectangle {
            required property int index
            required property real modelData
            x: Type.px(6) + (index % 2) * Type.px(6); y: Type.px(8) + index * Type.px(9)
            width: (parent.width - Type.px(18)) * modelData; height: 1
            color: index === 1 ? Ink.inkDim : Ink.inkMuted
          }
        }
      }
    }
  }

  // The theme: paper, four inks and one red, as swatches.
  Component {
    id: themeArt
    Item {
      id: th
      property string key
      property string current
      property bool hovered
      Row {
        anchors.centerIn: parent
        spacing: th.hovered ? Type.px(6) : Type.px(2)
        Behavior on spacing { enabled: Motion.live; NumberAnimation { duration: Motion.nuki } }
        Repeater {
          model: [Ink.paper, Ink.inkFaint, Ink.inkMuted, Ink.inkDim, Ink.ink, Ink.seal]
          Rectangle {
            required property color modelData
            width: Type.px(18); height: Type.px(40)
            color: modelData
            border.width: 1; border.color: Ink.lineSoft
          }
        }
      }
    }
  }
}
