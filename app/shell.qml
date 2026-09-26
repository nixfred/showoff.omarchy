import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import "ui"

// Showoff Omarchy — a standalone Quickshell application.
//
// Runs as its own process (`quickshell -n -p <this dir>`), never inside the
// user's omarchy-shell. Depends on nothing but Quickshell, Qt and the stock
// omarchy-* commands. This file is windows + bindings only; the show itself
// is Engine.qml walking the act table in acts.js (PLAN.md §1).
ShellRoot {
  id: root

  // ---- theme colours, read from stock Omarchy state ---------------------
  property color accent: "#44E8CB"
  property color foreground: "#FFFFFF"
  property color darkBackground: "#101C6E"

  function parseColors(text) {
    var lines = text.split("\n")
    for (var i = 0; i < lines.length; i++) {
      var m = lines[i].match(/^\s*(\w+)\s*=\s*"(#[0-9A-Fa-f]{6,8})"/)
      if (!m) continue
      if (m[1] === "accent") root.accent = m[2]
      else if (m[1] === "foreground") root.foreground = m[2]
      else if (m[1] === "darker_background") root.darkBackground = m[2]
    }
  }

  FileView {
    path: Quickshell.env("HOME") + "/.local/state/omarchy/current/theme/colors.toml"
    watchChanges: true
    onLoaded: root.parseColors(text())
    onFileChanged: reload()
  }

  Engine { id: engine }

  Component.onCompleted: engine.start(Quickshell.env("SHOWOFF_MODE") || "countdown",
                                      Quickshell.env("SHOWOFF_ACT") || "")

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
      WlrLayershell.keyboardFocus: engine.handoff ? WlrKeyboardFocus.None : WlrKeyboardFocus.Exclusive
      exclusionMode: ExclusionMode.Ignore

      // Keep the screen awake for the show without touching the user's
      // stay-awake toggle, and stop SUPER chords leaking to Hyprland.
      IdleInhibitor { enabled: engine.state !== "idle"; window: win }
      ShortcutInhibitor {
        id: shortcuts
        enabled: engine.state !== "idle" && !engine.handoff
        window: win
        onActiveChanged: console.log("[showoff] shortcut inhibitor active=" + active)
        onCancelled: console.log("[showoff] shortcut inhibitor cancelled by compositor")
      }

      // Light scrim: the desktop underneath is the thing being shown off.
      Rectangle { anchors.fill: parent; color: Qt.rgba(0, 0, 0, 0.35) }

      MouseArea { anchors.fill: parent; onClicked: engine.interact() }

      Column {
        anchors.centerIn: parent
        spacing: Math.round(win.height / 30)

        Keycap {
          anchors.horizontalCenter: parent.horizontalCenter
          combo: engine.keycap
          accent: root.accent
          foreground: root.foreground
          fill: root.darkBackground
          unit: Math.round(win.height / 16)
        }

        Caption {
          anchors.horizontalCenter: parent.horizontalCenter
          text: engine.caption
          sub: engine.state === "countdown" ? "" : engine.sub
          accent: root.accent
          foreground: root.foreground
          areaWidth: win.width
          areaHeight: win.height
        }

        Countdown {
          anchors.horizontalCenter: parent.horizontalCenter
          visible: engine.state === "countdown"
          seconds: engine.countdown
          foreground: root.foreground
          areaHeight: win.height
        }
      }

      // Progress: act i of n, bottom-centre, quiet.
      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Math.round(win.height / 30)
        visible: engine.state === "running" && engine.progress.total > 1
        text: engine.progress.index + " / " + engine.progress.total + "   ·   Esc Esc to stop"
        color: root.foreground
        opacity: 0.55
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: Math.round(win.height / 60)
      }

      Item {
        anchors.fill: parent
        focus: true
        Keys.priority: Keys.BeforeItem
        Keys.onPressed: function(event) {
          if (event.key === Qt.Key_Escape) engine.escapePressed()
          else engine.interact()
          event.accepted = true
        }
      }
    }
  }
}
