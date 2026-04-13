import gsap from "gsap"
import {
  cardIdentityKey,
  formatCard,
  playerFill,
  createCardElement,
  createCardBackElement,
} from "./cards"
import { MECHANIC } from "./theme"
import { flashEventDedupeKey, EVENT_FLASH_MS } from "./flash-key"
import { createPlayerAvatarSvg } from "./avatars"
import { animate } from "./animations"

/** GSAP delay before flash fades; scales with EVENT_FLASH_MS (was +=2.0 at 3000ms). */
const EVENT_FLASH_HOLD_SEC = Math.max(0.75, (EVENT_FLASH_MS / 3000) * 2.0)

/** Hex + two-digit alpha (same pattern as card backs). */
function hexWithAlpha(hex, alpha01) {
  const a = Math.round(Math.max(0, Math.min(1, alpha01)) * 255)
    .toString(16)
    .padStart(2, "0")
  return `${hex}${a}`
}

/** Scale for face cards in the event-flash strip (full card is 140×196 CSS px). */
const EVENT_FLASH_CARD_SCALE = 0.68

/**
 * Readable miniatures for the event flash (slap pattern / challenge card).
 * Scaled faces so ranks / suits stay easy to read in the strip.
 */
function appendEventFlashMiniCards(container, cards) {
  if (!cards || cards.length === 0) return
  const scale = EVENT_FLASH_CARD_SCALE
  const w = Math.round(140 * scale)
  const h = Math.round(196 * scale)
  const row = el("div", "flex items-end justify-center gap-2.5 sm:gap-3 flex-wrap w-full")
  for (const card of cards) {
    const holder = el(
      "div",
      "relative shrink-0 overflow-hidden rounded-lg bg-zinc-200/90 shadow-[0_6px_16px_rgba(0,0,0,0.12)] ring-1 ring-zinc-300/70 dark:bg-zinc-800/55 dark:shadow-[0_6px_16px_rgba(0,0,0,0.28)] dark:ring-zinc-500/25",
    )
    holder.style.width = `${w}px`
    holder.style.height = `${h}px`
    const face = createCardElement(card)
    face.style.position = "absolute"
    face.style.left = "0"
    face.style.top = "0"
    face.style.transform = `scale(${scale})`
    face.style.transformOrigin = "top left"
    holder.appendChild(face)
    row.appendChild(holder)
  }
  container.appendChild(row)
}

/**
 * Turn ring: mechanic mint = your turn (idle); mechanic orange = about to play / play_intent.
 * (Player seat colors are only on deck backs + avatar art — never used for this ring.)
 */
function turnGlowState(player, game, aboutToPlayPlayerIdx) {
  const idx = player.idx
  if (!player.alive) return { glowing: false, color: null }
  const isTurn = idx === game.current_player_idx
  if (!isTurn) return { glowing: false, color: null }
  const aboutToPlay = aboutToPlayPlayerIdx != null && aboutToPlayPlayerIdx === idx
  return {
    glowing: true,
    color: aboutToPlay ? MECHANIC.playIntent : MECHANIC.turnAwaitingPlay,
  }
}

function styleAvatarCircle(circle, player, glow) {
  const dead = !player.alive
  circle.className = [
    "w-11 h-11 rounded-full flex items-center justify-center border-2 transition-all",
    glow.glowing
      ? "animate-[glow-pulse_2s_ease-in-out_infinite] bg-zinc-200/90 dark:bg-zinc-700/85"
      : "border-transparent bg-zinc-200/70 dark:bg-zinc-700/45",
    dead ? "opacity-30 grayscale" : "",
  ].join(" ")
  if (glow.glowing && glow.color) {
    circle.style.setProperty("--glow-color", glow.color)
    circle.style.borderColor = glow.color
  } else {
    circle.style.removeProperty("--glow-color")
    circle.style.borderColor = ""
  }
}

