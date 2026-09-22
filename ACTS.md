# Showoff Omarchy — the acts

Fred, 2026-09-21: **"do them all."** All 20 candidates and both bonuses are
in. Nothing is cut; the only editorial choice left is the *running order* of
the auto show, and every act is also reachable on its own from the menu.

The audience is a **Windows or Mac person**. Every act is judged on one
question: *would someone who has only used a Mac say "wait, what?"* — not on
how clever it is to a Linux user. Fred: "it's important that this thing is
badass because this is going to bring people to Omarchy."

## The spine (fixed, Fred's script)

| | Act | What happens |
|---|---|---|
| S1 | **Takeover** | Every screen goes under the overlay. Wordmark. Countdown: *auto show in 5… press any key for the menu.* Esc×2 stops it at any point and puts everything back. |
| S2 | **omarchy.org** | Their default browser opens on omarchy.org under the glow. |
| S3 | **You pick the theme** | "Now I'm going to let **you** change the theme." Left/Right flick through the themes, every app recolours live; Enter picks. |
| S4 | **btop, installed on screen, left running** | The presentation terminal prints the logo, installs btop if missing, opens it. It stays up for the rest of the show. |

## Auto-show running order (proposed)

A story: *look → you drive → under the hood → hands-on → the send-off.*
Timings are guesses; measure on a real run. All 22 acts at full length is
about 5–6 minutes, so the auto show may need shortened versions of some acts
while the menu keeps the full ones — decide after the first end-to-end run.

| # | Act | Ref | Beat |
|---|---|---|---|
| 1 | Takeover + countdown gate | S1 | look |
| 2 | omarchy.org | S2 | look |
| 3 | Tiling Ballet | A3 | look |
| 4 | Workspace Flyby | A4 | look |
| 5 | You pick the theme | S3 | you drive |
| 6 | Theme Roulette (ends on theirs) | A2 | you drive |
| 7 | Wallpaper Rain | A7 | you drive |
| 8 | You pick a wallpaper | A16 | you drive |
| 9 | One-Line Install → btop, left running | S4 / A5 | under the hood |
| 10 | Terminal Aquarium (around the running btop) | A6 | under the hood |
| 11 | Fastfetch Flex | A11 | under the hood |
| 12 | Web Apps Become Apps | A12 | under the hood |
| 13 | Emoji + Clipboard Cameo | A10 | under the hood |
| 14 | The Menu Tour | A9 | under the hood |
| 15 | Night Shift, Linux Edition | A14 | under the hood |
| 16 | Gaps & Animations | B2 | under the hood |
| 17 | You launch an app | A15 | hands-on |
| 18 | Neovim in the Theme *(dev flag)* | A13 | hands-on |
| 19 | Local AI Cameo *(if Ollama)* | A20 | hands-on |
| 20 | Screensaver Cameo *(if ttfx)* | A8 | send-off |
| 21 | QR End Card | A18 | send-off |
| — | **Keycap Karaoke** runs as a layer over every act, not as a step | A1 | everywhere |

After the auto show ends (or is stopped) the app returns to the **menu**, so
the presenter can replay any single act on request.

## Infrastructure (not acts, but "do them all" includes these)

| Ref | Thing | Why |
|---|---|---|
| A17 | **Camera Roll** — the show records itself; the end card offers the MP4 | "send this to yourself"; free marketing every run |
| A19 | **Booth / Attract Mode** — loops on idle, everything restored after | unattended at a meetup table |
| B1 | **Voice** — local TTS reads the captions; whoosh per act. **Off by default** | booth without a presenter; Fred's rule: voice gets old |

## The menu

Any key or click during the countdown, or `showoff menu`, opens it. A grid of
acts the presenter can pick with arrows/Enter or the mouse; each runs and
returns to the menu. Grouped:

- **Look** — Tiling Ballet · Workspace Flyby · Gaps & Animations · Screensaver
- **Hand them the keyboard** — Pick the theme · Pick a wallpaper · Launch an app
- **Theming** — Theme Roulette · Wallpaper Rain · Night Shift
- **Under the hood** — One-Line Install + btop · Terminal Aquarium · Fastfetch · Web Apps · Emoji + Clipboard · Menu Tour · Neovim · Local AI
- **Send-off** — QR End Card · Run the whole show

