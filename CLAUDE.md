# Showoff Omarchy — project brief

> Identity and global rules: `~/.claude/CLAUDE.md` (Larry, 9 Laws, Constitution).
> Machine context: `~/Projects/CLAUDE.md` (vic, RTX 4050, Ollama).
> This file is the project brief. Born 2026-09-21 from Fred: *"create a plugin
> that people use on their real system that is an auto showoff Omarchy that
> will run on any omarchy system … The goal isn't to show an omarchy person
> omarchy, it's to show a windows or mac person."* Re-scoped the same night
> from plugin to **application** (below).

**Status: P1 (engine core) done and verified on vic 2026-09-26.** The show is a
state machine (`app/Engine.qml`) walking the act table (`app/acts.js`), with
Runner/Hypr/Snapshot, glowing captions, Keycap Karaoke, idle + shortcut
inhibitors, skip-on-missing-precondition and restore on every exit. Two acts
exist (`takeover`, `hello-terminal`); the other 20 are PLAN.md P2–P9.

P1 evidence (vic, coffee theme): `showoff auto` → takeover → SUPER + RETURN
keycaps → kitty tiles in under the scrim → closes → "THAT WAS OMARCHY"; windows
4→5→4; Esc×2 mid-hold closes the terminal and restores (`restored (0)`);
missing-binary drill skips with the missing names and continues;
`ShortcutInhibitor active=true`. No QML errors.

### Verified on vic, 2026-09-21 (Fred's go; three runs, screenshots pixel-checked)

| Check | Result |
|---|---|
| Loads as its own process (`quickshell -n -p app/`) | yes, "Configuration Loaded", no QML errors |
| Fullscreen layer above everything | Hyprland lists `showoff-omarchy` 1920×1080 at Overlay level; scrim leaves the desktop readable |
| Theme colours from `colors.toml` | caption rendered in Phosphor's accent `#44E8CB` |
| Countdown → auto (silence) | flipped to the AUTO SHOW placeholder by itself |
| Countdown → menu (any key) | Space during the countdown → PICK AN ACT placeholder |
| Single Esc does **not** quit | sub-caption "press Esc again to stop", process alive, layer up |
| Esc×2 quits | process gone, layer gone, within 0.5 s |
| Multi-monitor | **untested** — vic had one screen (eDP-1) |
| Log noise | one harmless `qt.qpa.services` WARN: portal app-id already registered (second Qt app in the session) |
| Title sizing | at `height/8` "SHOWOFF OMARCHY" nearly spans 1920 px — needs fit-to-width before smaller screens |

**Testing rule, learned the hard way that night:** never inject a key
(`wtype`) unless `hyprctl layers -j` shows `showoff-omarchy` *immediately*
before that key. Fred pressed Esc×2 himself mid-test; my two injected
Escapes then went to the focused terminal and cancelled an AskUserQuestion
prompt in one of his other Claude sessions. Guard every key; "gone after my
keys" proves nothing on its own.

Repo: `github.com/nixfred/showoff.omarchy` (PUBLIC — it is for other
people's machines; nothing private ever goes in here).

---

## Law 0 — runs on anyone's Omarchy, depends on no other plugin

Fred, 2026-09-21: *"It must work on anyone's omarchy and not depend on other
plugins."* This outranks every other choice in the project.

- **Only stock surface.** `omarchy-*` commands in `$OMARCHY_PATH/bin`,
  Quickshell (0.3.x, present on every Omarchy 4.x because the shell *is*
  Quickshell), Qt, and stock state under `~/.local/state/omarchy/current/`
  (`theme.name`, `theme/colors.toml`, `background`). Nothing from
  `~/.config/omarchy/plugins/*`, nothing from Fred's forks or vic patches, no
  `nixfred.*` IPC targets, and **not** the shell's `qs.Commons` (that is
  only importable from inside the shell process).
- **Optional packages are preconditions, not dependencies.** btop, cava,
  cmatrix, fastfetch, qrencode, ttfx are pacman packages the show can offer to
  install *on screen* (One-Line Install) or that `showoff prepare` installs
  once. An act whose package is missing is skipped, never fatal.
- **vic is NOT a stock box.** 80+ plugins, a patched shell, Infomarchy owning
  the `background` IPC target, a dev checkout at `$OMARCHY_PATH`
  (`4.0.0.alpha`). Something working on vic proves nothing. Verify on a
  **clean profile**: Fred chose a **fresh user on `ovm`** (packaged 4.0.4-1,
  Quickshell 0.3.1; its `pi` user's plugin dir was seeded from vic, so make a
  new user — `demo` — and test there).
- **Minimum Omarchy version = 4.0** (the release that made the shell a
  Quickshell process). Say so in the README; don't chase older releases.
- When a stock command doesn't exist on a release, the act says so on screen
  and moves on. Never paper over it with a copied script.

