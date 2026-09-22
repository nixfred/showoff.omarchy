# Showoff Omarchy — project brief

> Identity and global rules: `~/.claude/CLAUDE.md` (Larry, 9 Laws, Constitution).
> Machine context: `~/Projects/CLAUDE.md` (vic, RTX 4050, Ollama).
> This file is the project brief. Born 2026-09-21 from Fred: *"create a plugin
> that people use on their real system that is an auto showoff Omarchy that
> will run on any omarchy system … The goal isn't to show an omarchy person
> omarchy, it's to show a windows or mac person."*

**Status: scaffold + research. No act is built.** `manifest.json` validates,
`Showoff.qml` is a takeover-only stub (fullscreen overlay, exclusive
keyboard, Esc×2 to leave) that has **never been summoned** — runtime
unverified. Fred is narrowing `IDEAS.md` before any act gets written.

Repo: `github.com/nixfred/showoff.omarchy` (PUBLIC — it is for other
people's machines; nothing private ever goes in here).

---

## Law 0 — runs on anyone's Omarchy, depends on no other plugin

Fred, 2026-09-21, mid-session: *"It must work on anyone's omarchy and not
depend on other plugins."* This outranks every other choice in the project.

- **Only stock surface.** `omarchy-*` commands in `$OMARCHY_PATH/bin`, the
  shell's own `qs.Commons` (`Style`, `Color`, `Util`), Quickshell modules,
  Qt. Nothing from `~/.config/omarchy/plugins/*`, nothing from Fred's forks or
  vic patches, no `nixfred.*` IPC targets.
- **Optional packages are preconditions, not dependencies.** btop, cava,
  cmatrix, fastfetch, qrencode, ttfx are pacman packages the show can offer to
  install *on screen* (the One-Line Install act) or that `showoff prepare`
  installs once. An act whose package is missing is skipped, never fatal.
- **vic is NOT a stock box.** 80+ plugins, a patched shell, Infomarchy owning
  the `background` IPC target, a dev checkout at `$OMARCHY_PATH`
  (`4.0.0.alpha`, dev). Something working on vic proves nothing. Verify on a
  **clean Omarchy profile**: `ovm` runs packaged 4.0.4 but its plugin dir was
  seeded from vic (73 entries), so make a fresh user there, or a fresh
  omarchy-lab VM (`~/VMs/omarchy-lab`, hive VM 105), before calling anything
  portable.
- **Minimum Omarchy version = whatever shipped the shell plugin system
  (4.0).** Say so in the README; don't chase older releases.
- When a stock command doesn't exist on a release, the act says so on screen
  and moves on. Never paper over it with a copied script.

## The goal

A show, started with one command, that a Windows or Mac person watches (and
partly drives) and comes away thinking *"wait, what?"*. Roughly 90 s to 2 min.

Fred's spine (fixed):

1. Take over the screen. Esc twice, any time, stops it and puts everything back.
2. Open their default browser on omarchy.org.
3. Big, glowing captions over the screen talk to the watchers.
4. "Now I'm going to let **you** change the theme." Left/Right through the
   themes, Enter picks. Live: every app recolours as they arrow.
5. Take back over. Install btop if it's missing (on screen, in the presentation
   terminal), open it, **leave it running**.
6. Go on and do other things — the acts Fred picks from `IDEAS.md`.

Bonus points for interaction (the theme pick is the first; more in IDEAS).

## Decisions made so far (don't re-litigate)

- **It is an `overlay`-kind shell plugin**, id `nixfred.showoff`, started with
  `omarchy-shell shell summon nixfred.showoff '{}'`. Same primitive the stock
  emoji/clipboard/menu/lock overlays use. Research: `RESEARCH.md` §1.
- **The overlay is the theme picker.** It handles Left/Right/Enter itself and
  calls `omarchy-theme-set`; it never hands the keyboard to another surface
  for this act, so Esc×2 stays reliable. (Alternative rejected: summoning
  `omarchy-theme-switcher`, which would fight us for exclusive keyboard focus.)
- **btop installs on screen, not at plugin-add time.** `omarchy plugin add`
  never runs hooks or sudo (manual line 44). The presentation terminal *is*
  the showpiece.
- **The show is data.** An ordered act table (caption, precondition, command,
  wait-until, hold, cleanup); the engine is a small state machine. New acts
  are rows, not code paths.
- **Snapshot then restore.** Theme, background, idle, DND recorded before act 1
  and restored at the end or on Esc×2, unless the visitor chooses "keep".
- **Name:** Fred named it *Showoff Omarchy*. The plugin id `nixfred.showoff`
  is Larry's placeholder — Fred names things; ask before it ships.

## Guardrails

- Never sudo silently. Never a destructive command. The engine only runs
  commands from the shipped act table.
- Never leave the machine changed: everything the show touches is restored.
- Never summon it on vic without Fred's go — it grabs his keyboard.
- Voice is off by default if it ever exists (Fred: "parlor trick, gets old").

## Files

- `manifest.json` — schemaVersion 1, kinds `["overlay"]`, `keepLoaded: true`.
- `Showoff.qml` — the overlay stub (takeover + Esc×2 only).
- `RESEARCH.md` — everything verified about the platform, with anchors.
- `IDEAS.md` — 20 candidate acts (+2 bonus) with Larry's suggested cut.
- `docs/` — screenshots/recordings later (ignored by git except `.keep`).

## Next

1. Fred narrows `IDEAS.md`.
2. Summon the stub on a clean profile; confirm takeover, multi-monitor, Esc×2.
3. Build the engine + Fred's spine (browser → theme picker → btop).
4. Add the chosen acts one at a time, each verified on a clean profile.
5. Screenshots (pixel-checked), README, list on omarchyplugins.com.
