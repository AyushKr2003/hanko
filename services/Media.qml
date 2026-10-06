pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// Now playing. Prefers Omarchy's own choice of player (the omarchy.media
// proxy the host hands a full bar), so Hanko and Omarchy's media keys and OSD
// agree on which player is "the" player; falls back to MPRIS directly.
Singleton {
  id: root

  // Set by Bar.qml from shell.firstPartyServiceFor("omarchy.media").
  property var proxy: null

  readonly property var player: {
    if (proxy && proxy.activePlayer) return proxy.activePlayer
    var ps = Mpris.players.values
    for (var i = 0; i < ps.length; i++) if (ps[i].isPlaying) return ps[i]
    for (var j = 0; j < ps.length; j++) if (ps[j].trackTitle) return ps[j]
    return null
  }

  readonly property bool active: !!(player && (player.trackTitle || player.trackArtist))
  readonly property string title: player ? player.trackTitle || "" : ""
  readonly property string artist: player ? player.trackArtist || "" : ""
  readonly property bool playing: !!(player && player.isPlaying)
  readonly property real progress: player && player.length > 0 ? Math.max(0, Math.min(1, player.position / player.length)) : 0

  // { title, artist, progress, playing } or null: the plain shape the bar takes.
  readonly property var now: active ? { title: title, artist: artist, progress: progress, playing: playing } : null

  function act(action) {
    if (proxy) { proxy.runAction(action, false, ""); return }
    if (!player) return
    if (action === "next" && player.canGoNext) player.next()
    else if (action === "previous" && player.canGoPrevious) player.previous()
    else if (action === "playPause" && player.canTogglePlaying) player.togglePlaying()
  }

  // MPRIS only reports position on request; tick it while something plays.
  Timer {
    running: root.playing
    interval: 1000
    repeat: true
    onTriggered: if (root.player) root.player.positionChanged()
  }
}
