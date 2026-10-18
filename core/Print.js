.pragma library

// Sumizuri 墨摺 (docs/kaze, mockup 03): the wallpaper printed again in the
// theme's paper and ink. scripts/hanko-print does the printing with
// ImageMagick; plugins/hanko.background shows the result. This file holds
// the decisions, so they can be tested.
//
// Whatever covers most of the picture becomes the paper. On a dark theme a
// mostly light print turns into a rubbing (ishizuri 石摺): white marks on a
// black stone. No red is ever printed: red stays for "you" and "now".

// The tones the picture is crushed to (Tsushima's menu art crushed its values).
var TONES = 5
// The levels clipped off either end before crushing, in percent.
var CLIP = 6

// How to print a picture of mean brightness `mean` (0..1) on a theme.
//   negate  invert the picture first, so its majority tone lands on paper
//   from    the colour its darkest tone becomes, to  its lightest
// On a dark theme the dark end is paper; on a light theme the light end is.
function steps(mean, light, paper, ink) {
  var m = Number(mean)
  if (!(m >= 0)) m = 0.5
  if (light) return { negate: m < 0.5, from: ink, to: paper }
  return { negate: m > 0.5, from: paper, to: ink }
}

// The ink the print goes up to: faint on a dark theme, so the print never
// competes with the windows; muted on a light one, where faint would vanish.
function inkFor(ramp, light) {
  return light ? ramp.inkMuted : ramp.inkFaint
}

// The sky keeps the hour (mockup 03, "90% of the mood comes from your upper
// hemisphere"): the top 40% of the print lifts toward the ink by day and
// settles into shade at night, a few percent only. `hour` is local, 0..24.
// Returns { lift, shade }: alphas for an ink wash and a dark wash.
function skyAt(hour) {
  var h = ((Number(hour) % 24) + 24) % 24
  // The sun's height, roughly: 0 at 6 and 18, 1 at noon, below 0 at night.
  var sun = Math.sin((h - 6) / 12 * Math.PI)
  var lift = Math.max(0, sun) * 0.07
  var shade = Math.max(0, -sun) * 0.22
  return { lift: Math.round(lift * 1000) / 1000, shade: Math.round(shade * 1000) / 1000 }
}

// The few settings Kaze keeps for the wallpaper, from ~/.config/hanko/kaze.json.
function wallpaperMode(doc) {
  var v = doc && doc.wallpaper
  return v === "original" ? "original" : "print"
}
