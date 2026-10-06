pragma Singleton
import QtQuick
QtObject {
  property var defaultAudioSink: null
  property QtObject nodes: QtObject { property var values: [] }
}
