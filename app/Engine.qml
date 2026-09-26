import Quickshell
import QtQuick
import "acts.js" as Acts

// The show's state machine (PLAN.md §2.2). No UI here: windows bind to the
// properties, and every shell command goes through the Runner.
//
//   prep ─▶ running ─▶ … ─▶ ended ─(6 s)─▶ quit      (Fred: "no menu, just run it")
//   running: flag → check → stage → keycap → run → wait → hold → cleanup → next
//   Esc Esc from ANY state ─▶ quitting: abort → close ours → restore → Qt.quit()
//
// Acts are data (acts.js). A data act runs one command and waits on `until`;
// a function act gets this engine as `e` and calls e.done() when it is
// finished. The e.* helpers below are the whole act API.
Scope {
  id: engine

  // ---- public state (the UI binds to these) -------------------------------
  property string state: "idle"
  property string caption: ""
  property string sub: ""
  property string keycap: ""
  property string pose: "center"        // center | lower | top
  property bool logo: false
  property bool handoff: false
  property var progress: ({ index: 0, total: 0, actId: "" })
  property var carouselItems: []        // [{ title, image, note }]
  property int carouselIndex: 0
  property bool endCard: false
  property string endTheme: ""

  // ---- show-wide data acts may read ---------------------------------------
  property bool keepTheme: false
  property string chosenTheme: ""
  property var themeList: []            // [{ slug, title, image }]
  property string stageWs: ""           // an empty workspace the show plays on
  property var spareWs: []              // more empty ones (Workspace Flyby)
  property var binds: ({})              // description → "SUPER + RETURN"
  property var flags: []
  property var data: ({})               // per-act scratch, reset each act
  property bool x: false                // `showoff x`: the ~80 s cut for posting
  property bool recording: false
  // Global pace (Fred: "it's very slow... speed it up"). Every act timing is
  // scaled by this; reading and keycap dwells are computed separately (raw)
  // so text never drops below readable.
  readonly property real pace: 0.7
  property string recordingFile: ""

  // ---- internal ----------------------------------------------------------
  property string startMode: "auto"
  property string startAct: ""
  property var queue: []
  property int index: -1
  property var act: null
  property int gen: 0                   // bumps on every act; stale callbacks die
  property var ours: []                 // windows opened during the current act
  property bool watching: false
  property var waiters: []              // pending e.onWindow callbacks
  property var callbacks: ({})          // runner token → callback
  property var keyHandler: null
  property bool actDone: false
  property int seq: 0
  property string savedSub: ""
  property double lastEscAt: 0
  readonly property int escWindowMs: 1000

  function log(msg) { console.log("[showoff] " + msg) }

  // ======================================================================
  //  The act API — everything an act function may call as e.*
  // ======================================================================
  function say(c, s) { caption = c; sub = s === undefined ? "" : s; keycap = "" }
  // Pacing (Fred, 2026-09-26: "think about how long each text phrase should
  // be on the screen"). Big words read slower than small ones; a keycap has to
  // be read AND recognised as keys, so it gets its own, longer dwell.
  function words(t) { t = String(t || "").trim(); return t ? t.split(/\s+/).length : 0 }
  function readMs(c, s) { return Math.min(5000, Math.max(1300, 900 + words(c) * 220 + words(s) * 160)) }
  function keycapMs(combo) { return 1400 + 250 * String(combo).split(" + ").length }
  function sayThen(c, s, fn) { say(c, s); after(readMs(c, s), fn, true) }
  function setPose(p) { pose = p }
  function setHandoff(on) { handoff = on }
  function done() {
    if (actDone || state !== "running") return
    actDone = true
    hold()
  }
  function sh(cmd, cb, timeoutMs) {
    var token = "sh:" + gen + ":" + (++seq)
    var g = gen
    if (cb) callbacks[token] = function(code, out) { if (g === gen) cb(code, out) }
    runner.run(token, cmd, timeoutMs || 10000)
  }
  // Launch fully detached. uwsm-app stays attached to the app it starts, so a
  // launcher left in a Runner job dies with the job's watchdog — and takes
  // the app with it (that is how btop vanished 15 s after launch). setsid -f
  // returns at once and the app belongs to nobody.
  function detached(cmd) { return "setsid -f bash -lc " + q(cmd) + " >/dev/null 2>&1 </dev/null" }
  function launch(cmd) { sh(detached(cmd), null, 5000) }
  // raw = true: exact milliseconds (reading dwells); otherwise scaled by pace.
  function after(ms, fn, raw) {
    var g = gen
    var t = delayComponent.createObject(engine, { interval: Math.max(1, Math.round(raw ? ms : ms * pace)) })
    t.triggered.connect(function() { t.destroy(); if (g === gen) fn() })
    t.start()
  }
  // Call fn(addr, cls) on the next window that opens; onTimeout() if none.
  function onWindow(fn, timeoutMs, onTimeout) {
    var g = gen
    var w = { fn: fn, fired: false }
    waiters = waiters.concat([w])
    after(timeoutMs || 10000, function() {
      if (w.fired) return
      w.fired = true
      waiters = waiters.filter(function(x) { return x !== w })
      if (onTimeout) onTimeout()
    })
  }
  function hypr(lua, classic) { launch(hyprCmd(lua, classic)) }
  function hyprCmd(lua, classic) { return "showoff-hypr " + q(lua) + " " + classic }
  function focusWs(n) { if (n) hypr('hl.dsp.focus({ workspace = "' + n + '" })', "workspace " + n) }
  function focusWindow(addr) { hypr('hl.dsp.focus({ window = "address:' + addr + '" })', "focuswindow address:" + addr) }
  function closeWindow(addr) { launch(hypr_.closeCmd(addr)) }
  // The keycap appears, dwells long enough to read, then the action runs
  // with the keys still on screen. The next say() or cleanup clears it.
  function showKeycap(combo, ms, then) {
    if (!combo) { if (then) then(); return }
    keycap = combo
    after(ms || keycapMs(combo), function() { if (then) then() }, !ms)
  }
  function bind(description, fallback) { return binds[description] || fallback || "" }
  function onKey(fn) { keyHandler = fn }
  // X mode drives the pickers itself: each press shows as a keycap first, so
  // the viewer sees exactly what a person would press.
  function autoKeys(keys, gapMs) {
    function go(n) {
      if (n === keys.length || !keyHandler) return
      var k = keys[n], label = k === "Right" ? "→" : k === "Left" ? "←" : k === "Return" ? "ENTER" : k
      keycap = label
      after(gapMs * 0.45, function() { if (keyHandler) keyHandler(k, true); after(gapMs * 0.55, function() { keycap = ""; go(n + 1) }) })
    }
    go(0)
  }
  function carousel(items, idx) { carouselItems = items; carouselIndex = idx }
  function q(s) { return "'" + String(s).replace(/'/g, "'\\''") + "'" }
  function titleOf(slug) {
    return String(slug).split("-").map(function(w) { return w.charAt(0).toUpperCase() + w.slice(1) }).join(" ")
  }

  // ======================================================================
  //  Lifecycle
  // ======================================================================
  function start(mode, actId, flagStr) {
    startMode = mode
    startAct = actId
    flags = flagStr ? flagStr.split(",") : []
    state = "prep"
    caption = "SHOWOFF OMARCHY"
    runner.run("prep", prepCmd, 6000)
  }

  // One command gathers everything the show needs before act 1: the restore
  // snapshot, which workspaces are empty (the show plays on one), and the live
  // keybindings so every keycap shows what THIS machine actually uses.
  readonly property string prepCmd:
    "s=$HOME/.local/state/omarchy/current; " +
    "printf 'T\\t%s\\nB\\t%s\\n' \"$(cat $s/theme.name 2>/dev/null)\" \"$(readlink $s/background 2>/dev/null)\"; " +
    "printf 'W\\t%s\\n' \"$(hyprctl activeworkspace -j 2>/dev/null | jq -r .id)\"; " +
    "printf 'O\\t%s\\n' \"$(hyprctl workspaces -j 2>/dev/null | jq -r '[.[] | select(.windows > 0) | .id | tostring] | join(\" \")')\"; " +
    "hyprctl binds -j 2>/dev/null | jq -r '.[] | select(.has_description and .submap == \"\") | \"K\\t\\(.modmask)\\t\\(.key)\\t\\(.description)\"'"

  function parsePrep(out) {
    var occupied = [], b = {}
    String(out).split("\n").forEach(function(line) {
      var f = line.split("\t")
      if (f[0] === "T") snapshot.theme = f[1] || ""
      else if (f[0] === "B") snapshot.background = f[1] || ""
      else if (f[0] === "W") snapshot.workspace = f[1] || ""
      else if (f[0] === "O") occupied = (f[1] || "").split(" ")
      else if (f[0] === "K" && f[2] && !b[f[3]]) b[f[3]] = comboOf(parseInt(f[1]), f[2])
    })
    snapshot.recorded = true
    binds = b
    var empties = []
    for (var n = 1; n <= 10; n++) if (occupied.indexOf(String(n)) < 0) empties.push(String(n))
    stageWs = empties.length ? empties[0] : ""
    spareWs = empties.slice(1)
    log("snapshot " + snapshot.theme + " | ws " + snapshot.workspace + " | stage " + stageWs +
        " | spare " + spareWs.join(",") + " | " + Object.keys(b).length + " binds")
  }

  function comboOf(mask, key) {
    var parts = []
    if (mask & 64) parts.push("SUPER")
    if (mask & 1) parts.push("SHIFT")
    if (mask & 4) parts.push("CTRL")
    if (mask & 8) parts.push("ALT")
    parts.push(String(key).toUpperCase())
    return parts.join(" + ")
  }

  function begin() {
    if (startMode === "x") runX()
    else if (startMode === "act") runOne(startAct)
    else runAuto()
  }

  function runAuto() {
    queue = Acts.AUTO_ORDER.slice()
    index = -1
    next()
  }

  // `showoff act a,b,c` runs those acts in order (handy for rehearsing a bit).
  // The X cut: start Omarchy's own recorder, wait until it is really
  // recording, then play X_ORDER. end() stops the recorder BEFORE restoring,
  // so the restore never lands in the video.
  function runX() {
    x = true
    state = "running"
    caption = ""
    sub = ""
    launch("omarchy-capture-screenrecording --fullscreen")
    var tries = 0
    function wait() {
      sh("pgrep -f '^gpu-screen-recorder' >/dev/null", function(code) {
        if (code === 0) { recording = true; log("recording"); after(700, function() { queue = Acts.X_ORDER.slice(); index = -1; next() }) }
        else if (++tries > 20) { log("recorder never started — running the cut unrecorded"); queue = Acts.X_ORDER.slice(); index = -1; next() }
        else after(250, wait)
      }, 2000)
    }
    wait()
  }

  function stopRecording(then) {
    if (!recording) { then(); return }
    recording = false
    sh("omarchy-capture-screenrecording --stop-recording 2>/dev/null | tail -1", function(code, out) {
      recordingFile = String(out).trim()
      log("recording saved: " + recordingFile)
      then()
    }, 15000)
  }

  function runOne(ids) {
    var list = String(ids).split(",").filter(Boolean)
    var bad = list.filter(function(id) { return !Acts.byId(id) })
    if (!list.length || bad.length) { state = "ended"; caption = "NO SUCH ACT"; sub = bad.join(", ") + "  ·  Esc Esc to leave"; return }
    queue = list
    index = -1
    next()
  }

  function end() {
    gen++
    state = "ended"
    act = null
    keycap = ""
    logo = true
    pose = "center"
    caption = ""
    sub = "omarchy.org"
    log("show ended")
    if (!x) { after(4000, quit, true); return }
    // X cut: hold the logo for the last frames, then stop the recorder, then
    // say where the file is (after the recording, so it is not in the video).
    after(3000, function() {
      stopRecording(function() {
        logo = false
        caption = "SAVED"
        sub = recordingFile ? recordingFile.replace(/^.*\//, "~/Videos/") : "the recorder did not save a file"
        after(4000, quit)
      })
    })
  }

  // ======================================================================
  //  The act runner
  // ======================================================================
  function next() {
    gen++
    index++
    if (index >= queue.length) { end(); return }
    act = Acts.byId(queue[index])
    ours = []
    waiters = []
    data = ({})
    keyHandler = null
    actDone = false
    endCard = false
    carouselItems = []
    progress = { index: index + 1, total: queue.length, actId: act.id }
    state = "running"
    if (act.flag && flags.indexOf(act.flag) < 0) { log("skip " + act.id + " (flag " + act.flag + " off)"); after(1, next); return }
    log("act " + act.id + " (" + (index + 1) + "/" + queue.length + ")")
    check()
  }

  // Preconditions: `requires` commands, `requiresPkg` packages (any-of when
  // act.anyPkg), then `precheck`. Missing names print; any output = skip.
  function check() {
    var req = act.requires || [], pkg = act.requiresPkg || []
    if (!req.length && !pkg.length && !act.precheck) { present(); return }
    var cmd = ""
    req.forEach(function(c) { cmd += "command -v " + c + " >/dev/null || echo " + c + "; " })
    if (act.anyPkg) cmd += "{ " + pkg.map(function(p) { return "pacman -Q " + p + " >/dev/null 2>&1" }).join(" || ") + "; } || echo 'one of " + pkg.join(" ") + "'; "
    else pkg.forEach(function(p) { cmd += "pacman -Q " + p + " >/dev/null 2>&1 || echo " + p + "; " })
    if (act.precheck) cmd += "(" + act.precheck + ") >/dev/null 2>&1 || echo " + q(act.precheckWhy || "a precheck") + "; "
    var g = gen
    callbacks["check:" + g] = function(code, out) {
      if (g !== gen) return
      var missing = String(out).trim()
      if (code === 124) skip("check timed out")
      else if (missing) skip("needs " + missing.split("\n").join(", "))
      else present()
    }
    runner.run("check:" + g, cmd, 5000)
  }

  function skip(why) {
    log("skipped " + act.id + ": " + why)
    pose = "center"
    logo = false
    caption = ""
    sub = "skipping " + act.title + " — " + why
    keycap = ""
    after(readMs("", sub), next, true)
  }

  function present() {
    if (act.stage !== false) focusWs(stageWs)
    pose = act.pose || "center"
    logo = !!act.logo
    caption = act.caption || ""
    sub = act.sub || ""
    var combo = act.keycapBind ? bind(act.keycapBind, act.keycap) : (act.keycap || "")
    if (combo) showKeycap(combo, 0, launch_)
    else launch_()
  }

  function launch_() {
    watching = true
    if (typeof act.run === "function") { act.run(engine); return }
    var u = act.until || { ms: 0 }
    if (act.run) runner.run("run:" + gen, detached(act.run), 5000)
    if (u.window) {
      onWindow(function() { hold() }, u.timeoutMs || 10000, function() {
        log(act.id + ": no new window within " + (u.timeoutMs || 10000) + " ms")
        if (!u.soft) sub = "that took too long — moving on"
        hold()
      })
    } else {
      after(u.ms || 0, hold)
    }
  }

  function hold() {
    if (act.holdPose) pose = act.holdPose
    if (act.holdSub) sub = act.holdSub
    var ms = (act.hold !== undefined ? act.hold : 3000) * pace
    if (typeof act.run !== "function") ms = Math.max(ms, readMs(caption, sub))
    after(ms, cleanup, true)
  }

  function cleanup() {
    watching = false
    waiters = []
    keyHandler = null
    carouselItems = []
    endCard = false
    handoff = false
    keycap = ""
    closeOurs(act)
    if (typeof act.cleanup === "function") act.cleanup(engine)
    else if (act.cleanup && act.cleanup !== "close-ours" && act.cleanup !== "none") launch(act.cleanup)
    after(350, next)
  }

  function closeOurs(a) {
    if (!a || a.keep || a.cleanup !== "close-ours") return
    ours.forEach(function(addr) { runner.run("close:" + addr, hypr_.closeCmd(addr), 4000) })
    ours = []
  }

  // ======================================================================
  //  Events
  // ======================================================================
  function handleWindowOpened(addr, cls, title) {
    if (!watching) return
    ours = ours.concat([addr])
    log("window opened " + addr + " class=" + cls)
    for (var i = 0; i < waiters.length; i++) {
      var w = waiters[i]
      if (w.fired) continue
      w.fired = true
      waiters = waiters.filter(function(x) { return x !== w })
      w.fn(addr, cls)
      return
    }
  }

  function handleWindowClosed(addr) {
    ours = ours.filter(function(a) { return a !== addr })
  }

  function handleFinished(token, code, out) {
    if (token === "prep") { parsePrep(out); begin(); return }
    if (token === "restore") { log("restored (" + code + ")"); Qt.quit(); return }
    var cb = callbacks[token]
    if (cb) { delete callbacks[token]; cb(code, out); return }
    if (token.indexOf("run:") === 0 && code !== 0 && code !== 124)
      log("run exited " + code + " for " + (act ? act.id : "?"))
  }

  function keyPressed(name) {
    if (keyHandler) keyHandler(name)
  }

  // ======================================================================
  //  Esc Esc
  // ======================================================================
  function escapePressed() {
    if (state === "quitting") return
    var now = Date.now()
    log("Esc pressed (state " + state + ")")
    if (now - lastEscAt <= escWindowMs) { log("Esc Esc — quitting"); quit(); return }
    lastEscAt = now
    savedSub = sub
    sub = "press Esc again to stop"
    escResetTimer.restart()
  }

  function quit() {
    if (state === "quitting") return
    var abortCmd = ""
    if (act && typeof act.abort === "function") {
      try { abortCmd = act.abort(engine) || "" } catch (err) { log("abort failed: " + err) }
    }
    gen++
    state = "quitting"
    logo = false
    pose = "center"
    caption = "PUTTING EVERYTHING BACK"
    sub = ""
    keycap = ""
    carouselItems = []
    endCard = false
    watching = false
    runner.killAll()
    closeOurs(act)
    if (recording) { abortCmd = (abortCmd ? abortCmd + "; " : "") + "omarchy-capture-screenrecording --stop-recording >/dev/null 2>&1"; recording = false }
    runner.run("restore", (abortCmd ? abortCmd + "; " : "") + snapshot.restoreCmd(keepTheme), 12000)
    quitWatchdog.start()
  }

  // ---- parts -------------------------------------------------------------
  Runner { id: runner; onFinished: function(t, c, o) { engine.handleFinished(t, c, o) } }
  Hypr {
    id: hypr_
    onWindowOpened: function(a, c, t) { engine.handleWindowOpened(a, c, t) }
    onWindowClosed: function(a) { engine.handleWindowClosed(a) }
  }
  Snapshot { id: snapshot }

  property Component delayComponent: Component { Timer { repeat: false } }

  Timer {
    id: escResetTimer
    interval: 1500
    onTriggered: if (engine.state !== "quitting" && engine.sub === "press Esc again to stop") engine.sub = engine.savedSub
  }
  // Restore gets its chance (a theme switch is ~1.5 s); after that we leave
  // regardless. The show must never hold the screen hostage.
  Timer { id: quitWatchdog; interval: 13000; onTriggered: Qt.quit() }
}
