import Quickshell
import Quickshell.Hyprland
import QtQuick

// Window bookkeeping over Hyprland's event stream. openwindow data is
// "ADDR,WORKSPACE,CLASS,TITLE" with ADDR lacking the 0x prefix that
// dispatches need (PLAN.md Appendix B.7).
Scope {
  id: hypr
  signal windowOpened(string addr, string cls, string title)
  signal windowClosed(string addr)

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      if (event.name === "openwindow") {
        var parts = String(event.data).split(",")
        hypr.windowOpened("0x" + parts[0], parts[2] || "", parts.slice(3).join(","))
      } else if (event.name === "closewindow") {
        hypr.windowClosed("0x" + String(event.data))
      }
    }
  }

  // Dual-form close: Lua first, classic fallback (bin/showoff-hypr).
  function closeCmd(addr) {
    return "showoff-hypr 'hl.dsp.window.close({ window = \"address:" + addr + "\" })' closewindow address:" + addr
  }
}
