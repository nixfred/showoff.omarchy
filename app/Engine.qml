import Quickshell
import QtQuick
import "acts.js" as Acts

// The show's state machine (PLAN.md §2.2). No UI here: windows bind to the
// properties, and every shell command goes through the Runner.
//
//   countdown ─silence─▶ auto ─▶ running ─▶ … ─▶ ended
//       └─any key─▶ menu
//   running: check → keycap → run → wait(until) → hold → cleanup → next
//   Esc Esc from ANY state ─▶ quitting: cleanup → restore → Qt.quit()
Scope {
  id: engine

  // ---- public state (the UI binds to these) -------------------------------
  property string state: "idle"
  property string caption: "SHOWOFF OMARCHY"
  property string sub: ""
  property string keycap: ""
  property bool handoff: false
  property int countdown: 5
  property var progress: ({ index: 0, total: 0, actId: "" })
  property bool keepTheme: false

  // ---- internal ----------------------------------------------------------
  property var queue: []
  property int index: -1
  property var act: null
  property int gen: 0                 // bumps on every step; stale callbacks die
  property var ours: []               // windows opened during the current act
  property bool watching: false       // collecting openwindow events for `ours`
  property bool waitingWindow: false
  property var windowRegex: null
  property string savedSub: ""
  property double lastEscAt: 0
  readonly property int escWindowMs: 1000

  function log(msg) { console.log("[showoff] " + msg) }

  // ---- lifecycle ---------------------------------------------------------
  function start(mode, actId) {
    runner.run("snapshot", snapshot.recordCmd, 4000)
    if (mode === "auto") runAuto()
    else if (mode === "menu") toMenu()
    else if (mode === "act") runOne(actId)
    else { state = "countdown"; countdown = 5; countdownTimer.start() }
  }

  function interact() {
    if (state === "countdown") toMenu()
  }

  function toMenu() {
    countdownTimer.stop()
    state = "menu"
    caption = "PICK AN ACT"
    sub = "(the menu arrives in P3)  ·  Esc Esc to leave"
    keycap = ""
  }

  function runAuto() {
    countdownTimer.stop()
    queue = Acts.AUTO_ORDER.slice()
    index = -1
    state = "auto"
    next()
  }

  function runOne(id) {
    countdownTimer.stop()
    if (!Acts.byId(id)) { state = "ended"; caption = "NO SUCH ACT"; sub = id + "  ·  Esc Esc to leave"; return }
    queue = [id]
    index = -1
    next()
  }

  function end() {
    gen++
    state = "ended"
    act = null
    keycap = ""
    caption = "THAT WAS OMARCHY"
    sub = "Esc Esc to leave"
    log("show ended")
  }

  // ---- the act runner ----------------------------------------------------
  function after(ms, fn) {
    var g = gen
    var t = delayComponent.createObject(engine, { interval: Math.max(1, ms) })
    t.triggered.connect(function() { t.destroy(); if (g === gen) fn() })
    t.start()
  }

  function next() {
    gen++
    index++
    if (index >= queue.length) { end(); return }
    act = Acts.byId(queue[index])
    ours = []
    progress = { index: index + 1, total: queue.length, actId: act.id }
    state = "running"
    log("act " + act.id + " (" + (index + 1) + "/" + queue.length + ")")
    check()
  }

  // Preconditions: every `requires` command and `requiresPkg` package, then the
  // optional precheck. Missing ones print their names; any output = skip.
  function check() {
    var req = act.requires || [], pkg = act.requiresPkg || []
    if (!req.length && !pkg.length && !act.precheck) { present(); return }
    var cmd = ""
    req.forEach(function(c) { cmd += "command -v " + c + " >/dev/null || echo " + c + "; " })
    pkg.forEach(function(p) { cmd += "pacman -Q " + p + " >/dev/null 2>&1 || echo " + p + "; " })
    if (act.precheck) cmd += "(" + act.precheck + ") >/dev/null 2>&1 || echo precheck; "
    runner.run("check:" + gen, cmd, 5000)
  }

  function skip(why) {
    log("skipped " + act.id + ": " + why)
    caption = ""
    sub = "skipped: " + act.title + " — " + why
    keycap = ""
    after(1500, next)
  }

  function present() {
    caption = act.caption || ""
    sub = act.sub || ""
    if (act.keycap) {
      keycap = act.keycap
      after(900, function() { keycap = ""; launch() })
    } else {
      launch()
    }
  }

  function launch() {
    var u = act.until || { ms: 0 }
    watching = true
    if (u.window) {
      waitingWindow = true
      windowRegex = (u.window instanceof RegExp) ? u.window : null
      var g = gen
      after(u.timeoutMs || 10000, function() {
        if (!waitingWindow) return
        waitingWindow = false
        log(act.id + ": no window within " + (u.timeoutMs || 10000) + " ms")
        sub = "that took too long — moving on"
        cleanup()
      })
    }
    if (typeof act.run === "function") act.run(engine)
    else if (act.run) runner.run("run:" + gen, act.run, u.timeoutMs || 10000)
    if (!u.window) after(u.ms || 0, hold)
  }

  function hold() { after(act.hold !== undefined ? act.hold : 3000, cleanup) }

  function cleanup() {
    watching = false
    waitingWindow = false
    closeOurs(act)
    if (typeof act.cleanup === "function") act.cleanup(engine)
    else if (act.cleanup && act.cleanup !== "close-ours" && act.cleanup !== "none")
      runner.run("cleanup:" + gen, act.cleanup, 10000)
    after(400, next)
  }

  function closeOurs(a) {
    if (!a || a.keep || a.cleanup !== "close-ours") return
    ours.forEach(function(addr) { runner.run("close:" + addr, hypr.closeCmd(addr), 4000) })
    ours = []
  }

  // ---- events ------------------------------------------------------------
  function handleWindowOpened(addr, cls, title) {
    if (!watching) return
    ours = ours.concat([addr])
    log("window opened " + addr + " class=" + cls)
    if (waitingWindow && (!windowRegex || windowRegex.test(cls))) {
      waitingWindow = false
      hold()
    }
  }

  function handleWindowClosed(addr) {
    ours = ours.filter(function(a) { return a !== addr })
  }

  function handleFinished(token, code, out) {
    if (token === "snapshot") { snapshot.parse(out); log("snapshot " + snapshot.theme + " | ws " + snapshot.workspace); return }
    if (token === "restore") { log("restored (" + code + ")"); Qt.quit(); return }
    if (token === "check:" + gen) {
      var missing = String(out).trim()
      if (code === 124) skip("check timed out")
      else if (missing) skip("needs " + missing.split("\n").join(", "))
      else present()
      return
    }
    if (token.indexOf("run:") === 0 && code !== 0 && code !== 124)
      log("run exited " + code + " for " + (act ? act.id : "?"))
  }

  // ---- Esc Esc -----------------------------------------------------------
  function escapePressed() {
    if (state === "quitting") return
    var now = Date.now()
    if (now - lastEscAt <= escWindowMs) { quit(); return }
    lastEscAt = now
    savedSub = sub
    sub = "press Esc again to stop"
    escResetTimer.restart()
  }

  function quit() {
    gen++
    countdownTimer.stop()
    state = "quitting"
    caption = "PUTTING EVERYTHING BACK"
    sub = ""
    keycap = ""
    watching = false
    runner.killAll()
    closeOurs(act)
    runner.run("restore", snapshot.restoreCmd(keepTheme), 5000)
    quitWatchdog.start()
  }

  // ---- parts -------------------------------------------------------------
  Runner { id: runner; onFinished: function(t, c, o) { engine.handleFinished(t, c, o) } }
  Hypr {
    id: hypr
    onWindowOpened: function(a, c, t) { engine.handleWindowOpened(a, c, t) }
    onWindowClosed: function(a) { engine.handleWindowClosed(a) }
  }
  Snapshot { id: snapshot }

  property Component delayComponent: Component { Timer { repeat: false } }

  Timer {
    id: countdownTimer
    interval: 1000
    repeat: true
    onTriggered: {
      engine.countdown -= 1
      if (engine.countdown <= 0) { stop(); engine.runAuto() }
    }
  }
  Timer {
    id: escResetTimer
    interval: 1500
    onTriggered: if (engine.state !== "quitting" && engine.sub === "press Esc again to stop") engine.sub = engine.savedSub
  }
  // Restore gets 5 s; after that we leave regardless. The show must never
  // hold the screen hostage.
  Timer { id: quitWatchdog; interval: 5500; onTriggered: Qt.quit() }
}
