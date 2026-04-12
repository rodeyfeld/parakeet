import gsap from "gsap"

/**
 * Small quill for explosion particles (viewBox 0 0 24 40).
 */
export const FEATHER_SHARD_PATH = "M12 2 C4 14 4 26 12 38 C20 26 20 14 12 2 Z"

function parseHex(hex) {
  const h = hex.replace("#", "").trim()
  if (h.length === 3) {
    return {
      r: parseInt(h[0] + h[0], 16),
      g: parseInt(h[1] + h[1], 16),
      b: parseInt(h[2] + h[2], 16),
    }
  }
  return {
    r: parseInt(h.slice(0, 2), 16),
    g: parseInt(h.slice(2, 4), 16),
    b: parseInt(h.slice(4, 6), 16),
  }
}

function mixRgb(a, b, t) {
  return {
    r: Math.round(a.r + (b.r - a.r) * t),
    g: Math.round(a.g + (b.g - a.g) * t),
    b: Math.round(a.b + (b.b - a.b) * t),
  }
}

function toHex({ r, g, b }) {
  return `#${[r, g, b].map((x) => Math.max(0, Math.min(255, x)).toString(16).padStart(2, "0")).join("")}`
}

/** Several feather tints from one player accent color. */
export function paletteFromAccent(hex) {
  const rgb = parseHex(hex)
  const white = { r: 255, g: 255, b: 255 }
  const black = { r: 12, g: 12, b: 16 }
  return [
    toHex(mixRgb(rgb, white, 0.72)),
    toHex(mixRgb(rgb, white, 0.42)),
    toHex(rgb),
    toHex(mixRgb(rgb, black, 0.18)),
    toHex(mixRgb(rgb, black, 0.38)),
    toHex(mixRgb(rgb, white, 0.22)),
    toHex(mixRgb(rgb, black, 0.08)),
  ]
}

const DEFAULT_PALETTE = ["#fffbeb", "#fef3c7", "#fde68a", "#fcd34d", "#fbbf24", "#f59e0b", "#fef08a", "#e7e5e4"]

/**
 * Radial explosion from the center of `anchorEl`: feathers burst outward with independent
 * travel and spin speeds (rotation uses its own duration / linear ease).
 *
 * Pass `baseColor` (hex) to tint feathers to a player; omit for default gold mix.
 */
export function featherBurst(anchorEl, opts = {}) {
  if (!anchorEl) return

  const {
    count = 28,
    distanceMin = 55,
    distanceMax = 200,
    moveDurationMin = 0.42,
    moveDurationMax = 0.95,
    spinDurationMin = 0.28,
    spinDurationMax = 1.75,
    sizeMin = 14,
    sizeMax = 36,
    baseColor = null,
    palette: paletteOpt = null,
    /** Big finale burst when a slap resolves (server-confirmed outcome). */
    slapSurge = false,
  } = opts

  const palette =
    paletteOpt ||
    (baseColor ? paletteFromAccent(baseColor) : DEFAULT_PALETTE)

  const dramatic = Boolean(baseColor || paletteOpt)
  let countEff = count
  let distMaxEff = distanceMax
  let distMinEff = distanceMin
  let spinExtra = dramatic ? 360 : 0

  if (slapSurge) {
    distMaxEff *= 1.3
    distMinEff *= 1.1
    spinExtra += 540
  }

  const rect = anchorEl.getBoundingClientRect()
  if (rect.width === 0 && rect.height === 0) return

  const cx = rect.left + rect.width / 2
  const cy = rect.top + rect.height / 2

  const overlay = document.createElement("div")
  overlay.dataset.featherBurst = ""
  overlay.className = slapSurge
    ? "fixed pointer-events-none inset-0 z-[70] overflow-visible"
    : "fixed pointer-events-none inset-0 z-[60] overflow-visible"
  document.body.appendChild(overlay)

  const svgNS = "http://www.w3.org/2000/svg"
  const shard = FEATHER_SHARD_PATH

  for (let i = 0; i < countEff; i++) {
    const angle = Math.random() * Math.PI * 2
    const distBias = Math.pow(Math.random(), slapSurge ? 0.42 : dramatic ? 0.55 : 0.65)
    const dist = distMinEff + distBias * (distMaxEff - distMinEff)
    const endX = Math.cos(angle) * dist
    const endY = Math.sin(angle) * dist

    const rotStart = Math.random() * 360
    const spinDir = Math.random() > 0.5 ? 1 : -1
    const spinDegrees =
      280 +
      spinExtra +
      Math.random() * (slapSurge ? 1680 : 1320 + spinExtra * 0.5)

    const moveDuration = moveDurationMin + Math.random() * (moveDurationMax - moveDurationMin)
    const spinDuration = spinDurationMin + Math.random() * (spinDurationMax - spinDurationMin)

    const size = sizeMin + Math.random() * (sizeMax - sizeMin)
    const delay = Math.random() * 0.04

    const holder = document.createElement("div")
    holder.style.position = "fixed"
    holder.style.left = `${cx}px`
    holder.style.top = `${cy}px`
    holder.style.width = `${size}px`
    holder.style.height = `${size * 1.35}px`
    holder.style.marginLeft = `${-size / 2}px`
    holder.style.marginTop = `${(-size * 1.35) / 2}px`
    holder.style.willChange = "transform, opacity"

    const svg = document.createElementNS(svgNS, "svg")
    svg.setAttribute("viewBox", "0 0 24 40")
    svg.setAttribute("width", "100%")
    svg.setAttribute("height", "100%")
    svg.style.overflow = "visible"
    if (slapSurge && baseColor) {
      svg.style.filter = `drop-shadow(0 0 6px ${baseColor}88)`
    }
    if (Math.random() > 0.5) svg.style.transform = "scaleX(-1)"

    const path = document.createElementNS(svgNS, "path")
    path.setAttribute("d", shard)
    path.setAttribute("fill", palette[i % palette.length])
    path.setAttribute("opacity", slapSurge ? "1" : "0.94")
    svg.appendChild(path)
    holder.appendChild(svg)
    overlay.appendChild(holder)

    const endScale = 0.12 + Math.random() * 0.35

    gsap.set(holder, {
      x: 0, y: 0,
      scale: 0.05 + Math.random() * 0.1,
      opacity: 1,
      rotation: rotStart,
    })

    gsap.to(holder, {
      x: endX, y: endY, scale: endScale, opacity: 0,
      duration: moveDuration, delay,
      ease: "power3.out",
    })

    gsap.to(holder, {
      rotation: rotStart + spinDir * spinDegrees,
      duration: spinDuration,
      delay,
      ease: "none",
    })
  }

  const cleanupPad = slapSurge ? 0.35 : 0.15
  const cleanupMs = Math.max(
    (moveDurationMax + 0.12) * 1000,
    (spinDurationMax + 0.12) * 1000,
  )
  gsap.delayedCall(cleanupMs / 1000 + cleanupPad, () => overlay.remove())

  return overlay
}
