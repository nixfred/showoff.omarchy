# Showoff Omarchy — build plan

> Written 2026-09-21 by Larry on Fable so that **Opus or lower builds it**.
> Every API idiom here was read from working code on vic that night (anchors
> given). Where something is *not* verified it says so — verify it, don't
> guess. The brief is `CLAUDE.md`; the research is `RESEARCH.md`; the act
> catalogue is `ACTS.md`. This file is the instruction set.

## 0. Rules for the model executing this plan

1. **Law 0:** stock Omarchy only. `omarchy-*` commands, Quickshell, Qt, stock
   state files. No `qs.Commons`, no other plugin, no vic patch. If a command
   you want isn't in `$OMARCHY_PATH/bin`, the act says so on screen and skips.
2. **Never run `showoff` on vic without Fred's go** — it grabs his keyboard.
   Ask, then run. Prefer `demo@ovm` (see `CLAUDE.md`) for anything long.
3. **Never inject a key** (`wtype`) unless `hyprctl layers -j` shows namespace
   `showoff-omarchy` *immediately* before that key. Use the recipe in §C.3.
   Keys that miss go to Fred's other sessions — that already happened once.
4. **Verify with evidence, not belief:** screenshot (`grim`) + look at it,
   `hyprctl layers -j`, `pgrep -x quickshell -a`, the Quickshell log. Every
   phase's "Done when" lists what to show.
5. **One phase = one commit**, LR- trailers as in `git log`. Push after each
   (`git remote -v` first; origin is `git@github.com:nixfred/showoff.omarchy.git`, PUBLIC).
6. **Acts are data, not code paths.** Adding an act = adding a row to
   `app/acts.js`. If you find yourself special-casing an act in the engine,
   stop and add a field to the schema instead.
