import QtQuick

// Left/Right picker: the current card big and lit, neighbours dimmed. The
// engine owns the index; this only draws it.
Item {
  id: root
  property var items: []
  property int index: 0
  property color accent: "#44E8CB"
  property color foreground: "#FFFFFF"
  property color fill: "#101C6E"
  property real areaWidth: 1920
  property real areaHeight: 1080

  readonly property real cardW: Math.round(areaWidth * 0.26)
  readonly property real cardH: Math.round(cardW * 9 / 16)
  width: areaWidth
  height: cardH * 1.25 + areaHeight / 18

  ListView {
    id: list
    anchors.fill: parent
    orientation: ListView.Horizontal
    interactive: false
    model: root.items
    currentIndex: root.index
    spacing: Math.round(root.cardW * 0.08)
    preferredHighlightBegin: (width - root.cardW) / 2
    preferredHighlightEnd: (width + root.cardW) / 2
    highlightRangeMode: ListView.StrictlyEnforceRange
    highlightMoveDuration: 260

    delegate: Item {
      required property var modelData
      required property int index
      readonly property bool current: index === root.index
      width: root.cardW
      height: list.height
      opacity: current ? 1 : 0.45
      scale: current ? 1.18 : 0.86
      Behavior on opacity { NumberAnimation { duration: 220 } }
      Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

      Rectangle {
        id: card
        width: root.cardW
        height: root.cardH
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(root.cardH * 0.12)
        radius: Math.round(root.cardW / 40)
        color: root.fill
        border.width: current ? Math.max(3, Math.round(root.cardW / 110)) : 1
        border.color: current ? root.accent : Qt.rgba(1, 1, 1, 0.2)
        clip: true

        Image {
          anchors.fill: parent
          anchors.margins: card.border.width
          source: modelData.image || ""
          visible: source != ""
          fillMode: Image.PreserveAspectCrop
          asynchronous: true
          sourceSize.width: 720
          cache: true
        }
        Text {
          anchors.centerIn: parent
          visible: !modelData.image
          text: modelData.note || modelData.title
          color: root.foreground
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: Math.round(root.cardH / 9)
        }
      }
      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: card.bottom
        anchors.topMargin: Math.round(root.cardH * 0.08)
        text: modelData.title
        color: current ? root.accent : root.foreground
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: Math.round(root.areaHeight / 42)
        font.bold: current
        style: Text.Raised
        styleColor: Qt.rgba(0, 0, 0, 0.7)
      }
    }
  }
}
