import QtQuick
QtObject {
  enum Precision { Hours, Minutes, Seconds }
  property int precision: 1
  property date date: new Date()
}
