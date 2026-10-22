pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Oin.js" as Oin

// Ōin 押印 in small, for Settings › Boot: the boot screen at 1920 × 1080,
// placed as assets/boot/hanko.script places it, from the very pictures
// scripts/hanko-boot draws (`dir`, the page's preview of what `hanko boot
// on` would install). Before the first drawing, or without one, the seal and
// the words are drawn here in the same inks. Pure: a moment in, nothing out.
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

  readonly property var lay: Oin.LAYOUT
  readonly property bool asking: phase === "password" || phase === "checking" || phase === "wrong"
  readonly property bool ruled: phase !== "shutdown" && phase !== "still"
  readonly property real sealY: Math.round(1080 * lay.sealAt - lay.seal / 2)
  readonly property real ruleX: Math.round(960 - lay.rule / 2)
  readonly property real ruleY: sealY + lay.seal + lay.ruleGap
  readonly property string hintKey: Oin.hint(phase, count, failed)
  function pic(n) { return dir !== "" ? "file://" + dir + "/" + n + ".png" : "" }

  width: 1920
  height: 1080
  clip: true

  Rectangle {
    anchors.fill: parent
    color: Qt.rgba(Ink.paper.r * root.paper, Ink.paper.g * root.paper, Ink.paper.b * root.paper, 1)
  }

  // The seal: the pressed frame, or a plate drawn here before the pictures.
  Image {
    id: seal
    visible: root.dir !== "" && root.press > 0
    x: 960 - root.lay.seal / 2; y: root.sealY
    width: root.lay.seal; height: root.lay.seal
    smooth: true
    source: root.pic("seal-" + (root.pressInk ? Math.min(7, Math.floor(root.press * 8)) : 7))
  }
  Rectangle {
    visible: root.dir === "" && root.press > 0
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
