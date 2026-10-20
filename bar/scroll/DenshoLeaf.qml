pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Densho.js" as Densho

// The two leaves a licence scroll opens and closes on (order: mokuroku;
// docs/densho sheet 06), in place of the weather leaf and the end leaf:
//
//   house     序 00 // OPENING — The house: who keeps this desk, the house's
//             line (the last upgrade, the boot, now) down a hairline, and
//             your seal as the house's mark
//   colophon  奥 09 // COLOPHON — Signed and sealed: the scroll transmitted
//             to you, on the day, under your preset; the issuer's seal (your
//             glyph) and an empty place for yours, pressed when the scroll
//             rolls up (`sealed`)
ScrollSection {
  id: root

  property string kind: "house"
  property date now: new Date()
  // services/Leaf.qml reading (okugaki's colophon lines).
  property var reading: ({})
  property string version: ""
  property string preset: ""
  property string sealGlyph: "鑑"
  // The colophon's second seal is pressed (the scroll is rolling up).
  property bool sealed: false

  readonly property bool isHouse: kind === "house"
  readonly property var view: isHouse
    ? Densho.house((reading || {}).colophon || "", { version: version, preset: preset }, now)
    : Densho.colophon((reading || {}).colophon || "", { preset: preset }, now)

  info: isHouse ? ({ no: "00", jp: "序", label: "OPENING" }) : ({ no: "09", jp: "奥", label: "COLOPHON" })
  poem: isHouse ? "The house" : "Signed and sealed"
  title: view.title
  caption: view.caption

  // ------------------------------------------------------------ the house
  // The house's line down a hairline, oldest first, now in red; your seal
  // as the house's mark beside it.
  Row {
    visible: root.isHouse
    y: Type.px(26)
    spacing: Type.px(30)

    Column {
      spacing: Type.px(14)
      Text {
        text: "THE LINE OF THE HOUSE"
        color: Ink.inkFaint
        font.family: Type.mono
        font.pixelSize: Type.label
        font.letterSpacing: Type.trackLabel
      }
      Item {
        width: points.width
        height: points.height
        Rectangle { x: Type.px(3); y: Type.px(6); width: 1; height: Math.max(0, parent.height - Type.px(12)); color: Ink.lineStrong }
        Column {
          id: points
          spacing: Type.px(12)
          Repeater {
            model: root.isHouse ? root.view.points : []
            Row {
              id: point
              required property var modelData
              spacing: Type.px(14)
              Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: point.modelData.now ? Type.px(7) : Type.px(7)
                height: point.modelData.now ? 2 : 1
                color: point.modelData.now ? Ink.seal : Ink.inkMuted
              }
              Text {
                anchors.verticalCenter: parent.verticalCenter
                width: Type.px(72)
                text: point.modelData.label.toUpperCase()
                color: point.modelData.now ? Ink.seal : Ink.inkFaint
                font.family: Type.mono
                font.pixelSize: Type.label
                font.letterSpacing: Type.trackLabel
              }
              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: point.modelData.value
                color: Ink.inkDim
                font.family: Type.text
                font.pixelSize: Type.note
              }
            }
          }
        }
      }
    }

    Stamp {
      size: Type.px(76)
      glyph: root.sealGlyph
      rotation: -2
    }
  }

  // ------------------------------------------------------------ the colophon
  // Signed to you in three lines; under them the issuer's seal (your glyph)
  // and the place for yours, pressed as the scroll rolls up.
  Column {
    visible: !root.isHouse
    y: Type.px(22)
    spacing: Type.px(22)

    Column {
      Repeater {
        model: root.isHouse ? [] : root.view.lines
        Text {
          required property string modelData
          text: modelData
          color: Ink.inkDim
          font.family: Type.display
          font.italic: true
          font.pixelSize: Type.px(19)
          font.variableAxes: Type.axes(Type.px(19))
          lineHeight: 1.4
        }
      }
    }

    Row {
      spacing: Type.px(26)
      Column {
        spacing: Type.px(8)
        Stamp { size: Type.px(62); glyph: root.sealGlyph; rotation: -4 }
        Text { text: "ISSUER"; color: Ink.inkFaint; font.family: Type.mono; font.pixelSize: Type.label; font.letterSpacing: Type.trackLabel }
      }
      Column {
        spacing: Type.px(8)
        Item {
          width: Type.px(62)
          height: width
          Rectangle {
            anchors.fill: parent
            visible: !root.sealed
            radius: Type.px(4)
            color: "transparent"
            border.width: 1
            border.color: Ink.lineStrong
            Text {
              anchors.centerIn: parent
              text: "ESC"
              color: Ink.inkFaint
              font.family: Type.mono
              font.pixelSize: Type.label
              font.letterSpacing: Type.trackLabel
            }
          }
          Stamp {
            id: yours
            anchors.centerIn: parent
            size: parent.width
            visible: root.sealed
            glyph: Array.from(root.isHouse ? "人" : root.view.who)[0].toUpperCase()
            rotation: 3
          }
        }
        Text { text: "YOURS"; color: Ink.inkFaint; font.family: Type.mono; font.pixelSize: Type.label; font.letterSpacing: Type.trackLabel }
      }
    }
  }

  // Your seal presses as it appears: the stamp, the one overshoot.
  onSealedChanged: if (sealed && !Motion.still) press.restart()
  SequentialAnimation {
    id: press
    PropertyAction { target: yours; property: "scale"; value: 1.4 }
    NumberAnimation { target: yours; property: "scale"; to: 1; duration: Motion.stamp; easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.stampCurve }
  }

  // A seal in the theme's red, as the bar's: plate, inner rule, glyph.
  component Stamp: Rectangle {
    id: stamp
    property int size: Type.px(84)
    property string glyph: "鑑"
    width: size
    height: size
    radius: Math.round(size * 0.06)
    color: Ink.seal
    antialiasing: true
    Rectangle {
      anchors.fill: parent
      anchors.margins: Math.round(stamp.size * 0.07)
      radius: Math.max(1, stamp.radius - 1)
      color: "transparent"
      border.width: Math.max(1, Math.round(stamp.size * 0.02))
      border.color: Ink.alpha(Ink.paper, 0.5)
    }
    Text {
      anchors.centerIn: parent
      text: stamp.glyph
      color: Ink.paper
      font.family: Type.jpSerif
      font.weight: Font.Bold
      font.pixelSize: Math.round(stamp.size * 0.56)
    }
  }
}
