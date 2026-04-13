import { flashEventDedupeKey, EVENT_FLASH_DEDUPE_MS, EVENT_FLASH_MS } from "./flash-key"

export function createState(onChange) {
  return {
    game: null,
    log: [],
    eventFlash: null,
    eventFlashTimer: null,
    cooldown: false,
    cardDeltas: {},
    frozenPile: null,
    _onChange: onChange || null,
    _dedupeFlashKey: null,
    _dedupeFlashAt: null,
  }
}

export function updateState(state, payload) {
  const oldGame = state.game
  const newGame = payload.game

  if (oldGame) {
    state.cardDeltas = computeCardDeltas(oldGame, newGame)
  }

  const flash = payload.event_flash
  const pileWon = flash && (flash.type === "slap" || flash.type === "challenge_win")

  if (
    pileWon &&
    oldGame &&
    oldGame.pile.size > 0 &&
    newGame.pile.size === 0
  ) {
    state.frozenPile = {
      cards: oldGame.pile.cards,
      size: oldGame.pile.size,
      endsAt: Date.now() + EVENT_FLASH_MS,
      durationMs: EVENT_FLASH_MS,
    }
  }

  if (state.frozenPile && newGame.pile.size > 0) {
    state.frozenPile = null
  }

  state.game = newGame

  if (payload.log) {
    state.log.push(payload.log)
  }

  if (flash) {
    const k = flashEventDedupeKey(flash)
    const now = Date.now()
    const dup =
      k != null &&
      k === state._dedupeFlashKey &&
      state._dedupeFlashAt != null &&
      now - state._dedupeFlashAt < EVENT_FLASH_DEDUPE_MS
    if (!dup) {
      if (k != null) {
        state._dedupeFlashKey = k
        state._dedupeFlashAt = now
      }
      setEventFlash(state, flash)
    }
  }

  return state
}

function setEventFlash(state, flash) {
  if (state.eventFlashTimer) clearTimeout(state.eventFlashTimer)
  if (state.cooldownTimer) clearTimeout(state.cooldownTimer)

  state.eventFlash = flash
  state.cooldown = true

  state.eventFlashTimer = setTimeout(() => {
    state.eventFlash = null
    state.frozenPile = null
    state.cooldown = false
    if (state._onChange) state._onChange()
  }, EVENT_FLASH_MS)
}

function computeCardDeltas(oldGame, newGame) {
  const deltas = {}
  for (let i = 0; i < newGame.players.length; i++) {
    const oldCount = oldGame.players[i]?.card_count ?? 0
    const newCount = newGame.players[i]?.card_count ?? 0
    if (newCount > oldCount) deltas[i] = "up"
    else if (newCount < oldCount) deltas[i] = "down"
  }
  return deltas
}
