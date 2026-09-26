.pragma library
// Showoff Omarchy — the act table. The show is data: the engine walks these
// rows and never special-cases an act. Schema: PLAN.md §2.1. A function
// `run(e)` uses the act API in Engine.qml (e.say, e.sh, e.launch, e.after,
// e.onWindow, e.showKeycap, e.bind, e.onKey, e.carousel, e.done …).
//
// Copy is written for someone who has only used Windows or a Mac.

var OMARCHY = "${OMARCHY_PATH:-/usr/share/omarchy}"
var IMG = "\\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\)"
var MEDIA = "\\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.gif' -o -iname '*.mp4' -o -iname '*.webm' -o -iname '*.mov' -o -iname '*.mkv' \\)"

// slug<TAB>preview — same preview rule as omarchy-theme-switcher.
var THEMES_CMD =
  "declare -A seen; for d in $HOME/.config/omarchy/themes/*/ " + OMARCHY + "/themes/*/; do " +
  "[ -d \"$d\" ] || continue; n=$(basename \"$d\"); [ -n \"${seen[$n]}\" ] && continue; seen[$n]=1; " +
  "p=$(find -L \"$d\" -maxdepth 1 -type f \\( -iname 'preview.png' -o -iname 'preview.jpg' -o -iname 'preview.jpeg' -o -iname 'preview.webp' \\) -print -quit 2>/dev/null); " +
  "[ -z \"$p\" ] && p=$(find -L \"$d/backgrounds\" -maxdepth 1 -type f " + IMG + " 2>/dev/null | sort | head -1); " +
  "printf '%s\\t%s\\n' \"$n\" \"$p\"; done | sort"

function loadThemes(e, then) {
  if (e.themeList.length) { then(); return }
  e.sh(THEMES_CMD, function(code, out) {
    e.themeList = String(out).trim().split("\n").filter(Boolean).map(function(l) {
      var f = l.split("\t")
      return { slug: f[0], title: e.titleOf(f[0]), image: f[1] ? "file://" + f[1] : "" }
    })
    then()
  }, 8000)
}

// A theme-set that never queues: arrows only apply the latest pick.
function themeSetter(e) {
  var s = { busy: false, pending: "", applied: "" }
  s.set = function(slug) {
    if (s.busy) { s.pending = slug; return }
    if (slug === s.applied) return
    s.busy = true
    e.sh("omarchy-theme-set " + e.q(slug), function() {
      s.busy = false
      s.applied = slug
      if (s.pending && s.pending !== slug) { var p = s.pending; s.pending = ""; s.set(p) }
      else s.pending = ""
    }, 15000)
  }
  return s
}

// Left/Right/Enter over a carousel, live-applying after a pause, with an
// idle timeout so an unattended booth never stalls.
function picker(e, items, start, apply, onPick, idleMs) {
  var i = start, g = 0
  e.carousel(items, i)
  function idle() { var mine = ++g; e.after(idleMs, function() { if (mine === g) onPick(i, true) }) }
  function settle() { var mine = g; e.after(450, function() { if (mine === g) apply(i) }) }
  idle()
  e.onKey(function(k) {
    if (k === "Left" || k === "Right") {
      i = (i + (k === "Left" ? -1 : 1) + items.length) % items.length
      e.carousel(items, i)
      idle()
      settle()
    } else if (k === "Return" || k === "Enter" || k === " ") {
      g++
      apply(i)
      onPick(i, false)
    }
  })
}

function terminalName(e, then) {
  e.sh("id=$(xdg-terminal-exec --print-id 2>/dev/null); f=$(find $HOME/.local/share/applications /usr/share/applications -name \"$id\" 2>/dev/null | head -1); " +
       "grep -m1 '^Name=' \"$f\" 2>/dev/null | cut -d= -f2", function(c, out) { then(String(out).trim() || "terminal") }, 4000)
}

