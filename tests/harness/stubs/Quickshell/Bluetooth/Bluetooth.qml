pragma Singleton
import QtQuick
QtObject {
  property var defaultAdapter: null
  property QtObject devices: QtObject { property var values: [] }
}
