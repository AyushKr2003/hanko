.pragma library

// Kaisei 回生, rising again (docs/kaze, mockup 10): when the Omarchy shell
// comes back after a crash (not after a restart you asked for), the desk
// shows a small 回生 for a few seconds. The sign of a crash is a core dump
// of quickshell from systemd-coredump, read with
//   coredumpctl list /usr/bin/quickshell --since=-120s --json=short
// whose entries carry `time` in microseconds since the epoch.

// How long after a crash the shell's return still counts as rising again.
var WINDOW_MS = 120000

// Whether the coredumpctl JSON shows a quickshell crash within WINDOW_MS
// before `nowMs`. Anything unreadable counts as no crash.
function crashedRecently(json, nowMs, windowMs) {
  var w = windowMs || WINDOW_MS
  var list
  try { list = JSON.parse(String(json || "")) } catch (e) { return false }
  if (!Array.isArray(list)) return false
  for (var i = 0; i < list.length; i++) {
    var t = Number(list[i] && list[i].time) / 1000
    var exe = String(list[i] && list[i].exe || "")
    if (exe.indexOf("quickshell") >= 0 && t <= nowMs && nowMs - t <= w) return true
  }
  return false
}