var ACTS = [
  // ---------------------------------------------------------------- look
  {
    id: "takeover", title: "Takeover", blurb: "the logo, glowing in your theme", group: "look",
    logo: true, caption: "",
    sub: "no Windows. no macOS. watch this.",
    until: { ms: 3200 }, hold: 0
  },
  {
    id: "browser", title: "omarchy.org", blurb: "a new browser window, one key away", group: "look",
    caption: "THIS IS OMARCHY", sub: "your browser, one keystroke away",
    keycapBind: "Browser", keycap: "SUPER + SHIFT + RETURN",
    requires: ["omarchy-launch-browser"],
    run: "omarchy-launch-browser --new-window https://omarchy.org",
    until: { window: true, timeoutMs: 8000, soft: true },
    holdPose: "lower", holdSub: "a whole operating system, built to be fast",
    hold: 6500, cleanup: "close-ours"
  },
  {
    id: "tiling", title: "Tiling", blurb: "windows arrange themselves", group: "look",
    caption: "NO MORE DRAGGING WINDOWS", sub: "",
    requires: ["omarchy-launch-terminal"],
    cleanup: "close-ours",
    run: function(e) {
      var key = e.bind("Terminal", "SUPER + RETURN")
      var words = ["ONE", "TWO", "THREE", "FOUR"]
      var addrs = []
      function open(n) {
        if (n === words.length) { pop(); return }
        e.say(words[n], n === 0 ? "every window finds its own place" : "the layout rebuilds itself")
        e.showKeycap(n === 0 ? key : "", 0, function() {
          e.launch("omarchy-launch-terminal")
          e.onWindow(function(addr) { addrs.push(addr); e.setPose("lower"); e.after(n === 0 ? 2200 : (e.x ? 1000 : 1500), function() { open(n + 1) }) },
                     8000, function() { open(n + 1) })
        })
      }
      function pop() {
        var w = addrs[addrs.length - 1]
        if (!w) { e.done(); return }
        e.setPose("lower")
        e.say("POP ONE OUT", "float it, pin it, keep working under it")
        e.showKeycap(e.bind("Pop window out (float & pin)", "SUPER + O"), 0, function() {
          e.hypr('hl.dsp.window.float({ window = "address:' + w + '", action = "toggle" })', "togglefloating address:" + w)
          e.hypr('hl.dsp.window.resize({ window = "address:' + w + '", x = 900, y = 560 })', "resizewindowpixel exact 900 560,address:" + w)
          e.hypr('hl.dsp.window.center({ window = "address:' + w + '" })', "centerwindow")
          e.after(e.x ? 2600 : 3400, function() {
            e.say("AND SNAP IT BACK", "")
            e.hypr('hl.dsp.window.float({ window = "address:' + w + '", action = "toggle" })', "togglefloating address:" + w)
            e.after(e.x ? 1600 : 2400, e.done)
          })
        })
      }
      open(0)
    },
    hold: 400
  },
  {
    id: "workspaces", title: "Workspaces", blurb: "ten desktops, instant", group: "look",
    caption: "TEN DESKTOPS. ZERO WAITING.", sub: "",
    requires: ["omarchy-launch-terminal"],
    cleanup: "close-ours",
    run: function(e) {
      var spare = e.spareWs.slice(0, 3)
      if (spare.length < 3 || !e.stageWs) { e.sayThen("", "skipping Workspaces — not enough empty workspaces", e.done); return }
      var all = [e.stageWs].concat(spare)
      function fill(n) {
        if (n === spare.length) { fly(0); return }
        e.focusWs(spare[n])
        e.say(spare[n], "a fresh desktop, already there")
        e.launch("omarchy-launch-terminal")
        e.onWindow(function() { e.after(e.x ? 600 : 1400, function() { fill(n + 1) }) }, 8000, function() { fill(n + 1) })
      }
      function fly(n) {
        if (n === all.length * 2) { e.focusWs(e.stageWs); e.after(600, e.done); return }
        var ws = all[n % all.length]
        e.setPose("center")
        var first = e.x ? n === 0 : n < all.length
        e.say(ws, first ? "SUPER + a number. that's it." : "")
        e.keycap = first ? "SUPER + " + (ws === "10" ? "0" : ws) : ""
        e.focusWs(ws)
        // First lap: slow, with the keys on screen. Second lap: the whoosh.
        var slow = e.x ? n === 0 : n < all.length
        e.after(slow ? 2600 : 650, function() { e.keycap = ""; fly(n + 1) })
      }
      fill(0)
    },
    hold: 200
  },

  // --------------------------------------------------------------- drive
  {
    id: "theme-pick", title: "Pick a theme", blurb: "the visitor drives, live", group: "drive",
    caption: "NOW YOU PICK THE THEME", sub: "← →  to look around   ·   Enter to keep it",
    pose: "top",
    run: function(e) {
      loadThemes(e, function() {
        var list = e.themeList
        if (list.length < 2) { e.sayThen("", "only one theme installed — skipping", e.done); return }
        e.sh("cat $HOME/.local/state/omarchy/current/theme.name", function(c, out) {
          var cur = String(out).trim()
          var start = Math.max(0, list.map(function(t) { return t.slug }).indexOf(cur))
          var setter = themeSetter(e)
          setter.applied = cur
          picker(e, list.map(function(t) { return { title: t.title, image: t.image } }), start,
            function(i) { setter.set(list[i].slug) },
            function(i, timedOut) {
              e.chosenTheme = list[i].slug
              e.carousel([], 0)
              e.setPose("center")
              e.say(timedOut ? "NOBODY? I'LL DRIVE." : "GOOD CHOICE.", list[i].title)
              setter.set(list[i].slug)
              e.after(2800, e.done)
            }, 25000)
          if (e.x) e.after(1200, function() { e.autoKeys(["Right", "Right", "Right", "Return"], 1300) })
        }, 3000)
      })
    },
    hold: 0
  },
  {
    id: "roulette", title: "Theme roulette", blurb: "six themes in ten seconds", group: "drive",
    caption: "EVERY APP. EVERY COLOR.", sub: "", pose: "lower",
    requires: ["omarchy-theme-set"],
    run: function(e) {
      loadThemes(e, function() {
        var others = e.themeList.filter(function(t) { return t.slug !== e.chosenTheme })
        var picks = []
        for (var k = 0; k < (e.x ? 4 : 6) && others.length; k++) picks.push(others.splice(Math.floor(Math.random() * others.length), 1)[0])
        if (e.chosenTheme) picks.push({ slug: e.chosenTheme, title: e.titleOf(e.chosenTheme) })
        function go(n) {
          if (n === picks.length) { e.sayThen("AND BACK TO YOURS.", picks.length ? picks[picks.length - 1].title : "", e.done); return }
          e.sub = picks[n].title
          e.sh("omarchy-theme-set " + e.q(picks[n].slug), function() { e.after(250, function() { go(n + 1) }) }, 15000)
        }
        go(0)
      })
    },
    hold: 0
  },
  {
    id: "wallpapers", title: "Wallpapers", blurb: "including video ones", group: "drive",
    caption: "WALLPAPERS, TOO.", sub: "even video ones", pose: "lower",
    keycapBind: "Background switcher", keycap: "SUPER + CTRL + SPACE",
    requires: ["omarchy-theme-bg-next"],
    run: function(e) {
      function go(n) {
        if (n === (e.x ? 3 : 4)) { e.done(); return }
        e.launch("omarchy-theme-bg-next")
        e.after(1600, function() { go(n + 1) })
      }
      go(0)
    },
    hold: 400
  },
  {
    id: "wallpaper-pick", title: "Pick a wallpaper", blurb: "the visitor drives again", group: "drive",
    caption: "YOUR TURN AGAIN", sub: "← →  pick a wallpaper   ·   Enter to keep it", pose: "top",
    requires: ["omarchy-theme-bg-set"],
    run: function(e) {
      e.sh("slug=$(cat $HOME/.local/state/omarchy/current/theme.name); " +
           "find -L $HOME/.config/omarchy/backgrounds/$slug/ $HOME/.local/state/omarchy/current/theme/backgrounds/ -maxdepth 1 -type f " + MEDIA + " 2>/dev/null | sort -u",
        function(c, out) {
          var files = String(out).trim().split("\n").filter(Boolean)
          if (files.length < 2) { e.sayThen("", "this theme has one wallpaper — moving on", e.done); return }
          var items = files.map(function(f) {
            var video = /\.(mp4|webm|mov|mkv)$/i.test(f)
            return { title: f.replace(/^.*\//, "").replace(/\.[^.]+$/, ""), image: video ? "" : "file://" + f, note: video ? "▶ video wallpaper" : "" }
          })
          var last = ""
          picker(e, items, 0,
            function(i) { if (files[i] !== last) { last = files[i]; e.launch("omarchy-theme-bg-set " + e.q(files[i])) } },
            function(i, timedOut) {
              e.carousel([], 0)
              e.setPose("center")
              e.sayThen(timedOut ? "I'LL TAKE THIS ONE." : "NICE.", items[i].title, e.done)
            }, 18000)
        }, 5000)
    },
    hold: 0
  },

  // ---------------------------------------------------------------- hood
  {
    id: "install-btop", title: "Install an app", blurb: "one line, no app store", group: "hood",
    caption: "INSTALLING AN APP", sub: "no app store. no wizard. no reboot.",
    keep: true,
    run: function(e) {
      e.sh("command -v btop", function(code) {
        if (code === 0) {
          e.say("ONE LINE. ONE APP.", "btop: every core, every process, live")
          e.launch("omarchy-launch-floating-terminal-with-presentation btop")
          e.onWindow(function() { e.setPose("lower"); e.after(e.x ? 4500 : 5500, e.done) }, 10000, e.done)
          return
        }
        // Installing needs the visitor's password: hand them the keyboard.
        e.setHandoff(true)
        e.say("WATCH THIS INSTALL", "type your password when it asks — that's the whole process")
        e.launch("omarchy-launch-floating-terminal-with-presentation \"omarchy-pkg-add btop && btop\"")
        var tries = 0
        function poll() {
          e.sh("pgrep -x btop", function(c) {
            if (c === 0) { e.setHandoff(false); e.setPose("lower"); e.say("INSTALLED. RUNNING. DONE.", "seconds, not minutes"); e.after(5000, e.done) }
            else if (++tries > 120) { e.setHandoff(false); e.sayThen("", "no install today — moving on", e.done) }
            else e.after(1000, poll)
          }, 3000)
        }
        poll()
      }, 3000)
    },
    hold: 0
  },
  {
    id: "aquarium", title: "Aquarium", blurb: "cava, cmatrix, asciiquarium", group: "hood",
    caption: "THE TERMINAL IS A PLAYGROUND", sub: "", pose: "lower",
    requiresPkg: ["cava", "cmatrix", "asciiquarium"], anyPkg: true,
    cleanup: "close-ours",
    run: function(e) {
      e.sh("for p in cava cmatrix asciiquarium; do command -v $p >/dev/null && echo $p; done", function(c, out) {
        var apps = String(out).trim().split("\n").filter(Boolean)
        function go(n) {
          if (n === apps.length) { e.after(e.x ? 4000 : 6500, e.done); return }
          e.sub = apps.slice(0, n + 1).join(" · ")
          e.launch("omarchy-launch-terminal " + apps[n])
          e.onWindow(function() { e.after(500, function() { go(n + 1) }) }, 8000, function() { go(n + 1) })
        }
        go(0)
      }, 3000)
    },
    hold: 0
  },
  {
    id: "fastfetch", title: "Under the hood", blurb: "the whole system at a glance", group: "hood",
    caption: "THE WHOLE SYSTEM, AT A GLANCE", sub: "",
    requires: ["fastfetch", "omarchy-launch-floating-terminal-with-presentation"],
    run: "omarchy-launch-floating-terminal-with-presentation fastfetch",
    until: { window: true, timeoutMs: 8000 },
    holdPose: "lower", holdSub: "open source, top to bottom", hold: 6500,
    cleanup: "close-ours"
  },
  {
    id: "webapp", title: "Web apps", blurb: "YouTube as its own window", group: "hood",
    caption: "WEBSITES BECOME APPS", sub: "no browser tabs, no Electron",
    requires: ["omarchy-launch-webapp"],
    precheck: "b=$(xdg-settings get default-web-browser); case $b in google-chrome*|brave*|microsoft-edge*|opera*|vivaldi*|helium*|chromium*) true;; *) command -v chromium;; esac",
    precheckWhy: "a Chromium-based browser",
    run: "omarchy-launch-webapp https://www.youtube.com",
    until: { window: true, timeoutMs: 10000 },
    holdPose: "lower", holdSub: "YouTube, as its own window", hold: 6000,
    cleanup: "close-ours"
  },
  {
    id: "emoji-clipboard", title: "Emoji + clipboard", blurb: "both built in", group: "hood",
    caption: "EMOJI PICKER. BUILT IN.", sub: "",
    requires: ["omarchy-menu-emoji", "omarchy-menu-clipboard", "omarchy-shell"],
    run: function(e) {
      e.setHandoff(true)
      e.showKeycap(e.bind("Emojis", "SUPER + CTRL + E"), 0, function() {
        e.launch("omarchy-menu-emoji")
        e.after(e.x ? 2600 : 3500, function() {
          e.launch("omarchy-shell shell hide omarchy.emojis")
          e.say("CLIPBOARD HISTORY. BUILT IN.", "every copy, searchable")
          e.showKeycap(e.bind("Clipboard manager", "SUPER + CTRL + V"), 0, function() {
            e.launch("omarchy-menu-clipboard")
            e.after(e.x ? 2600 : 3500, function() {
              e.launch("omarchy-shell shell hide omarchy.clipboard")
              e.setHandoff(false)
              e.after(600, e.done)
            })
          })
        })
      })
    },
    abort: function() { return "omarchy-shell shell hide omarchy.emojis; omarchy-shell shell hide omarchy.clipboard" },
    hold: 0
  },
  {
    id: "menu-tour", title: "The menu", blurb: "one menu for everything", group: "hood",
    caption: "ONE MENU FOR EVERYTHING", sub: "",
    requires: ["omarchy-menu"],
    run: function(e) {
      var stops = [
        ["root", "ONE MENU FOR EVERYTHING", "not a settings app with forty panes"],
        ["style", "STYLE", "themes, fonts, wallpapers"],
        ["install", "INSTALL", "apps, languages, dev tools"],
        ["setup", "SETUP", "wifi, bluetooth, monitors"]
      ]
      e.setHandoff(true)
      e.setPose("lower")
      e.showKeycap(e.bind("Omarchy menu", "SUPER + SPACE"), 0, function() {
        function go(n) {
          if (n === stops.length) { e.launch("omarchy-menu close"); e.setHandoff(false); e.after(600, e.done); return }
          e.say(stops[n][1], stops[n][2])
          e.launch("omarchy-menu summon " + stops[n][0])
          e.after(e.readMs(stops[n][1], stops[n][2]) + 600, function() { go(n + 1) })
        }
        go(0)
      })
    },
    abort: function() { return "omarchy-menu close" },
    hold: 0
  },
  {
    id: "nightshift", title: "Night light", blurb: "warm screen, one key", group: "hood",
    caption: "NIGHT SHIFT? ONE KEY.", sub: "",
    requires: ["omarchy-toggle-nightlight"],
    run: function(e) {
      e.showKeycap(e.bind("Toggle nightlight", "SUPER + CTRL + N"), 0, function() {
        e.data.toggled = 1
        e.sh("omarchy-toggle-nightlight", function() {
          e.sub = "warm for the evening"
          e.after(3400, function() {
            e.sh("omarchy-toggle-nightlight", function() { e.data.toggled = 0; e.sub = "and back"; e.after(2200, e.done) }, 8000)
          })
        }, 8000)
      })
    },
    abort: function(e) { return e.data.toggled ? "omarchy-toggle-nightlight" : "" },
    hold: 0
  },
  {
    id: "gaps", title: "Gaps + fullscreen", blurb: "tight or airy", group: "hood",
    caption: "TIGHT OR AIRY. YOUR CALL.", sub: "", pose: "lower",
    requires: ["omarchy-hyprland-window-gaps-toggle", "omarchy-launch-terminal"],
    cleanup: "close-ours",
    run: function(e) {
      var addrs = []
      function open(n) {
        if (n === 2) { gaps(); return }
        e.launch("omarchy-launch-terminal")
        e.onWindow(function(a) { addrs.push(a); e.after(500, function() { open(n + 1) }) }, 8000, function() { open(n + 1) })
      }
      function gaps() {
        e.showKeycap(e.bind("Toggle window gaps", "SUPER + SHIFT + BACKSPACE"), 0, function() {
          e.data.gaps = 1
          e.launch("omarchy-hyprland-window-gaps-toggle")
          e.sub = "gaps off"
          e.after(2800, function() {
            e.launch("omarchy-hyprland-window-gaps-toggle")
            e.data.gaps = 0
            e.sub = "gaps back"
            e.after(2200, full)
          })
        })
      }
      function full() {
        var w = addrs[0]
        if (!w) { e.done(); return }
        e.say("FULLSCREEN, ONE KEY", "")
        e.focusWindow(w)
        e.after(200, function() {
          e.hypr('hl.dsp.window.fullscreen({ mode = "maximized" })', "fullscreen 1")
          e.after(2800, function() {
            e.hypr('hl.dsp.window.fullscreen({ mode = "maximized" })', "fullscreen 1")
            e.after(1400, e.done)
          })
        })
      }
      open(0)
    },
    abort: function(e) { return e.data.gaps ? "omarchy-hyprland-window-gaps-toggle" : "" },
    hold: 0
  },

  // --------------------------------------------------------------- hands
  {
    id: "you-launch", title: "Your turn", blurb: "the visitor launches an app", group: "hands",
    caption: "YOUR TURN", sub: "",
    cleanup: "close-ours",
    run: function(e) {
      terminalName(e, function(name) {
        var key = e.bind("Apps menu", e.bind("Omarchy menu", "SUPER + SPACE"))
        e.say("YOUR TURN", "press " + key + ", type " + name.toLowerCase() + ", press Enter")
        e.keycap = key
        e.setHandoff(true)
        e.onWindow(function() {
          e.keycap = ""
          e.setHandoff(false)
          e.setPose("lower")
          e.say("YOU JUST DID THAT.", "that's the whole trick. keys, not clicks.")
          e.after(3500, e.done)
        }, 40000, function() {
          e.keycap = ""
          e.launch("omarchy-menu close")
          e.setHandoff(false)
          e.sayThen("", "no worries — I'll keep going", e.done)
        })
      })
    },
    abort: function() { return "omarchy-menu close" },
    hold: 0
  },
  {
    id: "neovim", title: "Neovim", blurb: "an editor that matches", group: "hands", flag: "dev",
    caption: "AN EDITOR THAT MATCHES", sub: "already themed. zero setup.",
    keycapBind: "Terminal", keycap: "SUPER + RETURN",
    requires: ["nvim", "omarchy-launch-terminal"],
    run: "omarchy-launch-terminal nvim /etc/os-release",
    until: { window: true, timeoutMs: 8000 },
    holdPose: "lower", hold: 4500, cleanup: "close-ours"
  },
  {
    id: "local-ai", title: "Local AI", blurb: "runs on this laptop", group: "hands",
    caption: "AI THAT RUNS ON THIS LAPTOP", sub: "no cloud. no account.",
    requires: ["ollama", "omarchy-launch-floating-terminal-with-presentation"],
    precheck: "curl -sf --max-time 2 localhost:11434/api/tags | jq -e '.models | length > 0'",
    precheckWhy: "Ollama running with a model",
    run: "m=$(curl -sf localhost:11434/api/tags | jq -r '.models | sort_by(.size) | .[0].name'); " +
         "omarchy-launch-floating-terminal-with-presentation \"ollama run $m 'In two short sentences: what is Omarchy, the Linux setup by DHH?'\"",
    until: { window: true, timeoutMs: 10000 },
    holdPose: "lower", holdSub: "this answer never left the machine", hold: 15000,
    cleanup: "close-ours"
  },

  // ------------------------------------------------------------- sendoff
  {
    id: "screensaver", title: "Screensaver", blurb: "even the screensaver", group: "sendoff",
    caption: "", sub: "even the screensaver", pose: "lower",
    requires: ["ttfx", "omarchy-launch-screensaver"],
    run: "omarchy-launch-screensaver force",
    until: { window: true, timeoutMs: 6000, soft: true },
    hold: 6000, cleanup: "close-ours"
  },
  {
    id: "qr", title: "Take it home", blurb: "QR codes, keep the theme?", group: "sendoff",
    caption: "", sub: "",
    run: function(e) {
      e.endTheme = e.x ? "" : e.titleOf(e.chosenTheme || "")
      e.endCard = true
      if (e.x) { e.after(6000, function() { e.endCard = false; e.done() }); return }
      var g = 0
      function finish(keep) {
        g++
        e.keepTheme = keep
        e.endCard = false
        e.sayThen(keep ? "IT'S YOURS." : "PUT BACK. LIKE IT NEVER HAPPENED.", "", e.done)
      }
      e.onKey(function(k) {
        var c = String(k).toLowerCase()
        if (c === "y") finish(true)
        else if (c === "n") finish(false)
      })
      var mine = ++g
      e.after(20000, function() { if (mine === g) finish(false) })
    },
    hold: 0
  },

  // -------------------------------------------------- menu-only / drills
  {
    id: "hello-terminal", title: "A terminal", group: "look",
    caption: "ONE KEY. ONE TERMINAL.", sub: "no dock, no Finder, no Start menu",
    keycapBind: "Terminal", keycap: "SUPER + RETURN",
    requires: ["omarchy-launch-terminal"],
    run: "omarchy-launch-terminal",
    until: { window: true, timeoutMs: 8000 },
    hold: 3000, cleanup: "close-ours"
  }
]

var AUTO_ORDER = [
  "takeover", "browser", "tiling", "workspaces",
  "theme-pick", "roulette", "wallpapers", "wallpaper-pick",
  "install-btop", "aquarium", "fastfetch", "webapp",
  "emoji-clipboard", "menu-tour", "nightshift", "gaps",
  "you-launch", "neovim", "local-ai",
  "screensaver", "qr"
]

// `showoff x`: the ~80 s cut for posting. No waiting on a visitor, same
// readable keycaps. See the running-order table in ACTS.md.
var X_ORDER = [
  "takeover", "tiling", "workspaces", "theme-pick", "roulette",
  "wallpapers", "install-btop", "aquarium", "webapp", "emoji-clipboard", "qr"
]

var MENU_GROUPS = {
  look: "Look",
  drive: "Hand them the keyboard",
  hood: "Under the hood",
  hands: "Hands-on",
  sendoff: "Send-off"
}

function byId(id) {
  for (var i = 0; i < ACTS.length; i++) if (ACTS[i].id === id) return ACTS[i]
  return null
}
