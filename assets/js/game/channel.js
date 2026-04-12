import { Socket, LongPoll } from "phoenix"

export function createGameChannel(token, code, callbacks) {
  const socket = new Socket("/game-socket", { params: { token } })

  let wsFailCount = 0
  socket.onError(() => {
    wsFailCount++
    if (wsFailCount >= 2 && socket.transport === WebSocket) {
      socket.disconnect()
      socket.transport = LongPoll
      socket.connect()
    }
  })

  socket.connect()

  const channel = socket.channel(`game:${code}`, {})

  channel.on("game_state", (payload) => callbacks.onGameState(payload))
  channel.on("game_over", (payload) => callbacks.onGameOver(payload))
  channel.on("play_intent", (payload) => {
    if (callbacks.onPlayIntent) callbacks.onPlayIntent(payload)
  })

  channel
    .join()
    .receive("ok", () => {})
    .receive("error", (resp) => {
      if (callbacks.onError) callbacks.onError(resp)
    })

  return {
    playTurn() {
      channel.push("play_turn", {})
    },

    playIntent(active) {
      channel.push("play_intent", { active })
    },

    slap() {
      channel.push("slap", {})
    },

    leaveGame() {
      channel.push("leave_game", {}).receive("ok", () => {
        if (callbacks.onLeft) callbacks.onLeft()
      })
    },

    disconnect() {
      channel.leave()
      socket.disconnect()
    },
  }
}
