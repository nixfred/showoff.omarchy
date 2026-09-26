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

  // omarchy-theme-set swaps the whole theme directory, so the file briefly
  // does not exist and the watch can die with it. Retry until it's back.
  FileView {
    id: colorsFile
    path: Quickshell.env("HOME") + "/.local/state/omarchy/current/theme/colors.toml"
    watchChanges: true
    onLoaded: root.parseColors(text())
    onFileChanged: reload()
    onLoadFailed: colorsRetry.restart()
  }
  Timer { id: colorsRetry; interval: 400; onTriggered: colorsFile.reload() }
  // Belt and braces: re-read every few seconds so a lost watch never leaves
  // the captions in the previous theme's colour.
  Timer { interval: 2500; running: true; repeat: true; onTriggered: colorsFile.reload() }

  Engine { id: engine }

  property bool mapped: false
  Timer { interval: 450; running: true; onTriggered: root.mapped = true }

  Component.onCompleted: engine.start(Quickshell.env("SHOWOFF_MODE") || "auto",
                                      Quickshell.env("SHOWOFF_ACT") || "",
                                      Quickshell.env("SHOWOFF_FLAGS") || "")

  function keyName(event) {
    switch (event.key) {
    case Qt.Key_Left: return "Left"
    case Qt.Key_Right: return "Right"
    case Qt.Key_Up: return "Up"
    case Qt.Key_Down: return "Down"
    case Qt.Key_Return: return "Return"
    case Qt.Key_Enter: return "Enter"
    case Qt.Key_Space: return " "
    default: return event.text
    }
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
      // Hyprland grants exclusive keyboard focus when a layer surface MAPS.
      // Started from the launcher, the Apps menu (another exclusive overlay)
      // is still up at that moment, and when it closes focus goes back to the
      // last window, not to us. So the windows map only once the launcher has
      // had time to close (root.mapped, below).
      visible: root.mapped
      WlrLayershell.keyboardFocus: engine.handoff ? WlrKeyboardFocus.None : WlrKeyboardFocus.Exclusive
      exclusionMode: ExclusionMode.Ignore

      // During a hand-off act the visitor clicks and types into real apps.
      mask: engine.handoff ? emptyRegion : null
      Region { id: emptyRegion }

      // Keep the screen awake without touching the user's stay-awake toggle,
      // and stop SUPER chords leaking to Hyprland (except during hand-offs).
      IdleInhibitor { enabled: engine.state !== "idle"; window: win }
      ShortcutInhibitor {
        enabled: engine.state !== "idle" && !engine.handoff
        window: win
        onActiveChanged: console.log("[showoff] shortcut inhibitor active=" + active)
        onCancelled: console.log("[showoff] shortcut inhibitor cancelled by compositor")
      }

      readonly property string pose: engine.pose
      readonly property bool compact: pose === "lower"

      // Scrim: heavy for a headline, light when the apps are the point.
      Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: win.pose === "top" ? 0.55 : win.pose === "lower" ? 0.12 : 0.35
        Behavior on opacity { NumberAnimation { duration: 350 } }
      }

      // Swallow clicks so nothing under the show gets them (except in hand-offs).
      MouseArea { anchors.fill: parent; enabled: !engine.handoff }

      // The headline stack: logo, keycap, caption. It slides between poses.
      Item {
        id: stack
        width: parent.width
        height: col.implicitHeight
        y: win.pose === "lower" ? Math.round(win.height * 0.93 - height)
         : win.pose === "top" ? Math.round(win.height * 0.07)
         : Math.round((win.height - height) / 2)
        Behavior on y { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }
        visible: !engine.endCard

        // Backing plate so lower-thirds and skip lines stay readable over
        // any page (PLAN.md Appendix B.19).
        Rectangle {
          readonly property bool on: win.compact || (engine.caption === "" && !engine.logo && engine.sub !== "")
          anchors.centerIn: col
          width: Math.min(win.width * 0.94, col.contentWidth + win.height / 12)
          height: col.implicitHeight + win.height / 30
          radius: height / 6
          color: root.darkBackground
          opacity: on ? 0.82 : 0
          border.width: 1
          border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.5)
          Behavior on opacity { NumberAnimation { duration: 300 } }
        }

        Column {
          id: col
          anchors.horizontalCenter: parent.horizontalCenter
          spacing: Math.round(win.height / (win.compact ? 70 : 32))
          readonly property real contentWidth: Math.max(caption.implicitWidth, logo.visible ? logo.width : 0)

          Logo {
            id: logo
            anchors.horizontalCenter: parent.horizontalCenter
            visible: engine.logo
            accent: root.accent
            logoWidth: Math.round(win.width * 0.55)
          }

          Keycap {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: engine.keycap !== "" || !win.compact
            combo: engine.keycap
            accent: root.accent
            foreground: root.foreground
            fill: root.darkBackground
            unit: Math.round(win.height / (win.compact ? 26 : 16))
          }

          Caption {
            id: caption
            anchors.horizontalCenter: parent.horizontalCenter
            text: engine.caption
            sub: engine.sub
            accent: root.accent
            foreground: root.foreground
            areaWidth: win.width
            areaHeight: win.compact ? win.height * 0.55 : win.height
          }

        }
      }

      Carousel {
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: Math.round(win.height * 0.06)
        visible: engine.carouselItems.length > 0
        items: engine.carouselItems
        index: engine.carouselIndex
        accent: root.accent
        foreground: root.foreground
        fill: root.darkBackground
        areaWidth: win.width
        areaHeight: win.height
      }

      EndCard {
        anchors.centerIn: parent
        visible: engine.endCard
        qrDir: Qt.resolvedUrl("assets")
        theme: engine.endTheme
        accent: root.accent
        foreground: root.foreground
        areaWidth: win.width
        areaHeight: win.height
      }

      // Progress: act i of n, bottom-centre, quiet.
      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Math.round(win.height / 90)
        visible: engine.state === "running" && engine.progress.total > 1 && !engine.handoff
        text: engine.progress.index + " / " + engine.progress.total + "   ·   Esc Esc to stop"
        color: root.foreground
        opacity: 0.5
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: Math.round(win.height / 70)
      }

      Item {
        id: keyCatcher
        anchors.fill: parent
        focus: true
        Keys.priority: Keys.BeforeItem
        Keys.onPressed: function(event) {
          if (event.key === Qt.Key_Escape) engine.escapePressed()
          else engine.keyPressed(root.keyName(event))
          event.accepted = true
        }
      }
    }
  }
}
