.pragma library

// Where the weather is, for the wind in hanko.background's grass.
//
// The place follows Omarchy's own weather panel (shell/plugins/panels/
// weather), so the wind blows where Omarchy says you are:
//  - the place comes from ~/.local/state/omarchy/settings/weather.json
//    ({name, latitude, longitude}, owned by omarchy-weather-location);
//    without coordinates the place is found from the IP address the way
//    Omarchy does, through wttr.in's nearest_area;
//  - the wind comes from Open-Meteo (fast, keyless).

function trim(s) { return String(s === undefined || s === null ? "" : s).replace(/^\s+|\s+$/g, "") }

// weather.json → { name, latitude, longitude } (null coordinates = auto).
function location(raw) {
  var unset = { name: "", latitude: null, longitude: null }
  try {
    var d = JSON.parse(String(raw || ""))
    if (!d || typeof d !== "object") return unset
    var lat = parseFloat(d.latitude), lon = parseFloat(d.longitude)
    var ok = !isNaN(lat) && !isNaN(lon)
    return { name: typeof d.name === "string" ? trim(d.name) : "", latitude: ok ? lat : null, longitude: ok ? lon : null }
  } catch (e) {
    return unset
  }
}

// wttr.in j1 → { name, country, latitude, longitude } of the detected area.
function area(raw) {
  try {
    var a = JSON.parse(String(raw || "")).nearest_area[0]
    var v = function(x) { return x && x[0] ? trim(x[0].value) : "" }
    var lat = parseFloat(a.latitude), lon = parseFloat(a.longitude)
    if (isNaN(lat) || isNaN(lon)) return null
    return { name: v(a.areaName), country: v(a.country), latitude: lat, longitude: lon }
  } catch (e) {
    return null
  }
}

// One request: the wind now.
function url(latitude, longitude) {
  return "https://api.open-meteo.com/v1/forecast"
    + "?latitude=" + encodeURIComponent(String(latitude))
    + "&longitude=" + encodeURIComponent(String(longitude))
    + "&current=wind_speed_10m,wind_direction_10m"
}
