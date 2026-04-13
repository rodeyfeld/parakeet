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
  }
}

const EVENT_FLASH_MS = 3000

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
    setEventFlash(state, flash)
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
