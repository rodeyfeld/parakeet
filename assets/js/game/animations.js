import gsap from "gsap"
import { featherBurst } from "./feathers"
import { MECHANIC } from "./theme"
import {
  ORIGAMI_BIRD_PATH_D,
  ORIGAMI_BIRD_ROTATION_EXTRA_DEG,
  ORIGAMI_BIRD_ROTATION_OFFSET_DEG,
  ORIGAMI_BIRD_VIEWBOX,
} from "./origami-bird"

function createOrigamiBirdSvg(fill) {
  const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg")
  svg.setAttribute("viewBox", ORIGAMI_BIRD_VIEWBOX)
  svg.setAttribute("xmlns", "http://www.w3.org/2000/svg")
  svg.setAttribute("aria-hidden", "true")
  svg.style.overflow = "visible"
  const path = document.createElementNS("http://www.w3.org/2000/svg", "path")
  path.setAttribute("d", ORIGAMI_BIRD_PATH_D)
  path.setAttribute("fill", fill || "currentColor")
  svg.appendChild(path)
  return svg
}

/** Faint contrail behind the bird (local −x = behind when wrap is rotated to face). */
function trailGradientFromFill(fill) {
  const m = /^#?([0-9a-f]{6})$/i.exec(String(fill || "").trim())
  if (!m) {
    return "linear-gradient(90deg, transparent, rgba(255,255,255,0.04), rgba(200,200,210,0.1))"
  }
  const h = m[1]
  const r = Number.parseInt(h.slice(0, 2), 16)
  const g = Number.parseInt(h.slice(2, 4), 16)
  const b = Number.parseInt(h.slice(4, 6), 16)
  return `linear-gradient(90deg, rgba(${r},${g},${b},0) 0%, rgba(${r},${g},${b},0.05) 35%, rgba(${r},${g},${b},0.12) 100%)`
}

function createBirdWrap(px, color, zBase) {
  const wrap = document.createElement("div")
  wrap.style.cssText =
    `position:absolute;width:${px}px;height:${px}px;will-change:transform,opacity;z-index:${zBase}`

  const trail = document.createElement("div")
  trail.setAttribute("aria-hidden", "true")
  const tw = Math.round(px * 1.35)
  trail.style.cssText = [
    "position:absolute",
    "left:50%",
    "top:50%",
    `width:${tw}px`,
    "height:1.5px",
    "margin-top:-0.75px",
    "transform:translate(-100%,0)",
    "transform-origin:right center",
    "z-index:0",
    `background:${trailGradientFromFill(color)}`,
    "opacity:0.42",
    "pointer-events:none",
  ].join(";")

  const svg = createOrigamiBirdSvg(color)
  svg.style.width = `${px}px`
  svg.style.height = `${px}px`
  svg.style.position = "relative"
  svg.style.zIndex = "1"
  svg.style.filter =
    px >= 52
      ? "drop-shadow(0 3px 12px rgba(0,0,0,0.35))"
      : "drop-shadow(0 2px 6px rgba(0,0,0,0.26))"

  wrap.appendChild(trail)
  wrap.appendChild(svg)
  return wrap
}

