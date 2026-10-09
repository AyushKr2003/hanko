.pragma library

// Mon 紋: which crest a choice on a crest-book sheet bears when it has no
// level to show. Each gets one of the classic geometric crests, in order:
// one, two and three bars (引両), the lozenge (菱), the well frame (井桁)
// and interlaced rings (輪違い), so neighbours never wear the same mon.
var ORDER = [
  { kind: "bars", count: 1 }, { kind: "bars", count: 2 }, { kind: "bars", count: 3 },
  { kind: "hishi", count: 1 }, { kind: "igeta", count: 1 }, { kind: "wa", count: 1 }
]

function at(i) {
  var n = ORDER.length
  return ORDER[((Number(i) || 0) % n + n) % n]
}

// The weekday kanji for a date's day (0 = Sunday), for Time's crests.
var WEEKDAYS = ["日", "月", "火", "水", "木", "金", "土"]
