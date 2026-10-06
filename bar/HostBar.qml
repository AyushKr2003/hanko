import QtQuick
import "../core"

// The `bar` a hosted widget sees (Omarchy's Ui/PluginBarApi.qml contract):
// Hanko's ink for its colours, Hanko's mono face, the bar's height as its
// size, and popouts coordinated with Hanko's own sheets. Every call into the
// host is guarded, since widgets call some of these while being torn down.
QtObject {
  id: facade

  // Bar.qml (or null in the harness) and the widget this facade serves.
  property var host: null
  property string moduleName: ""
  property string pluginId: moduleName
  property int barHeight: 40
  property string position: "top"

  readonly property color foreground: Ink.ink
  // Marks on the bar take the dim tier, like Hanko's own status glyphs.
  readonly property color barForeground: Ink.inkDim
  readonly property color background: Ink.paper
  readonly property color urgent: Ink.seal
  readonly property string fontFamily: Type.mono
  readonly property bool vertical: false
  readonly property int barSize: barHeight
  readonly property bool transparent: false
  readonly property bool foregroundAnimationEnabled: true
  readonly property bool centerSectionRevealHeld: false
  readonly property bool centerHoverRevealSuppressed: false
  readonly property var foreignPopoutMarker: ({ foreign: true })
  // Panels forward clicks on the bar strip to these (Omarchy's KeyboardPanel).
  property var clickTargets: []
  readonly property var layoutConfig: host && host.barConfig && host.barConfig.layout ? host.barConfig.layout : ({})
  readonly property var activePopout: !host || !host.hostedPopout ? null
    : _mine.indexOf(host.hostedPopout) >= 0 ? host.hostedPopout : foreignPopoutMarker
  // The host's scoped, service-less shell facade for this entry.
  readonly property var shell: host && host.shell && typeof host.shell.pluginShellForBarEntry === "function"
    ? host.shell.pluginShellForBarEntry(pluginId, moduleName) : null

  property var _mine: []

  function _call(name, args, fallback) {
    try {
      if (host && typeof host[name] === "function") return host[name].apply(host, args)
    } catch (e) {}
    return fallback
  }

  // Hanko has no tooltips: its cells say what they are.
  function showTooltip(target, text) {}
  function hideTooltip(target) {}
  function setCenterHoverRevealSuppressed(value) {}

  function requestPopout(owner) {
    if (_mine.indexOf(owner) < 0) _mine = _mine.concat([owner])
    _call("requestHostedPopout", [owner])
  }
  function releasePopout(owner) { _call("releaseHostedPopout", [owner]) }
  function registerClickTarget(target) {
    if (clickTargets.indexOf(target) < 0) clickTargets = clickTargets.concat([target])
  }
  function unregisterClickTarget(target) {
    clickTargets = clickTargets.filter(function(t) { return t !== target })
  }
  function switchPanelFrom(owner, direction) { return false }
  function targetBelongsToWindow(target, window) {
    return !!target && !!window && !!target.QsWindow && target.QsWindow.window === window
  }
  function moduleWidgets(id) { return _call("hostedWidgets", [String(id || "")], []) }
  function run(command) { _call("run", [String(command || "")]) }
}
