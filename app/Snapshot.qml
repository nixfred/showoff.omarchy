import Quickshell
import QtQuick

// Records what the show may change, restores it on every exit path.
// Restore is ONE bash string so it finishes even while QML tears down, and it
// only touches what actually changed (omarchy-theme-set is slow; skip it when
// the theme is already right).
Scope {
  id: snap
  property bool recorded: false
  property string theme: ""
  property string background: ""
  property string workspace: ""

  readonly property string recordCmd:
    "s=$HOME/.local/state/omarchy/current; " +
    "printf '%s\\n' \"$(cat $s/theme.name 2>/dev/null)\" \"$(readlink $s/background 2>/dev/null)\" " +
    "\"$(hyprctl activeworkspace -j 2>/dev/null | jq -r .id)\""

  function parse(out) {
    var l = String(out).split("\n")
    theme = l[0] || ""; background = l[1] || ""; workspace = l[2] || ""
    recorded = true
  }

  function q(s) { return "'" + String(s).replace(/'/g, "'\\''") + "'" }

  function restoreCmd(keepTheme) {
    if (!recorded) return "true"
    var s = "s=$HOME/.local/state/omarchy/current; "
    if (theme && !keepTheme)
      s += "[ \"$(cat $s/theme.name 2>/dev/null)\" = " + q(theme) + " ] || omarchy-theme-set " + q(theme) + "; "
    if (background && !keepTheme)
      s += "[ \"$(readlink $s/background 2>/dev/null)\" = " + q(background) + " ] || omarchy-theme-bg-set " + q(background) + "; "
    if (workspace && workspace !== "null")
      s += "showoff-hypr 'hl.dsp.focus({ workspace = \"" + workspace + "\" })' workspace " + workspace + "; "
    return s + "true"
  }
}
