# Showoff Omarchy — feature research

> Everything here was verified on vic (Omarchy 4.0.3-dev checkout at
> `$OMARCHY_PATH`, Hyprland 0.56.2, Quickshell shell) on **2026-09-21** by
> reading the shell source and the `omarchy-*` commands. Anchors are given so
> the next session can re-check instead of re-discovering. Nothing below has
> been *run* as part of the show yet — see "Open questions".

## 0. Portability rules (Fred, 2026-09-21: "must work on anyone's omarchy and not depend on other plugins")

- Stock surface only: `$OMARCHY_PATH/bin/omarchy-*`, `qs.Commons`
  (`Style`, `Color`, `Util` — imported by 209 third-party QML files on vic,
  so it is part of the third-party contract), Quickshell, Qt.
- Plugins named in this document (face-id, omagotchi, Tetris) are **technique
  anchors only** — places to read how something is done. None is a dependency.
- vic is not stock: dev checkout `4.0.0.alpha`, 80+ plugins, patched shell
  (Infomarchy owns the `background` IPC target — never talk to it).
  `ovm` is packaged **4.0.4-1** but its plugin dir was seeded from vic (73
  entries). Portability claims need a **clean user profile** on ovm or a fresh
  omarchy-lab VM.
- Minimum version: Omarchy 4.0 (first release with the shell plugin system).

## 1. The takeover primitive

The Omarchy desktop is one long-lived Quickshell process (`omarchy-shell`).
Everything on screen is a plugin inside it, including "the fullscreen
overlays like the emoji picker and the clipboard manager, the Omarchy menu
itself, the lock screen" (`$OMARCHY_PATH/manual/32-shell-plugins.md:3`).

So the show is an **`overlay`-kind plugin**. That gives us, for free:

| Need | How the first-party overlays do it | Anchor |
|---|---|---|
| Cover the whole screen, above every window | `PanelWindow` anchored on all four sides, `WlrLayershell.layer: WlrLayer.Overlay`, `exclusionMode: ExclusionMode.Ignore` | `shell/plugins/emojis/Emojis.qml:160-168` |
| Grab the keyboard (nothing else gets keys) | `WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive` | same; also `menu/Menu.qml:1024`, `clipboard/Clipboard.qml:321`, `lock/Service.qml:336` |
| Catch Esc | an `Item { focus: true; Keys.priority: Keys.BeforeItem; Keys.onPressed }` inside the window | `emojis/Emojis.qml:195-202` |
| Cover **every** monitor | `Variants { model: Quickshell.screens; PanelWindow { screen: modelData … } }` | `~/.config/omarchy/plugins/fitzzz.face-id/Service.qml:697-708` |
| Be opened / closed by the shell | plugin root `Item` implements `open(payloadJson)`, `close()`; it ends itself with `shell.hide(manifest.id)` | `emojis/Emojis.qml:45-67` |
| Stay loaded between runs (timers, state) | `"keepLoaded": true` in the manifest | `shell/README.md:79-88`; `clipboard/manifest.json` |

Summon / hide from a shell (this is how a `showoff` launcher, a keybinding,
or a bar button starts it):

```bash
omarchy-shell shell summon nixfred.showoff '{}'
omarchy-shell shell hide   nixfred.showoff
omarchy-shell shell toggle nixfred.showoff '{}'
```

IPC contract: `shell/README.md:172-216`.

**Consequence of exclusive keyboard focus:** while the overlay is up, the
apps under it get *no* keystrokes. For every act where the visitor should
drive, either (a) the overlay handles the keys itself and translates them
into commands, or (b) it drops to `WlrKeyboardFocus.None` for that act and
takes it back afterwards. Recommendation: **(a)** for the theme picker — the
overlay *is* the picker (Left/Right live-apply `omarchy-theme-set`, Enter
locks in). Esc×2 stays reliable because we never give the keyboard away.
(b) is needed for "let them launch an app" style acts.

**Layer ordering:** the browser, btop, etc. open as normal windows *below*
the overlay layer, so glowing captions float over the live apps. That is the
intended look. The scrim must stay light enough to see through.

## 2. Install reality: no hooks, no sudo

> "It never runs anything from the plugin, never executes an install hook,
> and never asks for sudo — it clones files, checks the manifest, and flips a
> bit over IPC." — `manual/32-shell-plugins.md:44`

