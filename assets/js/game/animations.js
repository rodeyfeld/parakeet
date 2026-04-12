import gsap from "gsap"
import { featherBurst } from "./feathers"

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
   * Angled text overlay centered on anchorEl (the pile zone).
   * Bad slap → red "BAD SLAP"; good slap → green rule name (e.g. "SANDWICH").
   * Appears with the feather burst and fades out with it.
   */
  slapOverlayText(anchorEl, { text, good }) {
    if (!anchorEl) return
    const rect = anchorEl.getBoundingClientRect()
    if (rect.width === 0 && rect.height === 0) return

    const overlay = document.createElement("div")
    overlay.style.cssText = `position:fixed;left:${rect.left}px;top:${rect.top}px;width:${rect.width}px;height:${rect.height}px;pointer-events:none;z-index:65;display:flex;align-items:center;justify-content:center;`

    const label = document.createElement("span")
    const color = good ? "rgb(52 211 153)" : "rgb(248 113 113)"
    const shadow = good
      ? "0 0 20px rgba(52,211,153,0.6), 0 0 40px rgba(52,211,153,0.3), 0 2px 8px rgba(0,0,0,0.5)"
      : "0 0 20px rgba(248,113,113,0.6), 0 0 40px rgba(248,113,113,0.3), 0 2px 8px rgba(0,0,0,0.5)"
    label.style.cssText = `font-size:28px;font-weight:900;letter-spacing:0.12em;text-transform:uppercase;color:${color};text-shadow:${shadow};transform:rotate(-12deg);white-space:nowrap;user-select:none;`
    label.textContent = text
    overlay.appendChild(label)
    document.body.appendChild(overlay)

    const tl = gsap.timeline({ onComplete: () => overlay.remove() })
    tl.fromTo(label,
      { opacity: 0, scale: 0.5 },
      { opacity: 1, scale: 1, duration: 0.15, ease: "back.out(2)" },
    )
    tl.to(label, { opacity: 0, scale: 1.1, duration: 0.25, ease: "power2.in" }, "+=0.5")

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
    el.className = [
      "text-[11px] font-mono font-bold leading-tight min-h-[14px] text-center pointer-events-none",
      pos ? "text-emerald-400" : "text-red-400",
    ].join(" ")

    const tl = gsap.timeline({
      onComplete: () => {
        el.textContent = ""
        el.className =
          "text-[11px] font-mono font-bold leading-tight min-h-[14px] text-center opacity-0 pointer-events-none"
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
