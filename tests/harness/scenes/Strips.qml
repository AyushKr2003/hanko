import QtQuick
import qs.Commons
import "../../../core"
import "../../../core/Style.js" as S
import "../../../bar"

// A sheet of labelled bars, one per strip. render.py passes `params`:
//   { theme: { foreground, background, red }, width, now, title,
//     strips: [ { label, doc } ] }   doc is a style.json document.
Rectangle {
  id: sheet

  readonly property var p: JSON.parse(params)
  width: p.width || 1600
  height: column.implicitHeight + 72
  color: Ink.paper

  // Hosted widgets for a strip: [{ id, label }] become registry-like
  // entries built from tests/harness/widgets/FakeWidget.qml.
  readonly property var fakeWidget: Qt.createComponent(Qt.resolvedUrl("../widgets/FakeWidget.qml"))
  function hostedFor(strip) {
    return (strip.hosted || []).map(function(h) {
      return { id: h.id, key: h.id, settings: { label: h.label }, component: sheet.fakeWidget, pluginId: h.id }
    })
  }

  // A strip's own value wins, then the sheet's, then nothing.
  function pick(strip, key) {
    if (strip[key] !== undefined) return strip[key]
    return p[key] !== undefined ? p[key] : null
  }

  Component.onCompleted: {
    Color.foreground = p.theme.foreground
    Color.background = p.theme.background
    Color.urgent = p.theme.red
  }

  Column {
    id: column
    x: 40
    y: 36
    width: sheet.width - 80
    spacing: 22

    Text {
      text: sheet.p.title || ""
      visible: text !== ""
      color: Ink.ink
      font.family: Type.display
      font.pixelSize: 30
      font.variableAxes: { "opsz": 72, "wght": 400 }
    }

    Repeater {
      model: sheet.p.strips

      Column {
        required property var modelData
        width: column.width
        spacing: 8

        Text {
          text: modelData.label
          color: Ink.inkMuted
          font.family: Type.mono
          font.pixelSize: 10
          font.letterSpacing: 1.6
        }

        Rectangle {
          id: desk
          readonly property var style: S.resolve(modelData.doc || {})
          // Inset floats 8 px off the screen's edges, like BarWindow's margins.
          readonly property int gap: style.surface === "inset" ? 8 : 0
          readonly property bool atBottom: style.position === "bottom"
          width: parent.width
          height: bar.height + 2 + gap
          color: "transparent"
          border.color: Ink.lineSoft
          clip: true

          // Something behind the bar, so glass has a desktop to show.
          Row {
            visible: !!modelData.backdrop
            x: desk.width * 0.55
            y: 1
            height: desk.height - 2
            spacing: 6
            Repeater {
              model: 40
              Rectangle {
                required property int index
                width: 6
                height: parent.height
                color: index % 3 === 0 ? Ink.seal : Ink.ink
              }
            }
          }

          BarSurface {
            id: bar
            x: 1 + desk.gap
            y: 1 + (desk.atBottom ? 0 : desk.gap)
            width: parent.width - 2 - 2 * desk.gap
            height: implicitHeight
            style: desk.style
            now: new Date(modelData.now || sheet.p.now || "2026-10-06T21:44:00")
            spaces: modelData.spaces || sheet.p.spaces || []
            activeWindow: modelData.window !== undefined ? modelData.window : (sheet.p.window || null)
            home: "/home/ayush"
            media: modelData.media !== undefined ? modelData.media : (sheet.p.media || null)
            timeFormat: modelData.timeFormat || "HH:mm"
            volume: sheet.pick(modelData, "volume")
            network: sheet.pick(modelData, "network")
            battery: sheet.pick(modelData, "battery")
            brightness: sheet.pick(modelData, "brightness")
            bluetooth: sheet.pick(modelData, "bluetooth")
            notifications: sheet.pick(modelData, "notifications") || []
            dnd: !!sheet.pick(modelData, "dnd")
            hosted: sheet.hostedFor(modelData)
            indicators: sheet.pick(modelData, "indicators") || []
            keyboard: sheet.pick(modelData, "keyboard")
            mic: sheet.pick(modelData, "mic")
            tray: sheet.pick(modelData, "tray") || []
            pointAt: modelData.pointAt || ""
          }
        }
      }
    }
  }
}
