import { createPlayerAvatarSvg } from "./avatars"

const SUIT_SYMBOLS = {
  hearts: "♥",
  diamonds: "♦",
  clubs: "♣",
  spades: "♠",
}

const SUIT_COLORS_CARD = {
  hearts: "text-red-600",
  diamonds: "text-red-600",
  clubs: "text-zinc-800",
  spades: "text-zinc-800",
}

const PLAYER_FILLS = ["#34d399", "#38bdf8", "#fbbf24", "#fb7185", "#a78bfa"]

export function suitSymbol(suit) {
  return SUIT_SYMBOLS[suit] || ""
}

function suitColorCard(suit) {
  return SUIT_COLORS_CARD[suit] || "text-zinc-800"
}

export function formatFace(card) {
  if (!card) return ""
  switch (card.face) {
    case "ace": return "A"
    case "king": return "K"
    case "queen": return "Q"
    case "jack": return "J"
    case "number": return `${card.value}`
    default: return ""
  }
}

export function formatCard(card) {
  if (!card) return "none"
  return `${formatFace(card)}${suitSymbol(card.suit)}`
}

export function playerFill(idx) {
  return PLAYER_FILLS[idx] || "#a1a1aa"
}

export function createCardElement(card) {
  const colorClass = suitColorCard(card.suit)
  const face = formatFace(card)
  const suit = suitSymbol(card.suit)

  const el = document.createElement("div")
  el.className = "w-[140px] h-[196px] rounded-xl bg-white border border-zinc-300 relative overflow-hidden select-none"
  el.innerHTML = `
    <div class="absolute top-2 left-2.5 flex flex-col items-center leading-none ${colorClass}">
      <span class="text-xl font-bold">${face}</span>
      <span class="text-sm">${suit}</span>
    </div>
    <div class="absolute bottom-2 right-2.5 flex flex-col items-center leading-none rotate-180 ${colorClass}">
      <span class="text-xl font-bold">${face}</span>
      <span class="text-sm">${suit}</span>
    </div>
    <div class="absolute inset-0 flex items-center justify-center ${colorClass}">
      <span class="text-5xl">${suit}</span>
    </div>
  `
  return el
}

/**
 * @param {object} [player] — when set (your deck), shows avatar + count inside the frame
 * @param {object} [opts]
 * @param {string} [opts.color] — hex colour for the card chrome (defaults to player fill or #34d399)
 * @param {boolean} [opts.active] — true = saturated + glow; false = dim
 */
export function createCardBackElement(player, opts = {}) {
  const c = opts.color || (player ? playerFill(player.idx) : "#34d399")
  const on = !!opts.active

  const el = document.createElement("div")
  el.className = "w-[100px] h-[140px] rounded-xl shadow-lg relative select-none transition-[background,box-shadow] duration-300"

  const bgFrom = `color-mix(in srgb, ${c} ${on ? 30 : 16}%, #0c0c0c)`
  const bgVia  = `color-mix(in srgb, ${c} ${on ? 22 : 10}%, #0a0a0a)`
  const bgTo   = `color-mix(in srgb, ${c} ${on ? 16 : 6}%, #080808)`
  el.style.background = `linear-gradient(to bottom right, ${bgFrom}, ${bgVia}, ${bgTo})`
  if (on) el.style.boxShadow = `0 0 20px 3px ${c}35, 0 0 6px 1px ${c}20`

  const border1 = on ? `${c}45` : `${c}18`
  const border2 = on ? `${c}30` : `${c}10`
  const hatchOp = on ? 0.07 : 0.03

  const clipped = document.createElement("div")
  clipped.className = "absolute inset-0 rounded-xl overflow-hidden pointer-events-none"
  clipped.innerHTML = `
    <div class="absolute inset-[3px] rounded-lg" style="border:1px solid ${border1}">
      <div class="absolute inset-1.5 rounded-md overflow-hidden" style="border:1px solid ${border2}">
        <div class="absolute inset-0" style="opacity:${hatchOp};background-image:repeating-linear-gradient(45deg,transparent,transparent 4px,${c} 4px,${c} 5px)"></div>
      </div>
    </div>
  `
  el.appendChild(clipped)

  const center = document.createElement("div")
  center.className = "absolute inset-0 flex items-center justify-center pointer-events-none"
  const ring = document.createElement("div")
  ring.className = "w-10 h-10 rounded-full flex items-center justify-center shadow-inner"
  ring.style.cssText = `border:2px solid ${on ? c + '45' : c + '20'};background:color-mix(in srgb, ${c} 6%, #080808);`
  if (player) {
    ring.appendChild(createPlayerAvatarSvg(player, playerFill(player.idx), "w-6 h-6"))
  } else {
    const p = document.createElement("span")
    p.className = "text-sm font-black tracking-tight"
    p.style.color = `${c}55`
    p.textContent = "P"
    ring.appendChild(p)
  }
  center.appendChild(ring)
  el.appendChild(center)

  if (player) {
    const count = document.createElement("div")
    count.className = "absolute bottom-1.5 left-1 right-1 text-center text-[11px] font-bold font-mono tabular-nums drop-shadow-sm"
    count.style.color = on ? `color-mix(in srgb, ${c} 90%, white)` : `color-mix(in srgb, ${c} 60%, white)`
    count.textContent = `${player.card_count}`
    count.id = "player-deck-count"
    el.appendChild(count)
  }

  return el
}
