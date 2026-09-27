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
  property var monitors: []           // [{ name, ws, special, focused }]

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
    // Put every monitor back on its own workspace, the focused one LAST so
    // focus ends where it started; then reopen a special workspace if one was
    // showing. Negative ids (none, or special) are not focusable directly.
    var mons = monitors.slice().sort(function(a, b) { return (a.focused ? 1 : 0) - (b.focused ? 1 : 0) })
    mons.forEach(function(m) {
      s += "showoff-hypr " + q('hl.dsp.focus({ monitor = "' + m.name + '" })') + " focusmonitor " + q(m.name) + "; "
      if (Number(m.ws) > 0)
        s += "showoff-hypr 'hl.dsp.focus({ workspace = \"" + m.ws + "\" })' workspace " + m.ws + "; "
    })
    if (!mons.length && workspace && Number(workspace) > 0)
      s += "showoff-hypr 'hl.dsp.focus({ workspace = \"" + workspace + "\" })' workspace " + workspace + "; "
    mons.forEach(function(m) {
      var sp = String(m.special || "").replace(/^special:/, "")
      if (m.special && sp) s += "showoff-hypr " + q('hl.dsp.workspace.toggle_special("' + sp + '")') + " togglespecialworkspace " + q(sp) + "; "
    })
    return s + "true"
  }
}
