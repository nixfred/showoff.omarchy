import QtQuick
import QtQuick.Effects

// The send-off: two QR codes to take home, and the one question that matters
// on someone else's machine — keep the theme, or put it all back?
Item {
  id: root
  property string qrDir: ""
  property string theme: ""
  property color accent: "#44E8CB"
  property color foreground: "#FFFFFF"
  property real areaWidth: 1920
  property real areaHeight: 1080
  readonly property real qr: Math.round(areaHeight * 0.26)

  implicitWidth: col.implicitWidth
  implicitHeight: col.implicitHeight

  Column {
    id: col
    spacing: Math.round(root.areaHeight / 30)

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: "TAKE IT HOME"
      color: root.accent
      font.family: "JetBrainsMono Nerd Font"
      font.pixelSize: Math.round(root.areaHeight / 11)
      font.bold: true
      layer.enabled: true
      layer.effect: MultiEffect { shadowEnabled: true; shadowColor: root.accent; shadowBlur: 1.0; shadowOpacity: 0.9; shadowHorizontalOffset: 0; shadowVerticalOffset: 0 }
    }

    Row {
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: Math.round(root.qr * 0.45)
      Repeater {
        model: [
          { file: "qr-omarchy.png", label: "omarchy.org", note: "get Omarchy" },
          { file: "qr-showoff.png", label: "this show", note: "run it on yours" }
        ]
        delegate: Column {
          required property var modelData
          spacing: Math.round(root.areaHeight / 90)
          Rectangle {
            width: root.qr; height: root.qr
            radius: Math.round(root.qr / 18)
            color: "white"
            border.width: 4
            border.color: root.accent
            Image {
              anchors.fill: parent
              anchors.margins: Math.round(root.qr / 22)
              source: root.qrDir + "/" + modelData.file
              smooth: false
              fillMode: Image.PreserveAspectFit
            }
          }
          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: modelData.label
            color: root.foreground
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: Math.round(root.areaHeight / 34)
            font.bold: true
          }
          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: modelData.note
            color: root.foreground
            opacity: 0.7
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: Math.round(root.areaHeight / 50)
          }
        }
      }
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: root.theme ? "keep " + root.theme + "?   Y  keep it   ·   N  put everything back" : "N  put everything back"
      color: root.foreground
      font.family: "JetBrainsMono Nerd Font"
      font.pixelSize: Math.round(root.areaHeight / 34)
    }
  }
}