So "install btop in the plugin install" cannot happen at `omarchy plugin
add` time. Two routes, both already provided by Omarchy:

- **First-run act ("One-Line Install"):** `omarchy-install-and-launch <name>
  <packages> <desktop-id>` or directly
  `omarchy-launch-floating-terminal-with-presentation "omarchy-pkg-add btop"`
  — a floating terminal that prints the logo, runs pacman (the user types
  their password on screen), then shows "Done! Press any key". That is itself
  a show piece: *no app store, no wizard, no reboot.*
  (`bin/omarchy-install-and-launch`, `bin/omarchy-launch-floating-terminal-with-presentation`, `bin/omarchy-show-logo`, `bin/omarchy-show-done`)
- **`showoff prepare` (booth mode):** one explicit command that installs
  every optional package the acts want (btop cava cmatrix fastfetch qrencode
  ttfx …) once, so the show never stops for a password at the booth.

Preconditions are cheap: `omarchy-cmd-present <cmd…>` and
`omarchy-pkg-present <pkg…>` return 0/1. **Every act declares its
precondition and is skipped, not failed, when it isn't met.**

## 3. Commands each act drives (all in `$OMARCHY_PATH/bin`)

| Act | Command | Notes |
|---|---|---|
| Open omarchy.org | `omarchy-launch-browser https://omarchy.org` | resolves the xdg default browser, runs it under `systemd-run --user`, then focuses it |
| Theme list / current / set | `omarchy-theme-list`, `omarchy-theme-current`, `omarchy-theme-set "<Name>"` | 43 themes on vic; `theme-set` takes display names ("Tokyo Night"), holds a lock file, and fans out to every app setter in parallel — measure how long it takes before rapid cycling |
| Theme picker (stock) | `omarchy-theme-switcher` | walker-based with previews — alternative to our own carousel |
| Wallpaper next | `omarchy-theme-bg-next` | includes video wallpapers |
| btop / any TUI, framed | `omarchy-launch-floating-terminal-with-presentation btop` | floating terminal, logo first, `Done!` after |
| Plain TUI | `omarchy-launch-tui`, `omarchy-launch-or-focus-tui` | |
| Web app as a window | `omarchy-launch-webapp <url>` | chrome-less app window |
| Screensaver | `omarchy-launch-screensaver force` | needs `ttfx` **and** Alacritty/Foot/Ghostty/Kitty; else it notifies and exits 1 → precondition |
| Keep screen on during the show | `omarchy-toggle-idle stay-awake` / `allow-idle` / `status` | restore afterwards |
| Silence notifications | `omarchy-toggle-notification-silencing` (DND) | restore afterwards |
| Record the show | `omarchy-capture-screenrecording` | may raise a portal prompt — verify |
| Menu tour | `omarchy-shell shell summon omarchy.menu '{"menu":"root"}'`; `omarchy menu summon <route>` | routes are JSON payloads (`bin/omarchy-menu:5-8`) |
| Emoji / clipboard cameos | `omarchy-menu-emoji`, `omarchy-menu-clipboard` | both are overlays — they will fight ours for exclusive keyboard focus; sequence them (hide ours, summon theirs, wait, resummon) |
| Night light | `omarchy-toggle-nightlight` | |
| Float / pin a window | `omarchy-hyprland-window-pop`, `omarchy-hyprland-window-gaps-toggle`, `omarchy-hyprland-window-tiled-fullscreen-toggle` | |
| Keybinding sheet | `omarchy-menu-keybindings` | |

## 4. Driving Hyprland

vic's Hyprland (0.56.2) takes **Lua dispatches**; Omarchy's own scripts use the
Lua form and fall back to the classic one so they run on both (from
`bin/omarchy-launch-screensaver`):

```bash
hyprctl dispatch "hl.dsp.exec_cmd([[$command]])" >/dev/null 2>&1 || hyprctl dispatch exec -- bash -lc "$command"
hyprctl dispatch "hl.dsp.focus({ monitor = \"$m\" })" || hyprctl dispatch focusmonitor "$m"
```

Other Lua forms seen in `bin/`: `hl.dsp.focus({ window = "address:…" })`,
`hl.dsp.focus({ workspace = "1" })`, `hl.dsp.dpms({ action = "enable" })`,
`hl.dsp.send_key_state({ mods = …})`. Use the same dual pattern everywhere.

