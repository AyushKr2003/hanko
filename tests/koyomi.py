#!/usr/bin/env python3
"""Koyomi 暦 under stress: every hand of the almanac on a day in each of the
72 kō and each month, five cities, a long forecast, regular and large type.
Fails if a sheet is taller than the room it is given, changes height as you
pick days or turn months, or has a part past its sides or its own box.

  python3 tests/koyomi.py            # every hand, every third kō
  python3 tests/koyomi.py --all      # every kō
  python3 tests/koyomi.py -v ledger  # one hand, every overflow printed
"""
import os, sys, json, subprocess
from pathlib import Path
os.environ["QT_QPA_PLATFORM"] = "offscreen"
os.environ.setdefault("QT_SCALE_FACTOR", "1")
from PySide6.QtCore import QUrl, QTimer, qInstallMessageHandler
from PySide6.QtGui import QGuiApplication
from PySide6.QtQuick import QQuickView

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent
args = [a for a in sys.argv[1:] if a not in ("-v", "--all")]
verbose = "-v" in sys.argv
every = "--all" in sys.argv
HANDS = args or ["ledger", "tanzaku", "shogi", "soroban", "odoshi", "kasumi", "shoji"]

# The sky: sixteen days of the longest words and widest figures there are.
sky = json.loads(subprocess.check_output(["node", "-e", """
const {readFileSync}=require('fs');const src=readFileSync(process.argv[1],'utf8').replace(/^\\.pragma library\\s*$/m,'');
const K=new Function(src+'\\nreturn {forecast}')();
const time=[],code=[],hi=[],lo=[],rain=[];
for(let i=0;i<16;i++){const d=new Date(2026,9,6+i);time.push(d.getFullYear()+'-'+String(d.getMonth()+1).padStart(2,'0')+'-'+String(d.getDate()).padStart(2,'0'));
code.push([86,82,99,45,2,3,77,61][i%8]);hi.push(i%2?-12.4:104);lo.push(-28);rain.push(100)}
const raw={current:{temperature_2m:-18.6,apparent_temperature:-29.4,weather_code:86,wind_speed_10m:118,wind_direction_10m:315,is_day:1},
daily:{time,weather_code:code,temperature_2m_max:hi,temperature_2m_min:lo,precipitation_probability_max:rain}};
console.log(JSON.stringify(K.forecast(JSON.stringify(raw),false)))""", str(ROOT / "core/Koyomi.js")]))
zones = [{"label": n, "id": i, "ready": True, "time": "23:44", "date": "Wed 07 · " + a, "rel": r} for n, i, a, r in [
    ("Kolkata", "Asia/Kolkata", "IST", "+5:30"), ("Tokyo", "Asia/Tokyo", "JST", "+9"), ("Los Angeles", "America/Los_Angeles", "PDT", "−7"),
    ("New York", "America/New_York", "EDT", "−4"), ("London", "Europe/London", "BST", "+1"), ("São Paulo", "America/Sao_Paulo", "BRT", "−3"),
    ("Kathmandu", "Asia/Kathmandu", "NPT", "+5:45")]]
# A day in every kō (five days apart; --all) or every third kō (the
# default, as tests/run uses it), and months back and on.
picks = [0] + list(range(-180, 186, 5 if every else 15)) + [-365, -334, 31, 61, 92, 122, 153, 365, 2000]

# The room (SheetWindow's feed.room): the screen less the bar (36 px) and
# 24 px for the crop marks. 1080 px with five cities (the user's desk) and
# seven; a 768 px laptop; a short 640 px window; no cities at all.
def room(screen): return screen - 36 - 24
cases = [("regular", 5, room(1080)), ("regular", 7, room(1080)), ("regular", 5, room(768)), ("regular", 7, room(640)), ("regular", 0, room(768))]
bad = 0
for size, nz, room in cases:
    params = {"hands": HANDS, "picks": picks, "zones": zones[:nz], "sky": sky, "typeSize": size, "room": room}
    out = []
    qInstallMessageHandler(lambda m, c, s: out.append(s))
    app = QGuiApplication.instance() or QGuiApplication(sys.argv[:1])
    view = QQuickView()
    view.engine().addImportPath(str(HERE / "harness" / "stubs"))
    view.engine().quit.connect(app.quit)
    view.rootContext().setContextProperty("params", json.dumps(params))
    view.setSource(QUrl.fromLocalFile(str(HERE / "harness" / "scenes" / "KoyomiProbe.qml")))
    if view.status() == QQuickView.Error:
        for e in view.errors(): print(e.toString())
        sys.exit(1)
    view.show()
    # A sheet that fails to load never finishes: give up after four minutes.
    QTimer.singleShot(240000, lambda: (out.append("TIMEOUT"), app.quit()))
    app.exec()
    if "TIMEOUT" in out or not any(m.startswith("PROBE ") for m in out):
        print("FAIL the probe did not run; the first messages:")
        for m in [m for m in out if "propertyCache" not in m][:6]: print("     ", m[:200])
        bad += 1
        continue
    for w in [m for m in out if not m.startswith("PROBE ") and "propertyCache" not in m][:10]: print("warning:", w); bad += 1
    rows = [m.split(" ", 5) for m in out if m.startswith("PROBE ")]
    by = {}
    for r in rows: by.setdefault(r[1], []).append(r)
    for h, rs in by.items():
        hs = sorted(set(int(r[4]) for r in rs))
        over = [r for r in rs if len(r) > 5 and r[5].strip()]
        tall = max(hs)
        ok = tall <= room and len(hs) == 1 and not over
        if not ok: bad += 1
        print(f"{'ok  ' if ok else 'FAIL'} {size:7} {nz} cities  {h:8} width {rs[0][3]}  height {hs[0] if len(hs)==1 else str(hs[0])+'..'+str(tall)} / room {room}")
        # Each kind of overflow once, with the first pick it shows on.
        kinds = {}
        for r in over:
            for o in r[5].split(" | "):
                key = o.split("@")[0].split(" ")[0] + (o.split("'")[1] if "'" in o else "")
                kinds.setdefault(key, (r[2], o))
        for k, (pk, o) in list(kinds.items())[: (60 if verbose else 12)]: print("       pick", pk, o[:160])
print("koyomi ok" if not bad else f"koyomi: {bad} problems")
sys.exit(1 if bad else 0)