## The full catalogue

| Ref | Act | What the visitor sees | Why a Mac/Windows person cares | Needs | Effort |
|---|---|---|---|---|---|
| A1 | **Keycap Karaoke** | Before every action, the real keystroke appears as a giant glowing keycap (`SUPER + RETURN`), then the thing happens. | Turns "magic" into "oh, it's a shortcut, I could do that". | nothing extra | M |
| A2 | **Theme Roulette** | All installed themes (43 here) flash by in ~8 s — everything recolours live — then it lands on the one *they* picked. | System-wide theming with zero settings panes. | measure `omarchy-theme-set` timing | M |
| A3 | **Tiling Ballet** | One terminal, then two, three, four; the layout re-tiles itself. Pop one to float, pin it, drop it back. | "You never drag or resize a window again." | nothing extra | S |
| A4 | **Workspace Flyby** | Apps spread over workspaces 1–4, then whip through them with the number glowing. | Mission Control, but instant and keyboard-driven. | nothing extra | S |
| A5 | **One-Line Install** | Floating terminal with the logo runs `omarchy-pkg-add btop`; done in seconds, app opens. | No app store, no wizard, no reboot. | `omarchy-install-and-launch` | S |
| A6 | **Terminal Aquarium** | 2×2 grid: btop, cava, cmatrix or pipes.sh, asciiquarium. | The hacker screen everyone secretly wants. | btop cava cmatrix asciiquarium | S |
| A7 | **Wallpaper Rain** | Backgrounds of the chosen theme cycle, video ones included. | Live video wallpaper, built in. | nothing extra | S |
| A8 | **Screensaver Cameo** | The ASCII screensaver plays ~6 s, then dismisses. | Spectacle. | `ttfx` + Alacritty/Foot/Ghostty/Kitty | S |
| A9 | **The Menu Tour** | The Omarchy menu opens and walks itself: Style → Theme → Install → Setup. | "One menu, not a Settings app with 40 panes." | menu routes | M |
| A10 | **Emoji + Clipboard Cameo** | Emoji picker pops, then clipboard history. | The two Mac features people ask about most. | sequencing with our overlay | M |
| A11 | **Fastfetch Flex** | Logo, kernel, packages, uptime, RAM in use. | "This is the whole OS, idling under 1 GB." | fastfetch | S |
| A12 | **Web Apps Become Apps** | YouTube opens as a chrome-less native window tiled beside a terminal. | Sites as apps, no wrappers. | nothing extra | S |
| A13 | **Neovim in the Theme** | nvim opens a file; already themed. Three seconds. | Dev audience — config flag. | nvim | S |
| A14 | **Night Shift, Linux Edition** | Screen goes warm / cool with a big caption. | They know Night Shift; this is one key. | `omarchy-toggle-nightlight` | S |
| A15 | **You launch an app** | "Press SUPER+SPACE, type `fire`, Enter." Show cheers when the window maps. | They *did* it. | keyboard hand-over + window-map detection | M |
| A16 | **You pick a wallpaper** | Same Left/Right carousel as the theme picker, for backgrounds. | A second choice they own. | theme picker first | S |
| A17 | **Camera Roll** | Whole show recorded; end card offers the MP4. | Shareable clip every run. | `omarchy-capture-screenrecording` | M |
| A18 | **QR End Card** | Huge QR to omarchy.org and to this repo. | The one thing a booth visitor takes home. | `qrencode` or shipped SVG | S |
| A19 | **Booth / Attract Mode** | Loops on idle; machine restored exactly when it ends. | Unattended use. | snapshot/restore, idle inhibit | M |
| A20 | **Local AI Cameo** | If Ollama: a terminal streams "Explain Omarchy in two sentences". | "Runs on this laptop, no cloud." | Ollama (skip if absent) | S |
| B1 | **Voice** | Local TTS reads captions; whoosh per act. Off by default. | Booth without a presenter. | piper + shipped OGG | M |
| B2 | **Gaps & Animations** | Toggle gaps and fullscreen to show Hyprland's animations. | Eye candy. | nothing extra | S |
