const SHARD = "M12 2 C4 14 4 26 12 38 C20 26 20 14 12 2 Z"

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

const stampCache = new Map()

function bakeStamp(fill, size) {
  const key = `${fill}:${size}`
  if (stampCache.has(key)) return stampCache.get(key)

  const w = size
  const h = Math.round(size * 1.667)
  const c = new OffscreenCanvas(w, h)
  const ctx = c.getContext("2d")

  const sx = w / 24
  const sy = h / 40
  ctx.scale(sx, sy)

  const p = new Path2D(SHARD)
  ctx.fillStyle = fill
  ctx.fill(p)

  stampCache.set(key, c)
  return c
}

function easeOutCubic(t) { return 1 - Math.pow(1 - t, 3) }

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
    slapSurge = false,
  } = opts

  const palette = paletteOpt || (baseColor ? paletteFromAccent(baseColor) : DEFAULT_PALETTE)

  const rect = anchorEl.getBoundingClientRect()
  if (rect.width === 0 && rect.height === 0) return

  const dpr = window.devicePixelRatio || 1
  const cx = rect.left + rect.width / 2
  const cy = rect.top + rect.height / 2

  const canvas = document.createElement("canvas")
  canvas.style.cssText = "position:fixed;inset:0;width:100%;height:100%;pointer-events:none;z-index:65;"
  const vw = window.innerWidth
  const vh = window.innerHeight
  canvas.width = vw * dpr
  canvas.height = vh * dpr
  document.body.appendChild(canvas)
  const ctx = canvas.getContext("2d")
  ctx.scale(dpr, dpr)

  const stampSize = 32
  const stamps = palette.map((fill) => bakeStamp(fill, stampSize))

  const particles = []
  for (let i = 0; i < count; i++) {
    const angle = Math.random() * Math.PI * 2
    const distBias = Math.pow(Math.random(), slapSurge ? 0.4 : 0.6)
    const dist = distanceMin + distBias * (distanceMax - distanceMin)
    const size = sizeMin + Math.random() * (sizeMax - sizeMin)

    particles.push({
      stamp: stamps[i % stamps.length],
      cx, cy,
      endX: Math.cos(angle) * dist,
      endY: Math.sin(angle) * dist,
      size,
      rotStart: Math.random() * Math.PI * 2,
      spinSpeed: (Math.random() > 0.5 ? 1 : -1) * (3 + Math.random() * (slapSurge ? 12 : 8)),
      duration: moveDurationMin + Math.random() * (moveDurationMax - moveDurationMin),
      delay: Math.random() * 0.03,
      flipX: Math.random() > 0.5,
      startScale: 0.15 + Math.random() * 0.2,
      endScale: 0.6 + Math.random() * 0.4,
      glow: slapSurge && baseColor,
    })
  }

  const maxDuration = Math.max(...particles.map((p) => p.duration + p.delay))
  const glowColor = baseColor ? `${baseColor}44` : null
  let start = null
  let frameId = null

  function frame(ts) {
    if (start === null) start = ts
    const elapsed = (ts - start) / 1000

    if (elapsed >= maxDuration + 0.05) {
      canvas.remove()
      return
    }

    ctx.clearRect(0, 0, vw, vh)

    if (glowColor && slapSurge) {
      ctx.shadowColor = glowColor
      ctx.shadowBlur = 10
    }

    for (const p of particles) {
      const t = Math.min(1, Math.max(0, (elapsed - p.delay) / p.duration))
      if (t <= 0) continue

      const ease = easeOutCubic(t)
      const x = p.cx + p.endX * ease
      const y = p.cy + p.endY * ease

      const scale = p.startScale + (p.endScale - p.startScale) * ease
      const alpha = t < 0.15 ? t / 0.15 : 1 - Math.pow(Math.max(0, t - 0.3) / 0.7, 1.5)
      if (alpha <= 0.01) continue

      const rot = p.rotStart + p.spinSpeed * elapsed
      const drawW = p.size * scale
      const drawH = drawW * 1.667

      ctx.save()
      ctx.globalAlpha = Math.max(0, Math.min(1, alpha))
      ctx.translate(x, y)
      ctx.rotate(rot)
      if (p.flipX) ctx.scale(-1, 1)
      ctx.drawImage(p.stamp, -drawW / 2, -drawH / 2, drawW, drawH)
      ctx.restore()
    }

    ctx.shadowColor = "transparent"
    ctx.shadowBlur = 0

    frameId = requestAnimationFrame(frame)
  }

  frameId = requestAnimationFrame(frame)
  return canvas
}
