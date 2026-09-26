import QtQuick

// The gate: silence runs the auto show, any key or click opens the menu.
Text {
  id: root
  property int seconds: 5
  property color foreground: "#FFFFFF"
  property real areaHeight: 1080
  text: "auto show in " + seconds + "   ·   press any key for the menu"
  color: foreground
  font.family: "JetBrainsMono Nerd Font"
  font.pixelSize: Math.round(areaHeight / 30)
  opacity: 0.9
}
