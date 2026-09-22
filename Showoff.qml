import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.Commons

// Showoff Omarchy — the overlay that runs the show.
//
// STATUS: scaffold. This proves the takeover primitive only: a fullscreen
// overlay on every screen, exclusive keyboard focus, one glowing caption,
// and Esc pressed twice within a second to leave. The acts (browser, theme
// picker, btop, ...) are not here yet; see RESEARCH.md and IDEAS.md.
//
// Contract with the shell (same as the first-party emoji overlay):
//   open(payloadJson)  — the shell calls this on `summon nixfred.showoff`
//   close()            — the shell calls this on `hide nixfred.showoff`
//   dismiss()          — we call shell.hide ourselves when the show ends
Item {
  id: root

  property string omarchyPath: Quickshell.env("OMARCHY_PATH")
  property var shell: null
  property var manifest: null

  property bool opened: false
  property string caption: "SHOWOFF OMARCHY"
  property string subcaption: "press Esc twice to stop"

  // Esc twice within escWindowMs ends the show. One Esc alone does nothing,
  // so a visitor who taps it by reflex doesn't kill the demo.
  readonly property int escWindowMs: 1000
  property double lastEscAt: 0

  function open(payloadJson) {
    root.opened = true
    root.lastEscAt = 0
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  function close() {
    root.opened = false
  }

  function dismiss() {
    root.opened = false
    if (root.shell && typeof root.shell.hide === "function")
      root.shell.hide((root.manifest && root.manifest.id) || "nixfred.showoff")
  }

  function toggle() {
    if (root.opened) root.dismiss()
    else root.open("{}")
  }

  function handleEscape() {
    var now = Date.now()
    if (now - root.lastEscAt <= root.escWindowMs) {
      root.dismiss()
    } else {
      root.lastEscAt = now
      root.subcaption = "press Esc again to stop"
    }
  }

  // One window per screen so the takeover covers every monitor, the way the
  // face-id and lock overlays do it.
  Variants {
    model: Quickshell.screens

    PanelWindow {
      required property var modelData
      screen: modelData
      visible: root.opened
      anchors { top: true; bottom: true; left: true; right: true }
      color: "transparent"
      WlrLayershell.namespace: "nixfred-showoff"
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
      exclusionMode: ExclusionMode.Ignore

      // Scrim: dark enough that the caption reads, light enough that the
      // desktop underneath (the thing being shown off) still shows through.
      Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.35)
      }

      Column {
        anchors.centerIn: parent
        spacing: Style.spacing.lg

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: root.caption
          color: Color.accent
          font.family: Style.font.family
          font.pixelSize: Style.font.display * 4
          font.bold: true
          style: Text.Outline
          styleColor: Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.5)
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: root.subcaption
          color: Color.foreground
          font.family: Style.font.family
          font.pixelSize: Style.font.display
          opacity: 0.8
        }
      }

      Item {
        id: keyCatcher
        anchors.fill: parent
        focus: true
        Keys.priority: Keys.BeforeItem
        Keys.onPressed: function(event) {
          if (event.key === Qt.Key_Escape) {
            root.handleEscape()
            event.accepted = true
          }
        }
      }
    }
  }
}
