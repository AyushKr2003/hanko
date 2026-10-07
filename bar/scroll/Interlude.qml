pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Scroll.js" as Scroll

// What sits between two sections of the scroll: the `interlude` setting
// (core/Style.js). Drawn in the theme's ink and seal red, quieter than the
// sections it divides; the designs are in docs/revision1 on the docs branch.
//   ma        space alone (nothing is drawn)
//   hairline  one rule fading at both ends, a ring at its middle
//   folio     a ruler like the day rule, with both section numbers
//   kotoba    the next section's kanji and name, set vertically
//   tsugime   a paper join: the next sheet laps over the last
//   seal      the join, with a seal of the next section pressed across it
//   jiku      a slim inner roller with caps
//   fuda      a bone index tab with the next kanji and number
//   su        the next section's number, large and sideways
Item {
  id: root

  property int seed: 0
  property string style: "seal"
  // What comes after, when it is not a section (the end leaf after Inbox).
  property var after: null
  // The sections either side (seed 11 = the weather leaf, before Time).
  readonly property var next: after || Scroll.SECTIONS[seed === 11 ? 0 : Math.min(seed + 1, Scroll.SECTIONS.length - 1)]
  readonly property var prev: seed === 11 ? ({ no: "00", jp: "天", label: "WEATHER" }) : Scroll.SECTIONS[seed]
  readonly property real cx: Math.round(width / 2)
  // Drawing scale; the settings page draws them smaller.
  property real s: Type.scale
  function a(c, al) { return Qt.rgba(c.r, c.g, c.b, al) }

  // ---------------------------------------------------- hairline 罫
  Rectangle {
    visible: root.style === "hairline"
    x: root.cx; width: 1; height: parent.height
    gradient: Gradient {
      GradientStop { position: 0; color: root.a(Ink.ink, 0) }
      GradientStop { position: 0.18; color: Ink.line }
      GradientStop { position: 0.82; color: Ink.line }
      GradientStop { position: 1; color: root.a(Ink.ink, 0) }
    }
  }
  Rectangle {
    visible: root.style === "hairline"
    x: root.cx - 2; y: parent.height / 2 - 2; width: 5; height: 5; radius: 2.5
    color: Ink.paper; border.color: Ink.lineStrong; border.width: 1
  }
  // ---------------------------------------------------- folio 柱 (a ruler)
  Item {
    visible: root.style === "folio"
    anchors.fill: parent
    Rectangle { x: root.cx; width: 1; height: parent.height; color: Ink.line }
    Repeater {
      model: Math.floor(root.height / (12 * root.s))
      Rectangle {
        required property int index
        x: root.cx - (index % 4 === 0 ? 6 : 3) * root.s
        y: index * 12 * root.s
        width: (index % 4 === 0 ? 6 : 3) * root.s
        height: 1
        color: index % 4 === 0 ? Ink.lineStrong : Ink.line
      }
    }
    Rectangle {
      x: root.cx + 6 * root.s; y: parent.height / 2 - height / 2
      width: folioText.implicitHeight + 6; height: folioText.implicitWidth + 12
      color: Ink.paper
      Text {
        id: folioText
        anchors.centerIn: parent
        rotation: 90
        text: root.prev.no + " — " + root.next.no
        color: Ink.inkMuted
        font.family: Type.mono; font.pixelSize: 9 * root.s; font.letterSpacing: 2 * root.s
      }
    }
  }
  // ---------------------------------------------------- kotoba 詞書 (a text column)
  Column {
    visible: root.style === "kotoba"
    anchors.centerIn: parent
    spacing: 10 * root.s
    Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: 1; height: 70 * root.s; color: Ink.line }
    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: root.next.jp
      color: Ink.seal
      font.family: Type.jpSerif; font.pixelSize: 15 * root.s
    }
    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: (root.next.no + " " + root.next.label).split("").join("\n")
      horizontalAlignment: Text.AlignHCenter
      lineHeight: 0.92
      color: Ink.inkMuted
      font.family: Type.mono; font.pixelSize: 9 * root.s
    }
    Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: 1; height: 70 * root.s; color: Ink.line }
  }
  // ---------------------------------------------------- tsugime 継目 (a paper join)
  Item {
    visible: root.style === "tsugime" || root.style === "seal"
    anchors.fill: parent
    // The paste margin: the next sheet laps over the last by a few px.
    Rectangle {
      x: root.cx; width: 7 * root.s; height: parent.height
      gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0; color: root.a(Ink.ink, 0.07) }
        GradientStop { position: 1; color: root.a(Ink.ink, 0.0) }
      }
    }
    Rectangle { x: root.cx; width: 1; height: parent.height; color: Ink.lineStrong }
    // Its shadow, falling back on the earlier sheet.
    Rectangle {
      x: root.cx - 14 * root.s; width: 14 * root.s; height: parent.height
      gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0; color: Qt.rgba(0, 0, 0, 0) }
        GradientStop { position: 1; color: Qt.rgba(0, 0, 0, Ink.paper.hslLightness > 0.5 ? 0.07 : 0.32) }
      }
    }
  }
  // 継目印: a seal pressed across the join, half on each sheet.
  Item {
    visible: root.style === "seal"
    x: root.cx - width / 2; y: parent.height * 0.5 - height / 2
    width: 26 * root.s; height: width
    rotation: (root.seed % 3 - 1) * 4
    Rectangle { anchors.fill: parent; radius: 3 * root.s; color: Ink.seal; opacity: 0.92 }
    Rectangle { anchors.fill: parent; anchors.margins: 2.5 * root.s; radius: 2 * root.s; color: "transparent"; border.color: Ink.paper; border.width: 1; opacity: 0.55 }
    Text {
      anchors.centerIn: parent
      text: root.next.jp
      color: Ink.paper
      font.family: Type.jpSerif; font.pixelSize: 14 * root.s; font.weight: Font.DemiBold
    }
  }
  // ---------------------------------------------------- jiku 軸 (an inner roller)
  Item {
    visible: root.style === "jiku"
    anchors.fill: parent
    Rectangle {
      x: root.cx - 2 * root.s; y: 8 * root.s; width: 4 * root.s; height: parent.height - 16 * root.s; radius: 2 * root.s
      gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0; color: root.a(Ink.ink, 0.35) }
        GradientStop { position: 0.45; color: root.a(Ink.ink, 0.75) }
        GradientStop { position: 1; color: root.a(Ink.ink, 0.25) }
      }
    }
    Repeater {
      model: 2
      Rectangle {
        id: cap
        required property int index
        x: root.cx - 4 * root.s; y: cap.index === 0 ? 2 * root.s : root.height - 8 * root.s
        width: 8 * root.s; height: 6 * root.s; radius: 1.5 * root.s
        color: Ink.inkDim
      }
    }
  }
  // ---------------------------------------------------- fuda 札 (an index tab)
  Item {
    visible: root.style === "fuda"
    anchors.fill: parent
    Rectangle { x: root.cx; width: 1; height: parent.height; color: Ink.lineSoft }
    Rectangle {
      x: root.cx - width / 2; y: parent.height * 0.5 - height / 2
      width: 22 * root.s; height: fudaCol.implicitHeight + 16 * root.s
      color: Ink.bone; radius: 2 * root.s
      Column {
        id: fudaCol
        anchors.centerIn: parent
        spacing: 6 * root.s
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.next.jp; color: Ink.seal; font.family: Type.jpSerif; font.pixelSize: 12 * root.s; font.weight: Font.DemiBold }
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.next.no.split("").join("\n"); horizontalAlignment: Text.AlignHCenter; lineHeight: 0.9; color: Ink.boneInk; font.family: Type.mono; font.pixelSize: 9 * root.s }
      }
    }
  }
  // ---------------------------------------------------- su 数 (an oversized folio numeral)
  Text {
    visible: root.style === "su"
    anchors.centerIn: parent
    rotation: -90
    text: root.next.no
    color: root.a(Ink.ink, 0.28)
    font.family: Type.display; font.pixelSize: 64 * root.s; font.weight: Font.Light
  }
  Rectangle {
    visible: root.style === "su"
    x: root.cx - 3 * root.s; y: parent.height / 2 + 46 * root.s; width: 6 * root.s; height: 6 * root.s; radius: 3 * root.s; color: Ink.seal
  }
}
