#!/usr/bin/env python3
"""Render a harness scene to PNG, offscreen, with stub Quickshell modules.

  python3 tests/harness/render.py <scene.qml> <params.json> <out.png>

Needs PySide6 (pip install PySide6-Essentials). Fonts in $HANKO_HARNESS_FONTS
(a directory of .ttf files) are added first; use it for Noto CJK and a mono
face on machines that lack them.
"""
import os, sys, json
from pathlib import Path

# Always offscreen: under a Wayland session the default would open a real
# window, and the compositor would tile it to its own size.
os.environ["QT_QPA_PLATFORM"] = "offscreen"
os.environ.setdefault("QT_SCALE_FACTOR", "2")

from PySide6.QtCore import QUrl, QTimer
from PySide6.QtGui import QGuiApplication, QFontDatabase
from PySide6.QtQuick import QQuickView

HERE = Path(__file__).resolve().parent

def main():
    scene, params_path, out = sys.argv[1:4]
    app = QGuiApplication(sys.argv[:1])
    fonts = os.environ.get("HANKO_HARNESS_FONTS")
    if fonts:
        for f in sorted(Path(fonts).glob("*.ttf")):
            QFontDatabase.addApplicationFont(str(f))
    view = QQuickView()
    view.engine().addImportPath(str(HERE / "stubs"))
    view.rootContext().setContextProperty("params", Path(params_path).read_text())
    view.setResizeMode(QQuickView.SizeViewToRootObject)
    view.setSource(QUrl.fromLocalFile(str(Path(scene).resolve())))
    if view.status() == QQuickView.Error:
        for e in view.errors():
            print(e.toString(), file=sys.stderr)
        sys.exit(1)
    view.show()

    def grab():
        img = view.grabWindow()
        if img.isNull() or not img.save(out):
            print("could not save " + out, file=sys.stderr)
            app.exit(1)
        else:
            app.exit(0)
    # Two passes: fonts load, then singletons settle, then paint.
    QTimer.singleShot(400, grab)
    sys.exit(app.exec())

if __name__ == "__main__":
    main()
