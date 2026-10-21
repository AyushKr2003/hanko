.pragma library

// The Japanese almanac (koyomi 暦): the solar term and microseason a day
// falls in, the moon, and a month laid out as a grid. Pure JavaScript; the
// lock's standoff (core/Standoff.qml) shows the microseason, and
// scripts/hanko-greet reads the KO table straight from this file.

function two(n) { return (n < 10 ? "0" : "") + n }

var MONTHS = ["January", "February", "March", "April", "May", "June", "July",
              "August", "September", "October", "November", "December"]

// The 24 solar terms (sekki) and 72 microseasons (kō) of the Japanese
// almanac, by the day each starts in an ordinary year (they move by a day
// or so year to year; good enough for a calendar on a bar).
var SEKKI = [
  ["立春", "Risshun", "start of spring", 2, 4], ["雨水", "Usui", "rain water", 2, 19],
  ["啓蟄", "Keichitsu", "insects awaken", 3, 6], ["春分", "Shunbun", "spring equinox", 3, 21],
  ["清明", "Seimei", "clear and bright", 4, 5], ["穀雨", "Kokuu", "grain rain", 4, 20],
  ["立夏", "Rikka", "start of summer", 5, 5], ["小満", "Shōman", "lesser ripening", 5, 21],
  ["芒種", "Bōshu", "grain in ear", 6, 6], ["夏至", "Geshi", "summer solstice", 6, 21],
  ["小暑", "Shōsho", "lesser heat", 7, 7], ["大暑", "Taisho", "greater heat", 7, 23],
  ["立秋", "Risshū", "start of autumn", 8, 7], ["処暑", "Shosho", "end of heat", 8, 23],
  ["白露", "Hakuro", "white dew", 9, 7], ["秋分", "Shūbun", "autumn equinox", 9, 23],
  ["寒露", "Kanro", "cold dew", 10, 8], ["霜降", "Sōkō", "frost falls", 10, 23],
  ["立冬", "Rittō", "start of winter", 11, 7], ["小雪", "Shōsetsu", "lesser snow", 11, 22],
  ["大雪", "Taisetsu", "greater snow", 12, 7], ["冬至", "Tōji", "winter solstice", 12, 22],
  ["小寒", "Shōkan", "lesser cold", 1, 5], ["大寒", "Daikan", "greater cold", 1, 20]
]
var SEASONS = ["spring", "summer", "autumn", "winter"]

