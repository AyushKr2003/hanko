pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/InkMath.js" as InkMath

// Settings › Colour 色 (docs/settings-kosei). Hanko picks no colour of its
// own: one paper, four inks stepped from the theme's foreground to fixed
// contrasts, and the theme's red. The top is a printer's drawdown (展色):
// each ink drawn down on your paper, thick to thin, with what it is for and
// its contrast measured. Under it every Omarchy theme as a specimen in its
// own paper, inks and red; a click switches the whole desk (omarchy-theme-set).
Column {
  id: root

  // [{ slug, name, bg, fg, red, light }] and the slug in use.
  property var themes: []
  property string theme: ""
  property string glyph: "鑑"
  property bool compact: false

  signal themePicked(string slug)

  width: parent ? parent.width : 0
  spacing: 0
  topPadding: Type.px(22)

  function hex(c) { return String(c).length === 9 ? "#" + String(c).slice(3) : String(c) }
  readonly property string paperHex: hex(Ink.paper)

  // ------------------------------------------------------------ drawdown
  Rectangle {
    width: parent.width
    height: drawdown.height + Type.px(28)
    radius: 3
    color: "transparent"
    border.width: 1
    border.color: Ink.line

    Column {
      id: drawdown
      x: Type.px(20)
      y: Type.px(14)
      width: parent.width - 2 * x
      spacing: 0

      Row {
        spacing: Type.px(8)
        Text { text: "展色"; color: Ink.seal; font.family: Type.jp; font.pixelSize: Type.px(12) }
        Text { text: "DRAWDOWN · YOUR THEME'S INKS ON ITS PAPER"; color: Ink.inkMuted; font.family: Type.mono; font.pixelSize: Type.tag; font.letterSpacing: Type.trackLabel; anchors.verticalCenter: parent.verticalCenter }
      }
      Item { width: 1; height: Type.px(12) }

      Repeater {
        model: [
          { name: "Paper", role: "Everything is printed on it", c: Ink.paper, paper: true },
          { name: "Ink", role: "Values, names, the clock", c: Ink.ink, target: 12 },
          { name: "Dim", role: "Second lines, the date", c: Ink.inkDim, target: 9 },
          { name: "Muted", role: "Labels and notes", c: Ink.inkMuted, target: 6.2 },
          { name: "Faint", role: "Rules and the quietest marks", c: Ink.inkFaint, target: 4.6 },
          { name: "Red", role: "You and now: the seal, what needs you", c: Ink.seal }
        ]
        Item {
          id: ink
          required property var modelData
          required property int index
          readonly property real ratio: InkMath.contrast(root.hex(modelData.c), root.paperHex)
          width: drawdown.width
          height: Type.px(46)
          Rectangle { visible: ink.index > 0; width: parent.width; height: 1; color: Ink.lineSoft }

          Column {
            id: inkName
            anchors.verticalCenter: parent.verticalCenter
            width: Type.px(root.compact ? 120 : 220)
            spacing: Type.px(1)
            Text {
              text: ink.modelData.name
              color: Ink.ink
              font.family: Type.display
              font.pixelSize: Type.px(18)
              font.weight: Font.Normal
              font.variableAxes: Type.axes(Type.px(18))
            }
            Text {
              visible: !root.compact
              text: ink.modelData.role
              color: Ink.inkMuted
              font.family: Type.text
              font.pixelSize: Type.note
            }
          }
          // The ink drawn down: full where the knife starts, thinning out.
          Rectangle {
            id: strip
            x: inkName.width + Type.px(12)
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(Type.px(80), parent.width - x - figures.width - sample.width - Type.px(40))
            height: Type.px(22)
            radius: 1
            border.width: ink.modelData.paper ? 1 : 0
            border.color: Ink.line
            gradient: ink.modelData.paper ? null : grad
            color: ink.modelData.paper ? Ink.paper : "transparent"
            Gradient {
              id: grad
              orientation: Gradient.Horizontal
              GradientStop { position: 0; color: ink.modelData.c }
              GradientStop { position: 0.62; color: ink.modelData.c }
              GradientStop { position: 1; color: Ink.alpha(ink.modelData.c, 0.05) }
            }
          }
          // A line set in it.
          Text {
            id: sample
            anchors.left: strip.right
            anchors.leftMargin: Type.px(16)
            anchors.verticalCenter: parent.verticalCenter
            text: ink.modelData.paper ? "" : "21:44 " + root.glyph
            color: ink.modelData.c
            font.family: Type.display
            font.pixelSize: Type.px(18)
            font.weight: Font.Normal
            font.variableAxes: Type.axes(Type.px(18))
          }
          Column {
            id: figures
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: Type.px(110)
            spacing: Type.px(2)
            Text {
              anchors.right: parent.right
              text: root.hex(ink.modelData.c).toUpperCase()
              color: Ink.inkDim
              font.family: Type.mono
              font.pixelSize: Type.px(11)
              font.letterSpacing: 1
            }
            Text {
              anchors.right: parent.right
              text: ink.modelData.paper ? "THE GROUND" : ink.ratio.toFixed(1) + " : 1" + (ink.modelData.target ? "  ·  SET " + ink.modelData.target : "")
              color: Ink.inkMuted
              font.family: Type.mono
              font.pixelSize: Type.tag
              font.letterSpacing: 1
            }
          }
        }
      }
    }
  }

  Item { width: 1; height: Type.px(28) }

  // ------------------------------------------------------------ the themes
  SectionLabel {
    jp: "色"
    text: root.themes.length ? "Omarchy themes · " + root.themes.length + " · click one to switch the whole desk" : "Omarchy themes · reading them…"
  }
  Item { width: 1; height: Type.px(12) }

  Grid {
    id: grid
    width: parent.width
    columns: Math.max(1, Math.floor((width + spacing) / (Type.px(230) + spacing)))
    spacing: Type.px(10)
    readonly property real cardWidth: (width - (columns - 1) * spacing) / columns

    Repeater {
      model: root.themes
      Item {
        id: card
        required property var modelData
        readonly property bool used: modelData.slug === root.theme
        readonly property var ramp: InkMath.ramp(modelData.fg, modelData.bg)
        width: grid.cardWidth
        height: face.height + caption.height + Type.px(6)

        // The theme's own paper, with a bar set on it in its inks.
        Rectangle {
          id: face
          width: parent.width
          height: Type.px(92)
          radius: 3
          color: card.modelData.bg
          border.width: card.used ? 2 : 1
          border.color: card.used ? Ink.ink : cardHover.containsMouse ? Ink.lineStrong : Ink.line

          Row {
            x: Type.px(12)
            y: Type.px(14)
            spacing: Type.px(8)
            Rectangle {
              width: Type.px(22)
              height: width
              radius: 2
              color: card.modelData.red
              Text { anchors.centerIn: parent; text: root.glyph; color: card.modelData.bg; font.family: Type.jpSerif; font.pixelSize: Type.px(13) }
            }
            Repeater {
              model: ["壱", "弐", "参"]
              Rectangle {
                id: ws
                required property string modelData
                required property int index
                width: Type.px(20)
                height: Type.px(22)
                radius: 2
                color: ws.index === 2 ? card.ramp.ink : "transparent"
                Text {
                  anchors.centerIn: parent
                  text: ws.modelData
                  color: ws.index === 2 ? card.modelData.bg : card.ramp.inkMuted
                  font.family: Type.jp
                  font.pixelSize: Type.px(12)
                }
              }
            }
          }
          Text {
            anchors.right: parent.right
            anchors.rightMargin: Type.px(12)
            y: Type.px(12)
            text: "21:44"
            color: card.ramp.ink
            font.family: Type.display
            font.pixelSize: Type.px(20)
            font.weight: Font.Normal
            font.variableAxes: Type.axes(Type.px(20))
          }
          // The four inks and the red, as Hanko would step them.
          Row {
            x: Type.px(12)
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Type.px(12)
            spacing: Type.px(4)
            Repeater {
              model: [card.ramp.ink, card.ramp.inkDim, card.ramp.inkMuted, card.ramp.inkFaint, card.modelData.red]
              Rectangle { required property var modelData; width: Type.px(18); height: Type.px(6); radius: 1; color: modelData }
            }
          }
          Text {
            anchors.right: parent.right
            anchors.rightMargin: Type.px(12)
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Type.px(9)
            text: card.modelData.light ? "LIGHT" : "DARK"
            color: card.ramp.inkMuted
            font.family: Type.mono
            font.pixelSize: Type.tag
            font.letterSpacing: Type.trackLabel
          }
        }
        Row {
          id: caption
          y: face.height + Type.px(6)
          spacing: Type.px(8)
          Rectangle { visible: card.used; anchors.verticalCenter: parent.verticalCenter; width: Type.px(5); height: width; radius: width / 2; color: Ink.seal }
          Text {
            text: card.modelData.name
            color: card.used ? Ink.ink : Ink.inkDim
            font.family: Type.text
            font.pixelSize: Type.px(13)
          }
          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: card.used ? "IN USE" : cardHover.containsMouse ? "USE ›" : ""
            color: card.used ? Ink.ink : Ink.inkMuted
            font.family: Type.mono
            font.pixelSize: Type.tag
            font.letterSpacing: Type.trackLabel
          }
        }
        MouseArea {
          id: cardHover
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: card.used ? Qt.ArrowCursor : Qt.PointingHandCursor
          readonly property bool keyStop: enabled
          readonly property bool keyChosen: card.used
          function keyPress() { if (!card.used) root.themePicked(card.modelData.slug) }
          onClicked: if (!card.used) root.themePicked(card.modelData.slug)
        }
      }
    }
  }
}
