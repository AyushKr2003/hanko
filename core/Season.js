.pragma library

// The 24 solar terms (sekki) and 72 micro-seasons (kō) for any date, from
// the sun's ecliptic longitude: each kō is 5° of it, starting at 315°
// (立春). Exact in any year with no table of dates, unlike the day-of-year
// approximations in Leaf.js. Used by Kata's season touch (design 3, Shōji).

var SEKKI = [
  ["立春", "Risshun", "Spring begins"], ["雨水", "Usui", "Rain water"], ["啓蟄", "Keichitsu", "Insects awaken"],
  ["春分", "Shunbun", "Spring equinox"], ["清明", "Seimei", "Clear and bright"], ["穀雨", "Kokuu", "Grain rain"],
  ["立夏", "Rikka", "Summer begins"], ["小満", "Shōman", "Lesser ripening"], ["芒種", "Bōshu", "Grain in ear"],
  ["夏至", "Geshi", "Summer solstice"], ["小暑", "Shōsho", "Lesser heat"], ["大暑", "Taisho", "Greater heat"],
  ["立秋", "Risshū", "Autumn begins"], ["処暑", "Shosho", "Heat eases"], ["白露", "Hakuro", "White dew"],
  ["秋分", "Shūbun", "Autumn equinox"], ["寒露", "Kanro", "Cold dew"], ["霜降", "Sōkō", "Frost falls"],
  ["立冬", "Rittō", "Winter begins"], ["小雪", "Shōsetsu", "Lesser snow"], ["大雪", "Taisetsu", "Greater snow"],
  ["冬至", "Tōji", "Winter solstice"], ["小寒", "Shōkan", "Lesser cold"], ["大寒", "Daikan", "Greater cold"]
]

var KO = [
  ["東風解凍", "East wind melts the ice"], ["黄鶯睍睆", "Bush warblers sing"], ["魚上氷", "Fish rise from the ice"],
  ["土脉潤起", "Rain moistens the soil"], ["霞始靆", "Mist begins to linger"], ["草木萌動", "Grass sprouts, trees bud"],
  ["蟄虫啓戸", "Hibernating insects surface"], ["桃始笑", "First peach blossoms"], ["菜虫化蝶", "Caterpillars become butterflies"],
  ["雀始巣", "Sparrows start to nest"], ["桜始開", "First cherry blossoms"], ["雷乃発声", "Distant thunder"],
  ["玄鳥至", "Swallows return"], ["鴻雁北", "Wild geese fly north"], ["虹始見", "First rainbows"],
  ["葭始生", "First reeds sprout"], ["霜止出苗", "Last frost, rice seedlings grow"], ["牡丹華", "Peonies bloom"],
  ["蛙始鳴", "Frogs start singing"], ["蚯蚓出", "Worms surface"], ["竹笋生", "Bamboo shoots sprout"],
  ["蚕起食桑", "Silkworms feast on mulberry"], ["紅花栄", "Safflowers bloom"], ["麦秋至", "Wheat ripens"],
  ["蟷螂生", "Praying mantises hatch"], ["腐草為螢", "Fireflies rise from the grass"], ["梅子黄", "Plums turn yellow"],
  ["乃東枯", "Self-heal withers"], ["菖蒲華", "Irises bloom"], ["半夏生", "Crow-dipper sprouts"],
  ["温風至", "Warm winds blow"], ["蓮始開", "First lotus blossoms"], ["鷹乃学習", "Hawks learn to fly"],
  ["桐始結花", "Paulownia sets its seeds"], ["土潤溽暑", "Damp earth, humid air"], ["大雨時行", "Great rains sometimes fall"],
  ["涼風至", "Cool winds blow"], ["寒蝉鳴", "Evening cicadas sing"], ["蒙霧升降", "Thick fog descends"],
  ["綿柎開", "Cotton bolls open"], ["天地始粛", "The heat finally eases"], ["禾乃登", "Rice ripens"],
  ["草露白", "Dew glistens white on grass"], ["鶺鴒鳴", "Wagtails sing"], ["玄鳥去", "Swallows leave"],
  ["雷乃収声", "Thunder ceases"], ["蟄虫坏戸", "Insects hole up underground"], ["水始涸", "Fields are drained"],
  ["鴻雁来", "Wild geese return"], ["菊花開", "Chrysanthemums bloom"], ["蟋蟀在戸", "Crickets chirp at the door"],
  ["霜始降", "First frost"], ["霎時施", "Light rains sometimes fall"], ["楓蔦黄", "Maples and ivy turn"],
  ["山茶始開", "Camellias bloom"], ["地始凍", "The land starts to freeze"], ["金盞香", "Daffodils bloom"],
  ["虹蔵不見", "Rainbows hide"], ["朔風払葉", "North wind strips the leaves"], ["橘始黄", "Tachibana citrus turns yellow"],
  ["閉塞成冬", "Cold sets in, winter begins"], ["熊蟄穴", "Bears go into their dens"], ["鱖魚群", "Salmon gather upstream"],
  ["乃東生", "Self-heal sprouts"], ["麋角解", "Deer shed their antlers"], ["雪下出麦", "Wheat sprouts under snow"],
  ["芹乃栄", "Parsley flourishes"], ["水泉動", "Springs thaw"], ["雉始雊", "Pheasants start to call"],
  ["款冬華", "Butterburs bud"], ["水沢腹堅", "Ice thickens on the streams"], ["鶏始乳", "Hens start laying"]
]

// Low-precision solar longitude in degrees (good to about 0.01°).
function sunLongitude(date) {
  var n = date.getTime() / 864e5 + 2440587.5 - 2451545.0
  var rad = Math.PI / 180
  var L = (280.460 + 0.9856474 * n) % 360
  var g = ((357.528 + 0.9856003 * n) % 360) * rad
  var lam = (L + 1.915 * Math.sin(g) + 0.020 * Math.sin(2 * g)) % 360
  return (lam + 360) % 360
}

function koIndex(date) {
  return Math.floor(((sunLongitude(date) - 315 + 360) % 360) / 5) % 72
}

// { ko, koName, koKanji, sekki, sekkiKanji, sekkiRomaji, sekkiName }
function at(date) {
  var k = koIndex(date), s = Math.floor(k / 3)
  return { ko: k, koKanji: KO[k][0], koName: KO[k][1], sekki: s, sekkiKanji: SEKKI[s][0], sekkiRomaji: SEKKI[s][1], sekkiName: SEKKI[s][2] }
}

// What the bar shows beside the date for the season touch.
function label(date, how) {
  if (how !== "kanji" && how !== "english") return ""
  var s = at(date)
  return how === "kanji" ? s.sekkiKanji : s.sekkiName
}
