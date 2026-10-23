#!/usr/bin/env python3
"""Draw the almanac's month turn (Koyomi 暦) frame by frame, motion on.

  python3 tests/harness/turn.py <hand> <out-prefix> [days] [sky.json]

Opens the Time sheet in <hand> (ledger, tanzaku, shogi, soroban, odoshi,
kasumi, shoji) on 6 October 2026, turns it by [days] (31: on to November)
and saves <out-prefix>-00.png (before) to -18.png, 45 ms apart, at 1x.
sky.json is a forecast as core/Koyomi.js forecast() returns it.
"""
import os, sys, json
from pathlib import Path
os.environ["QT_QPA_PLATFORM"] = "offscreen"
os.environ.setdefault("QT_SCALE_FACTOR", "1")
from PySide6.QtCore import QUrl, QTimer
from PySide6.QtGui import QGuiApplication
from PySide6.QtQuick import QQuickView

HERE = Path(__file__).resolve().parent
hand, out = sys.argv[1], sys.argv[2]
days = int(sys.argv[3]) if len(sys.argv) > 3 else 31
sky = json.loads(Path(sys.argv[4]).read_text()) if len(sys.argv) > 4 else None
app = QGuiApplication(sys.argv[:1])
view = QQuickView()
view.engine().addImportPath(str(HERE / "stubs"))
view.rootContext().setContextProperty("params", json.dumps({"hand": hand, "sky": sky}))
view.setResizeMode(QQuickView.SizeViewToRootObject)
view.setSource(QUrl.fromLocalFile(str(HERE / "scenes" / "KoyomiTurn.qml")))
if view.status() == QQuickView.Error:
    for e in view.errors(): print(e.toString(), file=sys.stderr)
    sys.exit(1)
view.show()
frames = []
START = 700
QTimer.singleShot(START - 100, lambda: frames.append(view.grabWindow()))
QTimer.singleShot(START, lambda: view.rootObject().setProperty("pick", days))
ticks = [START + 30 + 45 * k for k in range(18)]
for t in ticks: QTimer.singleShot(t, lambda: frames.append(view.grabWindow()))
def done():
    for i, f in enumerate(frames): f.save(f"{out}-{i:02d}.png")
    app.exit(0)
QTimer.singleShot(ticks[-1] + 200, done)
sys.exit(app.exec())
