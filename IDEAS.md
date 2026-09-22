# Showoff Omarchy — the act list to choose from

The spine is Fred's script (2026-09-21):

1. Take over the screen (Esc×2 to stop).
2. Open the default browser on omarchy.org.
3. Big glowing captions talk to the watchers.
4. "Now I'm going to let **you** change the theme" — Left/Right through the
   themes, Enter to pick.
5. Take back over, install btop if missing, open it, leave it running.
6. Go on and do other things.

The audience is a **Windows or Mac person**, not an Omarchy person. So every
act is judged on one question: *would someone who has only ever used a Mac
say "wait, what?"* — not on how clever it is to a Linux user.

Below are 20 candidate acts for step 6 (plus two bonuses). Fred narrows this
list; nothing here is decided. Effort is a guess: S = an evening, M = a
weekend, L = more.

| # | Act | What the visitor sees | Why a Mac/Windows person cares | Needs | Effort |
|---|---|---|---|---|---|
| 1 | **Keycap Karaoke** | Before every action, the real keystroke appears as a giant glowing keycap (`SUPER + RETURN`), then the thing happens. | Turns "magic" into "oh, it's a shortcut, I could do that". The single most convincing thing on this list. | nothing extra | M |
| 2 | **Theme Roulette** | All installed themes (43 here) flash by in ~8 s — terminal, bar, browser, everything recolours live — then it lands on the one *they* picked. | System-wide theming with zero settings panes. Mac has light/dark. | measure `omarchy-theme-set` timing first | M |
| 3 | **Tiling Ballet** | Open one terminal, then two, three, four; the layout re-tiles itself each time. Pop one out to float, pin it, drop it back. | "You never drag or resize a window again." | nothing extra | S |
| 4 | **Workspace Flyby** | Apps spread over workspaces 1–4, then whip through them with the number glowing and the bar indicator following. | Mission Control, but instant and keyboard-driven. | nothing extra | S |
| 5 | **One-Line Install** *(this is the btop install, made a showpiece)* | Floating terminal with the logo runs `omarchy-pkg-add btop`; done in seconds, app opens. | No app store, no wizard, no reboot, no "drag to Applications". | `omarchy-install-and-launch` | S |
| 6 | **Terminal Aquarium** | 2×2 grid: btop, cava (audio spectrum), cmatrix or pipes.sh, asciiquarium. | The hacker screen everyone secretly wants. | btop cava cmatrix asciiquarium (pacman) | S |
| 7 | **Wallpaper Rain** | Backgrounds of the chosen theme cycle, including video wallpapers where present. | Live video wallpaper built in. | nothing extra | S |
| 8 | **Screensaver Cameo** | The ASCII screensaver plays for ~6 s, then dismisses. | Pure spectacle. | `ttfx` + Alacritty/Foot/Ghostty/Kitty (precondition) | S |
| 9 | **The Menu Tour** | The Omarchy menu opens and walks itself: Style → Theme → Install → Setup. | "One menu. Not a Settings app with 40 panes." | menu routes | M |
| 10 | **Emoji + Clipboard Cameo** | The emoji picker pops, then the clipboard history. | The two Mac features people ask about most. Both built in. | sequencing with our overlay (keyboard focus) | M |
| 11 | **Fastfetch Flex** | Floating terminal: logo, kernel, packages, uptime, RAM in use (usually under 1 GB idle). | "This is the whole OS, idling." | fastfetch (usually present) | S |
| 12 | **Web Apps Become Apps** | YouTube (or their pick) opens as a chrome-less native window tiled beside a terminal. | Sites as apps, no Electron wrappers. | nothing extra | S |
| 13 | **Neovim in the Theme** | nvim opens a file; it is already in the theme. Three seconds. | Dev audience only — make it a config flag. | nvim (present) | S |
| 14 | **Night Shift, Linux Edition** | Screen goes warm / cool with a big caption. | They know Night Shift; this one is one key. | `omarchy-toggle-nightlight` | S |
| 15 | **Let Them Launch** *(interaction #2)* | "Press SUPER+SPACE, type `fire`, press Enter." The launcher opens; Firefox/whatever appears; the show cheers when the window maps. | They *did* it. Hands-on beats watching. | overlay must hand the keyboard over for this act, then take it back | M |
| 16 | **Let Them Pick a Wallpaper** *(interaction #3)* | Same Left/Right carousel as the theme picker, for backgrounds. | Second choice they own; cheap once the theme picker exists. | theme picker built first | S |
| 17 | **Camera Roll** | The whole show is screen-recorded; the end card offers the MP4. | "Send this to yourself." Every run produces a shareable clip — also our marketing. | `omarchy-capture-screenrecording`, portal prompt check | M |
| 18 | **QR End Card** | Final overlay: a huge QR to omarchy.org and one to this repo. "Scan me." | The only thing they take home from a booth. | `qrencode` (pacman) or a shipped SVG | S |
| 19 | **Booth / Attract Mode** | Loops the show every N idle minutes; Esc×2 exits; the machine is exactly as it was when it ends (theme, wallpaper, idle, DND restored). | Makes it usable at a meetup table unattended. | stay-awake + DND + snapshot/restore | M |
| 20 | **Local AI Cameo** | If Ollama is here: a terminal streams `ollama run … "Explain Omarchy in two sentences"`. | "Runs on this laptop. No cloud." Skipped silently when absent. | Ollama (precondition) | S |
| B1 | **Voice** | Local TTS (piper) reads the captions; whoosh sound on each act. Off by default. | Booth without a presenter. | piper + shipped OGG | M |
| B2 | **Gaps & Animations** | Toggle gaps and fullscreen on a window to show Hyprland's animations. | Eye candy Mac people rate highly. | nothing extra | S |

## How I'd cut it (Larry's opinion, for the narrowing)

A show should be **90 seconds to two minutes**. Longer and people walk. That
is about eight acts including Fred's spine. My pick:

**Spine** (fixed): takeover → omarchy.org → theme picker (visitor drives) →
One-Line Install + btop.

**Then:** 1 Keycap Karaoke (as a layer over everything, not an act of its
own) · 3 Tiling Ballet · 4 Workspace Flyby · 6 Terminal Aquarium · 2 Theme
Roulette (ending on their theme) · 18 QR End Card.

**Booth mode (19) and Camera Roll (17)** are infrastructure, not acts; build
them once the show exists.

**Skip for v1:** 9 (menu tour is inside-baseball), 13 (dev only), 20 (needs
Ollama), B1 (voice — Fred's own rule: parlor trick, gets old).
