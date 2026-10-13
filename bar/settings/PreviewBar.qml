import QtQuick
import "../../core"
import "../../core/Inkan.js" as Inkan
import ".."

// A bar on a settings page, drawn from the live data with a given style. It
// is laid out at least a desktop's width and scaled down to fit, so a narrow
// page shows the bar as it looks on a screen instead of a crushed one.
// Typesetting shows yours; Presets one per preset. Under form: inkan there
// is no bar to show: a strip of desk with the seal at its side of the
// screen and its reading set in beside it, as on hover.
Item {
  id: previewItem
  property var style: ({})
  // SettingsPage.barData: { now, spaces, activeWindow, home, media, volume,
  // network, bluetooth, battery, brightness, notifications, dnd, timeFormat }.
  property var barData: ({})
  // The narrowest desk the bar is laid out on before it is scaled down.
  property real minDesign: Type.px(1240)
  readonly property real design: Math.max(width, minDesign)
  readonly property bool inkan: style.form === "inkan"
  readonly property bool sealLeft: String(style.inkanAt).indexOf("left") > 0
  height: inkan ? Type.px(Inkan.SIZE) + 2 * Type.px(14) : Math.round(surface.implicitHeight * width / design)

  InkanSeal {
    id: seal
    visible: previewItem.inkan
    x: previewItem.sealLeft ? Type.px(14) : previewItem.width - Type.px(14) - width
    y: Type.px(14)
    hovered: true
    carving: Inkan.carving(previewItem.style, {
      battery: previewItem.barData.battery || null,
      network: previewItem.barData.network || null,
      notifications: previewItem.barData.notifications || [],
      dnd: !!previewItem.barData.dnd,
      workspace: (function() {
        var list = previewItem.barData.spaces || []
        for (var i = 0; i < list.length; i++) if (list[i].active) return list[i].id
        return 1
      })()
    })
  }
  InkanReading {
    visible: previewItem.inkan
    parts: Inkan.reading(previewItem.barData, Qt.formatTime(previewItem.barData.now || new Date(), previewItem.barData.timeFormat || "HH:mm"))
    y: seal.y + (seal.height - height) / 2
    x: previewItem.sealLeft ? seal.x + seal.width + Type.px(14) : seal.x - Type.px(14) - width
  }

  BarSurface {
    id: surface
    visible: !previewItem.inkan
    width: previewItem.design
    height: implicitHeight
    scale: previewItem.width / previewItem.design
    transformOrigin: Item.TopLeft
    style: previewItem.style
    now: previewItem.barData.now || new Date()
    spaces: previewItem.barData.spaces || []
    activeWindow: previewItem.barData.activeWindow || null
    home: previewItem.barData.home || ""
    media: previewItem.barData.media || null
    timeFormat: previewItem.barData.timeFormat || "HH:mm"
    volume: previewItem.barData.volume || null
    network: previewItem.barData.network || null
    bluetooth: previewItem.barData.bluetooth || null
    battery: previewItem.barData.battery || null
    brightness: previewItem.barData.brightness || null
    notifications: previewItem.barData.notifications || []
    dnd: !!previewItem.barData.dnd
  }
}
