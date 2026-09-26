import QtQuick
import QtQuick.Effects

// Keycap Karaoke: "SUPER + RETURN" drawn as glowing keys, shown just before
// the action happens, so nothing on screen looks like magic.
Item {
  id: root
  property string combo: ""
  property color accent: "#44E8CB"
  property color foreground: "#FFFFFF"
  property color fill: "#101C6E"
  property real unit: 60

  readonly property var keys: combo ? combo.split(" + ") : []
  implicitWidth: row.implicitWidth
  implicitHeight: root.unit * 1.5  // reserved even when empty, so the caption never jumps
  opacity: combo ? 1 : 0
  scale: combo ? 1 : 0.85
  Behavior on opacity { NumberAnimation { duration: 300 } }
  Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }

  Row {
    id: row
    spacing: Math.round(root.unit * 0.35)

    Repeater {
      model: Math.max(0, root.keys.length * 2 - 1)
      delegate: Item {
        required property int index
        readonly property bool isKey: index % 2 === 0
        readonly property string label: isKey ? root.keys[index / 2] : "+"
        width: isKey ? Math.max(root.unit * 1.6, keyText.implicitWidth + root.unit * 0.8) : plus.implicitWidth
        height: root.unit * 1.5

        Rectangle {
          id: cap
          visible: parent.isKey
          anchors.fill: parent
          radius: root.unit * 0.22
          color: Qt.rgba(root.fill.r, root.fill.g, root.fill.b, 0.92)
          border.width: Math.max(2, Math.round(root.unit / 20))
          border.color: root.accent
          layer.enabled: true
          layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: root.accent
            shadowBlur: 1.0
            shadowOpacity: 0.9
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 0
          }
        }
        Text {
          id: keyText
          visible: parent.isKey
          anchors.centerIn: parent
          text: parent.label
          color: root.foreground
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: root.unit * 0.6
          font.bold: true
        }
        Text {
          id: plus
          visible: !parent.isKey
          anchors.verticalCenter: parent.verticalCenter
          text: "+"
          color: root.accent
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: root.unit * 0.8
          font.bold: true
        }
      }
    }
  }
}