7. **Skip, never fail.** Any precondition miss, timeout, or non-zero exit
   inside an act logs a line, shows a one-line caption ("skipped: btop not
   installed"), and moves on. The show never dies mid-run.
8. **Restore on every exit path:** normal end, Esc×2, menu "quit", crash of
   an act. Test each.
9. **Model tiers** (Fred's rule: lowest that does the job): each phase names
   one. Opus only where the plan says so; Sonnet for the rest; nothing here
   needs Fable.

## 1. Architecture (final)

```
bin/showoff                       launcher: modes → env → exec quickshell -n -p app/
bin/showoff-hypr                  dual-form hyprctl dispatch helper (Lua, classic fallback)
app/shell.qml                     ShellRoot: windows per screen, colours, inhibitors, key routing
app/Engine.qml                    the state machine + act runner (QtObject, no UI)
app/acts.js                       the act table (data) + running order + menu groups
app/Runner.qml                    one Process wrapper: run(cmd) → exited(code, stdout), watchdog
app/Hypr.qml                      window bookkeeping: snapshot toplevels, wait for new, close ours
app/Snapshot.qml                  record + restore theme / background / workspace / toggles
app/ui/Caption.qml                the big glowing caption + sub-caption
app/ui/Keycap.qml                 "SUPER + RETURN" as glowing keycaps (Keycap Karaoke layer)
app/ui/Countdown.qml              splash + countdown gate
app/ui/Menu.qml                   act grid, keyboard + mouse
app/ui/ThemePicker.qml            Left/Right carousel with preview, live apply
app/ui/WallpaperPicker.qml        same, for backgrounds
app/ui/EndCard.qml                QR + "keep this theme?" + recording path
app/assets/qr-omarchy.svg         pre-generated QR (no runtime qrencode dependency)
app/assets/qr-repo.svg
showoff-omarchy.desktop           launcher entry
install.sh                        user-local install (P10)
PKGBUILD                          AUR package (P10)
```

**Process model:** one Quickshell process. `shell.qml` owns one `PanelWindow`
per screen (`Variants` over `Quickshell.screens`), all on `WlrLayer.Overlay`
with `WlrKeyboardFocus.Exclusive` unless `engine.handoff` is true (then
`WlrKeyboardFocus.None`). Only the *primary* window (the focused monitor, or
the first) renders the interactive UI; the others render the scrim and a
mirrored caption.

**Data flow:** `acts.js` → `Engine` walks rows → for each row: show keycap →
run command via `Runner` → wait on `until` (timer / new window / key) → hold →
cleanup → next. `Engine` exposes `state`, `act`, `caption`, `sub`, `keycap`,
`handoff`, `progress` as properties; the UI binds to them. No UI code calls
shell commands directly — everything goes through `Engine`.

## 2. Contracts (exact)

### 2.1 Act row schema (`app/acts.js`)

```js
// Every field except id/title/caption is optional. Defaults in brackets.
{
  id: "browser",                        // unique, kebab-case; `showoff act <id>`
  title: "omarchy.org",                 // menu card title
  blurb: "Your browser, on the site.",  // menu card one-liner
  group: "look",                        // look | drive | theme | hood | hands | sendoff
  caption: "THIS IS OMARCHY",           // big text; "" hides it
  sub: "a Linux desktop that gets out of your way",
  keycap: "SUPER + RETURN",             // [""] shown ~900 ms before `run`; "" = none
  requires: ["omarchy-launch-browser"], // [[]] every entry must pass omarchy-cmd-present
  requiresPkg: ["btop"],                // [[]] every entry must pass omarchy-pkg-present
  precheck: "curl -sf localhost:11434/api/tags >/dev/null",  // [""] bash; non-zero = skip
  run: "omarchy-launch-browser https://omarchy.org",         // bash -lc string, or a function(engine)
  until: { window: true, timeoutMs: 8000 },   // wait for a NEW toplevel (any class)
  //   or { window: /brave|firefox|chromium/i, timeoutMs } — class regex
  //   or { ms: 1500 }                        — plain wait
  //   or { key: ["Return"] }                 — interactive; engine hands keys to `onKey`
  //   [{ ms: 0 }]
  hold: 6000,                           // [3000] ms to sit on the result before cleanup
  cleanup: "close-ours",                // ["none"] | "close-ours" (windows opened by this act)
  //   | bash string | function(engine)
  keep: false,                          // [false] true = do not close what this act opened (btop)
  handoff: false,                       // [false] true = release the keyboard for the act's duration
  interactive: "ThemePicker",           // [""] name of a ui/ component that drives this act
  onKey: function(engine, key) {},      // for until.key acts without a component
  shortRun: "...",                      // [run] variant used by the auto show if the full act is long
  flag: "dev",                          // [""] only runs when config.flags includes it
  skipInAuto: false                     // [false] menu-only act
}
```

Running order and menu are also data in `acts.js`:

```js
export const AUTO_ORDER = ["takeover","browser","tiling","workspaces","theme-pick", ...]
export const MENU_GROUPS = { look: "Look", drive: "Hand them the keyboard", ... }
```

### 2.2 Engine state machine (`app/Engine.qml`)

States (a string property `state`):

```
idle ─(start)─▶ countdown ─(5 s silence)─▶ auto ─▶ running ─▶ … ─▶ ended ─▶ menu
                    │(any key/click)──────▶ menu ─(pick)─▶ running ─▶ menu
                    │
                    └─ mode=auto|menu|act from env skips the gate
running: prep(act) → keycap(900 ms) → run → waiting(until) → hold → cleanup → next
Esc Esc from ANY state ─▶ quitting: cleanup(current act) → Snapshot.restore() → Qt.quit()
```

Events: `start()`, `interact()`, `escape()`, `runAct(id)`, `runAuto()`,
`keyPressed(key)`, `windowOpened(addr, cls, title)`, `windowClosed(addr)`,
`processExited(token, code, out)`, `tick()`.

Rules the engine enforces (write tests as manual checklists in §C):
- `escape()` twice within 1000 ms → `quitting`. One Esc → `sub = "press Esc again to stop"` for 1500 ms, then the previous sub returns.
- In `quitting`, all `Runner` processes get `kill()`; restore runs with a 5 s watchdog; then `Qt.quit()` no matter what.
- `handoff` true ⇒ windows set `WlrKeyboardFocus.None` and `ShortcutInhibitor.enabled = false`; Esc×2 cannot be seen then, so the act **must** have a `timeoutMs` and the engine also polls `Hyprland.rawEvent` for the expected window. A hand-off act never lasts more than 45 s.
- Every `run` has a watchdog: `until.timeoutMs` (default 10 000). Missing binary = `Process` never emits `exited` (known Quickshell gotcha) — that is why `requires` runs *before* `run`.
- `progress` = `{ index, total, actId }` for the UI strip.

### 2.3 Runner (`app/Runner.qml`)

Wraps `Quickshell.Io.Process`. Verified idiom (`~/.config/omarchy/plugins/nixfred.reel/Panel.qml:261-345`):

```qml
import Quickshell.Io
QtObject {
  id: runner
  signal finished(string token, int code, string out)
  property var procs: ({})
  function run(token, cmd, timeoutMs) {
    var p = procComponent.createObject(runner, { token: token, timeoutMs: timeoutMs || 10000 })
    p.command = ["bash", "-lc", cmd]
    procs[token] = p
    p.running = true
  }
  function killAll() { for (var t in procs) { procs[t].running = false } }
  property Component procComponent: Component {
    Process {
      property string token
      property int timeoutMs
      stdout: StdioCollector { waitForEnd: true }
      onExited: function(code, status) { runner.finished(token, code, stdout.text); destroy() }
      Timer { running: true; interval: timeoutMs; onTriggered: { parent.running = false; runner.finished(parent.token, 124, "") } }
    }
  }
}
```
Exact property names of `StdioCollector` (`text`, `waitForEnd`,
`onStreamFinished`) are verified; the `Timer`-inside-`Process` shape is a
sketch — if `Process` can't parent a `Timer`, keep the timer in the runner
keyed by token. Verify on first use.

### 2.4 Hypr (`app/Hypr.qml`)

```qml
import Quickshell.Hyprland
QtObject {
  function addresses() { return Hyprland.toplevels.values.map(function(t) { return t.address }) }
  // Connections { target: Hyprland; function onRawEvent(e) { ... } }
  //   e.name === "openwindow"  → e.data = "ADDR,WORKSPACENAME,CLASS,TITLE"   (ADDR has no 0x)
  //   e.name === "closewindow" → e.data = "ADDR"
  // Verified names: openwindow closewindow movewindow(v2) resizewindow workspace(v2)
  //   changefloatingmode fullscreen focusedmon   (omagotchi RoamWindow.qml:445-460)
  function close(addr) { engine.sh('showoff-hypr "hl.dsp.window.close({ window = \\"address:0x' + addr + '\\" })" closewindow address:0x' + addr) }
}
```
Verified Lua forms you can copy (`bin/omarchy-hyprland-window-pop:24-37`,
`bin/omarchy-hyprland-window-close-all:8`, `default/hypr/bindings/*.lua`):

| Action | Lua (first try) | Classic (fallback) |
|---|---|---|
| close window | `hl.dsp.window.close({ window = "address:0x…" })` | `closewindow address:0x…` |
| focus workspace N | `hl.dsp.focus({ workspace = "N" })` | `workspace N` |
| previous workspace | `hl.dsp.focus({ workspace = "previous" })` | `workspace previous` |
| focus window | `hl.dsp.focus({ window = "address:0x…" })` | `focuswindow address:0x…` |
| toggle float | `hl.dsp.window.float({ window = "address:0x…", action = "toggle" })` | `togglefloating address:0x…` |
| pin | `hl.dsp.window.pin({ window = "address:0x…" })` | `pin address:0x…` |
| resize | `hl.dsp.window.resize({ window = W, x = 1300, y = 900 })` | `resizeactive exact 1300 900 W` |
| center | `hl.dsp.window.center({ window = W })` | `centerwindow W` |
| exec | `hl.dsp.exec_cmd([[cmd]])` | `exec -- bash -lc "cmd"` |
| toggle split | `hl.dsp.layout("togglesplit")` | `togglesplit` |

`bin/showoff-hypr` (P1) is:

```bash
#!/bin/bash
# showoff-hypr <lua-dispatch> [classic dispatch args...]
# Hyprland ≥0.56 takes Lua; older takes the classic form. Try Lua, fall back.
hyprctl dispatch "$1" >/dev/null 2>&1 || hyprctl dispatch "${@:2}" >/dev/null
```

### 2.5 Snapshot (`app/Snapshot.qml`)

Record before the first act; restore on every exit.

| Thing | Read | Restore |
|---|---|---|
| theme slug | `cat ~/.local/state/omarchy/current/theme.name` | `omarchy-theme-set "<display>"` (display = slug with `-`→space and words capitalised; `omarchy-theme-set` accepts either — verify with `omarchy-theme-set phosphor`) |
| background | `readlink ~/.local/state/omarchy/current/background` | `omarchy-theme-bg-set <path>` |
| workspace | `hyprctl activeworkspace -j \| jq .id` | `showoff-hypr 'hl.dsp.focus({ workspace = "N" })' workspace N` |
| our windows | `Hypr.addresses()` diff | close everything we opened unless `keep` |
| nightlight, gaps, DND | we only ever toggle **twice** inside one act (net zero); track a bool and re-toggle in restore if an act died between toggles | same toggle command |
| idle | `IdleInhibitor` on our window — nothing to restore | — |

### 2.6 Keyboard handling (`app/shell.qml`)

- One `Item { focus: true; Keys.priority: Keys.BeforeItem }` per window. All
  keys go to `engine.keyPressed(event.key, event.text)`; Esc goes to
  `engine.escape()`. Accept every event (nothing leaks).
- `WlrLayershell.keyboardFocus: engine.handoff ? WlrKeyboardFocus.None : WlrKeyboardFocus.Exclusive`
- Inhibitors (verified types, `Quickshell.Wayland`):
  ```qml
  IdleInhibitor    { enabled: engine.state !== "idle"; window: win }
  ShortcutInhibitor{ enabled: engine.state !== "idle" && !engine.handoff; window: win }
  ```
  `ShortcutInhibitor` has `active` (read-only) and a `cancelled` signal — log both. **Verify** on first run: with it active, SUPER+RETURN during the show must *not* open a terminal.

### 2.7 Theme helpers (used by ThemePicker, Roulette, Snapshot)

```bash
omarchy-theme-list                    # display names, one per line ("Tokyo Night")
omarchy-theme-current                 # display name of the current theme
cat ~/.local/state/omarchy/current/theme.name   # slug ("tokyo-night")
omarchy-theme-set "Tokyo Night"       # apply (display name; slug also works — verify)
omarchy-theme-dir tokyo-night         # directory (user copy preferred)
# preview image, in this order (same rule as omarchy-theme-switcher):
#   $dir/preview.{png,jpg,jpeg,webp,gif,bmp}  else first of $dir/backgrounds/* sorted
# display→slug: tr 'A-Z ' 'a-z-'   slug→display: sed -E 's/(^|-)([a-z])/\1\u\2/g; s/-/ /g'
```
`omarchy-theme-set` holds a lock and fans out to many setters in parallel.
**Measure it** (`time omarchy-theme-set "<current>"`) before writing Roulette;
if it is >600 ms, Roulette samples every k-th theme to fit 8–10 s.

### 2.8 Theme colours (already working in `app/shell.qml`)

`FileView { path: ~/.local/state/omarchy/current/theme/colors.toml; watchChanges: true }`
+ regex per line. Keys used: `accent`, `foreground`, `background`,
`dark_background`, `muted`, `red`. Keep it; extend the parsed set.

### 2.9 Config (`~/.config/showoff-omarchy/config.json`, optional)

```json
{ "flags": ["dev"], "skip": ["local-ai"], "voice": false, "booth": { "everyMinutes": 10 } }
```
Missing file = defaults. Read once at start with `FileView`.

## 3. Phases

Each phase: **Goal · Files · Steps · Done when · Tier**. Commit after each.

### P1 — Engine core  · Tier: **Opus**  · ✅ DONE 2026-09-26 (verified on vic)

Goal: the show runs *as a state machine over data*, with two trivial acts,
snapshot/restore, Keycap layer, glow captions, inhibitors, Esc×2 everywhere.

Files: `app/Engine.qml`, `app/Runner.qml`, `app/Hypr.qml`, `app/Snapshot.qml`,
`app/acts.js`, `app/ui/Caption.qml`, `app/ui/Keycap.qml`, `app/ui/Countdown.qml`,
`bin/showoff-hypr`, refactor `app/shell.qml`.

Steps:
1. Move the countdown/Esc logic out of `shell.qml` into `Engine.qml` (a
   `QtObject` with the properties in §2.2). `shell.qml` becomes windows +
   bindings only.
2. `acts.js` with two acts: `takeover` (caption only, `until: {ms: 2500}`)
   and `hello-terminal` (`keycap: "SUPER + RETURN"`, `run: "omarchy-launch-terminal"`,
   `until: {window: true}`, `hold: 3000`, `cleanup: "close-ours"`).
3. `Runner.qml` per §2.3, `Hypr.qml` per §2.4 (read `omarchy-hyprland-window-close-all` for the close dispatch), `bin/showoff-hypr` per §2.4.
4. `Snapshot.qml` per §2.5. Restore runs as ONE `bash -lc` string so it
   completes even if QML is mid-teardown; `Qt.quit()` on its `exited` or on a 5 s watchdog.
5. `Caption.qml`: `Text` + two `MultiEffect` glow layers (`import QtQuick.Effects`;
   verified usage `slcode777.omagotchi/PetSprite.qml:70-75` uses `colorization`;
   for glow use `blurEnabled: true; blur: 1.0; blurMax: 64; colorization: 1;
   colorizationColor: accent; opacity: 0.85` under the text, plus a tighter
   second layer). **Fit-to-width:** `font.pixelSize` = min(height/8, width/(0.62 × text.length)) — the stub's fixed `height/8` nearly overflowed 1920 px.
6. `Keycap.qml`: split on `" + "`, one rounded rect per token, accent border,
   `dark_background` fill, glow; shown 900 ms before `run`, fades over 300 ms.
7. Inhibitors per §2.6.
8. Wire modes: `SHOWOFF_MODE=countdown|auto|menu|act`, `SHOWOFF_ACT`.

Done when (on vic with Fred's go, or `demo@ovm`):
- `showoff auto` → takeover caption → keycap `SUPER + RETURN` → a terminal
  opens *under* the overlay → 3 s → it closes → "ended" caption → (menu is P3;
  for now "ended" then Esc×2).
- Screenshot of the keycap frame and of the terminal-under-scrim frame, looked at.
- Esc×2 during `hold` closes the terminal AND quits (restore ran: check
  `theme.name` unchanged, terminal gone).
- Missing binary test: temporarily set `run: "definitely-not-a-command"` with
  `requires: ["definitely-not-a-command"]` → act shows "skipped" and the show continues.
- `ShortcutInhibitor.active` logged true; SUPER+RETURN pressed by Fred during
  the show does nothing.
- Log has no QML errors/warnings besides the known portal WARN.

### P2 — The spine  · ✅ built 2026-09-26 with the full auto show (P4–P8 acts too); P3 menu + P9/P10 remain

####  · Tier: **Opus** (ThemePicker + install act), Sonnet for `browser`

Goal: Fred's script end-to-end: omarchy.org → *you* pick the theme → btop.

Files: `app/acts.js` (rows `browser`, `theme-pick`, `install-btop`),
`app/ui/ThemePicker.qml`.

Steps:
1. `browser` row per Appendix A. Note `omarchy-launch-browser` already
   focuses the window; `until: {window: true, timeoutMs: 8000}`.
2. `ThemePicker.qml` (`interactive: "ThemePicker"`): on enter, `Runner`
   fetches `omarchy-theme-list` → array; current index from
   `omarchy-theme-current`. Renders a horizontal carousel: centre card =
   preview image (§2.7 rule via `omarchy-theme-dir`) + name, neighbours
   dimmed. Left/Right move the index and, after a **400 ms debounce**, run
   `omarchy-theme-set "<name>"`. Enter = accept (`engine.chosenTheme = name`,
   next act). Esc×2 still quits (Snapshot restores the original theme).
   Caption: "NOW **YOU** PICK THE THEME" / sub: "← → to look around · Enter to keep it".
3. `install-btop` row: `run` is a bash string that branches on
   `omarchy-cmd-present btop` (Appendix A). `keep: true`. The presentation
   terminal is *floating*; leave it exactly where Omarchy puts it.
4. `Snapshot.restore()` skips the theme when `engine.keepTheme` is true
   (EndCard sets it in P8; until then, the picker's Enter sets it).

Done when:
- A full `showoff auto` run: browser appears on omarchy.org under the glow →
  picker → arrows visibly recolour bar/terminal live → Enter → presentation
  terminal with the logo, btop running, still running after the show ends.
- With btop uninstalled on `demo@ovm` (`sudo pacman -R btop`): the same run
  shows `omarchy-pkg-add btop` in the presentation terminal (password prompt
  visible), then btop.
- Esc×2 mid-picker restores the original theme (check `theme.name`).
- `time omarchy-theme-set …` measured and written into `RESEARCH.md` §2.7 note.

### P3 — Menu  · Tier: Sonnet

Files: `app/ui/Menu.qml`, `acts.js` (`MENU_GROUPS`), `Engine` (`menu` state).

Steps: grid of cards by group; arrows move, Enter runs, mouse click runs;
first card "Run the whole show"; last "Quit (Esc Esc)". Each act returns to
the menu. Countdown → any key → menu (already in the stub). After `auto`
ends → menu. Show a small progress strip (act i / n) during `running`.

Done when: screenshot of the menu; keyboard and mouse both pick an act; the
act runs and the menu returns; `showoff act browser` runs one act then menu.

### P4 — Look acts  · Tier: Sonnet

Rows: `tiling`, `workspaces`, `gaps`, `screensaver` (Appendix A).
`workspaces` needs `Snapshot.workspace` to return afterwards. `screensaver`
closes only windows with class `org.omarchy.screensaver` that appeared after
its `run`.

Done when: each act runs from the menu with screenshots; `close-ours` leaves
no window behind (`hyprctl clients -j | jq length` before == after).

### P5 — Theme acts  · Tier: Sonnet

Rows: `roulette`, `wallpapers`, `wallpaper-pick`, `nightshift`.
`roulette`: sequential `omarchy-theme-set` per theme (next starts when the
previous exits), sampled to fit 10 s using the measured duration, ends on
`engine.chosenTheme` (or the snapshot theme if none). `wallpaper-pick`:
same carousel as ThemePicker over the file list from Appendix A, applying
`omarchy-theme-bg-set <path>` on arrows.

Done when: roulette finishes within 12 s on vic and lands on the chosen theme;
wallpaper restore verified after Esc×2.

### P6 — Under-the-hood acts  · Tier: Sonnet

Rows: `aquarium`, `fastfetch`, `webapp`, `emoji-clipboard`, `menu-tour`,
`neovim` (`flag: "dev"`), `local-ai`.
`emoji-clipboard` and `menu-tour` are **handoff** acts (the shell's overlays
need the keyboard): `handoff: true`, fixed `until: {ms}`, then
`omarchy-shell shell hide <id>` in cleanup. Read
`$OMARCHY_PATH/shell/plugins/menu/MenuModel.js` for real route ids before
writing `menu-tour`.

Done when: each act from the menu, screenshot each; after a handoff act the
overlay has the keyboard again (Esc×2 works immediately after).

### P7 — Hands-on act  · Tier: **Opus** (keyboard hand-over + detection)

Row: `you-launch`. `handoff: true`. Caption tells them the *real* default
browser's name (`omarchy-default-browser` → e.g. "brave"): "Press SUPER +
SPACE, type **brave**, press Enter". `until: {window: true, timeoutMs: 45000}`.
On the window: caption "YOU JUST LAUNCHED AN APP" for 3 s, `close-ours`, take
the keyboard back. On timeout: "no worries — next act".

Done when: Fred does it live; the cheer fires; the window closes; Esc×2 works after.

### P8 — Send-off + polish  · Tier: Sonnet

Files: `app/ui/EndCard.qml`, `app/assets/qr-*.svg` (generate once:
`qrencode -t SVG -o app/assets/qr-omarchy.svg https://omarchy.org` — commit
the SVG; no runtime dependency), rows `qr`.
EndCard: two QRs, "Keep the theme you picked? Y / N" (sets
`engine.keepTheme`), the recording path if P9 recorded, "Esc Esc to leave".
Polish: glow tuning, caption transitions (fade/slide 250 ms), progress strip,
the mirrored caption on secondary screens.

Done when: end card screenshot; `N` restores the theme, `Y` keeps it
(check `theme.name` both ways).

### P9 — Infrastructure  · Tier: Sonnet

- **Camera Roll:** at show start (if `config.record !== false`)
  `omarchy-capture-screenrecording --fullscreen`; at end `--stop-recording`;
  newest file in `${XDG_VIDEOS_DIR:-~/Videos}` shown on the EndCard.
  **Verify first** that `--fullscreen` skips the slurp picker and that no
  portal dialog appears (the script says the portal path is off by default).
- **Booth mode:** `showoff booth` → runs auto; on end, waits; when
  `Quickshell.Wayland` `IdleMonitor` (module `_IdleNotify`, **verify the type
  and property names** in `/usr/lib/qt6/qml/Quickshell/Wayland/_IdleNotify/*.qmltypes`)
  reports idle ≥ `config.booth.everyMinutes`, run again. Esc×2 exits the loop.
- **Voice:** `config.voice === true` only. `piper` if present; text = caption
  + sub; never blocks the act. Default off.

Done when: a recording exists after a run and its path is on the EndCard;
booth loops twice on `demo@ovm`; voice stays silent by default.

### P10 — Install + release  · Tier: Sonnet

- `install.sh`: copies `app/` and `bin/` to `~/.local/share/showoff-omarchy`,
  symlinks `~/.local/bin/showoff` and `showoff-hypr`, writes the desktop entry
  with an absolute `Exec`, `update-desktop-database ~/.local/share/applications`.
  Idempotent; `--uninstall` reverses it. `shellcheck` clean.
- `PKGBUILD`: `pkgname=showoff-omarchy`, `depends=(quickshell omarchy)`,
  `optdepends=(btop cava cmatrix asciiquarium fastfetch ttfx)`, installs to
  `/usr/share/showoff-omarchy`, `/usr/bin/showoff`, `/usr/bin/showoff-hypr`,
  `/usr/share/applications/showoff-omarchy.desktop`. `namcap` clean.
- README: install both ways, a pixel-checked screenshot of the countdown, the
  theme picker and the end card **taken on `demo@ovm`** (vic screenshots show
  Fred's sessions — never commit those), the act list, "Esc twice".
- Tag `v1.0.0`, annotated, with the LR- schema.

Done when: `curl … | bash` install on `demo@ovm` puts *Showoff Omarchy* in
SUPER+SPACE and it runs; `makepkg -si` does the same.

## Appendix A — the act table (data for `app/acts.js`)

Commands are exact and were checked against `$OMARCHY_PATH/bin` on
2026-09-21 unless marked *verify*. `W` = the window this act opened.

| id | group | keycap | requires / pkg | run | until | hold | cleanup |
|---|---|---|---|---|---|---|---|
| `takeover` | look | — | — | — (caption "SHOWOFF OMARCHY" / "watch this") | ms 2500 | 0 | none |
| `browser` | look | `SUPER + RETURN`* | `omarchy-launch-browser` | `omarchy-launch-browser https://omarchy.org` | window, 8000 | 6000 | close-ours |
| `tiling` | look | `SUPER + RETURN` ×4 | `omarchy-launch-terminal` | function: 4× `omarchy-launch-terminal`, 900 ms apart, caption counts "ONE… TWO… THREE… FOUR"; then `omarchy-hyprland-window-pop` (caption "POP"), 2000 ms, `omarchy-hyprland-window-pop` again | function-driven | 1500 | close-ours |
| `workspaces` | look | `SUPER + 2` … | `showoff-hypr` | function: for N in 2 3 4: `showoff-hypr 'hl.dsp.focus({ workspace = "N" })' workspace N` → `omarchy-launch-terminal`; then cycle 1→2→3→4→1 with 1200 ms holds, caption = the number | function | 0 | close-ours + `Snapshot.workspace` |
| `theme-pick` | drive | `← →` | `omarchy-theme-set` | interactive `ThemePicker` | key Return | 0 | none (sets `chosenTheme`) |
| `roulette` | drive | — | `omarchy-theme-set` | function: sequential `omarchy-theme-set "<name>"` over sampled list, end on `chosenTheme` | function | 1500 | none |
| `wallpapers` | drive | `SUPER + CTRL + SPACE`* | `omarchy-theme-bg-next` | function: 5× `omarchy-theme-bg-next` 1500 ms apart | function | 0 | `omarchy-theme-bg-set <snapshot>` unless `wallpaper-pick` follows |
| `wallpaper-pick` | drive | `← →` | `omarchy-theme-bg-set` | interactive `WallpaperPicker`; list = `find -L ~/.config/omarchy/backgrounds/$(cat ~/.local/state/omarchy/current/theme.name)/ ~/.local/state/omarchy/current/theme/backgrounds/ -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.mp4' -o -iname '*.webm' \) 2>/dev/null \| sort` | key Return | 0 | none |
| `install-btop` | hood | `SUPER + ALT + SPACE`* | `omarchy-launch-floating-terminal-with-presentation` | `if omarchy-cmd-present btop; then omarchy-launch-floating-terminal-with-presentation btop; else omarchy-launch-floating-terminal-with-presentation "omarchy-pkg-add btop && btop"; fi` | window, 15000 (60000 if installing) | 5000 | **keep: true** |
| `aquarium` | hood | `SUPER + RETURN` | pkg `cava cmatrix asciiquarium` (each optional: skip the missing pane) | function: `omarchy-launch-terminal cava`, `omarchy-launch-terminal cmatrix`, `omarchy-launch-terminal asciiquarium`, 700 ms apart (btop already up) | function | 6000 | close-ours |
| `fastfetch` | hood | — | `fastfetch` | `omarchy-launch-floating-terminal-with-presentation fastfetch` | window, 8000 | 6000 | close-ours |
| `webapp` | hood | — | `omarchy-launch-webapp` | `omarchy-launch-webapp https://www.youtube.com` | window, 10000 | 5000 | close-ours |
| `emoji-clipboard` | hood | `SUPER + CTRL + E`* | `omarchy-menu-emoji`, `omarchy-menu-clipboard` | function, **handoff**: `omarchy-menu-emoji` → 3000 ms → `omarchy-shell shell hide omarchy.emojis` → `omarchy-menu-clipboard` → 3000 ms → `omarchy-shell shell hide omarchy.clipboard` | function | 0 | none |
| `menu-tour` | hood | `SUPER + ALT + SPACE` | `omarchy-menu` | function, **handoff**: `omarchy-menu toggle root` → 2500 ms → routes from `MenuModel.js` (*verify*) → `omarchy-shell shell hide omarchy.menu` | function | 0 | none |
| `nightshift` | hood | — | `omarchy-toggle-nightlight` | function: toggle → 2500 ms (caption "WARM") → toggle (caption "COOL") | function | 0 | re-toggle if died mid-way |
| `gaps` | hood | — | `omarchy-hyprland-window-gaps-toggle`, `omarchy-hyprland-window-tiled-fullscreen-toggle` | function on a window we open: gaps toggle ×2 (1500 ms apart), fullscreen toggle ×2 | function | 0 | close-ours |
| `you-launch` | hands | `SUPER + SPACE` | `omarchy-default-browser` (for the name) | **handoff**; caption from `omarchy-default-browser` output | window, 45000 | 3000 | close-ours |
| `neovim` | hands | `SUPER + RETURN` | `nvim`; `flag: "dev"` | `omarchy-launch-terminal nvim /etc/os-release` | window, 8000 | 4000 | close-ours |
| `local-ai` | hands | — | `ollama`; precheck `curl -sf localhost:11434/api/tags >/dev/null` | `m=$(curl -sf localhost:11434/api/tags \| jq -r '.models[0].name'); omarchy-launch-floating-terminal-with-presentation "ollama run $m 'Explain Omarchy in two sentences.'"` | window, 10000 | 15000 | close-ours |
| `screensaver` | sendoff | — | `ttfx`; `omarchy-launch-screensaver` | `omarchy-launch-screensaver force` | ms 1500 | 6000 | close windows with class `org.omarchy.screensaver` opened after `run` |
| `qr` | sendoff | — | — | `EndCard` component | key (Y/N/Esc) | 0 | none |

Keycaps — **use the stock binding for the thing the visitor would press**, read
from `$OMARCHY_PATH/default/hypr/bindings/*.lua` on 2026-09-21 (dev checkout;
re-confirm on packaged 4.0.x before v1 — a wrong keycap teaches the visitor a lie):

| Binding | Does |
|---|---|
| `SUPER + SPACE` | Omarchy menu (root: Install, Style, …) → use for `install-btop` |
| `SUPER + ALT + SPACE` | Apps menu → use for `browser`, `webapp`, `you-launch` ("…then type its name") |
| `SUPER + O` | Pop window out (float & pin) → `tiling` |
| `SUPER + CTRL + SPACE` | Background switcher → `wallpapers`, `wallpaper-pick` |
| `SUPER + SHIFT + CTRL + SPACE` | Theme menu → `theme-pick`, `roulette` |
| `SUPER + SHIFT + BACKSPACE` | Toggle window gaps → `gaps` |
| `SUPER + K` | Keybindings sheet |
| `SUPER + RETURN` (terminal), emoji/clipboard chords | **not seen in that grep** — find them before using; otherwise show no keycap |

Rows above marked * must be replaced with the values from this table.

Menu groups: `look` "Look" · `drive` "Hand them the keyboard" · `theme`
"Theming" · `hood` "Under the hood" · `hands` "Hands-on" · `sendoff` "Send-off".

`AUTO_ORDER`: takeover, browser, tiling, workspaces, theme-pick, roulette,
wallpapers, wallpaper-pick, install-btop, aquarium, fastfetch, webapp,
emoji-clipboard, menu-tour, nightshift, gaps, you-launch, neovim, local-ai,
screensaver, qr.

## Appendix B — pitfalls (read before each phase)

1. `qs.Commons` does not exist outside the shell. Colours come from `colors.toml`.
2. A missing binary makes `Process` never emit `exited` → `requires` first, watchdog always.
3. Exclusive keyboard focus means **no** app under us gets keys. Every act that needs the visitor to type in an app is a `handoff` act with a hard timeout.
4. The shell's own overlays (emoji, clipboard, menu, theme switcher) also take exclusive focus → handoff, then `omarchy-shell shell hide <id>` to get it back. Ids: `omarchy.emojis`, `omarchy.clipboard`, `omarchy.menu`.
5. `hyprctl dispatch` is Lua on ≥0.56 and classic before — always `showoff-hypr` with both forms. Never assume one.
6. `omarchy-theme-set` is slow-ish and locked; debounce arrows, measure before Roulette.
7. Window addresses from `openwindow` events have no `0x`; dispatches need `address:0x…`.
8. `omarchy-launch-floating-terminal-with-presentation` ends with "Done! Press any key" that nobody can press while we hold the keyboard — close the window in cleanup, don't wait for exit.
9. `omarchy-launch-screensaver` refuses unless the terminal is Alacritty/Foot/Ghostty/Kitty and `ttfx` exists → precondition, skip.
10. `wtype` in tests goes to whatever is focused. Guard every key (§C.3).
11. Two Quickshell processes share one instance registry — if `quickshell` refuses to start, check `/run/user/1000/quickshell/` (known to corrupt when tmpfs is full).
12. Screenshots on vic contain Fred's other sessions. Never commit them; take README shots on `demo@ovm`.
13. Multi-monitor is untested. `Variants` makes a window per screen; only the primary renders the interactive UI — test with a second output before v1.
14. Fractional scaling: layer-surface coordinates assume scale 1 (omagotchi's note). Test on the iPad output on ovm (`BEAM-IPAD 2048x1536 scale=2`).
15. Fit captions to width; the stub's `height/8` nearly overflowed 1920 px.

16. **QML method names:** never `onSomething` for a plain method (reserved for signal handlers → "Illegal method name"), and never a JS global like `escape` (same error). Engine uses `handleFinished`, `handleWindowOpened`, `escapePressed`. (P1)
17. A `Repeater` model must never go negative (`Math.max(0, …)`) — "Model size of -1" warning. (P1)
18. Reserve the keycap row's height even when empty, or the caption jumps ~70 px when it hides. (P1)
19. Captions/skip lines over a busy page (X feed, browser) lose contrast — give sub-captions a backing plate in P8.
20. `ShortcutInhibitor` **does** go active on a layer surface on vic (logged `active=true`) — SUPER chords are held during the show. Re-check on packaged 4.0.x.

21. **Detach every launch** (`setsid -f bash -lc …`). `uwsm-app` stays attached to the app it starts, so a launcher inside a Runner job is killed by the job watchdog and takes the app with it — btop died exactly 15 s after launch. (full show)
22. **Pacing is a model, not a number per act:** `readMs(caption, sub)` = 1200 + 300/word (caption) + 230/word (sub), clamped 1.8–7 s; `keycapMs` = 2000 + 350/key, and the keycap stays on screen while its action runs. Fred: "think about how long each text phrase should be on the screen." (full show)
23. `omarchy-theme-set` replaces the theme dir, so a watched `colors.toml` vanishes mid-switch — retry the read, and re-read on a timer. (full show)
24. Bind lookups: on Hyprland 0.56 `hyprctl binds -j` `.arg` is a Lua index; match on `.description` instead ("Terminal", "Apps menu", "Emojis"…). modmask: 64 SUPER, 1 SHIFT, 4 CTRL, 8 ALT. (full show)

## Appendix C — verification recipes

### C.1 Start / stop for tests
```bash
# A shell started outside the session (ssh, herdr pane, resumed Claude) may lack this; derive it:
export HYPRLAND_INSTANCE_SIGNATURE=${HYPRLAND_INSTANCE_SIGNATURE:-$(ls -t /run/user/$(id -u)/hypr | head -1)}
S=$XDG_RUNTIME_DIR/showoff-test; mkdir -p "$S"
setsid -f bash -c "exec bin/showoff auto > $S/log 2>&1"
pgrep -x quickshell -a | grep showoff            # running?
hyprctl layers -j | jq -r '.. | objects | select(.namespace? == "showoff-omarchy") | "\(.w)x\(.h)"'
quickshell kill -p "$PWD/app"                    # emergency stop (restore will NOT run — use Esc Esc)
```

### C.2 Evidence
```bash
grim "$S/frame.png"        # then LOOK at it (Read tool). A file existing is not evidence.
tail -20 "$S/log"          # no QML errors; the portal WARN is known
hyprctl clients -j | jq length   # before/after a close-ours act must match
cat ~/.local/state/omarchy/current/theme.name    # restore check
```

### C.3 Guarded key injection (the only allowed way)
```bash
up() { hyprctl layers -j | jq -e '.. | objects | select(.namespace? == "showoff-omarchy")' >/dev/null 2>&1; }
key() { up && wtype -k "$1" || { echo "layer not up — key '$1' NOT sent"; return 1; }; }
key space      # → menu
key Escape; key Escape   # → quit
```
Wait ~200 ms between keys (`read -t 0.2 <> <(:)` — plain `sleep` is blocked in Claude Code's Bash).

### C.4 Missing-binary drill
Set `requires: ["nope-not-here"]` on one act; the show must print
"skipped: nope-not-here not installed" and continue.

### C.5 Restore drill
Before: `omarchy-theme-current`, `readlink ~/.local/state/omarchy/current/background`.
Run to the picker, arrow twice, Esc×2. After: both values identical.
