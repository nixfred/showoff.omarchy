# Showoff Omarchy

> **Early.** The whole show runs. A clean stock-box test pass is next.

An application that takes over your screen and shows Omarchy off to someone
who has only ever used Windows or macOS. Big glowing captions over your real
apps, a running order of short acts, and moments where the watcher gets the
keyboard and picks things themselves.

Press **Esc twice** at any point and it stops, putting everything back exactly
as it was.

## How it runs

```
showoff            countdown: "auto show in 5 · press any key for the menu"
                   silence → the whole show runs itself
                   any key → a menu; pick an act, it runs, back to the menu
showoff auto       straight into the full show
showoff menu       straight to the menu
showoff act <id>   one act
```

The auto show, in order: take over → your browser on
[omarchy.org](https://omarchy.org) → windows tile and fly between
workspaces → *you* pick the theme (every app recolours as you flick) → theme
roulette lands on yours → wallpapers, video ones too → `btop` installed on
screen in seconds and left running → the terminal aquarium → what's under the
hood → hands-on: *you* launch an app → a QR code to take home. Every
keystroke it uses is shown as a glowing keycap first, so none of it looks like
magic. The full list is in [ACTS.md](ACTS.md).

## Runs on any Omarchy

- Omarchy 4.0 or newer. That's the whole requirement: it uses Quickshell,
  which every Omarchy 4 desktop already runs, and the stock `omarchy-*`
  commands.
- Depends on **no plugin** and runs as its **own process** — it can't take
  your bar down with it.
- Optional packages (btop, cava, …) are offered for install *on screen*, or
  installed once with `showoff prepare`. Missing ones are skipped, never fatal.
- Nothing is changed for good: theme, wallpaper, idle and do-not-disturb are
  restored when the show ends, unless you choose to keep the theme you picked.

## Install

```bash
git clone https://github.com/nixfred/showoff.omarchy
cd showoff.omarchy && makepkg -si
```

pacman owns every file. It lands in your launcher as **Showoff Omarchy**.
Remove it with `sudo pacman -R showoff-omarchy`.

```
showoff        the whole show, about 4 minutes; Esc twice stops it any time
showoff x      the 80 second cut; records itself to ~/Videos for posting
```

## Repo map

- [CLAUDE.md](CLAUDE.md) — the project brief and the decisions made.
- [RESEARCH.md](RESEARCH.md) — what Omarchy and Quickshell give us, verified
  with file anchors.
- [ACTS.md](ACTS.md) — the spine, every act, and the running order.
- `bin/showoff` — launcher. `app/shell.qml` — the application.
  `showoff-omarchy.desktop` — launcher entry.

MIT.
