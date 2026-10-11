import QtQuick
import "../../core"
import ".."

// A bar on a settings page, drawn from the live data with a given style. It
// is laid out at least a desktop's width and scaled down to fit, so a narrow
// page shows the bar as it looks on a screen instead of a crushed one.
// Typesetting shows yours; Presets one per preset.
Item {
  id: previewItem
  property var style: ({})
  // SettingsPage.barData: { now, spaces, activeWindow, home, media, volume,
  // network, bluetooth, battery, brightness, notifications, dnd, timeFormat }.
  property var barData: ({})
  // The narrowest desk the bar is laid out on before it is scaled down.
  property real minDesign: Type.px(1240)
  readonly property real design: Math.max(width, minDesign)
  height: Math.round(surface.implicitHeight * width / design)
  BarSurface {
    id: surface
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
