pragma Singleton
import QtQuick

// Harness stand-in for Omarchy's qs.Commons.Color. Scenes set these three
// from a theme; the real one reads colors.toml.
QtObject {
  property color foreground: "#ddd5c7"
  property color background: "#0a0a09"
  property color urgent: "#d8452f"
  property color accent: foreground
}