// Kō 1..72 (kanji, English, month, day), from 東風解凍 on 4 February.
var KO = [
  ["東風解凍", "east wind melts the ice", 2, 4], ["黄鶯睍睆", "bush warblers sing", 2, 9], ["魚上氷", "fish rise from the ice", 2, 14],
  ["土脉潤起", "rain moistens the soil", 2, 19], ["霞始靆", "mist starts to linger", 2, 24], ["草木萌動", "grass sprouts, trees bud", 3, 1],
  ["蟄虫啓戸", "insects come out", 3, 6], ["桃始笑", "first peach blossoms", 3, 11], ["菜虫化蝶", "caterpillars become butterflies", 3, 16],
  ["雀始巣", "sparrows start to nest", 3, 21], ["櫻始開", "first cherry blossoms", 3, 26], ["雷乃発声", "distant thunder", 3, 31],
  ["玄鳥至", "swallows return", 4, 5], ["鴻雁北", "wild geese fly north", 4, 10], ["虹始見", "first rainbows", 4, 15],
  ["葭始生", "first reeds sprout", 4, 20], ["霜止出苗", "last frost, rice seedlings", 4, 25], ["牡丹華", "peonies bloom", 4, 30],
  ["蛙始鳴", "frogs start singing", 5, 5], ["蚯蚓出", "worms surface", 5, 10], ["竹笋生", "bamboo shoots sprout", 5, 15],
  ["蚕起食桑", "silkworms feast on mulberry", 5, 21], ["紅花栄", "safflowers bloom", 5, 26], ["麦秋至", "wheat ripens", 5, 31],
  ["螳螂生", "praying mantises hatch", 6, 6], ["腐草為螢", "fireflies over the grass", 6, 11], ["梅子黄", "plums turn yellow", 6, 16],
  ["乃東枯", "self-heal withers", 6, 21], ["菖蒲華", "irises bloom", 6, 26], ["半夏生", "crow-dipper sprouts", 7, 2],
  ["温風至", "warm winds blow", 7, 7], ["蓮始開", "first lotus blossoms", 7, 12], ["鷹乃学習", "hawks learn to fly", 7, 17],
  ["桐始結花", "paulownia seeds", 7, 23], ["土潤溽暑", "damp earth, humid air", 7, 28], ["大雨時行", "great rains fall", 8, 2],
  ["涼風至", "cool winds blow", 8, 7], ["寒蝉鳴", "evening cicadas sing", 8, 12], ["蒙霧升降", "thick fog descends", 8, 17],
  ["綿柎開", "cotton flowers open", 8, 23], ["天地始粛", "the heat dies down", 8, 28], ["禾乃登", "rice ripens", 9, 2],
  ["草露白", "dew glistens on the grass", 9, 7], ["鶺鴒鳴", "wagtails sing", 9, 12], ["玄鳥去", "swallows leave", 9, 17],
  ["雷乃収声", "thunder ceases", 9, 23], ["蟄虫坏戸", "insects hole up", 9, 28], ["水始涸", "farmers drain their fields", 10, 3],
  ["鴻雁来", "wild geese return", 10, 8], ["菊花開", "chrysanthemums bloom", 10, 13], ["蟋蟀在戸", "crickets at the door", 10, 18],
  ["霜始降", "first frost", 10, 23], ["霎時施", "light rains fall", 10, 28], ["楓蔦黄", "maple and ivy turn", 11, 2],
  ["山茶始開", "camellias bloom", 11, 7], ["地始凍", "the land starts to freeze", 11, 12], ["金盞香", "daffodils bloom", 11, 17],
  ["虹蔵不見", "rainbows hide", 11, 22], ["朔風払葉", "north wind strips the leaves", 11, 27], ["橘始黄", "tachibana leaves yellow", 12, 2],
  ["閉塞成冬", "cold sets in, winter begins", 12, 7], ["熊蟄穴", "bears go to their dens", 12, 12], ["鱖魚群", "salmon gather upstream", 12, 16],
  ["乃東生", "self-heal sprouts", 12, 22], ["麋角解", "deer shed their antlers", 12, 26], ["雪下出麦", "wheat sprouts under snow", 12, 31],
  ["芹乃栄", "parsley flourishes", 1, 5], ["水泉動", "springs thaw", 1, 10], ["雉始雊", "pheasants start to call", 1, 15],
  ["款冬華", "butterburs bud", 1, 20], ["水沢腹堅", "ice thickens on streams", 1, 25], ["鶏始乳", "hens start laying", 1, 30]
]

// The entry of a (month, day) table that `d` falls in: the last one that
// started on or before it, wrapping round the new year.
function termIndex(table, d) {
  var md = (d.getMonth() + 1) * 100 + d.getDate()
  var best = -1, bestMd = -1
  for (var i = 0; i < table.length; i++) {
    var t = table[i][table[i].length - 2] * 100 + table[i][table[i].length - 1]
    if (t <= md && t > bestMd) { best = i; bestMd = t }
  }
  if (best >= 0) return best
  // Before the year's first start (1-4 January): the last one of last year.
  for (var j = 0; j < table.length; j++) {
    var u = table[j][table[j].length - 2] * 100 + table[j][table[j].length - 1]
    if (u > bestMd) { best = j; bestMd = u }
  }
  return best
}

function startOf(entry, year) {
  return new Date(year, entry[entry.length - 2] - 1, entry[entry.length - 1])
}

// The next start of a table entry after `d`.
function nextStart(entry, d) {
  var s = startOf(entry, d.getFullYear())
  if (s <= d) s = startOf(entry, d.getFullYear() + 1)
  return s
}

