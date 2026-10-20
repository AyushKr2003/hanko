.pragma library

// Omarchy's themes, for Settings › Colour 色. Pure JavaScript:
// services/Themes.qml lists them and this reads the list.

function trim(s) { return String(s === undefined || s === null ? "" : s).replace(/^\s+|\s+$/g, "") }

// Omarchy's theme slug as its theme list prints it ("tokyo-night" ->
// "Tokyo Night"), the same sed omarchy-theme-list runs.
function themeName(slug) {
  return trim(slug).replace(/(^|-)([a-z])/g, function(m, a, b) { return a + b.toUpperCase() }).replace(/-/g, " ")
}

// services/Themes.qml's theme script prints `slug<TAB>bg<TAB>fg<TAB>red<TAB>mode`
// per theme, the user's own copies first; Omarchy's list keeps one of each.
function themes(text) {
  var seen = {}, out = []
  var lines = String(text || "").split("\n")
  for (var i = 0; i < lines.length; i++) {
    var f = lines[i].split("\t")
    var slug = trim(f[0])
    if (!slug || seen[slug]) continue
    var bg = trim(f[1]), fg = trim(f[2]), red = trim(f[3])
    if (!/^#[0-9a-fA-F]{6}$/.test(bg) || !/^#[0-9a-fA-F]{6}$/.test(fg)) continue
    seen[slug] = true
    out.push({ slug: slug, name: themeName(slug), bg: bg, fg: fg,
               red: /^#[0-9a-fA-F]{6}$/.test(red) ? red : fg, light: trim(f[4]) === "light" })
  }
  return out.sort(function(a, b) { return a.name.toLowerCase() < b.name.toLowerCase() ? -1 : a.name.toLowerCase() > b.name.toLowerCase() ? 1 : 0 })
}
