# Showoff Omarchy — project brief

> Identity and global rules: `~/.claude/CLAUDE.md` (Larry, 9 Laws, Constitution).
> Machine context: `~/Projects/CLAUDE.md` (vic, RTX 4050, Ollama).
> This file is the project brief. Born 2026-09-21 from Fred: *"create a plugin
> that people use on their real system that is an auto showoff Omarchy that
> will run on any omarchy system … The goal isn't to show an omarchy person
> omarchy, it's to show a windows or mac person."* Re-scoped the same night
> from plugin to **application** (below).

**Status: the whole auto show is built (2026-09-26).** All 21 acts in
`app/acts.js` run in `AUTO_ORDER` on a stage workspace (the first empty one),
with live keycaps looked up from the machine's own Hyprland binds, a
reading-time pacing model, the theme and wallpaper pickers, hand-off acts,
the QR end card (keep the theme? Y/N) and restore on every exit path. There is no menu (removed at Fred's word); install.sh / PKGBUILD (P10) not written.

Verified on vic 2026-09-26 (contact sheet of a 122 s run, then drills):
takeover logo → browser → tiling → workspace flyby → theme picker driven with
Right Right Enter → roulette recolouring everything → wallpapers → wallpaper
picker → btop → aquarium → fastfetch → YouTube web app → emoji → clipboard;
theme, wallpaper and window count restored. That run was ended by Esc Esc
(Fred, watching) before menu-tour; acts 14–21 have **not** been seen on screen
yet. Fixed on the way: launches were tied to the runner watchdog and died at
15 s (btop) — every launch is now `setsid -f` detached; keycaps flashed for
0.9 s — now `readMs`/`keycapMs` pacing and keycaps stay up during the action.

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

### Pace and music (Fred, 2026-09-26: "it's very slow... speed it up, add some 80's arcade music, punchy and cool. Write it yourself.")

- `Engine.pace` = 0.7 scales every act timing; `readMs`/`keycapMs` dwells are
  raw (never scaled) so text stays readable. Pickers self-drive after 3.5 s of
  no input instead of waiting 25 s.
- Music: **Insert Coin**, composed by Larry, score + synth in
  `tools/compose.ts` (bun), rendered to `app/assets/insert-coin.ogg`
  (45 s loop, 628 KB), played by `exec mpv --loop-file=inf` as a Runner job
  so killing the job stops it. The X cut records with `--with-desktop-audio`.
  `SHOWOFF_MUSIC=off` mutes. Verified: mpv runs during the show, gone after.

### How it runs (Fred, 2026-09-26: "no more menu... just run it")

```
showoff                 → straight into the whole show; it ends by itself and restores
showoff x               → the ~80 s cut; records itself to ~/Videos for posting
showoff act <id>[,…]    → rehearse just those acts (a dev tool, not for visitors)
Esc Esc                 → from anywhere: restore everything, quit
```

There is **no menu and no countdown gate**. Both were built and removed the
same day: Fred started it, pressed a key for the promised menu, and wanted the
show, not a chooser. Don't bring a menu back without him asking.

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
