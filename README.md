# Showoff Omarchy

> **Pre-alpha.** Nothing to watch yet. This repo is the plan, the research,
> and a takeover stub. Star it and come back.

A show that takes over your screen and demonstrates Omarchy to someone who has
only ever used Windows or macOS. Big glowing captions, your real apps, and a
few moments where the watcher gets the keyboard and picks things themselves.

Press **Esc twice** at any point and it stops, putting everything back exactly
as it was.

## What the show does

1. Takes over the screen.
2. Opens your default browser on [omarchy.org](https://omarchy.org).
3. Talks to the room in big glowing letters.
4. Hands over the arrow keys: *"Now **you** change the theme."* Every app
   recolours live as they flick through; Enter picks one.
5. Takes the keyboard back, installs `btop` on screen if it isn't there, opens
   it, and leaves it running.
6. Then shows off some more. The list of acts is being chosen — see
   [IDEAS.md](IDEAS.md).

## Runs on any Omarchy

- Needs Omarchy 4.0 or newer (the shell plugin system).
- Depends on **no other plugin**. Only stock `omarchy-*` commands and the
  shell's own components.
- Optional packages (btop, cava, …) are offered for install *on screen*, or
  installed once with `showoff prepare`. Missing ones are skipped, never fatal.
- Nothing is changed for good: theme, wallpaper, idle and do-not-disturb are
  restored when the show ends, unless you choose to keep the theme you picked.

## Install (when there is something to run)

```bash
omarchy plugin add https://github.com/nixfred/showoff.omarchy
omarchy-shell shell summon nixfred.showoff '{}'
```

## Repo map

- [CLAUDE.md](CLAUDE.md) — the project brief and the decisions made.
- [RESEARCH.md](RESEARCH.md) — what the Omarchy shell gives us, verified with
  file anchors.
- [IDEAS.md](IDEAS.md) — 20 candidate acts, with a suggested cut.
- `manifest.json`, `Showoff.qml` — the plugin scaffold.

MIT. Made by [nixfred](https://github.com/nixfred) with Larry.
