import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

// Showoff Omarchy — a standalone Quickshell application.
//
// Runs as its own process (`quickshell -n -p <this dir>`), never inside the
// user's omarchy-shell. It depends on nothing but Quickshell, Qt, and the
// stock omarchy-* commands; theme colours come straight from Omarchy's own
// colors.toml so the captions follow whatever theme is on screen.
//
// STATUS: scaffold. This proves the takeover and the mode gate only:
//   - a fullscreen overlay on every screen, above every window
//   - exclusive keyboard focus (nothing under us gets keys)
//   - Esc twice within a second quits and restores
//   - the countdown gate: any other key or click before it hits zero opens
//     the menu; silence lets the auto show run
// No act exists yet. See RESEARCH.md and ACTS.md.
ShellRoot {
  id: root

  // countdown | auto | menu | act   (bin/showoff sets SHOWOFF_MODE)
  property string mode: Quickshell.env("SHOWOFF_MODE") || "countdown"
  property string actId: Quickshell.env("SHOWOFF_ACT") || ""

  // ---- theme colours, read from stock Omarchy state ---------------------
  property color accent: "#44E8CB"
  property color foreground: "#FFFFFF"
  property color background: "#1B2FB0"

  function parseColors(text) {
    var lines = text.split("\n")
    for (var i = 0; i < lines.length; i++) {
      var m = lines[i].match(/^\s*(\w+)\s*=\s*"(#[0-9A-Fa-f]{6,8})"/)
      if (!m) continue
      if (m[1] === "accent") root.accent = m[2]
      else if (m[1] === "foreground") root.foreground = m[2]
      else if (m[1] === "background") root.background = m[2]
    }
  }

  FileView {
    path: Quickshell.env("HOME") + "/.local/state/omarchy/current/theme/colors.toml"
    watchChanges: true
    onLoaded: root.parseColors(text())
    onFileChanged: reload()
  }

  // ---- state ------------------------------------------------------------
  property string caption: "SHOWOFF OMARCHY"
  property string subcaption: ""
  property int countdown: 5

  // Esc twice within escWindowMs ends the show. A single reflex tap does
  // nothing, so a visitor can't kill the demo by accident.
  readonly property int escWindowMs: 1000
  property double lastEscAt: 0

  Component.onCompleted: {
    if (root.mode === "countdown") countdownTimer.start()
    else root.enter(root.mode)
  }

  Timer {
    id: countdownTimer
    interval: 1000
    repeat: true
    onTriggered: {
      root.countdown -= 1
      if (root.countdown <= 0) {
        stop()
        root.enter("auto")
      }
    }
  }

  function enter(newMode) {
    countdownTimer.stop()
    root.mode = newMode
    // Placeholders until the engine exists.
    if (newMode === "auto") { root.caption = "AUTO SHOW"; root.subcaption = "(no acts built yet)  Esc Esc to leave" }
    else if (newMode === "menu") { root.caption = "PICK AN ACT"; root.subcaption = "(menu not built yet)  Esc Esc to leave" }
    else if (newMode === "act") { root.caption = "ACT: " + root.actId.toUpperCase(); root.subcaption = "(acts not built yet)  Esc Esc to leave" }
  }

  function quit() {
    // Restore hooks go here once the engine exists (theme, wallpaper, DND).
    Qt.quit()
  }

  function handleEscape() {
    var now = Date.now()
    if (now - root.lastEscAt <= root.escWindowMs) root.quit()
    else { root.lastEscAt = now; root.subcaption = "press Esc again to stop" }
  }

  // Anything that isn't Esc, during the countdown, means "I want the menu".
  function handleInteraction() {
    if (root.mode === "countdown") root.enter("menu")
  }

  // ---- one overlay window per screen -------------------------------------
  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: win
      required property var modelData
      screen: modelData
      anchors { top: true; bottom: true; left: true; right: true }
      color: "transparent"
      WlrLayershell.namespace: "showoff-omarchy"
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
      exclusionMode: ExclusionMode.Ignore

      // Light scrim: the desktop underneath is the thing being shown off.
      Rectangle { anchors.fill: parent; color: Qt.rgba(0, 0, 0, 0.35) }

      MouseArea {
        anchors.fill: parent
        onClicked: root.handleInteraction()
      }

      Column {
        anchors.centerIn: parent
        spacing: 24

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: root.caption
          color: root.accent
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: Math.round(win.height / 8)
          font.bold: true
          style: Text.Outline
          styleColor: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.5)
        }

        Text {
          visible: root.mode === "countdown"
          anchors.horizontalCenter: parent.horizontalCenter
          text: "auto show in " + root.countdown + "   ·   press any key for the menu"
          color: root.foreground
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: Math.round(win.height / 30)
          opacity: 0.85
        }

        Text {
          visible: root.subcaption !== ""
          anchors.horizontalCenter: parent.horizontalCenter
          text: root.subcaption
          color: root.foreground
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: Math.round(win.height / 30)
          opacity: 0.85
        }
      }

      Item {
        id: keyCatcher
        anchors.fill: parent
        focus: true
        Keys.priority: Keys.BeforeItem
        Keys.onPressed: function(event) {
          if (event.key === Qt.Key_Escape) root.handleEscape()
          else root.handleInteraction()
          event.accepted = true
        }
      }
    }
  }
}