**Waiting for a window to appear** (browser opened, btop mapped): read the
Hyprland event socket, exactly as `omarchy-launch-screensaver` does:

```bash
socat -U - "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
# lines like: openwindow>>ADDR,WORKSPACE,CLASS,TITLE
```

Inside QML, Quickshell's `Quickshell.Hyprland` module exposes the same events
and window list (the omagotchi plugin uses it for window geometry:
`~/.config/omarchy/plugins/slcode777.omagotchi/RoamWindow.qml:15-17`). Prefer
that over shelling out to socat.

## 5. Look and feel

- Colours: `qs.Commons` `Color.foreground / accent / urgent` and the
  `Style` tokens (`shell/Commons/Style.qml`, `Color.qml`) — the captions
  recolour with whatever theme the visitor picks, automatically.
- UI font: **JetBrainsMono Nerd Font**. The wordmark is
  `/usr/share/omarchy/logo.svg` (never typeset "OMARCHY" from a font — the
  letters in `omarchy.ttf` are empty stubs; `U+E900` is the logo *mark*).
  Source: `~/.claude/MEMORY/AUTO/omarchy-brand-assets-and-fonts.md`.
- Glow: `QtQuick.Effects` `MultiEffect` (blur + shadow) is available in this
  Qt (omagotchi imports it). The scaffold uses `Text.Outline` as a placeholder;
  the real glow is a layered MultiEffect — not built yet.
- Sound: the Tetris and Omagotchi plugins ship sounds and play them from QML;
  copy their approach if we add whooshes.

## 6. Safety rules the engine must enforce

1. **Snapshot, then restore.** Record `omarchy-theme-current` and the current
   background link (`~/.local/state/omarchy/current/background`) before act 1.
   At the end ask *Keep this theme?*; on No or on Esc×2, restore both.
2. **Stay-awake + DND during the show**, restored after (also on Esc×2).
3. **Never sudo silently.** Package installs only ever happen in the visible
   presentation terminal, or via the explicit `showoff prepare`.
4. **No destructive commands, ever.** The act list is data; the engine only
   runs commands from the shipped act table.
5. **Skip, don't fail.** Precondition unmet → act skipped, show continues.
6. **Esc×2 always works** because the overlay never releases the keyboard
   except during explicitly hand-over acts, and even then a global
   `omarchy-shell shell hide nixfred.showoff` ends it.
7. Close what we opened (browser window, btop terminal) unless an act says
   "leave it running" — btop is the one Fred wants left up.

## 7. Engine shape (proposed, not built)

A show is an ordered list of **acts**. Each act is data:

```js
{ id: "browser",
  caption: "THIS IS OMARCHY",  sub: "a Linux desktop that gets out of your way",
  requires: ["omarchy-launch-browser"],          // omarchy-cmd-present
  run: "omarchy-launch-browser https://omarchy.org",
  until: { window: { class: /brave|firefox|chromium/ }, timeoutMs: 8000 },
  hold: 6000,
  cleanup: "close-window" }
```

Interactive acts add `keys: { Left, Right, Return }` handlers and a `prompt`
caption. The overlay walks the list with a small state machine
(`idle → running(act i) → waiting → next → done`). Esc×2 from any state →
`cleanup-all → restore → dismiss`.

## 8. Open questions (verify before building)

- Does a `keepLoaded` overlay keep its `Timer`s running while hidden?
- How long does `omarchy-theme-set` take end-to-end on a typical box, and is
  rapid cycling (Theme Roulette) smooth or does the lock file serialize it
  into a slideshow?
- Does launching the browser (`systemd-run` + `omarchy-hyprland-focus-app`)
  ever pull keyboard focus away from an *exclusive* layer surface? (Expect no.)
- Summoning another overlay (emoji, clipboard, menu) while ours is up — who
  wins the keyboard, and does hiding theirs hand it back to us?
- `omarchy-capture-screenrecording`: does a portal prompt appear, and can we
  pre-authorise it for booth mode?
- Fractional scaling: omagotchi notes layer-surface coordinates assume scale 1.
- The scaffold `Showoff.qml` has **not been summoned yet** (it would grab
  Fred's keyboard until Esc×2). `omarchy plugin validate` passes; runtime is
  unverified.