// The moon: age in days since new, how much is lit, waxing or waning, and
// the next new and full moons. From the mean synodic month and a known new
// moon (6 January 2000, 18:14 UTC): within about half a day, plenty here.
var SYNODIC = 29.530588853
var NEW_MOON = Date.UTC(2000, 0, 6, 18, 14)
function moon(d) {
  var days = (d.getTime() - NEW_MOON) / 86400000
  var age = ((days % SYNODIC) + SYNODIC) % SYNODIC
  var lit = (1 - Math.cos(2 * Math.PI * age / SYNODIC)) / 2
  var toNew = SYNODIC - age
  var toFull = age < SYNODIC / 2 ? SYNODIC / 2 - age : SYNODIC * 1.5 - age
  var nextNew = new Date(d.getTime() + toNew * 86400000)
  var nextFull = new Date(d.getTime() + toFull * 86400000)
  var waxing = age < SYNODIC / 2
  var next = toNew < toFull ? { word: "New", date: nextNew } : { word: "Full", date: nextFull }
  return {
    age: age,
    lit: lit,
    percent: Math.round(lit * 100),
    waxing: waxing,
    phase: age < 1.5 || age > SYNODIC - 1.5 ? "new" : Math.abs(age - SYNODIC / 2) < 1.5 ? "full"
      : (waxing ? (lit < 0.5 ? "waxing crescent" : "waxing gibbous") : (lit < 0.5 ? "waning crescent" : "waning gibbous")),
    next: next.word + " · " + ordinal(next.date.getDate()),
    nextDate: next.date
  }
}

function ordinal(n) {
  var s = (n % 100 >= 11 && n % 100 <= 13) ? "th" : ["th", "st", "nd", "rd", "th", "th", "th", "th", "th", "th"][n % 10]
  return n + s
}

function dayOfYear(d) {
  var start = new Date(d.getFullYear(), 0, 1)
  return Math.round((new Date(d.getFullYear(), d.getMonth(), d.getDate()) - start) / 86400000) + 1
}
function daysInYear(y) { return (y % 4 === 0 && y % 100 !== 0) || y % 400 === 0 ? 366 : 365 }

// The almanac for `d`: a Monday-first month grid (35 or 42 cells), the
// solar term and microseason we are in and the next term, the moon, and
// how far through the year we are.
function almanac(d) {
  var y = d.getFullYear(), m = d.getMonth()
  var first = new Date(y, m, 1)
  var lead = (first.getDay() + 6) % 7
  var count = new Date(y, m + 1, 0).getDate()
  var si = termIndex(SEKKI, d)
  var ki = termIndex(KO, d)
  var sekki = SEKKI[si], nextSekki = SEKKI[(si + 1) % SEKKI.length]
  var nextAt = nextStart(nextSekki, d)
  var cells = []
  var total = lead + count <= 35 ? 35 : 42
  for (var i = 0; i < total; i++) {
    var day = i - lead + 1
    var inMonth = day >= 1 && day <= count
    cells.push({
      day: inMonth ? day : 0,
      label: inMonth ? two(day) : "",
      today: inMonth && day === d.getDate(),
      past: inMonth && day < d.getDate(),
      weekend: i % 7 >= 5,
      // The day the next solar term starts, when it falls this month.
      term: inMonth && nextAt.getFullYear() === y && nextAt.getMonth() === m && nextAt.getDate() === day
    })
  }
  var doy = dayOfYear(d), diy = daysInYear(y)
  var season = SEASONS[Math.floor(((si + 24) % 24) / 6)]
  return {
    month: MONTHS[m],
    year: y,
    cells: cells,
    sekki: { jp: sekki[0], name: sekki[1], english: sekki[2], season: season },
    ko: { no: ki + 1, jp: KO[ki][0], english: KO[ki][1] },
    next: { jp: nextSekki[0], name: nextSekki[1], english: nextSekki[2], day: nextAt.getDate(), date: nextAt },
    moon: moon(d),
    day: doy,
    days: diy,
    yearDone: (doy - 1 + (d.getHours() * 60 + d.getMinutes()) / 1440) / diy,
    title: sekki[1] + ", <i>" + season + "</i>",
    caption: "Kō " + (ki + 1) + " · " + KO[ki][1]
  }
}
