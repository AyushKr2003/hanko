pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Oin.js" as Oin

// Ōin 押印 in small, for Settings › Boot: the boot screen at 1920 × 1080,
// placed as assets/boot/hanko.script places it, from the very pictures
// scripts/hanko-boot draws (`dir`, the page's preview of what `hanko boot
// on` would install). Before the first drawing, or without one, the seal and
// the words are drawn here in the same inks. Pure: a moment in, nothing out.
// Two marks: the seal, or the brush (始 written as the shutdown ceremony
// writes 終, the words beside it, a seal pressed at its foot).
Item {
  id: root

  // The theme's pictures (a folder), or "".
  property string dir: ""
  // still | password | checking | wrong | booting | shutdown
  property string phase: "password"
  property int count: 0
  property real progress: 0
  // The press, 0..1 (eight frames), and black to the paper, 0..1.
  property real press: 1
  property real paper: 1
  property int failed: 0
  // A wrong passphrase's fade, 0..1 (the spark and the old nicks go).
  property real fade: 0
  property bool showName: true
  property bool pressInk: true
  property string glyph: "鑑"
  property string name: ""
  // The brush mark, its writing (0..1) and what follows it (the seal
  // pressed, the words), 0..1.
  property bool brush: false
  property real write: 1
  property real after: 1

  readonly property var lay: Oin.LAYOUT
  readonly property bool asking: phase === "password" || phase === "checking" || phase === "wrong"
  readonly property bool ruled: phase !== "shutdown" && phase !== "still"
  readonly property real sealY: Math.round(1080 * lay.sealAt - lay.seal / 2)
  readonly property real ruleX: Math.round(960 - lay.rule / 2)
  readonly property real kanjiY: Math.floor(1080 * lay.brushAt - lay.brush / 2)
  readonly property real wordsW: Math.max(wordsPic.implicitWidth, subPic.implicitWidth)
  readonly property real kanjiX: Math.floor(960 - (lay.brush + lay.brushGap + wordsW) / 2)
  readonly property real ruleY: brush ? kanjiY + lay.brush + lay.brushRuleGap : sealY + lay.seal + lay.ruleGap
  readonly property bool ending: phase === "shutdown"
  readonly property string hintKey: Oin.hint(phase, count, failed)
  function pic(n) { return dir !== "" ? "file://" + dir + "/" + n + ".png" : "" }

  width: 1920
  height: 1080
  clip: true

  Rectangle {
    anchors.fill: parent
    color: Qt.rgba(Ink.paper.r * root.paper, Ink.paper.g * root.paper, Ink.paper.b * root.paper, 1)
  }

  // The brush: the frame the writing has reached (終 whole at shutdown), the
  // words beside it, and the seal pressed at its foot from 115%.
  Item {
    visible: root.brush
    Image {
      visible: root.dir !== "" && root.write > 0
      x: root.kanjiX; y: root.kanjiY
      width: root.lay.brush; height: root.lay.brush
      smooth: true
      source: root.ending ? root.pic("end-0")
        : root.pic("brush-" + (root.pressInk ? Math.min(root.lay.brushFrames - 1, Math.floor(root.write * root.lay.brushFrames)) : root.lay.brushFrames - 1))
    }
    Text {
      visible: root.dir === ""
      x: root.kanjiX; y: root.kanjiY
      text: root.ending ? "終" : "始"
      color: Ink.ink
      font.family: Type.brush
      font.pixelSize: root.lay.brush
    }
    Image {
      id: wordsPic
      readonly property real block: implicitHeight + root.lay.wordsGap + subPic.implicitHeight
      x: root.kanjiX + root.lay.brush + root.lay.brushGap
      y: Math.floor(root.kanjiY + root.lay.brush / 2 - block / 2)
      opacity: root.after
      source: root.pic(root.ending ? "words-end" : "words-start")
    }
    Image {
      id: subPic
      x: wordsPic.x
      y: wordsPic.y + wordsPic.implicitHeight + root.lay.wordsGap
      opacity: root.after
      source: root.pic(root.ending ? "sub-shutdown" : "sub-start")
    }
    Image {
      readonly property real s: 1.15 - 0.15 * root.after
      x: root.kanjiX + root.lay.brush - root.lay.stamp * 0.4 + root.lay.stamp / 2 - width / 2
      y: root.kanjiY + root.lay.brush - root.lay.stamp * 1.1 + root.lay.stamp / 2 - height / 2
      width: Math.round(root.lay.stamp * s); height: width
      smooth: true
      opacity: root.after
      source: root.pic("stamp")
    }
  }

  // The seal: the pressed frame, or a plate drawn here before the pictures.
  Image {
    id: seal
    visible: !root.brush && root.dir !== "" && root.press > 0
    x: 960 - root.lay.seal / 2; y: root.sealY
    width: root.lay.seal; height: root.lay.seal
    smooth: true
    source: root.pic("seal-" + (root.pressInk ? Math.min(7, Math.floor(root.press * 8)) : 7))
  }
  Rectangle {
    visible: !root.brush && root.dir === "" && root.press > 0
    x: 960 - root.lay.seal / 2; y: root.sealY
    width: root.lay.seal; height: root.lay.seal
    radius: Math.round(width * 0.11)
    color: Ink.seal
    opacity: root.pressInk ? root.press : 1
    Text {
      anchors.centerIn: parent
      text: root.glyph
      color: Ink.paper
      font.family: Type.jpSerif
      font.pixelSize: Math.round(parent.width * 0.58)
    }
  }

  // The hairline: the sheath, then the progress.
  Rectangle {
    visible: root.ruled
    x: root.ruleX; y: root.ruleY
    width: root.lay.rule; height: 1
    color: Ink.inkFaint
    opacity: 0.35
  }
  Rectangle {
    visible: root.asking
    x: root.ruleX; y: root.ruleY - Math.floor(root.lay.hiltH / 2)
    width: 1; height: root.lay.hiltH
    color: Ink.ink
  }
  // The blade, a nick a key; dimmed while checking, fading when deflected.
  Item {
    id: blade
    visible: root.asking
    readonly property int keys: root.count
    opacity: root.phase === "checking" ? 0.55 : root.phase === "wrong" ? 0.35 * (1 - root.fade) : 1
    Rectangle {
      x: root.ruleX; y: root.ruleY
      width: Oin.bladeWidth(blade.keys); height: 1
      visible: width > 0
      color: Ink.ink
    }
    Repeater {
      model: Oin.nicks(blade.keys)
      Rectangle {
        required property int modelData
        x: root.ruleX + modelData; y: root.ruleY - root.lay.nickH
        width: 1; height: root.lay.nickH
        color: Ink.ink
      }
    }
  }
  Image {
    visible: root.phase === "wrong" && root.dir !== ""
    opacity: 1 - root.fade
    source: root.pic("spark")
    x: root.ruleX + Oin.bladeWidth(root.count) - width / 2
    y: root.ruleY - height / 2
  }
  Rectangle {
    visible: root.phase === "booting"
    x: root.ruleX; y: root.ruleY
    width: Math.max(1, Math.round(root.lay.rule * root.progress)); height: 1
    color: Ink.ink
    Rectangle { x: parent.width - 1; y: -4; width: 2; height: 8; color: Ink.seal }
  }

  // The hint under the hairline.
  Image {
    visible: root.hintKey !== "" && root.dir !== ""
    source: root.hintKey !== "" ? root.pic(root.hintKey) : ""
    x: 960 - width / 2
    y: root.ruleY + root.lay.hintGap
  }
  Text {
    visible: root.hintKey !== "" && root.dir === ""
    x: 960 - width / 2
    y: root.ruleY + root.lay.hintGap
    text: ({ "hint-type": "TYPE TO UNLOCK", "hint-enter": "ENTER TO CUT", "hint-check": "CHECKING" })[root.hintKey] || ("NOT THAT ONE · " + Math.max(1, root.failed))
    color: root.phase === "wrong" ? Ink.seal : root.count > 0 || root.phase === "checking" ? Ink.inkMuted : Ink.inkFaint
    font.family: Type.mono
    font.pixelSize: 11
    font.letterSpacing: 3.2
  }

  // The corner while it asks: your name, SEALED · 封.
  Item {
    visible: root.asking && root.showName
    Image {
      id: sealedPic
      visible: root.dir !== ""
      source: root.pic("sealed")
      x: 1920 - root.lay.corner - width
      y: 1080 - root.lay.corner - height
    }
    Image {
      visible: root.dir !== ""
      source: root.pic("name")
      x: 1920 - root.lay.corner - width
      y: sealedPic.y - 10 - height
    }
    Column {
      visible: root.dir === ""
      x: 1920 - root.lay.corner - width
      y: 1080 - root.lay.corner - height
      spacing: 8
      Text {
        anchors.right: parent.right
        text: root.name
        color: Ink.ink
        font.family: Type.display
        font.pixelSize: 26
        font.variableAxes: Type.axes(26, 340)
      }
      Text {
        anchors.right: parent.right
        text: "SEALED · 封"
        color: Ink.inkMuted
        font.family: Type.mono
        font.pixelSize: 10
        font.letterSpacing: 3
      }
    }
  }
}
