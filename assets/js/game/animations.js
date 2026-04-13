import gsap from "gsap"
import { featherBurst } from "./feathers"
import { MECHANIC } from "./theme"

export const animate = {
  featherBurst,

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