export const animate = {
  featherBurst,

  /**
   * Origami bird flies across the pile zone (bottom-left → upper-right). Used for challenge wins.
   * @param {HTMLElement} anchorEl — pile drop zone
   * @param {{ color?: string }} [opts]
   */
  origamiBirdFlyAcross(anchorEl, { color = "#a1a1aa" } = {}) {
    if (!anchorEl) return
    const rect = anchorEl.getBoundingClientRect()
    if (rect.width === 0 && rect.height === 0) return

    const overlay = document.createElement("div")
    overlay.style.cssText =
      `position:fixed;left:${rect.left}px;top:${rect.top}px;width:${rect.width}px;height:${rect.height}px;pointer-events:none;z-index:60;overflow:visible`

    const FLIGHT_EASE = "sine.inOut"
    /** Nearly identical speeds (tiny jitter so it doesn’t look robotic) */
    const D_BASE = 1.0
    const durJitter = [0, 0.008, -0.008, 0.005, -0.005, 0.003, -0.003]

    const x0 = rect.width * 0.06
    const y0 = rect.height * 0.82
    const x1 = rect.width * 0.9
    const y1 = rect.height * 0.08

    const vx = x1 - x0
    const vy = y1 - y0
    const len = Math.hypot(vx, vy) || 1
    const ux = vx / len
    const uy = vy / len
    const px = -vy / len
    const py = vx / len

    const baseSide = Math.min(rect.width, rect.height) * 0.052
    const ahead = len * 0.052
    const wingTaper = 0.9

    const at = (xb, yb, along, side) => ({
      x: xb + ux * along + px * side,
      y: yb + uy * along + py * side,
    })

    // V: lead at tip; three staggered pairs behind (along −flight, ±perpendicular)
    const rows = [
      { w: 68, z: 20, a0: ahead, a1: 0, s0: 0, s1: 0, op: 1, sc0: 0.9, sc1: 1 },
      { w: 40, z: 15, a0: -len * 0.07, a1: -len * 0.038, s0: baseSide, s1: baseSide * wingTaper, op: 0.9, sc0: 0.84, sc1: 0.95 },
      { w: 40, z: 15, a0: -len * 0.07, a1: -len * 0.038, s0: -baseSide, s1: -baseSide * wingTaper, op: 0.9, sc0: 0.84, sc1: 0.95 },
      { w: 34, z: 13, a0: -len * 0.125, a1: -len * 0.072, s0: baseSide * 1.65, s1: baseSide * 1.55 * wingTaper, op: 0.85, sc0: 0.8, sc1: 0.92 },
      { w: 34, z: 13, a0: -len * 0.125, a1: -len * 0.072, s0: -baseSide * 1.65, s1: -baseSide * 1.55 * wingTaper, op: 0.85, sc0: 0.8, sc1: 0.92 },
      { w: 28, z: 11, a0: -len * 0.18, a1: -len * 0.105, s0: baseSide * 2.35, s1: baseSide * 2.2 * wingTaper, op: 0.8, sc0: 0.76, sc1: 0.88 },
      { w: 28, z: 11, a0: -len * 0.18, a1: -len * 0.105, s0: -baseSide * 2.35, s1: -baseSide * 2.2 * wingTaper, op: 0.8, sc0: 0.76, sc1: 0.88 },
    ]

    // Screen y increases downward — use -vy so “up-right” matches atan2 in visual space
    const flightDeg = (Math.atan2(-vy, vx) * 180) / Math.PI
    const rotation =
      flightDeg + ORIGAMI_BIRD_ROTATION_OFFSET_DEG + ORIGAMI_BIRD_ROTATION_EXTRA_DEG

    const wraps = []
    for (let i = 0; i < rows.length; i++) {
      const r = rows[i]
      const wrap = createBirdWrap(r.w, color, r.z)
      const p0 = at(x0, y0, r.a0, r.s0)
      const p1 = at(x1, y1, r.a1, r.s1)
      gsap.set(wrap, {
        left: p0.x,
        top: p0.y,
        x: -r.w / 2,
        y: -r.w / 2,
        rotation,
        opacity: r.op,
        scale: r.sc0,
      })
      overlay.appendChild(wrap)
      wraps.push({
        wrap,
        p1,
        sc1: r.sc1,
        duration: D_BASE + (durJitter[i] ?? 0),
      })
    }
    document.body.appendChild(overlay)

    const maxFlight = Math.max(...wraps.map((w) => w.duration))

    const tl = gsap.timeline({ onComplete: () => overlay.remove() })
    for (const item of wraps) {
      tl.to(
        item.wrap,
        {
          left: item.p1.x,
          top: item.p1.y,
          scale: item.sc1,
          duration: item.duration,
          ease: FLIGHT_EASE,
        },
        0,
      )
    }
    tl.to(
      wraps.map((w) => w.wrap),
      { opacity: 0, duration: 0.22, ease: "sine.out" },
      maxFlight - 0.14,
    )

    return tl
  },

  cardPlay(cardEl) {
    if (!cardEl) return
    const inner = cardEl.firstElementChild
    if (!inner) return
    gsap.fromTo(inner,
      { opacity: 0, y: -14, scale: 0.88 },
      { opacity: 1, y: 0, scale: 1, duration: 0.2, ease: "back.out(1.5)" }
    )
  },

  slapHit(pileEl) {
    if (!pileEl) return
    const cards = pileEl.querySelectorAll(":scope > div")
    gsap.killTweensOf(cards)
    const tl = gsap.timeline()
    tl.fromTo(cards,
      { scale: 1 },
      { scale: 0.9, duration: 0.06, ease: "power2.in" })
      .to(cards, { scale: 1, duration: 0.2, ease: "elastic.out(1, 0.35)" })
    return tl
  },

  /**
   * Big angled text splash centered on anchorEl (the pile zone).
   * @param {string} opts.text — display text
   * @param {string} opts.color — CSS color for the text
   * @param {string} [opts.sub] — optional smaller subtitle below
   */
  pileOverlayText(anchorEl, { text, color, sub }) {
    if (!anchorEl) return
    const rect = anchorEl.getBoundingClientRect()
    if (rect.width === 0 && rect.height === 0) return

    const overlay = document.createElement("div")
    overlay.style.cssText = `position:fixed;left:${rect.left}px;top:${rect.top}px;width:${rect.width}px;height:${rect.height}px;pointer-events:none;z-index:65;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:2px;`

    const label = document.createElement("span")
    const shadow = `0 0 20px ${color}99, 0 0 40px ${color}44, 0 2px 8px rgba(0,0,0,0.5)`
    label.style.cssText = `font-size:32px;font-weight:900;letter-spacing:0.1em;text-transform:uppercase;color:${color};text-shadow:${shadow};transform:rotate(-12deg);white-space:nowrap;user-select:none;`
    label.textContent = text
    overlay.appendChild(label)

    if (sub) {
      const subEl = document.createElement("span")
      subEl.style.cssText = `font-size:14px;font-weight:700;letter-spacing:0.06em;text-transform:uppercase;color:${color}cc;text-shadow:0 1px 6px rgba(0,0,0,0.5);transform:rotate(-12deg);white-space:nowrap;user-select:none;`
      subEl.textContent = sub
      overlay.appendChild(subEl)
    }

    document.body.appendChild(overlay)

    const tl = gsap.timeline({ onComplete: () => overlay.remove() })
    tl.fromTo(overlay,
      { opacity: 0, scale: 0.5 },
      { opacity: 1, scale: 1, duration: 0.15, ease: "back.out(2.2)" },
    )
    tl.to(overlay, { opacity: 0, scale: 1.08, duration: 0.3, ease: "power2.in" }, "+=0.6")

    return tl
  },

  /**
   * Shows +N / -N under the player's hand count after a slap (hand size change).
   */
  slapHandDelta(el, { delta }) {
    if (!el || delta === 0) return
    gsap.killTweensOf(el)
    const pos = delta > 0
    const text = delta > 0 ? `+${delta}` : `${delta}`
    el.textContent = text
    el.className =
      "text-[11px] font-mono font-bold leading-tight min-h-[14px] text-center pointer-events-none"
    el.style.color = pos ? MECHANIC.handDeltaGain : MECHANIC.handDeltaLoss

    const tl = gsap.timeline({
      onComplete: () => {
        el.textContent = ""
        el.style.color = ""
        el.className =
          "text-[11px] font-mono font-bold leading-tight min-h-[14px] text-center opacity-0 pointer-events-none text-zinc-800 dark:text-zinc-200"
      },
    })
    tl.fromTo(el, { opacity: 0, y: 4 }, { opacity: 1, y: 0, duration: 0.22, ease: "power2.out" })
      .to(el, { opacity: 0, duration: 0.4, delay: 0.5, ease: "power2.in" })

    return tl
  },

  pileCollect(pileEl) {
    if (!pileEl) return
    gsap.killTweensOf(pileEl)
    gsap.fromTo(pileEl,
      { opacity: 1 },
      { opacity: 0, duration: 0.25, ease: "power2.in" }
    )
  },

  countBump(countEl) {
    if (!countEl) return
    gsap.fromTo(countEl,
      { scale: 1 },
      { scale: 1.1, duration: 0.08, ease: "power2.out",
        yoyo: true, repeat: 1 }
    )
  },

  gameOver(bannerEl) {
    if (!bannerEl) return
    gsap.fromTo(bannerEl,
      { opacity: 0, y: 16 },
      { opacity: 1, y: 0, duration: 0.4, ease: "power3.out" }
    )
  },
}
