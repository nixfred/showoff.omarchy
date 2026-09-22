# Showoff Omarchy — feature research

> Everything here was verified on vic (Omarchy dev checkout at
> `$OMARCHY_PATH`, Hyprland 0.56.2, Quickshell 0.3.1) and, where noted, on
> ovm (packaged Omarchy 4.0.4-1, Quickshell 0.3.1) on **2026-09-21**, by
> reading the shell source and the `omarchy-*` commands. Anchors are given so
> the next session can re-check instead of re-discovering. Nothing below has
> been *run* as part of the show yet — see "Open questions".

## 0. Portability rules (Fred: "must work on anyone's omarchy and not depend on other plugins")

- Stock surface only: `$OMARCHY_PATH/bin/omarchy-*`, Quickshell, Qt, and the
  stock state files under `~/.local/state/omarchy/current/`.
- **Not** `qs.Commons` — that module is importable only from inside the
  shell's own config; a standalone process reads `colors.toml` instead (§9).
- Plugins named in this document (emoji, clipboard, face-id, omagotchi) are
  **technique anchors only** — places to read how something is done. None is
  a dependency.
- vic is not stock: dev checkout `4.0.0.alpha`, 80+ plugins, patched shell
  (Infomarchy owns the `background` IPC target — never talk to it). ovm is
  packaged **4.0.4-1** but its `pi` user's plugin dir was seeded from vic (73
  entries). Portability claims need a **fresh user on ovm** (Fred's choice).
- Minimum version: Omarchy 4.0 (the release that made the shell a Quickshell
  process).

## 1. The takeover primitive

The Omarchy desktop is one long-lived Quickshell process (`omarchy-shell`).
The fullscreen overlays — emoji picker, clipboard, the menu, the lock screen —
are layer-shell windows inside it (`$OMARCHY_PATH/manual/32-shell-plugins.md:3`).
Showoff uses the **same primitive from its own process**:

| Need | How the stock overlays do it | Anchor |
|---|---|---|
| Cover the whole screen, above every window | `PanelWindow` anchored on all four sides, `WlrLayershell.layer: WlrLayer.Overlay`, `exclusionMode: ExclusionMode.Ignore` | `shell/plugins/emojis/Emojis.qml:160-168` |
| Grab the keyboard (nothing else gets keys) | `WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive` | same; also `menu/Menu.qml:1024`, `clipboard/Clipboard.qml:321`, `lock/Service.qml:336` |
| Catch Esc | an `Item { focus: true; Keys.priority: Keys.BeforeItem; Keys.onPressed }` inside the window | `emojis/Emojis.qml:195-202` |
| Cover **every** monitor | `Variants { model: Quickshell.screens; PanelWindow { screen: modelData … } }` | `~/.config/omarchy/plugins/fitzzz.face-id/Service.qml:697-708` |

**Consequence of exclusive keyboard focus:** while the overlay is up, the
apps under it get *no* keystrokes. For every act where the visitor should
drive, either (a) the overlay handles the keys itself and translates them
into commands, or (b) it drops to `WlrKeyboardFocus.None` for that act and
takes it back afterwards. **(a)** for the theme picker — the overlay *is* the
picker. (b) for "You launch an app".

**Layer ordering:** the browser, btop, etc. open as normal windows *below*
the overlay layer, so glowing captions float over the live apps. That is the
intended look and the reason this is layer-shell, not a fullscreen window.
The scrim must stay light enough to see through.

## 2. Install reality: no hooks, no sudo

`omarchy plugin add` "never executes an install hook, and never asks for
sudo" (`manual/32-shell-plugins.md:44`), and an application install shouldn't
either. So optional packages are handled in two stock ways:

- **On screen (One-Line Install act):** `omarchy-install-and-launch <name>
  <packages> <desktop-id>` or directly
  `omarchy-launch-floating-terminal-with-presentation "omarchy-pkg-add btop"`
  — a floating terminal that prints the logo, runs pacman (the user types
  their password on screen), then "Done! Press any key". *No app store, no
  wizard, no reboot.* (`bin/omarchy-install-and-launch`,
  `bin/omarchy-launch-floating-terminal-with-presentation`, `bin/omarchy-show-logo`, `bin/omarchy-show-done`)
- **`showoff prepare` (booth mode):** installs every optional package once
  (btop cava cmatrix fastfetch qrencode ttfx …) so the show never stops for a
  password at the booth.

Preconditions are cheap: `omarchy-cmd-present <cmd…>` and
`omarchy-pkg-present <pkg…>` return 0/1. **Every act declares its
precondition and is skipped, not failed, when it isn't met.**

## 3. Commands each act drives (all in `$OMARCHY_PATH/bin`)

| Act | Command | Notes |
|---|---|---|
| Open omarchy.org | `omarchy-launch-browser https://omarchy.org` | resolves the xdg default browser, runs it under `systemd-run --user`, then focuses it |
| Theme list / current / set | `omarchy-theme-list`, `omarchy-theme-current`, `omarchy-theme-set "<Name>"` | 43 themes on vic; `theme-set` takes display names ("Tokyo Night"), holds a lock file, fans out to every app setter in parallel — measure duration before Theme Roulette |
| Theme picker (stock) | `omarchy-theme-switcher` | walker-based with previews — alternative to our own carousel |
| Wallpaper next | `omarchy-theme-bg-next` | includes video wallpapers |
| btop / any TUI, framed | `omarchy-launch-floating-terminal-with-presentation btop` | floating terminal, logo first, `Done!` after |
| Plain TUI | `omarchy-launch-tui`, `omarchy-launch-or-focus-tui` | |
| Web app as a window | `omarchy-launch-webapp <url>` | chrome-less app window |
| Screensaver | `omarchy-launch-screensaver force` | needs `ttfx` **and** Alacritty/Foot/Ghostty/Kitty; else notifies and exits 1 → precondition |
| Keep screen on | prefer Quickshell `IdleInhibitor` (§9); fallback `omarchy-toggle-idle stay-awake` / `allow-idle` | never leave the user's toggle flipped |
| Silence notifications | `omarchy-toggle-notification-silencing` (DND) | restore afterwards |
| Record the show | `omarchy-capture-screenrecording` | may raise a portal prompt — verify |
| Menu tour | `omarchy-shell shell summon omarchy.menu '{"menu":"root"}'`; `omarchy menu summon <route>` | routes are JSON payloads (`bin/omarchy-menu:5-8`); IPC contract `shell/README.md:172-216` |
| Emoji / clipboard cameos | `omarchy-menu-emoji`, `omarchy-menu-clipboard` | both are exclusive-keyboard overlays in the *shell* process — they will fight ours; drop our focus, summon theirs, wait, take it back |
| Night light | `omarchy-toggle-nightlight` | |
| Float / pin a window | `omarchy-hyprland-window-pop`, `omarchy-hyprland-window-gaps-toggle`, `omarchy-hyprland-window-tiled-fullscreen-toggle` | |
| Keybinding sheet | `omarchy-menu-keybindings` | |
| Launch or focus an app | `omarchy-launch-or-focus <pattern> [cmd]` | `hyprctl clients -j` + jq, Lua focus with classic fallback |

## 4. Driving Hyprland

Hyprland 0.56 takes **Lua dispatches**; Omarchy's own scripts use the Lua
form and fall back to the classic one so they run on both (from
`bin/omarchy-launch-screensaver`, `bin/omarchy-launch-or-focus`):

```bash
hyprctl dispatch "hl.dsp.exec_cmd([[$command]])" >/dev/null 2>&1 || hyprctl dispatch exec -- bash -lc "$command"
hyprctl dispatch "hl.dsp.focus({ monitor = \"$m\" })" || hyprctl dispatch focusmonitor "$m"
hyprctl dispatch "hl.dsp.focus({ window = \"address:$a\" })" || hyprctl dispatch focuswindow "address:$a"
```

Other Lua forms seen in `bin/`: `hl.dsp.focus({ workspace = "1" })`,
`hl.dsp.dpms({ action = "enable" })`, `hl.dsp.send_key_state({ mods = …})`.
Use the same dual pattern everywhere.

**Waiting for a window to appear** (browser opened, btop mapped): inside
QML, `Quickshell.Hyprland` exposes the event stream and window list (the
omagotchi plugin reads window geometry from it:
`~/.config/omarchy/plugins/slcode777.omagotchi/RoamWindow.qml:15-17`). The
shell equivalent is the `.socket2.sock` event stream via `socat`, exactly as
`omarchy-launch-screensaver` waits for `openwindow>>…,org.omarchy.screensaver,…`.

## 5. Look and feel

- Colours: read from `~/.local/state/omarchy/current/theme/colors.toml` (§9),
  watched, so captions recolour with whatever theme the visitor picks.
- UI font: **JetBrainsMono Nerd Font**. The wordmark is
  `/usr/share/omarchy/logo.svg` (never typeset "OMARCHY" from a font — the
  letters in `omarchy.ttf` are empty stubs; `U+E900` is the logo *mark*).
  `/usr/share/omarchy/logo.txt` is the ASCII version. Source:
  `~/.claude/MEMORY/AUTO/omarchy-brand-assets-and-fonts.md`.
- Glow: `QtQuick.Effects` `MultiEffect` (blur + shadow) is available in this
  Qt (omagotchi imports it). The scaffold uses `Text.Outline` as a placeholder;
  the real glow is a layered MultiEffect — not built yet.
- Sound: the Tetris and Omagotchi plugins ship sounds and play them from QML;
  copy their approach if we add whooshes.

## 6. Safety rules the engine must enforce

1. **Snapshot, then restore.** Record `omarchy-theme-current` and the current
   background link (`~/.local/state/omarchy/current/background`) before act 1.
   At the end ask *Keep this theme?*; on No or on Esc×2, restore both.
2. **Idle inhibit + DND during the show**, released after (also on Esc×2).
3. **Never sudo silently.** Package installs only ever happen in the visible
   presentation terminal, or via the explicit `showoff prepare`.
4. **No destructive commands, ever.** The act list is data; the engine only
   runs commands from the shipped act table.
5. **Skip, don't fail.** Precondition unmet → act skipped, show continues.
6. **Esc×2 always works** because the overlay never releases the keyboard
   except during explicit hand-over acts, and even then the process can be
   ended with `quickshell kill -p <app dir>` or `showoff stop` (to add).
7. Close what we opened (browser window, terminals) unless an act says
   "leave it running" — btop is the one Fred wants left up.

## 7. Engine shape (proposed, not built)

A show is an ordered list of **acts**. Each act is data:

```js
{ id: "browser",
  caption: "THIS IS OMARCHY",  sub: "a Linux desktop that gets out of your way",
  keycap: "SUPER + RETURN",                      // Keycap Karaoke layer
  requires: ["omarchy-launch-browser"],          // omarchy-cmd-present
  run: "omarchy-launch-browser https://omarchy.org",
  until: { window: { class: /brave|firefox|chromium/ }, timeoutMs: 8000 },
  hold: 6000,
  cleanup: "close-window" }
```

Interactive acts add `keys: { Left, Right, Return }` handlers and a `prompt`
caption; hand-over acts add `keyboard: "release"`. The app walks the list
with a small state machine (`countdown → auto|menu → running(act i) →
waiting → next → menu`). Esc×2 from any state → `cleanup-all → restore → quit`.

## 8. Open questions (verify on `demo@ovm` before building)

- Does `app/shell.qml` even load? It has never been run; `qmllint` isn't on vic.
- How long does `omarchy-theme-set` take end-to-end on a typical box, and is
  rapid cycling (Theme Roulette) smooth, or does the lock file serialize it
  into a slideshow?
- Does launching the browser (`systemd-run` + `omarchy-hyprland-focus-app`)
  ever pull keyboard focus away from an *exclusive* layer surface? (Expect no.)
- Summoning a shell overlay (emoji, clipboard, menu) while ours is up — who
  wins the keyboard, and does hiding theirs hand it back to us?
- `omarchy-capture-screenrecording`: does a portal prompt appear, and can we
  pre-authorise it for booth mode?
- Fractional scaling: omagotchi notes layer-surface coordinates assume scale 1.
- Two Quickshell instances (the shell + ours): any instance-registry trouble?
  (vic memory: the registry corrupts when tmpfs is full — unrelated, but watch.)

## 9. Standalone application facts (verified 2026-09-21)

- **Quickshell 0.3.1** on vic and on ovm (packaged 4.0.4). Omarchy starts its
  shell as `systemd-cat -t omarchy-shell -- quickshell -n -p "$OMARCHY_PATH/shell"`
  (`bin/omarchy-launch-shell:19`) and stops it with
  `quickshell kill -p "$CONFIG_DIR" --any-display` (`bin/omarchy-restart-shell:66`).
  A second config path is a second, independent process — that is
  `bin/showoff`: `exec quickshell -n -p "$app_dir"`. `-n` refuses a duplicate.
- **Config root** is `shell.qml` in the config dir; the root element is
  `ShellRoot`. `Quickshell.env()` reads environment (`SHOWOFF_MODE`,
  `SHOWOFF_ACT` from the launcher). `Qt.quit()` ends the process.
- **Theme colours:** `~/.local/state/omarchy/current/theme/colors.toml` is
  flat `key = "#RRGGBB"` lines (`mode`, `accent`, `selection`, `muted`,
  `background`, `dark_background`, `darker_background`, `lighter_background`,
  `foreground`, `dark_foreground`, `light_foreground`, `bright_foreground`,
  `red`, … plus `hyprland_inactive_border = "rgba(…)"`). Read with
  `Quickshell.Io.FileView { watchChanges: true; onLoaded: …text() }` and a
  one-line regex. Also stock: `current/theme.name`, `current/background`.
- **`Quickshell.Wayland` ships** (`/usr/lib/qt6/qml/Quickshell/Wayland/`):
  `WlrLayerShell`, **`ShortcutsInhibitor`** (stop SUPER-chords reaching
  Hyprland during the show), **`IdleInhibitor`** (keep the screen on without
  touching the user's stay-awake toggle), `Screencopy`, `ToplevelManagement`
  (window list without hyprctl), `BackgroundEffect`.
- **Launcher entry:** stock Omarchy `.desktop` files are minimal
  (`$OMARCHY_PATH/applications/Basecamp.desktop`: Name/Exec/Terminal/Type/
  Icon/StartupNotify). `showoff-omarchy.desktop` follows that shape;
  `Icon=omarchy` uses the stock icon (`/usr/share/pixmaps/omarchy.png`).
- **Name is free:** no `showoff` command on vic, nothing in `pacman -Ss
  '^showoff'`, nothing in the AUR search.
- **Install options (undecided):** (a) `install.sh` → files to
  `~/.local/share/showoff-omarchy`, `~/.local/bin/showoff`, desktop entry to
  `~/.local/share/applications` + `update-desktop-database`; (b) AUR
  `PKGBUILD` (`showoff-omarchy`) so `omarchy-pkg-add showoff-omarchy` works
  and updates ride pacman. Both can coexist. Neither is written.
