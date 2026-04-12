import gsap from "gsap"
import { formatCard, playerFill, createCardElement, createCardBackElement } from "./cards"
import { createPlayerAvatarSvg } from "./avatars"
import { animate } from "./animations"

function eventFlashKey(flash) {
  if (!flash) return null
  return `${flash.type}|${flash.label}|${flash.detail}`
}

const TURN_GLOW_GREEN = "#34d399"
/** Amber: current player is about to play (dragging card, or server play_intent — e.g. bot wind-up). */
const ABOUT_TO_PLAY_GLOW = "#eab308"

/**
 * Green = their turn, not yet committing a play.
 * Amber = about to play (local deck drag, remote intent from another human, or bot pre-play glow).
 */
function turnGlowState(player, game, aboutToPlayPlayerIdx) {
  const idx = player.idx
  if (!player.alive) return { glowing: false, color: null }
  const isTurn = idx === game.current_player_idx
  if (!isTurn) return { glowing: false, color: null }
  const aboutToPlay = aboutToPlayPlayerIdx != null && aboutToPlayPlayerIdx === idx
  return {
    glowing: true,
    color: aboutToPlay ? ABOUT_TO_PLAY_GLOW : TURN_GLOW_GREEN,
  }
}

function styleAvatarCircle(circle, player, glow) {
  const dead = !player.alive
  circle.className = [
    "w-11 h-11 rounded-full flex items-center justify-center border-2 transition-all",
    glow.glowing ? "animate-[glow-pulse_2s_ease-in-out_infinite] bg-zinc-800/80" : "border-transparent bg-zinc-800/40",
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

  function mount() {
    container.innerHTML = ""
    rootEl = el("div", "relative h-full flex flex-col overflow-hidden")

    rootEl.appendChild(createHeader())
    rootEl.appendChild(el("div", "flex justify-center gap-2 shrink-0 px-1", "", "avatars"))

    const body = el("div", "flex-1 min-h-0 flex flex-col pb-32 sm:pb-28", "", "game-body")
    const gameArea = el("div", "flex-1 min-h-0 flex flex-col items-center gap-2", "", "game-area")
    gameArea.appendChild(
      el("div", "shrink-0 w-full max-w-2xl mx-auto", "", "history-slot"),
    )
    const pileWrap = el("div", "relative w-full flex-1 min-h-0 min-w-0 flex flex-col overflow-hidden", "", "pile-section")
    const pileSlot = el("div", "flex-1 min-h-0 min-w-0", "", "pile-slot")
    const pileFlashHost = el(
      "div",
      "absolute inset-x-0 top-0 z-20 pointer-events-none flex items-start justify-center px-3 pt-2",
      "",
      "pile-event-flash-host",
    )
    pileFlashHost.style.opacity = "0"
    pileWrap.appendChild(pileSlot)
    pileWrap.appendChild(pileFlashHost)
    gameArea.appendChild(pileWrap)
    gameArea.appendChild(el("div", "shrink-0 w-full flex justify-center pt-1.5 pb-0.5", "", "controls-slot"))
    body.appendChild(gameArea)

    rootEl.appendChild(body)

    const drawers = el("div", "absolute bottom-0 inset-x-0 z-30 flex flex-col gap-1.5 px-1 pb-2", "", "game-drawers")
    drawers.appendChild(createGameLog())
    drawers.appendChild(createGameRules())
    rootEl.appendChild(drawers)

    container.appendChild(rootEl)
  }

  function pileKey(game) {
    const top = game.pile.cards.map(c => `${c.card.face}-${c.card.suit}`).join(",")
    return `${game.pile.size}:${top}`
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
        const { outer, topCardEl, pileEl } = renderPile(activePile, fp)
        pileSlot.appendChild(outer)
        currentPileEl = pileEl
        refs.topCard = topCardEl
        refs.pileContainer = pileEl
      } else {
        refs.topCard = null
        refs.pileContainer = currentPileEl
      }

      const nextFlashKey = eventFlashKey(state.eventFlash)
      const historySlot = rootEl.querySelector("#history-slot")
      const stack = ensureHistoryInfoStack(historySlot)

      stack.querySelector("#history-stats").replaceChildren(renderStatsRow(game, fp))
      stack.querySelector("#history-challenge").replaceChildren(renderChallengeRow(game))

      const pileFlashHost = rootEl.querySelector("#pile-event-flash-host")
      if (nextFlashKey !== prevFlashKey) {
        prevFlashKey = nextFlashKey

        if (flashTimeline) {
          flashTimeline.kill()
          flashTimeline = null
        }

        if (pileFlashHost) {
          pileFlashHost.innerHTML = ""
          if (nextFlashKey) {
            const flashEl = renderEventFlashInner(state.eventFlash, game)
            pileFlashHost.appendChild(flashEl)

            requestAnimationFrame(() => {
              const inner = pileFlashHost.querySelector("#event-flash-inner")
              if (!inner) return

              const tl = gsap.timeline({
                onComplete: () => {
                  flashTimeline = null
                  pileFlashHost.innerHTML = ""
                  gsap.set(pileFlashHost, { opacity: 0 })
                },
              })

              gsap.set(pileFlashHost, { opacity: 1 })
              gsap.set(inner, { opacity: 0, scale: 0.7, y: -12 })

              tl.to(inner, {
                opacity: 1, scale: 1, y: 0,
                duration: 0.35, ease: "back.out(1.4)",
              })

              tl.to(inner, {
                opacity: 0, scale: 0.85, y: -8,
                duration: 0.4, ease: "power2.in",
              }, "+=2.5")

              flashTimeline = tl
            })
          } else {
            const inner = pileFlashHost.querySelector("#event-flash-inner")
            if (inner) {
              gsap.to(inner, {
                opacity: 0, scale: 0.85, y: -8,
                duration: 0.3, ease: "power2.in",
                onComplete: () => {
                  pileFlashHost.innerHTML = ""
                  gsap.set(pileFlashHost, { opacity: 0 })
                },
              })
            } else {
              pileFlashHost.innerHTML = ""
              gsap.set(pileFlashHost, { opacity: 0 })
            }
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

    renderLog(state.log)
    return refs
  }

  function createHeader() {
    const header = el("div", "flex items-center justify-between shrink-0")
    header.innerHTML = `<h1 class="text-2xl font-bold tracking-tight">Parakeet</h1>`
    const leaveBtn = el("button",
      "rounded-lg border border-zinc-700 px-3 py-1.5 text-sm text-zinc-400 hover:text-white hover:border-zinc-500 transition-all",
      "Leave"
    )
    leaveBtn.id = "leave-game-btn"
    header.appendChild(leaveBtn)
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
      active ? "text-white" : "text-zinc-400",
      !player.alive ? "line-through text-zinc-600" : "",
    ].join(" "), player.name)

    const delta = cardDeltas?.[idx]
    const bumpColor = delta === "up" ? "#34d399" : delta === "down" ? "#ef4444" : "#34d399"
    const countEl = el("div", [
      "text-lg font-bold font-mono inline-flex items-center gap-0.5",
      isMe ? "text-sky-400" : "text-zinc-500",
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

  function renderPile(pile, frozenInfo) {
    const frozen = !!frozenInfo
    const outer = el("div", "relative w-full h-full flex flex-col items-center justify-center rounded-2xl transition-all duration-150 px-4 py-2")
    outer.id = "pile-drop-zone"
    outer.style.cssText = "touch-action: manipulation;"

    let topCardEl = null
    let pileEl = null

    const BASE_FAN_X = 36
    const BASE_FAN_Y = 3

    if (pile.size > 0) {
      const cards = pile.cards
      const n = cards.length
      const fanW = 140 + (n - 1) * BASE_FAN_X + 16
      const fanH = 196 + (n - 1) * BASE_FAN_Y + 16

      const fan = el("div", "relative mx-auto transition-opacity duration-500")
      fan.style.cssText = `width: ${fanW}px; height: ${fanH}px;`
      if (frozen) fan.style.opacity = "0.55"
      pileEl = fan

      const oldest = [...cards].reverse()
      oldest.forEach((ct, i) => {
        const isTop = i === oldest.length - 1
        const seed = ct.angle

        const rot = isTop ? ((seed % 5) - 2) : ((seed % 11) - 5)
        const jitterX = (seed % 7) - 3
        const jitterY = ((seed * 3) % 9) - 4
        const x = 8 + i * BASE_FAN_X + jitterX
        const y = 8 + i * BASE_FAN_Y + jitterY

        const cardWrap = el("div", "absolute")
        cardWrap.style.cssText = [
          `left: ${x}px; top: ${y}px;`,
          `z-index: ${i + 1};`,
          `transform: rotate(${rot}deg);`,
          `transform-origin: center center;`,
        ].join(" ")
        cardWrap.appendChild(createCardElement(ct.card))
        fan.appendChild(cardWrap)
        if (isTop) topCardEl = cardWrap
      })

      if (pile.size > n) {
        const hiddenBadge = el("div",
          "absolute flex items-center justify-center rounded-full bg-zinc-800/90 border border-zinc-600 text-xs font-bold text-zinc-400 font-mono"
        )
        hiddenBadge.style.cssText = `left: 0px; top: ${Math.round(fanH / 2 - 12)}px; z-index: 0; width: 24px; height: 24px;`
        hiddenBadge.textContent = `+${pile.size - n}`
        fan.appendChild(hiddenBadge)
      }

      outer.appendChild(fan)
    } else {
      const empty = el("div",
        "w-full flex-1 rounded-xl border-2 border-dashed border-zinc-700 flex items-center justify-center"
      )
      empty.innerHTML = `<span class="text-zinc-600 text-sm">Drop card here</span>`
      outer.appendChild(empty)
    }

    if (frozen) {
      const c = 94.248
      const freezeRow = el("div", "flex items-center justify-center gap-1.5 mt-1")
      freezeRow.innerHTML = `
        <span class="text-[11px] font-mono font-medium text-amber-300/80">${frozenInfo.label}</span>
        <svg class="h-4 w-4 -rotate-90 shrink-0 text-amber-400/70" viewBox="0 0 36 36" aria-hidden="true">
          <circle cx="18" cy="18" r="15" fill="none" stroke="currentColor" stroke-width="2.5" class="text-zinc-700/50" opacity="0.4"/>
          <circle id="slap-freeze-ring" cx="18" cy="18" r="15" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-dasharray="${c}" stroke-dashoffset="0" data-circ="${c}"/>
        </svg>
        <span id="slap-freeze-countdown" class="text-[9px] font-mono font-medium tabular-nums text-zinc-400">\u2014</span>
      `
      outer.appendChild(freezeRow)
    } else {
      const hint = el("div", "text-center pointer-events-none mt-1")
      hint.innerHTML = `<span class="text-[11px] text-zinc-600 font-medium">Double-tap to slap</span>`
      outer.appendChild(hint)
    }

    return { outer, topCardEl, pileEl }
  }

  /** Stats + challenge — round flash lives on #pile-event-flash-host so it does not push layout. */
  const HISTORY_STACK_CLASS =
    "w-full max-h-[6rem] overflow-y-auto overflow-x-hidden overscroll-contain px-2 py-1 space-y-1"

  function ensureHistoryInfoStack(historySlot) {
    let stack = historySlot.querySelector("#history-info-stack")
    if (stack) {
      stack.className = HISTORY_STACK_CLASS
      const legacyFlash = stack.querySelector("#event-flash-host")
      if (legacyFlash) legacyFlash.remove()
      return stack
    }
    historySlot.innerHTML = ""
    stack = el("div", HISTORY_STACK_CLASS, "", "history-info-stack")
    stack.appendChild(el("div", "shrink-0", "", "history-stats"))
    stack.appendChild(el("div", "shrink-0", "", "history-challenge"))
    historySlot.appendChild(stack)
    return stack
  }

  function renderStatsRow(game, frozenPile) {
    const displaySize = frozenPile ? frozenPile.size : game.pile.size
    const statsRow = el("div", "grid grid-cols-[1fr_auto_1fr] items-center gap-x-1.5 text-[13px] leading-tight text-zinc-500")

    const countEl = el("span", "font-mono tabular-nums text-right", `${displaySize} in pile`)
    countEl.id = "pile-count-label"
    statsRow.appendChild(countEl)

    const sep = el("span", "text-zinc-600 select-none", "\u00b7")
    statsRow.appendChild(sep)

    const penaltyColor = game.penalty_count > 0 ? "text-rose-400/70" : "text-zinc-500"
    const penalty = el("span", `font-mono tabular-nums text-left ${penaltyColor}`, `${game.penalty_count} in penalty`)
    statsRow.appendChild(penalty)
    return statsRow
  }

  function renderChallengeRow(game) {
    const challengeRow = el("div", "relative flex items-center justify-center overflow-hidden")

    if (game.challenger_idx !== null) {
      challengeRow.classList.add("min-h-[1.1rem]")
      const challenger = game.players[game.challenger_idx]
      const pendingResolve = game.chances === 0 && game.pile.size > 0
      const name = challenger?.name || "?"
      const card = formatCard(game.challenge_card)

      if (pendingResolve) {
        const c = 94.248
        challengeRow.innerHTML = `
          <span class="inline-flex items-center gap-1 text-[11px] font-mono text-amber-200/75">
            <span class="font-medium text-amber-300/70">${name}</span>
            <span class="text-zinc-400/90">${card}</span>
            <span class="text-zinc-500/80">&middot; done</span>
            <svg id="slap-window-ring-wrap" class="h-4 w-4 -rotate-90 shrink-0 text-amber-400/50" viewBox="0 0 36 36" aria-hidden="true">
              <circle cx="18" cy="18" r="15" fill="none" stroke="currentColor" stroke-width="2.5" class="text-zinc-700/50" opacity="0.4"/>
              <circle id="slap-window-ring" cx="18" cy="18" r="15" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-dasharray="${c}" stroke-dashoffset="0" data-circ="${c}"/>
            </svg>
            <span id="slap-window-countdown" class="text-[9px] font-medium tabular-nums text-zinc-400">\u2014</span>
          </span>
        `
      } else {
        challengeRow.innerHTML = `
          <span class="inline-flex items-center gap-1 text-[11px] font-mono text-amber-200/75">
            <span class="font-medium text-amber-300/70">${name}</span>
            <span class="text-zinc-400/90">${card}</span>
            <span class="text-zinc-600/80">&middot;</span>
            <span class="font-medium text-zinc-300">${game.chances}</span>
            <span class="text-zinc-600/80">left</span>
          </span>
        `
      }
    }

    return challengeRow
  }

  function renderControls(game, cooldown) {
    const myTurn = game.player_idx === game.current_player_idx
    const player = game.players[game.player_idx]
    const alive = player?.alive ?? false
    const pendingChallenge = game.challenger_idx !== null && game.chances === 0
    const currentPlayer = game.players[game.current_player_idx]
    const canPlay = myTurn && alive && !cooldown && !pendingChallenge

    const myColor = playerFill(player.idx)
    const turnColor = playerFill(currentPlayer.idx)
    const deckColor = myTurn ? myColor : turnColor
    const deckActive = myTurn && alive

    const wrap = el("div", "flex flex-col items-center gap-1.5 w-full max-w-[min(100%,18rem)]")

    if (!alive) {
      wrap.appendChild(el("div", "text-sm text-zinc-600 font-semibold", "Eliminated"))
      return wrap
    }

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
      status.classList.add("text-zinc-500")
      status.textContent = "Challenge resolving\u2026"
    } else {
      status.classList.add("text-zinc-500")
      status.textContent = `${currentPlayer.name}\u2019s turn`
    }
    wrap.appendChild(status)

    return wrap
  }

  function renderGameOver(game) {
    const wrap = el("div", "flex-1 flex flex-col items-center justify-center gap-4 text-center")
    wrap.innerHTML = `
      <div class="text-5xl font-black tracking-tight text-emerald-400">Game Over</div>
      <div class="text-xl text-zinc-200">
        <span class="font-bold text-white">${game.winner}</span> wins!
      </div>
      <div class="text-sm text-zinc-500">This game will close in 2 minutes.</div>
    `
    const backBtn = el("a",
      "rounded-lg bg-emerald-700 hover:bg-emerald-600 text-white px-6 py-2.5 font-semibold transition-all",
      "Back to Lobby")
    backBtn.id = "back-to-lobby-btn"
    wrap.appendChild(backBtn)
    return wrap
  }

  function renderEventFlashInner(flash, game) {
    const isSlap = flash.type === "slap"
    const isChallenge = flash.type === "challenge_win"

    const winnerIdx = flash.winner_idx
    const winner = winnerIdx != null && game ? game.players[winnerIdx] : null
    const c = winnerIdx != null ? playerFill(winnerIdx) : "#a1a1aa"
    const winnerName = winner ? winner.name : "?"

    const mix = (pct) => `color-mix(in srgb, ${c} ${pct}%, transparent)`

    const eyebrow = isSlap ? "Slap" : isChallenge ? "Challenge" : "Round"
    const headline = flash.label || (isChallenge ? "Won" : "")
    const pileSize = flash.pile_size

    const inner = el(
      "div",
      "pointer-events-none w-full max-w-[min(20rem,calc(100vw-2rem))] mx-auto rounded-2xl backdrop-blur-xl flex items-center gap-3 px-4 py-3",
    )
    inner.id = "event-flash-inner"
    inner.style.cssText = [
      `background:linear-gradient(135deg, color-mix(in srgb, ${c} 18%, #0c0c0c), color-mix(in srgb, ${c} 8%, #080808))`,
      `border:1px solid ${mix(20)}`,
      `box-shadow:0 0 30px 4px ${mix(10)}, 0 12px 32px rgba(0,0,0,0.4)`,
    ].join(";")

    const iconWrap = el("div", "shrink-0 w-10 h-10 rounded-full flex items-center justify-center overflow-hidden")
    iconWrap.style.cssText = `background:${mix(15)};border:2px solid ${mix(35)};`
    if (winner) {
      iconWrap.appendChild(createPlayerAvatarSvg(winner, c, "w-6 h-6"))
    }
    inner.appendChild(iconWrap)

    const text = el("div", "flex-1 min-w-0")
    const pileBadge = pileSize != null
      ? `<span class="inline-flex items-center gap-0.5 text-[10px] font-mono font-semibold rounded-full px-1.5 py-0.5" style="background:${mix(12)};color:${c}">${pileSize} cards</span>`
      : ""
    text.innerHTML = `
      <div class="flex items-center gap-1.5 flex-wrap">
        <span class="text-[9px] font-bold uppercase tracking-[0.18em]" style="color:${mix(70)}">${eyebrow}</span>
        ${headline ? `<span class="text-sm font-bold text-white/90">${headline}</span>` : ""}
        ${pileBadge}
      </div>
      <p class="text-xs text-white/55 leading-snug mt-0.5 truncate">${winnerName} wins the pile</p>
    `
    inner.appendChild(text)

    if (isChallenge && flash.challenge_card) {
      const cc = flash.challenge_card
      const isRed = cc.suit === "hearts" || cc.suit === "diamonds"
      const mini = el("div", "shrink-0 w-9 h-[3.25rem] rounded-lg bg-white flex flex-col items-center justify-center leading-none")
      mini.style.cssText = "box-shadow:0 2px 8px rgba(0,0,0,0.3);"
      mini.innerHTML = `<span class="text-sm font-bold ${isRed ? "text-red-600" : "text-zinc-800"}">${formatCard(cc)}</span>`
      inner.appendChild(mini)
    }

    return inner
  }

  function createGameLog() {
    const details = document.createElement("details")
    details.id = "game-log-drawer"
    details.className = "group rounded-xl border border-zinc-700 bg-zinc-900/95 backdrop-blur-xl shadow-lg"
    details.innerHTML = `
      <summary class="cursor-pointer select-none px-4 py-2.5 flex items-center justify-between text-sm font-semibold text-zinc-300 hover:text-white transition-colors">
        <span class="flex items-center gap-2">
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-4 h-4 text-zinc-500 group-open:text-emerald-400 transition-colors">
            <path stroke-linecap="round" stroke-linejoin="round" d="M8.625 9.75a.375.375 0 1 1-.75 0 .375.375 0 0 1 .75 0Zm0 0H8.25m4.125 0a.375.375 0 1 1-.75 0 .375.375 0 0 1 .75 0Zm0 0H12m4.125 0a.375.375 0 1 1-.75 0 .375.375 0 0 1 .75 0Zm0 0h-.375m-13.5 3.01c0 1.6 1.123 2.994 2.707 3.227 1.087.16 2.185.283 3.293.369V21l4.184-4.183a1.14 1.14 0 0 1 .778-.332 48.294 48.294 0 0 0 5.83-.498c1.585-.233 2.708-1.626 2.708-3.228V6.741c0-1.602-1.123-2.995-2.707-3.228A48.394 48.394 0 0 0 12 3c-2.392 0-4.744.175-7.043.513C3.373 3.746 2.25 5.14 2.25 6.741v6.018Z" />
          </svg>
          Game Log
        </span>
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-4 h-4 text-zinc-500 group-open:rotate-180 transition-transform duration-200">
          <path stroke-linecap="round" stroke-linejoin="round" d="m19.5 8.25-7.5 7.5-7.5-7.5" />
        </svg>
      </summary>
      <div class="px-4 pb-3 border-t border-zinc-800 max-h-36 overflow-y-auto">
        <div id="game-log-entries" class="space-y-1 text-sm font-mono pt-2">
          <div class="text-zinc-500">No actions yet</div>
        </div>
      </div>
    `
    return details
  }

  function renderLog(log) {
    const logEntries = rootEl.querySelector("#game-log-entries")
    if (!logEntries) return

    logEntries.innerHTML = ""
    if (log.length === 0) {
      logEntries.innerHTML = `<div class="text-zinc-500">No actions yet</div>`
      return
    }

    const reversed = [...log].reverse()
    reversed.forEach((msg, i) => {
      const row = el("div", [
        "text-zinc-400",
        i === 0 ? "text-zinc-200 font-semibold" : "",
      ].join(" "), msg)
      row.id = `log-${i}`
      logEntries.appendChild(row)
    })
  }

  function createGameRules() {
    const details = document.createElement("details")
    details.className = "group rounded-xl border border-zinc-700 bg-zinc-900/95 backdrop-blur-xl shadow-lg"
    details.innerHTML = `
      <summary class="cursor-pointer select-none px-4 py-2.5 flex items-center justify-between text-sm font-semibold text-zinc-300 hover:text-white transition-colors">
        <span class="flex items-center gap-2">
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-4 h-4 text-zinc-500 group-open:text-emerald-400 transition-colors">
            <path stroke-linecap="round" stroke-linejoin="round" d="M12 6.042A8.967 8.967 0 0 0 6 3.75c-1.052 0-2.062.18-3 .512v14.25A8.987 8.987 0 0 1 6 18c2.305 0 4.408.867 6 2.292m0-14.25a8.966 8.966 0 0 1 6-2.292c1.052 0 2.062.18 3 .512v14.25A8.987 8.987 0 0 0 18 18a8.967 8.967 0 0 0-6 2.292m0-14.25v14.25" />
          </svg>
          How to Play
        </span>
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-4 h-4 text-zinc-500 group-open:rotate-180 transition-transform duration-200">
          <path stroke-linecap="round" stroke-linejoin="round" d="m19.5 8.25-7.5 7.5-7.5-7.5" />
        </svg>
      </summary>
      <div class="px-4 pb-3 pt-1 text-sm text-zinc-400 space-y-4 border-t border-zinc-800 max-h-44 overflow-y-auto">
        <p>The deck is split evenly between all players. <strong class="text-zinc-300">Drag</strong> a card from your deck onto the pile to play. <strong class="text-zinc-300">Double-tap</strong> the pile to slap. Win by collecting all the cards.</p>
        <div>
          <h4 class="font-semibold text-zinc-200 mb-1">Slaps</h4>
          <p class="mb-2">When the pile matches any of these patterns, the first player to <strong class="text-zinc-300">double-tap</strong> the pile takes it:</p>
          <ul class="space-y-1 pl-4 list-disc marker:text-zinc-600">
            <li>Two identical cards in a row</li>
            <li>A "sandwich" &mdash; two matching cards separated by one card</li>
            <li>Three cards in numeric order</li>
            <li>Queen followed by King</li>
            <li>Two numbered cards adding up to ten</li>
          </ul>
          <p class="mt-2 text-zinc-500">Bad slap? You lose 2 cards from your hand to the bottom of the pile.</p>
        </div>
        <div>
          <h4 class="font-semibold text-zinc-200 mb-1">Challenges</h4>
          <p class="mb-2">When a face card is played, the next player must beat it by playing their own face card within a limited number of tries. If they fail, the challenger takes the pile.</p>
          <ul class="space-y-1 pl-4 list-disc marker:text-zinc-600">
            <li><span class="font-mono text-zinc-300">Jack</span> &mdash; 1 chance</li>
            <li><span class="font-mono text-zinc-300">Queen</span> &mdash; 2 chances</li>
            <li><span class="font-mono text-zinc-300">King</span> &mdash; 3 chances</li>
            <li><span class="font-mono text-zinc-300">Ace</span> &mdash; 4 chances</li>
          </ul>
          <p class="mt-2 text-zinc-500">A slap can be performed at any time during a challenge.</p>
        </div>
      </div>
    `
    return details
  }

  function getLeaveButton() {
    return rootEl?.querySelector("#leave-game-btn")
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
