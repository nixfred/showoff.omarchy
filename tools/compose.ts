#!/usr/bin/env bun
// Showoff Omarchy — "Insert Coin", an original 80s arcade theme.
// Composed by Larry for Showoff Omarchy, 2026-09-26. MIT like the rest.
//
// This file IS the music: a score (notes below) plus a tiny chiptune synth
// (pulse lead, triangle bass, thin pulse arpeggio, noise drums). Render with
//   bun tools/compose.ts app/assets/insert-coin.wav
//   ffmpeg -y -i app/assets/insert-coin.wav -c:a libvorbis -q:a 5 app/assets/insert-coin.ogg
// The show plays the .ogg on a loop through mpv (in omarchy-base).

const SR = 44100
const BPM = 152
const STEP = 60 / BPM / 4 // one 16th note, seconds
const BAR = 16            // 16ths per bar

// ---------------------------------------------------------------- the score
// Chords per bar. Intro, A, B, A. i–VI–III–VII in A minor for the hook,
// a climb through F G Em Am for the lift.
const PROG_A = ["Am", "F", "C", "G", "Am", "F", "C", "G"]
const PROG_B = ["F", "G", "Em", "Am", "F", "G", "Am", "Am"]
const SONG: { prog: string[]; lead: string[] | null; fills: boolean }[] = [
  { prog: ["Am", "F", "C", "G"], lead: null, fills: true },
  { prog: PROG_A, lead: null, fills: true },   // lead filled in below
  { prog: PROG_B, lead: null, fills: true },
  { prog: PROG_A, lead: null, fills: true },
]

// Lead lines: "NOTE:len" in 16ths, R = rest. Each bar sums to 16.
const LEAD_A = [
  "E5:2 A5:2 E5:2 C5:2 D5:2 E5:4 C5:2",
  "A4:2 C5:2 F5:4 E5:2 D5:2 C5:4",
  "G4:2 C5:2 E5:2 G5:4 E5:2 G5:2 C6:2",
  "B5:4 A5:2 G5:2 D5:4 R:4",
  "E5:2 A5:2 B5:2 C6:4 B5:2 A5:2 G5:2",
  "A5:4 F5:2 A5:2 C6:4 A5:4",
  "G5:2 E5:2 C5:2 E5:2 G5:2 C6:2 E6:4",
  "D6:4 B5:4 G5:4 B5:2 D6:2",
]
const LEAD_B = [
  "C6:3 A5:1 F5:2 A5:2 C6:4 D6:4",
  "B5:3 G5:1 D5:2 G5:2 B5:4 D6:4",
  "E6:4 D6:2 B5:2 G5:4 E5:4",
  "A5:6 R:2 A5:2 B5:2 C6:2 E6:2",
  "F6:4 E6:2 C6:2 A5:4 C6:4",
  "D6:4 B5:2 G5:2 D6:4 G6:4",
  "E6:2 C6:2 A5:2 C6:2 E6:2 A6:6",
  "A6:4 R:4 E6:2 C6:2 A5:4",
]
SONG[1].lead = LEAD_A
SONG[2].lead = LEAD_B
SONG[3].lead = LEAD_A

const CHORDS: Record<string, number[]> = { // semitones above A
  Am: [0, 3, 7], F: [-4, 0, 3], C: [3, 7, 10], G: [-2, 2, 5], Em: [-5, -2, 2],
}
const ROOT: Record<string, number> = { Am: 0, F: -4, C: 3, G: -2, Em: -5 }

