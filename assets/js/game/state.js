export function createState(onChange) {
  return {
    game: null,
    log: [],
    eventFlash: null,
    eventFlashTimer: null,
    cooldown: false,
    cooldownTimer: null,
    cardDeltas: {},
    frozenPile: null,
    _onChange: onChange || null,
  }
}

const EVENT_FLASH_MS = 3000
const COOLDOWN_MS = 1500
const SLAP_FREEZE_MS = 3000

export function updateState(state, payload) {
  const oldGame = state.game
  const newGame = payload.game

  if (oldGame) {
    state.cardDeltas = computeCardDeltas(oldGame, newGame)
  }

  if (
    payload.event_flash?.type === "slap" &&
    oldGame &&
    oldGame.pile.size > 0 &&
    newGame.pile.size === 0
  ) {
    state.frozenPile = {
      cards: oldGame.pile.cards,
      size: oldGame.pile.size,
      label: payload.event_flash.label,
      endsAt: Date.now() + SLAP_FREEZE_MS,
      durationMs: SLAP_FREEZE_MS,
    }
  }

  if (state.frozenPile && newGame.pile.size > 0) {
    state.frozenPile = null
  }

  state.game = newGame

  if (payload.log) {
    state.log.push(payload.log)
  }

  if (payload.event_flash) {
    setEventFlash(state, payload.event_flash)
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
    if (state._onChange) state._onChange()
  }, EVENT_FLASH_MS)

  state.cooldownTimer = setTimeout(() => {
    state.cooldown = false
    if (state._onChange) state._onChange()
  }, COOLDOWN_MS)
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
