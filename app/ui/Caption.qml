import QtQuick
import QtQuick.Effects

// The big glowing caption. Two blurred, accent-tinted copies of the text sit
// under the sharp one: a wide soft halo and a tight hot core. The size fits
// the width, so long captions never run off a small screen.
Item {
  id: root
  property string text: ""
  property string sub: ""
  property color accent: "#44E8CB"
  property color foreground: "#FFFFFF"
  property real areaWidth: 1920
  property real areaHeight: 1080

  readonly property int size: Math.round(Math.min(areaHeight / 8,
    areaWidth * 0.9 / Math.max(1, 0.62 * text.length)))
  readonly property int subSize: Math.round(Math.min(areaHeight / 30,
    areaWidth * 0.9 / Math.max(1, 0.62 * sub.length)))

  implicitWidth: Math.max(title.implicitWidth, subText.implicitWidth)
  implicitHeight: col.implicitHeight

  Column {
    id: col
    anchors.horizontalCenter: parent.horizontalCenter
    spacing: Math.round(root.areaHeight / 45)

    Item {
      anchors.horizontalCenter: parent.horizontalCenter
      width: title.implicitWidth
      height: title.implicitHeight
      visible: root.text !== ""

      Text {
        id: glowSource
        anchors.fill: parent
        text: root.text
        color: root.accent
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: root.size
        font.bold: true
        visible: false
      }
      MultiEffect {
        anchors.fill: glowSource
        source: glowSource
        blurEnabled: true
        blurMax: 64
        blur: 1.0
        brightness: 0.25
        opacity: 0.9
      }
      MultiEffect {
        anchors.fill: glowSource
        source: glowSource
        blurEnabled: true
        blurMax: 16
        blur: 0.6
        opacity: 0.8
      }
      Text {
        id: title
        text: root.text
        color: Qt.lighter(root.accent, 1.15)
        font: glowSource.font
      }
    }

    Text {
      id: subText
      anchors.horizontalCenter: parent.horizontalCenter
      visible: root.sub !== ""
      text: root.sub
      color: root.foreground
      font.family: "JetBrainsMono Nerd Font"
      font.pixelSize: root.subSize
      opacity: 0.9
      style: Text.Raised
      styleColor: Qt.rgba(0, 0, 0, 0.6)
    }
  }

  Behavior on opacity { NumberAnimation { duration: 250 } }
}
