.pragma library

// A file of the plugin as a path a process can run or read. The shell loads
// a plugin outside its config folder under qs:///<absolute path>, not
// file://, so Qt.resolvedUrl() hands back either; both are stripped (the
// rest is already absolute) and any %-escapes decoded.
function local(url) {
  var path = String(url || "").replace(/^(file|qs):\/\//, "")
  try { return decodeURIComponent(path) } catch (e) { return path }
}
