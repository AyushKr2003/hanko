.pragma library

// Ordered dither and value noise, for the settings page's sample plate.

var BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]

function hash(x, y) {
  var n = Math.sin(x * 127.1 + y * 311.7) * 43758.5453
  return n - Math.floor(n)
}

function valueNoise(x, y) {
  var xi = Math.floor(x), yi = Math.floor(y), xf = x - xi, yf = y - yi
  var u = xf * xf * (3 - 2 * xf), v = yf * yf * (3 - 2 * yf)
  var a = hash(xi, yi), b = hash(xi + 1, yi), c = hash(xi, yi + 1), d = hash(xi + 1, yi + 1)
  return a + (b - a) * u + (c - a) * v + (a - b - c + d) * u * v
}

function fbm(x, y) {
  var s = 0, a = 0.5
  for (var i = 0; i < 5; i++) { s += a * valueNoise(x, y); x *= 2.03; y *= 2.03; a *= 0.5 }
  return s
}