// ---------------------------------------------------------------- the synth
const NAMES: Record<string, number> = { C: -9, D: -7, E: -5, F: -4, G: -2, A: 0, B: 2 }
function hz(note: string): number {
  const m = note.match(/^([A-G])(#|b)?(\d)$/)!
  const semis = NAMES[m[1]] + (m[2] === "#" ? 1 : m[2] === "b" ? -1 : 0) + (Number(m[3]) - 4) * 12
  return 440 * 2 ** (semis / 12)
}
const fromA4 = (semis: number) => 440 * 2 ** (semis / 12)

const totalBars = SONG.reduce((n, s) => n + s.prog.length, 0)
const total = Math.ceil(totalBars * BAR * STEP * SR) + SR // +1 s tail
const lead = new Float32Array(total), bass = new Float32Array(total)
const arp = new Float32Array(total), drums = new Float32Array(total)

function env(i: number, n: number, a: number, r: number) {
  if (i < a) return i / a
  if (i > n - r) return Math.max(0, (n - i) / r)
  return 1
}
function pulse(buf: Float32Array, start: number, dur: number, f: number, duty: number, vol: number, vibrato = false) {
  const n = Math.floor(dur * SR), a = Math.floor(0.003 * SR), r = Math.floor(0.025 * SR)
  let ph = 0
  for (let i = 0; i < n && start + i < buf.length; i++) {
    const t = i / SR
    const vib = vibrato && t > 0.18 ? 1 + 0.006 * Math.sin(2 * Math.PI * 6 * t) : 1
    ph = (ph + (f * vib) / SR) % 1
    const decay = 0.75 + 0.25 * Math.exp(-t * 6)
    buf[start + i] += (ph < duty ? 1 : -1) * vol * env(i, n, a, r) * decay
  }
}
function tri(buf: Float32Array, start: number, dur: number, f: number, vol: number) {
  const n = Math.floor(dur * SR), a = Math.floor(0.002 * SR), r = Math.floor(0.02 * SR)
  let ph = 0
  for (let i = 0; i < n && start + i < buf.length; i++) {
    ph = (ph + f / SR) % 1
    buf[start + i] += (4 * Math.abs(ph - 0.5) - 1) * vol * env(i, n, a, r)
  }
}
let seed = 1337
const noise = () => ((seed = (seed * 1103515245 + 12345) & 0x7fffffff) / 0x3fffffff) - 1
function kick(start: number) {
  const n = Math.floor(0.16 * SR); let ph = 0
  for (let i = 0; i < n && start + i < total; i++) {
    const t = i / SR, f = 45 + 110 * Math.exp(-t * 35)
    ph += f / SR
    drums[start + i] += Math.sin(2 * Math.PI * ph) * 0.95 * Math.exp(-t * 18)
  }
}
function snare(start: number, vol = 0.55) {
  const n = Math.floor(0.14 * SR); let ph = 0
  for (let i = 0; i < n && start + i < total; i++) {
    const t = i / SR; ph += 185 / SR
    drums[start + i] += (noise() * 0.8 + Math.sin(2 * Math.PI * ph) * 0.4) * vol * Math.exp(-t * 26)
  }
}
function hat(start: number, vol = 0.18, open = false) {
  const n = Math.floor((open ? 0.09 : 0.03) * SR); let prev = 0
  for (let i = 0; i < n && start + i < total; i++) {
    const s = noise(), hp = s - prev; prev = s // crude high-pass: bright, tinny, arcade
    drums[start + i] += hp * vol * Math.exp(-(i / SR) * (open ? 30 : 90))
  }
}

// ---------------------------------------------------------------- render
let bar = 0
for (const section of SONG) {
  section.prog.forEach((chord, b) => {
    const barStart = (bar + b) * BAR
    const at = (step: number) => Math.floor((barStart + step) * STEP * SR)
    const last = b === section.prog.length - 1

    // Drums: four-on-the-floor kick with a push on the "and" of 3, snare on
    // 2 and 4, 8th hats with an open hat before each snare; fill on bar ends.
    for (const s of [0, 4, 8, 10, 12]) kick(at(s))
    for (const s of [4, 12]) snare(at(s))
    for (let s = 0; s < 16; s += 2) hat(at(s), s % 4 === 2 ? 0.2 : 0.14, s === 10)
    if (last && section.fills) for (const s of [13, 14, 15]) snare(at(s), 0.35 + (s - 13) * 0.1)

    // Bass: octave-bouncing 8ths on the root, triangle, two octaves down.
    const r = ROOT[chord]
    for (let s = 0; s < 16; s += 2) tri(bass, at(s), STEP * 1.8, fromA4(r - 24 + (s % 4 === 2 ? 12 : 0)), 0.42)

    // Arp: 16th arpeggio up the chord, thin 12.5% pulse, tucked under.
    const tones = CHORDS[chord], seq = [0, 1, 2, 1]
    for (let s = 0; s < 16; s++) pulse(arp, at(s), STEP * 0.9, fromA4(tones[seq[s % 4]] + (s >= 8 ? 12 : 0)), 0.125, 0.07)

    // Lead: 25% pulse, vibrato on held notes.
    if (section.lead) {
      let s = 0
      for (const tok of section.lead[b].split(" ")) {
        const [note, len] = tok.split(":"); const l = Number(len)
        if (note !== "R") pulse(lead, at(s), l * STEP * 0.92, hz(note), 0.25, 0.2, l >= 4)
        s += l
      }
    }
  })
  bar += section.prog.length
}

// Mix, soft-clip, 16-bit mono WAV.
const out = new Int16Array(total)
for (let i = 0; i < total; i++) {
  const x = lead[i] + bass[i] * 0.9 + arp[i] + drums[i] * 0.8
  out[i] = Math.round(Math.tanh(x * 0.9) * 0.89 * 32767)
}
const header = Buffer.alloc(44)
header.write("RIFF", 0); header.writeUInt32LE(36 + out.byteLength, 4); header.write("WAVE", 8)
header.write("fmt ", 12); header.writeUInt32LE(16, 16); header.writeUInt16LE(1, 20); header.writeUInt16LE(1, 22)
header.writeUInt32LE(SR, 24); header.writeUInt32LE(SR * 2, 28); header.writeUInt16LE(2, 32); header.writeUInt16LE(16, 34)
header.write("data", 36); header.writeUInt32LE(out.byteLength, 40)
const path = process.argv[2] ?? "insert-coin.wav"
await Bun.write(path, Buffer.concat([header, Buffer.from(out.buffer)]))
console.log(`${path}: ${totalBars} bars at ${BPM} BPM, ${(total / SR).toFixed(1)} s`)
