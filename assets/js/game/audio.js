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

const SOUND_DEFS = {
  /** Flip / land on pile (freesound flipcard-style) */
  cardPlay: { src: ["/audio/card_flip.mp3"], volume: 0.45, rate: 1.22 },
  /** Cards scooped / pile won — same clip used for shuffle + win UI paths */
  pileWin: { src: ["/audio/pile_shuffle.mp3"], volume: 0.38 },
  /** Slap / bush-cut style hit */
  slapHit: { src: ["/audio/slap_hit.mp3"], volume: 0.52 },
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
        volume: def.volume,
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
  pileWin() { this.play("pileWin") },
}
