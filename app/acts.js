.pragma library
// Showoff Omarchy — the act table. The show is data: the engine walks these
// rows and never special-cases an act. Schema: PLAN.md §2.1.
//
// P1 ships two acts that exercise the whole engine path: a caption-only act
// and one that opens a real window under the overlay and closes it again.

var ACTS = [
  {
    id: "takeover",
    title: "Takeover",
    blurb: "The screen is ours for a minute.",
    group: "look",
    caption: "SHOWOFF OMARCHY",
    sub: "a Linux desktop, shown off",
    until: { ms: 2500 },
    hold: 0
  },
  {
    id: "hello-terminal",
    title: "A terminal",
    blurb: "One keystroke, one terminal.",
    group: "look",
    caption: "ONE KEY. ONE TERMINAL.",
    sub: "no dock, no Finder, no Start menu",
    keycap: "SUPER + RETURN",
    requires: ["omarchy-launch-terminal"],
    run: "omarchy-launch-terminal",
    until: { window: true, timeoutMs: 8000 },
    hold: 3000,
    cleanup: "close-ours"
  }
]

var AUTO_ORDER = ["takeover", "hello-terminal"]

var MENU_GROUPS = {
  look: "Look",
  drive: "Hand them the keyboard",
  theme: "Theming",
  hood: "Under the hood",
  hands: "Hands-on",
  sendoff: "Send-off"
}

function byId(id) {
  for (var i = 0; i < ACTS.length; i++) if (ACTS[i].id === id) return ACTS[i]
  return null
}