## It is an application, not a plugin (Fred, 2026-09-21)

Fred: *"I don't think this should be a plugin. I think it should be an
application because it needs to take over a full screen and it needs to allow
the user to pick auto … or … select on a menu … maybe even as the thing
starts, it does a countdown, and if you don't pick something or move
something, it just goes ahead and runs the auto show."*

What that means concretely:

- **Its own process.** `showoff` runs `quickshell -n -p <app dir>` — exactly
  how Omarchy runs its own shell (`bin/omarchy-launch-shell:19`), but a
  separate instance. A crash in the show can never take down the user's bar,
  and installing it never means "load arbitrary code into your shell".
- **Still layer-shell.** The captions must float *over* the live browser and
  btop, so the window is a `PanelWindow` on `WlrLayer.Overlay` with exclusive
  keyboard focus — the same primitive as the stock emoji/clipboard/menu/lock
  overlays (`RESEARCH.md` §1). A normal fullscreen window would hide the very
  apps being shown off; that is why it isn't a "plain" app.
- **Launched like an app.** `showoff-omarchy.desktop` puts *Showoff Omarchy*
  in the launcher (SUPER+SPACE → "show"), which is itself a demo moment.
- **Packaged like an app.** Install path is still open: a curl-able
  `install.sh` (files to `~/.local/share/showoff-omarchy`, launcher to
  `~/.local/bin`, desktop entry to `~/.local/share/applications`) and/or an
  AUR `PKGBUILD` so `omarchy-pkg-add showoff-omarchy` works. Decide before v1.

### The modes

```
showoff                 → splash + countdown "auto show in 5 · any key for the menu"
                            silence → AUTO: the whole running order (ACTS.md)
                            any key / click → MENU: pick an act, it runs, back to the menu
showoff auto            → straight into the full show
showoff menu            → straight to the menu
showoff act <id>        → one act, then the menu
showoff prepare         → install the optional packages once (booth)
Esc Esc                 → from anywhere: restore everything, quit
```

When the auto show finishes it returns to the menu, so the presenter can
replay any act on request.

## Naming (Fred, 2026-09-21: "it's not about me")

The product is **Showoff Omarchy**. Command `showoff`, desktop id
`showoff-omarchy`, layer namespace `showoff-omarchy`. **No `nixfred` in any
id.** The GitHub repo stays under Fred's account (`nixfred/showoff.omarchy`)
because that is where it lives, not because it's about him.

## Decisions made so far (don't re-litigate)

- **All 22 acts are in** (Fred: "do them all"). Running order proposed in
  `ACTS.md`; the auto show may use shortened versions, the menu keeps full ones.
- **The overlay is the theme picker.** It handles Left/Right/Enter itself and
  calls `omarchy-theme-set`; it never hands the keyboard to another surface
  for this act, so Esc×2 stays reliable.
- **btop installs on screen.** `omarchy plugin add`/pacman aren't in play at
  install time; the presentation terminal *is* the showpiece.
- **The show is data.** An ordered act table (caption, precondition, command,
  wait-until, hold, cleanup); the engine is a small state machine. New acts
  are rows, not code paths.
- **Snapshot then restore.** Theme, background, idle, DND recorded before act
  1 and restored at the end or on Esc×2, unless the visitor chooses "keep".
- **Theme colours come from `colors.toml`**, watched for changes, so captions
  recolour with the theme the visitor picks.
- **Voice off by default** if it ever exists (Fred: "parlor trick, gets old").

## Guardrails

- Never sudo silently. Never a destructive command. The engine only runs
  commands from the shipped act table.
- Never leave the machine changed: everything the show touches is restored.
- Never run it on vic without Fred's go — it grabs his keyboard. First runs
  happen on the fresh `demo` user on `ovm`.
- Use Quickshell's `ShortcutsInhibitor` during the show so SUPER-chords don't
  leak to Hyprland, and `IdleInhibitor` instead of flipping the user's
  stay-awake toggle (both in `Quickshell.Wayland`, verified present).

## Files

- `bin/showoff` — launcher (modes above); `shellcheck` clean.
- `app/shell.qml` — the application root (`ShellRoot`): takeover, colours,
  countdown gate, Esc×2. Placeholders where the engine goes.
- `showoff-omarchy.desktop` — launcher entry.
- `RESEARCH.md` — everything verified about the platform, with anchors.
- `ACTS.md` — the spine, all 22 acts, running order, menu groups.
- `docs/` — screenshots/recordings later (ignored by git except `.keep`).

## Next — follow `PLAN.md`

`PLAN.md` is the build plan, written so Opus or lower can execute it: exact
contracts (act schema, engine states, Runner/Hypr/Snapshot APIs, verified
Quickshell and Hyprland idioms), ten phases each with steps, "done when"
evidence and a model tier, the full act table as data, a pitfalls list and
verification recipes. Start at P1 (Opus). Commit per phase.
