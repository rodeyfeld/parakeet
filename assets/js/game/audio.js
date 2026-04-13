import { Howl, Howler } from "howler"

let initialized = false
const sounds = {}

/** Browsers suspend Web Audio until a user gesture; resume on first interaction. */
function ensureAudioUnlocked() {
  const resume = () => {
    const ctx = Howler.ctx
    if (ctx && ctx.state === "suspended") {
      ctx.resume().catch(() => {})
    }
    window.removeEventListener("pointerdown", resume, true)
    window.removeEventListener("keydown", resume, true)
  }
  window.addEventListener("pointerdown", resume, true)
  window.addEventListener("keydown", resume, true)
}

ensureAudioUnlocked()

/** Scales every SFX (0–1). Lower = quieter across the board. */
const MASTER_VOLUME = 0.7

const SOUND_DEFS = {
  /** Flip / land on pile (freesound flipcard-style) */
  cardPlay: { src: ["/audio/card_flip.mp3"], volume: 0.45, rate: 1.22 },
  /** Cards scooped / pile won — same clip used for shuffle + win UI paths */
  pileWin: { src: ["/audio/pile_shuffle.mp3"], volume: 0.28 },
  /** Slap / bush-cut style hit */
  slapHit: { src: ["/audio/slap_hit.mp3"], volume: 0.52 },
  /** Penalty / invalid slap — finger snap (alex_jauk / freesound) */
  badSlap: { src: ["/audio/alex_jauk-finger-snap-sound-2-237895.mp3"], volume: 0.55 },
}

function init() {
  if (initialized) return
  initialized = true

  if (Howler.ctx && Howler.ctx.state === "suspended") {
    Howler.ctx.resume().catch(() => {})
  }

  for (const [name, def] of Object.entries(SOUND_DEFS)) {
    if (def.src.length > 0) {
      sounds[name] = new Howl({
        src: def.src,
        volume: def.volume * MASTER_VOLUME,
        rate: def.rate ?? 1,
        html5: true,
        preload: true,
      })
    }
  }
}

export const audio = {
  play(name) {
    init()
    if (sounds[name]) {
      sounds[name].play()
    }
  },

  cardPlay() { this.play("cardPlay") },
  slapHit() { this.play("slapHit") },
  badSlap() { this.play("badSlap") },
  pileWin() { this.play("pileWin") },
}
