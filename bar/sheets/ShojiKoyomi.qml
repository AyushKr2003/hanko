pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Brush.js" as Brush
import "../parts"

// Time 時 as an almanac on a Shōji panel (Koyomi 暦,
// docs/koyomi/README.md): the month behind a lattice (kumiko), each day a
// pane, today ringed in an ensō, the picked day underlined with a brush
// stroke that moves with it. A day a solar term starts carries its name;
// the full and new moons and the days' weather are written small. Beside
// it, the season as an ensō that closes as the season goes, the
// microseason written down the page, the moon and the sky. Under it, the
// year as twelve panes with their old names, then the other cities.
// A turn of the month slides the month behind the lattice like a door on
// its rail; the lattice stays.
Item {
  id: root

  property var skin: ({})
  property date now: new Date()
  property int pick: 0
  property var sky: null
  property var zones: []
  property real room: 0
  signal request(string sheet, string what, var arg)

  KoyomiState {
    id: ko
    now: root.now
    pick: root.pick
    sky: root.sky
    room: root.room
    sheet: root
    rowMax: Type.px(44)
    rowMin: Type.px(34)
    onRequest: function(what, arg) { root.request("time", what, arg) }
  }
  readonly property var leaf: ko.leaf
  readonly property real colW: (width - Type.px(24)) * 0.58
  readonly property var ordinals: ["", "first", "second", "third", "fourth", "fifth", "sixth", "seventh", "eighth", "ninth", "tenth",
    "eleventh", "twelfth", "thirteenth", "fourteenth", "fifteenth", "sixteenth", "seventeenth", "eighteenth", "nineteenth", "twentieth",
    "twenty-first", "twenty-second", "twenty-third", "twenty-fourth", "twenty-fifth", "twenty-sixth", "twenty-seventh", "twenty-eighth",
    "twenty-ninth", "thirtieth", "thirty-first"]

  implicitHeight: Math.max(left.implicitHeight, right.implicitHeight) + (year.visible ? Type.px(16) + year.height : 0) + (root.zones.length ? Type.px(14) + zonesRow.height : 0)
  onImplicitHeightChanged: ko.fit(implicitHeight)
  Component.onCompleted: ko.fit(implicitHeight)

  Column {
    id: left
    width: root.colW
    spacing: Type.px(4)
    Text {
      text: root.leaf.weekday + ", "
      color: Ink.ink
      font.family: Type.display; font.pixelSize: Type.px(30); font.weight: Font.Normal
      font.variableAxes: Type.axes(Type.px(30), 360)
      Text {
        anchors.left: parent.right; anchors.baseline: parent.baseline
        text: "the " + root.ordinals[root.leaf.day]
        color: Ink.ink2
        font.family: Type.display; font.italic: true; font.pixelSize: Type.px(30); font.weight: Font.Normal
      }
    }
    Text {
      width: left.width
      elide: Text.ElideRight
      text: ko.view.name + " " + ko.view.y + " · " + ko.view.wafu + " " + ko.view.romaji + (ko.k.moved ? " · " + root.leaf.when.toLowerCase() : "")
      color: Ink.ink3; font.family: Type.text; font.pixelSize: Type.px(12.5)
      bottomPadding: Type.px(8)
    }
    Row {
      Repeater {
        model: ["M", "T", "W", "T", "F", "S", "S"]
        Text { required property string modelData; width: left.width / 7; height: Type.px(22); horizontalAlignment: Text.AlignHCenter; text: modelData; color: Ink.ink3; font.family: Type.text; font.pixelSize: Type.px(11.5) }
      }
    }

    // The lattice, and the month behind it.
    Item {
      id: lattice
      readonly property real cw: left.width / 7
      readonly property real ch: ko.rowH
      width: left.width
      height: 6 * ch
      clip: true

      WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: function(w) { ko.wheel(w.angleDelta.y) }
      }

      Item {
        id: door
        width: lattice.width
        height: lattice.height
        // Slid along its rail on a turn.
        property real slid: 1
        x: (1 - slid) * ko.dir * lattice.width * 0.4
        opacity: 0.2 + 0.8 * slid
        NumberAnimation {
          id: slide
          target: door
          property: "slid"
          from: 0; to: 1
          duration: root.skin.open || 240
          easing.type: Easing.BezierSpline
          easing.bezierCurve: root.skin.openCurve || [0.16, 1, 0.3, 1, 1, 1]
        }
        Connections {
          target: ko
          function onMonthKeyChanged() { if (Motion.live) slide.restart() }
        }

        Repeater {
          model: [].concat.apply([], ko.k.weeks)
          Item {
            id: pane
            required property var modelData
            required property int index
            readonly property var c: modelData
            x: (index % 7) * lattice.cw
            y: Math.floor(index / 7) * lattice.ch
            width: lattice.cw
            height: lattice.ch
            opacity: c.inMonth ? 1 : 0.3
            readonly property bool keyStop: true
            readonly property bool keyChosen: c.picked
            function keyPress() { ko.day(pane.c) }
            Ring {
              visible: pane.c.today
              anchors.centerIn: parent
              anchors.verticalCenterOffset: -Type.px(4)
              skin: root.skin; size: Type.px(32); value: 97
            }
            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              y: Type.px(7)
              text: pane.c.day
              color: pane.c.today || pane.c.picked ? Ink.ink : pane.c.past ? Ink.ink3 : Ink.ink2
              font.family: Type.text; font.pixelSize: Type.px(12.5)
              font.weight: pane.c.today || pane.c.picked ? Font.DemiBold : Font.Normal
              font.features: { "tnum": 1 }
            }
            Text {
              visible: text !== ""
              anchors.horizontalCenter: parent.horizontalCenter
              y: lattice.ch - height - Type.px(4)
              width: lattice.cw - Type.px(4)
              horizontalAlignment: Text.AlignHCenter
              elide: Text.ElideRight
              // Today's sky is in the leaf; its ensō would sit on it here.
              text: pane.c.term !== "" ? pane.c.term : pane.c.sky && !pane.c.today ? pane.c.sky.jp + pane.c.sky.hi : ""
              color: pane.c.term !== "" ? Ink.ink : Ink.ink4
              font.family: pane.c.term !== "" ? Type.jp : Type.text
              font.pixelSize: Type.px(pane.c.term !== "" ? 10 : 9.5)
            }
            MoonMark {
              visible: pane.c.moon !== ""
              x: parent.width - width - Type.px(4)
              y: Type.px(4)
              size: Type.px(7)
              age: pane.c.moon === "full" ? 14.77 : 0
              ink: Ink.ink2
            }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: ko.day(pane.c) }
          }
        }
        // The picked day's brush stroke.
        InkShape {
          readonly property int at: {
            for (var w = 0; w < 6; w++) for (var d = 0; d < 7; d++) if (ko.k.weeks[w][d].picked) return w * 7 + d
            return -1
          }
          visible: at >= 0 && !ko.k.weeks[Math.floor(at / 7)][at % 7].today
          x: (at % 7) * lattice.cw + lattice.cw * 0.22
          y: Math.floor(at / 7) * lattice.ch + Math.round(lattice.ch * 0.52)
          width: lattice.cw * 0.56
          height: Type.px(4)
          path: Brush.stroke(lattice.cw * 0.56, Type.px(4), 7)
          fill: Ink.ink
          Behavior on x { enabled: Motion.live; NumberAnimation { duration: Motion.ms(Motion.slide); easing.type: Easing.OutCubic } }
          Behavior on y { enabled: Motion.live; NumberAnimation { duration: Motion.ms(Motion.slide); easing.type: Easing.OutCubic } }
        }
      }

      // The kumiko: the lattice the month slides behind, which stays.
      Repeater {
        model: 6
        Rectangle { required property int index; x: (index + 1) * lattice.cw; width: 1; height: lattice.height; color: Ink.alpha(Ink.kLine, 0.55) }
      }
      Repeater {
        model: 5
        Rectangle { required property int index; y: (index + 1) * lattice.ch; width: lattice.width; height: 1; color: Ink.alpha(Ink.kLine, 0.55) }
      }
      Rectangle { anchors.fill: parent; color: "transparent"; border.width: 1; border.color: Ink.kLine }
    }
  }

  Column {
    id: right
    x: root.colW + Type.px(24)
    width: root.width - x
    spacing: Type.px(10)
    Row {
      spacing: Type.px(12)
      Item {
        width: Type.px(74); height: width
        Ring { anchors.centerIn: parent; skin: root.skin; size: Type.px(74); value: Math.max(4, root.leaf.season.through * 100) }
        Text { anchors.centerIn: parent; text: root.leaf.season.jp; color: Ink.ink; font.family: Type.brush; font.pixelSize: Type.px(26) }
      }
      Column {
        anchors.verticalCenter: parent.verticalCenter
        spacing: Type.px(2)
        Text { width: right.width - Type.px(86); elide: Text.ElideRight; text: root.leaf.sekki.jp + "  " + root.leaf.sekki.english; color: Ink.ink; font.family: Type.jp; font.pixelSize: Type.px(13) }
        Text { width: right.width - Type.px(86); elide: Text.ElideRight; text: root.leaf.sekki.romaji + " · day " + root.leaf.sekki.day + " of " + root.leaf.sekki.days; color: Ink.ink3; font.family: Type.text; font.pixelSize: Type.px(11.5) }
        Text { width: right.width - Type.px(86); elide: Text.ElideRight; text: root.leaf.season.name + ", " + Math.round(root.leaf.season.through * 100) + "% gone"; color: Ink.ink3; font.family: Type.text; font.pixelSize: Type.px(11.5) }
      }
    }
    Divider { skin: root.skin; width: parent.width; bleed: 0 }
    Row {
      spacing: Type.px(14)
      Column {
        Repeater {
          model: Array.from(root.leaf.ko.jp)
          Text { required property string modelData; text: modelData; color: Ink.ink; font.family: Type.jpSerif; font.weight: Font.Medium; font.pixelSize: Type.px(28) }
        }
      }
      Column {
        width: right.width - Type.px(46)
        spacing: Type.px(6)
        // Two lines kept for the kō and three for its note, however long.
        Text {
          width: parent.width; height: Type.px(48); wrapMode: Text.WordWrap; maximumLineCount: 2; elide: Text.ElideRight
          text: root.leaf.ko.english
          color: Ink.ink
          font.family: Type.display; font.pixelSize: Type.px(20); font.weight: Font.Normal
          font.variableAxes: Type.axes(Type.px(20), 380)
        }
        Text {
          width: parent.width; height: Type.px(46); wrapMode: Text.WordWrap; maximumLineCount: 3; elide: Text.ElideRight
          text: "Kō " + root.leaf.ko.no + " of the seventy-two, about five days each. "
            + (root.leaf.ko.left === root.leaf.next.in
               ? "Next, " + root.leaf.next.jp + " " + root.leaf.next.romaji + (root.leaf.next.in === 1 ? " tomorrow." : " in " + root.leaf.next.in + " days.")
               : "Next kō " + (root.leaf.ko.left === 1 ? "tomorrow" : "in " + root.leaf.ko.left + " days") + "; " + root.leaf.next.jp + " in " + root.leaf.next.in + ".")
          color: Ink.ink3; font.family: Type.text; font.pixelSize: Type.px(11.5)
        }
        Item { width: 1; height: Type.px(4) }
        Row {
          spacing: Type.px(8)
          MoonMark { anchors.verticalCenter: parent.verticalCenter; size: Type.px(15); age: root.leaf.moon.age; ink: Ink.ink }
          Text { anchors.verticalCenter: parent.verticalCenter; width: right.width - Type.px(70); elide: Text.ElideRight; text: root.leaf.moon.jp + " · " + root.leaf.moon.name; color: Ink.ink2; font.family: Type.text; font.pixelSize: Type.px(12) }
        }
        Row {
          opacity: ko.skyLine !== "" ? 1 : 0
          height: Type.px(30)
          spacing: Type.px(8)
          Text { anchors.verticalCenter: parent.verticalCenter; text: ko.skyMark; color: Ink.ink; font.family: Type.brush; font.pixelSize: Type.px(16) }
          Column {
            anchors.verticalCenter: parent.verticalCenter
            Text { width: right.width - Type.px(70); elide: Text.ElideRight; text: ko.skyLine; color: Ink.ink2; font.family: Type.text; font.pixelSize: Type.px(12) }
            Text { width: right.width - Type.px(70); elide: Text.ElideRight; text: ko.skyNote; color: Ink.ink3; font.family: Type.text; font.pixelSize: Type.px(11) }
          }
        }
      }
    }
  }

  // The year: twelve panes, the one turned to lit like washi with light behind.
  Item {
    id: year
    visible: !ko.compact
    y: Math.max(left.implicitHeight, right.implicitHeight) + Type.px(16)
    width: root.width
    height: Type.px(46)
    Repeater {
      model: ko.k.year
      Item {
        id: mo
        required property var modelData
        required property int index
        readonly property var mm: modelData
        x: index * year.width / 12
        width: year.width / 12
        height: year.height
        readonly property bool keyStop: true
        readonly property bool keyChosen: mm.shown
        function keyPress() { ko.month(mo.mm.m) }
        Rectangle {
          anchors.fill: parent
          color: mo.mm.shown ? Ink.alpha(Ink.bone, 0.16) : paneHover.containsMouse ? Ink.alpha(Ink.bone, 0.06) : "transparent"
          border.width: 1
          border.color: Ink.alpha(Ink.kLine, 0.7)
        }
        Column {
          anchors.centerIn: parent
          Text { anchors.horizontalCenter: parent.horizontalCenter; text: mo.mm.jp; color: mo.mm.shown ? Ink.ink : Ink.ink3; font.family: Type.jp; font.pixelSize: Type.px(11) }
          Text { anchors.horizontalCenter: parent.horizontalCenter; text: mo.mm.wafu; color: mo.mm.shown ? Ink.ink2 : Ink.ink4; font.family: Type.jp; font.pixelSize: Type.px(9) }
        }
        Rectangle {
          visible: mo.mm.current
          anchors.right: parent.right; anchors.top: parent.top; anchors.margins: Type.px(4)
          width: Type.px(5); height: width; radius: width / 2
          color: Ink.seal
        }
        MouseArea { id: paneHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: ko.month(mo.mm.m) }
      }
    }
  }

  KoyomiZones {
    id: zonesRow
    y: (year.visible ? year.y + year.height : Math.max(left.implicitHeight, right.implicitHeight)) + Type.px(14)
    width: root.width
    zones: root.zones
    hand: "shoji"
    rows: ko.compact ? 1 : 2
  }

  Keys.onPressed: function(event) { if (ko.key(event)) event.accepted = true }
}
