#!/usr/bin/env python3
"""Drive tests/harness/scenes/MotionProbe.qml with motion on and check the
bar's counters: a whole number rolls through the numbers between, lands on
the new one, and a word fades through instead.

  python3 tests/motion.py
"""
import os, sys, re
from pathlib import Path
os.environ["QT_QPA_PLATFORM"] = "offscreen"
from PySide6.QtCore import QUrl, qInstallMessageHandler
from PySide6.QtGui import QGuiApplication
from PySide6.QtQuick import QQuickView

HERE = Path(__file__).resolve().parent
out = []
def handler(mode, ctx, msg):
    out.append(msg)
qInstallMessageHandler(handler)
app = QGuiApplication(sys.argv[:1])
view = QQuickView()
view.engine().addImportPath(str(HERE / "harness" / "stubs"))
view.engine().quit.connect(app.quit)
view.setSource(QUrl.fromLocalFile(str(HERE / "harness" / "scenes" / "MotionProbe.qml")))
if view.status() == QQuickView.Error:
    for e in view.errors(): print(e.toString())
    sys.exit(1)
view.show()
app.exec()
probe = next((m for m in out if m.startswith("PROBE ")), "")
warn = [m for m in out if not m.startswith("PROBE ")]
for w in warn: print("warning:", w)
print(probe)
f = dict(p.split(":", 1) for p in probe.split()[1:])
ok = True
mid = f.get("mid", "")
if not (mid.isdigit() and 40 < int(mid) < 62): print("FAIL: no roll mid-way", mid); ok = False
if f.get("end") != "62": print("FAIL: did not land on 62", f.get("end")); ok = False
fading = f.get("fading", "0:")
if not float(fading.split(":")[0]) < 1: print("FAIL: a word should fade through", fading); ok = False
if not f.get("faded", "").endswith("Kumo") or not f["faded"].startswith("1.00"): print("FAIL: fade did not finish", f.get("faded")); ok = False
if warn: print("FAIL: warnings"); ok = False
print("motion ok" if ok else "motion FAILED")
sys.exit(0 if ok else 1)