export function createRenderer(container) {
  let rootEl = null
  let prevPileKey = null
  let prevStatus = null
  let currentPileEl = null
  let prevFlashKey = undefined
  let flashTimeline = null
  let deckSlideTimeline = null

  function mount() {
    container.innerHTML = ""
    rootEl = el(
      "div",
      "relative h-full flex flex-col overflow-hidden min-h-0 text-zinc-900 dark:text-zinc-50",
    )

    rootEl.appendChild(createHeader())
    rootEl.appendChild(el("div", "flex justify-center gap-2 shrink-0 px-1", "", "avatars"))

    const body = el("div", "flex-1 min-h-0 flex flex-col pb-4", "", "game-body")
    const gameArea = el("div", "flex-1 min-h-0 flex flex-col items-center gap-2", "", "game-area")
    gameArea.appendChild(
      el("div", "shrink-0 w-full max-w-2xl mx-auto", "", "history-slot"),
    )
    const pileWrap = el("div", "relative w-full flex-1 min-h-0 min-w-0 flex flex-col overflow-hidden", "", "pile-section")
    const pileSlot = el("div", "flex-1 min-h-0 min-w-0", "", "pile-slot")
    const pileFlashHost = el(
      "div",
      "shrink-0 w-full overflow-hidden pointer-events-none flex justify-center px-3",
      "",
      "pile-event-flash-host",
    )
    pileFlashHost.style.height = "0px"
    pileWrap.appendChild(pileFlashHost)
    pileWrap.appendChild(pileSlot)
    gameArea.appendChild(pileWrap)
    gameArea.appendChild(el("div", "shrink-0 w-full flex justify-center pt-1.5 pb-0.5", "", "controls-slot"))
    body.appendChild(gameArea)

    rootEl.appendChild(body)

    container.appendChild(rootEl)
  }

  function pileKey(game) {
    const top = game.pile.cards.map(c => cardIdentityKey(c.card)).join(",")
    const challengeGlow =
      game.challenger_idx !== null && game.challenge_card
        ? `${cardIdentityKey(game.challenge_card)}@${game.challenger_idx}`
        : "-"
    return `${game.pile.size}:${top}:${challengeGlow}`
  }

  function render(state, options = {}) {
    if (!rootEl) mount()
    const { game } = state
    if (!game) return null

    const aboutToPlayPlayerIdx = options.aboutToPlayPlayerIdx ?? null

    const refs = { topCard: null, pileContainer: null, gameOverBanner: null, countEls: {} }

    renderAvatars(game, state.cardDeltas, aboutToPlayPlayerIdx)

    if (game.status === "finished" && prevStatus !== "finished") {
      const body = rootEl.querySelector("#game-body")
      body.innerHTML = ""
      const banner = renderGameOver(game)
      body.appendChild(banner)
      refs.gameOverBanner = banner
      prevStatus = "finished"
    } else if (game.status !== "finished") {
      prevStatus = game.status

      const gameArea = rootEl.querySelector("#game-area")
      if (!gameArea.parentElement) {
        const body = rootEl.querySelector("#game-body")
        body.innerHTML = ""
        body.appendChild(gameArea)
      }

      const fp = state.frozenPile
      const activePile = fp || game.pile
      const newPileKey = fp
        ? `frozen:${fp.size}`
        : pileKey(game)
      if (newPileKey !== prevPileKey) {
        prevPileKey = newPileKey
        const pileSlot = rootEl.querySelector("#pile-slot")
        pileSlot.innerHTML = ""
        const challengeCard =
          !fp && game.challenger_idx !== null ? game.challenge_card : null
        const challengerIdx = !fp && game.challenger_idx !== null ? game.challenger_idx : null
        const { outer, topCardEl, pileEl } = renderPile(activePile, fp, challengeCard, challengerIdx)
        pileSlot.appendChild(outer)
        currentPileEl = pileEl
        refs.topCard = topCardEl
        refs.pileContainer = pileEl
      } else {
        refs.topCard = null
        refs.pileContainer = currentPileEl
      }

      const nextFlashKey = flashEventDedupeKey(state.eventFlash)
      const historySlot = rootEl.querySelector("#history-slot")
      const stack = ensureHistoryInfoStack(historySlot)

      stack.querySelector("#history-stats").replaceChildren(renderStatsRow(game, fp))

      const pileFlashHost = rootEl.querySelector("#pile-event-flash-host")
      if (nextFlashKey !== prevFlashKey) {
        prevFlashKey = nextFlashKey

        if (flashTimeline) {
          flashTimeline.kill()
          flashTimeline = null
        }

        if (pileFlashHost) {
          pileFlashHost.innerHTML = ""
          const controlsSlot = rootEl.querySelector("#controls-slot")

          if (nextFlashKey) {
            const flashEl = renderEventFlashInner(state.eventFlash, game)
            pileFlashHost.appendChild(flashEl)

            requestAnimationFrame(() => {
              const inner = pileFlashHost.querySelector("#event-flash-inner")
              if (!inner) return

              pileFlashHost.style.height = "auto"
              const naturalH = pileFlashHost.offsetHeight
              pileFlashHost.style.height = "0px"

              const OPEN = 0.22
              const HOLD = EVENT_FLASH_HOLD_SEC
              const CLOSE = 0.22

              // Flash host expand / content fade
              const tl = gsap.timeline({
                onComplete: () => {
                  flashTimeline = null
                  pileFlashHost.innerHTML = ""
                  pileFlashHost.style.height = "0px"
                },
              })
              tl.to(pileFlashHost, { height: naturalH, duration: OPEN, ease: "power2.out" })
              tl.fromTo(inner,
                { opacity: 0, y: -4 },
                { opacity: 1, y: 0, duration: OPEN * 0.7, ease: "power2.out" },
                "<0.04",
              )
              tl.to(inner, { opacity: 0, y: -4, duration: CLOSE, ease: "power2.in" }, `+=${HOLD}`)
              tl.to(pileFlashHost, {
                height: 0, duration: CLOSE, ease: "power2.inOut",
                onComplete: () => { pileFlashHost.innerHTML = "" },
              }, "-=0.08")
              flashTimeline = tl

              // Deck slide off-screen on open, back in on close
              if (deckSlideTimeline) { deckSlideTimeline.kill(); deckSlideTimeline = null }
              if (controlsSlot) {
                const deckH = controlsSlot.offsetHeight + 16
                const dtl = gsap.timeline({ onComplete: () => { deckSlideTimeline = null } })
                dtl.to(controlsSlot, { y: deckH, opacity: 0, duration: OPEN, ease: "power2.in" })
                dtl.to(controlsSlot, { y: 0, opacity: 1, duration: CLOSE, ease: "power2.out" }, `+=${HOLD - 0.05}`)
                deckSlideTimeline = dtl
              }
            })
          } else {
            gsap.to(pileFlashHost, {
              height: 0, duration: 0.2, ease: "power2.inOut",
              onComplete: () => { pileFlashHost.innerHTML = "" },
            })
            if (deckSlideTimeline) { deckSlideTimeline.kill(); deckSlideTimeline = null }
            if (controlsSlot) gsap.to(controlsSlot, { y: 0, opacity: 1, duration: 0.2, ease: "power2.out" })
          }
        }
      }

      const controlsSlot = rootEl.querySelector("#controls-slot")
      controlsSlot.innerHTML = ""
      controlsSlot.appendChild(renderControls(game, state.cooldown))
    }

    for (const player of game.players) {
      const countEl = rootEl.querySelector(`#count-wrap-${player.idx}`)
      if (countEl) refs.countEls[player.idx] = countEl
    }

    return refs
  }

  function createHeader() {
    const header = el("div", "flex items-center justify-between shrink-0 gap-2")
    const title = el("h1", "text-2xl font-bold tracking-tight text-zinc-900 dark:text-white")
    title.textContent = "Parakeet"
    const actions = el("div", "flex items-center gap-2")
    const themeBtn = el("button")
    themeBtn.type = "button"
    themeBtn.id = "game-theme-btn"
    themeBtn.className = [
      "rounded-lg border border-zinc-300 p-2 text-lg leading-none text-zinc-800",
      "hover:bg-zinc-200/90 transition-colors min-w-[2.25rem] min-h-[2.25rem] flex items-center justify-center",
      "dark:border-zinc-500 dark:text-zinc-100 dark:hover:bg-zinc-700/75",
    ].join(" ")
    themeBtn.setAttribute("aria-label", "Color theme")
    const leaveBtn = el(
      "button",
      [
        "rounded-lg border border-zinc-300 px-3 py-1.5 text-sm text-zinc-700",
        "hover:text-zinc-900 hover:border-zinc-500 hover:bg-zinc-200/80 transition-all",
        "dark:border-zinc-500 dark:text-zinc-200 dark:hover:text-white dark:hover:bg-zinc-700/55",
      ].join(" "),
      "Leave",
    )
    leaveBtn.id = "leave-game-btn"
    actions.appendChild(themeBtn)
    actions.appendChild(leaveBtn)
    header.appendChild(title)
    header.appendChild(actions)
    return header
  }

  function renderAvatars(game, cardDeltas, aboutToPlayPlayerIdx) {
    const wrap = rootEl.querySelector("#avatars")
    wrap.innerHTML = ""

    for (const player of game.players) {
      wrap.appendChild(renderAvatar(player, game, cardDeltas, aboutToPlayPlayerIdx))
    }
  }

  function renderAvatar(player, game, cardDeltas, aboutToPlayPlayerIdx) {
    const idx = player.idx
    const active = idx === game.current_player_idx
    const isMe = idx === game.player_idx
    const fill = playerFill(idx)

    const glow = turnGlowState(player, game, aboutToPlayPlayerIdx)

    const wrapper = el("div", "flex flex-col items-center gap-0.5 flex-1 min-w-0 max-w-[5rem]")

    const circle = el("div", "")
    circle.id = `player-avatar-${idx}`
    styleAvatarCircle(circle, player, glow)

    circle.appendChild(createPlayerAvatarSvg(player, fill, "w-7 h-7"))

    wrapper.appendChild(circle)

    const info = el("div", "text-center w-full")
    const nameEl = el("div", [
      "text-xs font-semibold truncate w-full",
      active ? "text-zinc-900 dark:text-white" : "text-zinc-600 dark:text-zinc-400",
      !player.alive ? "line-through text-zinc-400 dark:text-zinc-600" : "",
    ].join(" "), player.name)

    const delta = cardDeltas?.[idx]
    const bumpColor =
      delta === "up"
        ? MECHANIC.handDeltaGain
        : delta === "down"
          ? MECHANIC.handDeltaLoss
          : MECHANIC.handDeltaGain
    const countEl = el("div", [
      "text-lg font-bold font-mono inline-flex items-center gap-0.5",
      isMe ? "text-sky-600 dark:text-sky-400" : "text-zinc-600 dark:text-zinc-500",
    ].join(" "))

    const countSpan = el("span", "inline-block", `${player.card_count}`)
    countSpan.id = `count-wrap-${idx}`
    countSpan.style.cssText = `--bump-color: ${bumpColor}`
    countEl.appendChild(countSpan)

    const handDeltaRow = el(
      "div",
      "text-[11px] font-mono font-bold leading-tight min-h-[14px] text-center opacity-0 pointer-events-none",
      "",
    )
    handDeltaRow.id = `player-hand-delta-${idx}`
    handDeltaRow.setAttribute("aria-hidden", "true")

    info.append(nameEl, countEl, handDeltaRow)
    wrapper.appendChild(info)
    return wrapper
  }

  function renderPile(pile, frozenInfo, challengeCard, challengerIdx) {
    const frozen = !!frozenInfo
    const challengeKey =
      challengeCard && !frozen ? cardIdentityKey(challengeCard) : null
    const challengeGlowColor =
      challengeKey != null && challengerIdx != null ? playerFill(challengerIdx) : null
    const outer = el(
      "div",
      "relative w-full h-full flex flex-col items-center justify-center rounded-2xl transition-all duration-150 px-4 py-2 bg-zinc-200/40 dark:bg-zinc-800/35",
    )
    outer.id = "pile-drop-zone"
    outer.style.cssText = "touch-action: manipulation;"

    let topCardEl = null
    let pileEl = null

    const BASE_FAN_X = 36
    const BASE_FAN_Y = 3
    /** Tight steps for cards *below* the primary four so they don’t steal fan spread. */
    const DEEP_FAN_X = 14
    const DEEP_FAN_Y = 2
    /** Top this many cards in the fan stay full size; deeper (older) cards shrink and fade. */
    const PILE_PRIMARY_VISIBLE = 4
    const CARD_W = 140
    const CARD_H = 196

    if (pile.size > 0) {
      const cards = pile.cards
      const n = cards.length
      const oldest = [...cards].reverse()
      const primaryStart = Math.max(0, n - PILE_PRIMARY_VISIBLE)

      /** Lay out so the top four use full fan spacing among themselves; deeper cards stack tightly behind. */
      const xy = []
      let x = 8
      let y = 8
      for (let i = 0; i < n; i++) {
        xy.push({ x, y })
        if (i >= n - 1) break
        const prev = i
        const s = oldest[prev].angle
        const jitterX = (s % 7) - 3
        const jitterY = ((s * 3) % 9) - 4
        let dx
        let dy
        if (primaryStart === 0) {
          dx = BASE_FAN_X + jitterX
          dy = BASE_FAN_Y + jitterY
        } else if (prev < primaryStart - 1 || prev === primaryStart - 1) {
          dx = DEEP_FAN_X + jitterX
          dy = DEEP_FAN_Y + jitterY
        } else {
          dx = BASE_FAN_X + jitterX
          dy = BASE_FAN_Y + jitterY
        }
        x += dx
        y += dy
      }

      let maxR = 0
      let maxB = 0
      for (let i = 0; i < n; i++) {
        maxR = Math.max(maxR, xy[i].x + CARD_W)
        maxB = Math.max(maxB, xy[i].y + CARD_H)
      }
      const fanW = maxR + 20
      const fanH = maxB + 20

      const fan = el("div", "relative mx-auto transition-opacity duration-500")
      fan.style.cssText = `width: ${fanW}px; height: ${fanH}px;`
      if (frozen) fan.style.opacity = "0.55"
      pileEl = fan

      oldest.forEach((ct, i) => {
        const isTop = i === oldest.length - 1
        const seed = ct.angle

        const rot = isTop ? ((seed % 5) - 2) : ((seed % 11) - 5)
        const { x: px, y: py } = xy[i]

        // 0 = face-up top card; 1 = one under; … deeper cards fade and shrink.
        const fromTop = n - 1 - i
        let scale = 1
        let opacity = 1
        if (fromTop >= PILE_PRIMARY_VISIBLE) {
          const t = fromTop - (PILE_PRIMARY_VISIBLE - 1)
          scale = Math.max(0.34, 1 - 0.09 * t)
          opacity = Math.max(0.1, 1 - 0.11 * t)
        }

        const cardWrap = el("div", "absolute")
        cardWrap.style.cssText = [
          `left: ${px}px; top: ${py}px;`,
          `z-index: ${i + 1};`,
          `transform: rotate(${rot}deg) scale(${scale});`,
          `transform-origin: center center;`,
          `opacity: ${opacity};`,
          `transition: transform 0.45s ease, opacity 0.45s ease;`,
        ].join(" ")
        const cardEl = createCardElement(ct.card)
        if (challengeKey && cardIdentityKey(ct.card) === challengeKey && challengeGlowColor) {
          const c = challengeGlowColor
          cardEl.style.boxShadow = [
            `0 0 18px 4px ${hexWithAlpha(c, 0.42)}`,
            `0 0 8px 2px ${hexWithAlpha(c, 0.28)}`,
          ].join(", ")
          cardEl.style.transition = "box-shadow 0.35s ease, border-color 0.35s ease"
          cardEl.style.borderColor = hexWithAlpha(c, 0.35)
        }
        cardWrap.appendChild(cardEl)
        fan.appendChild(cardWrap)
        if (isTop) topCardEl = cardWrap
      })

      if (pile.size > n) {
        const hiddenBadge = el(
          "div",
          "absolute flex items-center justify-center rounded-full bg-white/95 border border-zinc-300 text-xs font-bold text-zinc-600 font-mono dark:bg-zinc-700/95 dark:border-zinc-500/60 dark:text-zinc-200",
        )
        hiddenBadge.style.cssText = `left: 0px; top: ${Math.round(fanH / 2 - 12)}px; z-index: 0; width: 24px; height: 24px;`
        hiddenBadge.textContent = `+${pile.size - n}`
        fan.appendChild(hiddenBadge)
      }

      outer.appendChild(fan)
    } else {
      const empty = el(
        "div",
        "w-full flex-1 rounded-xl border-2 border-dashed border-zinc-400 dark:border-zinc-700 flex items-center justify-center",
      )
      empty.innerHTML = `<span class="text-zinc-500 dark:text-zinc-600 text-sm">Drop card here</span>`
      outer.appendChild(empty)
    }

    return { outer, topCardEl, pileEl }
  }

  /** Pile count / penalty + status: frozen = next round; challenge slap window = round ending (slaps still legal). */
  const HISTORY_STACK_CLASS =
    "w-full max-h-[8rem] overflow-y-auto overflow-x-hidden overscroll-contain px-2 py-1 space-y-1 text-zinc-700 dark:text-zinc-300"

  function ensureHistoryInfoStack(historySlot) {
    let stack = historySlot.querySelector("#history-info-stack")
    if (stack) {
      stack.className = HISTORY_STACK_CLASS
      const legacyFlash = stack.querySelector("#event-flash-host")
      if (legacyFlash) legacyFlash.remove()
      stack.querySelector("#history-challenge")?.remove()
      return stack
    }
    historySlot.innerHTML = ""
    stack = el("div", HISTORY_STACK_CLASS, "", "history-info-stack")
    stack.appendChild(el("div", "shrink-0 w-full", "", "history-stats"))
    historySlot.appendChild(stack)
    return stack
  }

  function renderStatsRow(game, frozenPile) {
    const wrap = el("div", "w-full flex flex-col items-center gap-1")

    const displaySize = frozenPile ? frozenPile.size : game.pile.size
    const statsRow = el(
      "div",
      "grid grid-cols-[1fr_auto_1fr] items-center gap-x-1.5 text-[13px] leading-tight text-zinc-600 dark:text-zinc-500 w-full",
    )

    const countEl = el("span", "font-mono tabular-nums text-right", `${displaySize} in pile`)
    countEl.id = "pile-count-label"
    statsRow.appendChild(countEl)

    const sep = el("span", "text-zinc-400 dark:text-zinc-600 select-none", "\u00b7")
    statsRow.appendChild(sep)

    const penaltyColor =
      game.penalty_count > 0 ? "text-rose-600/90 dark:text-rose-400/70" : "text-zinc-600 dark:text-zinc-500"
    const penalty = el("span", `font-mono tabular-nums text-left ${penaltyColor}`, `${game.penalty_count} in penalty`)
    statsRow.appendChild(penalty)
    wrap.appendChild(statsRow)

    if (frozenPile) {
      const c = 94.248
      const freezeRow = el("div", "flex items-center justify-center gap-1.5 flex-wrap pointer-events-none")
      freezeRow.innerHTML = `
        <span class="text-[11px] font-mono font-medium text-sky-700 dark:text-sky-200/90">Next round in</span>
        <span id="slap-freeze-countdown" class="text-[11px] font-mono font-semibold tabular-nums text-zinc-800 dark:text-zinc-200">\u2014</span>
        <svg class="h-4 w-4 -rotate-90 shrink-0 text-sky-600 dark:text-sky-400/70" viewBox="0 0 36 36" aria-hidden="true">
          <circle cx="18" cy="18" r="15" fill="none" stroke="currentColor" stroke-width="2.5" class="text-zinc-300 dark:text-zinc-700/50" opacity="0.5"/>
          <circle id="slap-freeze-ring" cx="18" cy="18" r="15" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-dasharray="${c}" stroke-dashoffset="0" data-circ="${c}"/>
        </svg>
      `
      wrap.appendChild(freezeRow)
    } else if (game.challenger_idx !== null) {
      const challenger = game.players[game.challenger_idx]
      const pendingResolve = game.chances === 0 && game.pile.size > 0
      const name = challenger?.name || "?"
      const card = formatCard(game.challenge_card)
      const challengeRow = el("div", "relative flex items-center justify-center overflow-hidden min-h-[1.1rem] pointer-events-none")

      if (pendingResolve) {
        const c = 94.248
        challengeRow.innerHTML = `
          <span class="inline-flex items-center gap-1.5 flex-wrap justify-center text-[11px] font-mono text-sky-800 dark:text-sky-200/90">
            <span class="font-semibold tracking-tight">Round ending</span>
            <span id="slap-window-countdown" class="font-semibold tabular-nums text-zinc-800 dark:text-zinc-200">\u2014</span>
            <svg id="slap-window-ring-wrap" class="h-4 w-4 -rotate-90 shrink-0 text-sky-600 dark:text-sky-400/60" viewBox="0 0 36 36" aria-hidden="true">
              <circle cx="18" cy="18" r="15" fill="none" stroke="currentColor" stroke-width="2.5" class="text-zinc-300 dark:text-zinc-700/50" opacity="0.5"/>
              <circle id="slap-window-ring" cx="18" cy="18" r="15" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-dasharray="${c}" stroke-dashoffset="0" data-circ="${c}"/>
            </svg>
          </span>
        `
      } else {
        challengeRow.innerHTML = `
          <span class="inline-flex items-center gap-1 text-[11px] font-mono text-violet-900 dark:text-violet-200/80">
            <span class="font-medium text-violet-700 dark:text-violet-300/75">${name}</span>
            <span class="text-zinc-600 dark:text-zinc-400/90">${card}</span>
            <span class="text-zinc-400 dark:text-zinc-600/80">&middot;</span>
            <span class="font-medium text-zinc-800 dark:text-zinc-300">${game.chances}</span>
            <span class="text-zinc-500 dark:text-zinc-600/80">left</span>
          </span>
        `
      }
      wrap.appendChild(challengeRow)
    } else {
      const hint = el("div", "text-center pointer-events-none")
      hint.innerHTML = `<span class="text-[11px] text-zinc-600 dark:text-zinc-600 font-medium">Double-tap to slap</span>`
      wrap.appendChild(hint)
    }

    return wrap
  }

  function renderControls(game, cooldown) {
    const myTurn = game.player_idx === game.current_player_idx
    const player = game.players[game.player_idx]
    const alive = player?.alive ?? false
    const pendingChallenge = game.challenger_idx !== null && game.chances === 0
    const currentPlayer = game.players[game.current_player_idx]
    const canPlay = myTurn && alive && !cooldown && !pendingChallenge

    const wrap = el("div", "flex flex-col items-center gap-1.5 w-full max-w-[min(100%,18rem)]")

    if (!alive) {
      wrap.appendChild(el("div", "text-sm text-zinc-600 dark:text-zinc-600 font-semibold", "Eliminated"))
      return wrap
    }

    const myColor = playerFill(player.idx)
    const turnColor = playerFill(currentPlayer.idx)
    const deckColor = myTurn ? myColor : turnColor
    const deckActive = myTurn && alive

    const deckWrap = el("div", "relative scale-[0.86] origin-bottom")

    if (player.card_count > 2) {
      const stack2 = createCardBackElement(null, { color: deckColor })
      stack2.style.cssText = "position: absolute; top: 5px; left: 5px; opacity: 0.2; pointer-events: none;"
      deckWrap.appendChild(stack2)
    }
    if (player.card_count > 1) {
      const stack1 = createCardBackElement(null, { color: deckColor })
      stack1.style.cssText = "position: absolute; top: 2px; left: 2px; opacity: 0.4; pointer-events: none;"
      deckWrap.appendChild(stack1)
    }

    const deckCard = createCardBackElement(player, { color: deckColor, active: deckActive })
    deckCard.id = "player-deck-card"
    deckCard.dataset.canPlay = canPlay ? "true" : "false"
    deckCard.style.position = "relative"

    if (canPlay) {
      deckCard.style.touchAction = "none"
      deckCard.style.cursor = "grab"
    } else if (!deckActive) {
      deckCard.style.opacity = "0.35"
    }

    deckWrap.appendChild(deckCard)
    wrap.appendChild(deckWrap)

    const status = el("div", "text-xs font-semibold text-center leading-tight px-1")
    if (canPlay) {
      status.style.color = myColor
      status.innerHTML = `<span class="inline-flex items-center gap-0.5"><svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-3 h-3"><path stroke-linecap="round" stroke-linejoin="round" d="M4.5 10.5 12 3m0 0 7.5 7.5M12 3v18"/></svg>Drag to play</span>`
    } else if (myTurn && pendingChallenge) {
      status.classList.add("text-zinc-600", "dark:text-zinc-500")
      status.textContent = "Challenge resolving\u2026"
    } else {
      status.classList.add("text-zinc-600", "dark:text-zinc-500")
      status.textContent = `${currentPlayer.name}\u2019s turn`
    }
    wrap.appendChild(status)

    return wrap
  }

  function renderGameOver(game) {
    const wrap = el("div", "flex-1 flex flex-col items-center justify-center gap-4 text-center")
    wrap.innerHTML = `
      <div class="text-5xl font-black tracking-tight text-sky-600 dark:text-sky-300">Game Over</div>
      <div class="text-xl text-zinc-700 dark:text-zinc-200">
        <span class="font-bold text-zinc-900 dark:text-white">${game.winner}</span> wins!
      </div>
      <div class="text-sm text-zinc-600 dark:text-zinc-500">This game will close in 2 minutes.</div>
    `
    const backBtn = el(
      "a",
      "rounded-lg bg-sky-600 hover:bg-sky-500 dark:bg-sky-700 dark:hover:bg-sky-600 text-white px-6 py-2.5 font-semibold transition-all",
      "Back to Lobby",
    )
    backBtn.id = "back-to-lobby-btn"
    wrap.appendChild(backBtn)
    return wrap
  }

  /** Event flash panel: neutral chrome; seat hue only on icon + name. */
  function renderEventFlashInner(flash, game) {
    const winnerIdx = flash.winner_idx
    const winner = winnerIdx != null && game ? game.players[winnerIdx] : null
    const identityColor = winnerIdx != null ? playerFill(winnerIdx) : null
    const winnerName = winner ? winner.name : "?"
    const pileSize = flash.pile_size

    const flashCards =
      flash.type === "slap" && flash.slap_cards?.length
        ? flash.slap_cards
        : flash.type === "challenge_win" && flash.challenge_card
          ? [flash.challenge_card]
          : []

    const inner = el(
      "div",
      [
        "pointer-events-none w-full max-w-[min(28rem,calc(100vw-1.25rem))] mx-auto rounded-xl backdrop-blur-md flex flex-col gap-2 px-3 py-2.5 sm:px-4 sm:py-3",
        "border shadow-xl",
        "bg-white/95 border-zinc-200/90 shadow-zinc-900/10",
        "dark:bg-[linear-gradient(135deg,rgba(39,39,42,0.95),rgba(24,24,27,0.96))] dark:border-zinc-500/40 dark:shadow-zinc-900/25",
      ].join(" "),
    )
    inner.id = "event-flash-inner"

    const headerRow = el("div", "flex items-start gap-3 w-full min-w-0")

    const iconWrap = el(
      "div",
      "shrink-0 w-10 h-10 rounded-full flex items-center justify-center overflow-hidden bg-zinc-200/90 dark:bg-zinc-700/90",
    )
    if (identityColor) {
      iconWrap.style.border = `1.5px solid ${identityColor}`
      iconWrap.style.boxShadow = `0 0 0 1px ${hexWithAlpha(identityColor, 0.25)}`
    } else {
      iconWrap.style.border = "1.5px solid rgba(113,113,122,0.55)"
    }
    if (winner && identityColor) {
      iconWrap.appendChild(createPlayerAvatarSvg(winner, identityColor, "w-6 h-6"))
    }
    headerRow.appendChild(iconWrap)

    const textBlock = el("div", "flex-1 min-w-0 flex flex-col gap-1")
    const nameLine = el("div", "text-[15px] sm:text-base font-semibold leading-snug truncate")
    nameLine.textContent = winnerName
    if (identityColor) {
      nameLine.style.color = identityColor
    } else {
      nameLine.classList.add("text-zinc-900", "dark:text-zinc-100")
    }
    textBlock.appendChild(nameLine)

    let headline = ""
    let subline = ""
    if (flash.type === "slap") {
      headline = "Slap won"
      subline = flash.label || "Valid slap"
    } else if (flash.type === "challenge_win") {
      headline = "Challenge won"
      subline = flash.challenge_card ? formatCard(flash.challenge_card) : "Face-card challenge"
    }

    if (headline) {
      const hl = el(
        "div",
        "text-[11px] sm:text-xs font-semibold uppercase tracking-wide text-zinc-600 dark:text-zinc-400/95",
      )
      hl.textContent = headline
      textBlock.appendChild(hl)
    }
    if (subline) {
      const sl = el(
        "div",
        "text-xs sm:text-[13px] leading-snug text-zinc-700 dark:text-zinc-200/90 font-medium",
      )
      sl.textContent = subline
      textBlock.appendChild(sl)
    }

    headerRow.appendChild(textBlock)

    if (pileSize != null) {
      const badgeCol = el("div", "shrink-0 flex flex-col items-end gap-0.5 pt-0.5")
      const badge = el(
        "span",
        "text-sm font-mono font-bold tabular-nums rounded-lg px-2.5 py-1 leading-none bg-zinc-200/95 text-zinc-900 border border-zinc-300/90 shadow-sm dark:bg-zinc-600/90 dark:text-zinc-50 dark:border-zinc-500/50 dark:shadow-[inset_0_1px_0_rgba(255,255,255,0.08)]",
      )
      badge.textContent = `+${pileSize}`
      const badgeHint = el(
        "span",
        "text-[9px] font-medium uppercase tracking-wide text-zinc-500 dark:text-zinc-500",
      )
      badgeHint.textContent = "cards"
      badgeCol.appendChild(badge)
      badgeCol.appendChild(badgeHint)
      headerRow.appendChild(badgeCol)
    }

    inner.appendChild(headerRow)

    if (flashCards.length > 0) {
      const strip = el(
        "div",
        "w-full flex flex-col gap-1.5 pt-1 border-t border-zinc-200/90 dark:border-white/[0.08]",
      )
      const stripLabel = el(
        "div",
        "text-[10px] font-medium uppercase tracking-wide text-zinc-600 dark:text-zinc-500 text-center sm:text-left",
      )
      stripLabel.textContent = flash.type === "slap" ? "Winning pattern" : "Challenge card"
      strip.appendChild(stripLabel)
      appendEventFlashMiniCards(strip, flashCards)
      inner.appendChild(strip)
    }

    return inner
  }

  function getLeaveButton() {
    return rootEl?.querySelector("#leave-game-btn")
  }

  function getThemeButton() {
    return rootEl?.querySelector("#game-theme-btn")
  }

  function getBackToLobbyButton() {
    return rootEl?.querySelector("#back-to-lobby-btn")
  }

  function getPileZone() {
    return rootEl?.querySelector("#pile-drop-zone")
  }

  function getPileSlapFeedback() {
    return null
  }

  function getDraggableCard() {
    return rootEl?.querySelector("#player-deck-card")
  }

  /** Update turn / about-to-play ring without re-rendering avatars (safe while dragging). */
  function syncPlayerTurnGlow(game, aboutToPlayPlayerIdx) {
    if (!rootEl || !game) return
    for (const player of game.players) {
      const circle = rootEl.querySelector(`#player-avatar-${player.idx}`)
      if (!circle) continue
      styleAvatarCircle(circle, player, turnGlowState(player, game, aboutToPlayPlayerIdx))
    }
  }

  return {
    mount,
    render,
    syncPlayerTurnGlow,
    getLeaveButton,
    getThemeButton,
    getBackToLobbyButton,
    getPileZone,
    getPileSlapFeedback,
    getDraggableCard,
  }
}

function el(tag, className, text, id) {
  const e = document.createElement(tag)
  if (className) e.className = className
  if (text) e.textContent = text
  if (id) e.id = id
  return e
}
