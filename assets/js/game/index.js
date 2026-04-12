import { createGameChannel } from "./channel"
import { createRenderer } from "./renderer"
import { createState, updateState } from "./state"
import { animate } from "./animations"
import { audio } from "./audio"
import { playerFill } from "./cards"

const Game = {
  mounted() {
    const code = this.el.dataset.code
    const token = this.el.dataset.token

    this._lockViewport()

    this._renderer = createRenderer(this.el)
    this._renderer.mount()
    this._channel = null
    this._interactionCleanup = []
    this._isDragging = false
    this._wasInChallengeSlapWindow = false
    this._slapWindowEndsAt = null
    this._slapWindowIntervalId = null
    this._remotePlayIntentIdx = null

    this._state = createState(() => {
      if (!this._state.game) return
      this._renderer.render(this._state, this._renderOpts())
      this._bindControls()
      this._syncSlapFreezeTimer()
    })

    this._channel = createGameChannel(token, code, {
      onGameState: (payload) => {
        this._remotePlayIntentIdx = null
        const oldGame = this._state.game
        updateState(this._state, payload)
        const newGame = this._state.game
        const cardDeltas = { ...this._state.cardDeltas }
        const refs = this._renderer.render(this._state, this._renderOpts())
        this._bindControls()
        this._runAnimations(refs, oldGame, newGame, cardDeltas, payload)
        this._syncSlapWindowTimer(newGame)
        this._syncSlapFreezeTimer()
      },

      onGameOver: (payload) => {
        this._state.game = payload.game
        const refs = this._renderer.render(this._state, { aboutToPlayPlayerIdx: null })
        this._bindControls()
        requestAnimationFrame(() => {
          if (refs?.gameOverBanner) animate.gameOver(refs.gameOverBanner)
        })
      },

      onError: (resp) => {
        console.error("Failed to join game channel:", resp)
        this.el.innerHTML = `
          <div class="flex items-center justify-center min-h-[60vh]">
            <span class="text-red-400">Failed to connect to game.</span>
          </div>
        `
      },

      onLeft: () => {
        window.location.href = "/den"
      },

      onPlayIntent: ({ player_idx, active }) => {
        if (!this._state?.game) return
        if (active) {
          this._remotePlayIntentIdx = player_idx
        } else if (this._remotePlayIntentIdx === player_idx) {
          this._remotePlayIntentIdx = null
        }
        this._renderer.syncPlayerTurnGlow(this._state.game, this._aboutToPlayPlayerIdx())
      },
    })
  },

  /** Local deck drag or channel play_intent (bots ~320ms before play, humans when dragging). */
  _aboutToPlayPlayerIdx() {
    const g = this._state?.game
    if (!g) return null
    if (this._isDragging) return g.player_idx
    if (this._remotePlayIntentIdx != null) return this._remotePlayIntentIdx
    return null
  },

  _renderOpts() {
    return { aboutToPlayPlayerIdx: this._aboutToPlayPlayerIdx() }
  },

  _runAnimations(refs, oldGame, newGame, cardDeltas, payload) {
    if (!refs) return

    const pileGrew = oldGame && newGame.pile.size > oldGame.pile.size
    const pileShrank = oldGame && newGame.pile.size < oldGame.pile.size

    const badSlap =
      typeof payload.log === "string" && payload.log.toLowerCase().includes("bad slap")
    const slapOutcome = payload.event_flash?.type === "slap" || badSlap

    if (payload.event_flash) {
      if (refs.pileContainer) {
        if (pileShrank) {
          animate.pileCollect(refs.pileContainer)
          audio.pileWin()
        } else {
          animate.slapHit(refs.pileContainer)
        }
      }
      if (!pileShrank) {
        if (payload.event_flash.type === "slap") {
          audio.slapHit()
        } else {
          audio.pileWin()
        }
      }
    }

    if (slapOutcome) {
      const slapPlayerIdx = badSlap
        ? Object.keys(cardDeltas).find((k) => cardDeltas[k] === "down")
        : Object.keys(cardDeltas).find((k) => cardDeltas[k] === "up")
      const accent =
        slapPlayerIdx !== undefined ? playerFill(Number(slapPlayerIdx)) : "#a1a1aa"

      const avatarEl =
        slapPlayerIdx !== undefined
          ? document.getElementById(`player-avatar-${slapPlayerIdx}`)
          : null

      const runSlapBurst = () => {
        const pileZone = this._renderer.getPileZone()

        const overlayText = badSlap
          ? "BAD SLAP"
          : payload.event_flash?.label || "SLAP"
        if (pileZone) {
          animate.slapOverlayText(pileZone, {
            text: overlayText,
            good: !badSlap,
          })
        }

        if (pileZone) {
          animate.featherBurst(pileZone, {
            baseColor: accent,
            slapSurge: true,
            count: 44,
            distanceMin: 52,
            distanceMax: 280,
            moveDurationMin: 0.5,
            moveDurationMax: 1.28,
            spinDurationMin: 0.32,
            spinDurationMax: 2.35,
            sizeMin: 16,
            sizeMax: 54,
          })
        }
        if (avatarEl) {
          animate.featherBurst(avatarEl, {
            baseColor: accent,
            slapSurge: true,
            count: 30,
            distanceMin: 28,
            distanceMax: 118,
            moveDurationMin: 0.4,
            moveDurationMax: 1.05,
            spinDurationMin: 0.28,
            spinDurationMax: 2.05,
            sizeMin: 12,
            sizeMax: 36,
          })
        }
      }
      requestAnimationFrame(() => setTimeout(runSlapBurst, 130))

      if (oldGame && slapPlayerIdx !== undefined) {
        const pIdx = Number(slapPlayerIdx)
        const oldC = oldGame.players[pIdx]?.card_count
        const newC = newGame.players[pIdx]?.card_count
        if (oldC !== undefined && newC !== undefined) {
          const handDelta = newC - oldC
          setTimeout(() => {
            const handEl = document.getElementById(`player-hand-delta-${pIdx}`)
            if (handEl) animate.slapHandDelta(handEl, { delta: handDelta })
          }, 200)
        }
      }
    }

    if (!payload.event_flash && pileGrew && refs.topCard) {
      animate.cardPlay(refs.topCard)
      const iPlayed =
        oldGame && oldGame.current_player_idx === newGame.player_idx
      if (!iPlayed) audio.cardPlay()
    }

    for (const [idx, delta] of Object.entries(cardDeltas)) {
      const countEl = refs.countEls[idx]
      if (countEl && delta) {
        animate.countBump(countEl)
      }
    }
  },

  /**
   * After the last challenge chance, the engine waits `slap_window_ms` before awarding
   * the pile; during that time the pile can still be stolen with a valid slap.
   */
  _syncSlapWindowTimer(game) {
    const ms = typeof game.slap_window_ms === "number" ? game.slap_window_ms : 1500
    const inWindow =
      game.challenger_idx !== null &&
      game.chances === 0 &&
      game.pile.size > 0

    if (this._slapWindowIntervalId) {
      clearInterval(this._slapWindowIntervalId)
      this._slapWindowIntervalId = null
    }

    if (!inWindow) {
      this._wasInChallengeSlapWindow = false
      this._slapWindowEndsAt = null
      return
    }

    if (!this._wasInChallengeSlapWindow) {
      this._slapWindowEndsAt = Date.now() + ms
    }
    this._wasInChallengeSlapWindow = true

    const tick = () => {
      const el = document.getElementById("slap-window-countdown")
      const ring = document.getElementById("slap-window-ring")
      if (!el && !ring) {
        if (this._slapWindowIntervalId) {
          clearInterval(this._slapWindowIntervalId)
          this._slapWindowIntervalId = null
        }
        return
      }
      const end = this._slapWindowEndsAt ?? Date.now()
      const left = Math.max(0, end - Date.now())
      const p = ms > 0 ? Math.min(1, left / ms) : 0
      if (el) {
        el.textContent = `${(left / 1000).toFixed(1)}s`
      }
      if (ring) {
        const c = Number.parseFloat(ring.dataset.circ || "94.248")
        ring.style.strokeDashoffset = String(c * (1 - p))
      }
      if (left <= 0 && this._slapWindowIntervalId) {
        clearInterval(this._slapWindowIntervalId)
        this._slapWindowIntervalId = null
      }
    }
    tick()
    this._slapWindowIntervalId = setInterval(tick, 50)
  },

  _bindControls() {
    const leaveBtn = this._renderer.getLeaveButton()
    const backBtn = this._renderer.getBackToLobbyButton()

    if (leaveBtn && !leaveBtn._bound) {
      leaveBtn._bound = true
      leaveBtn.addEventListener("click", () => {
        if (this._channel) {
          this._channel.leaveGame()
        }
      })
    }

    if (backBtn && !backBtn._bound) {
      backBtn._bound = true
      backBtn.addEventListener("click", () => {
        window.location.href = "/den"
      })
    }

    this._setupInteractions()
  },

  _setupInteractions() {
    for (const fn of this._interactionCleanup) fn()
    this._interactionCleanup = []
    const oldGhost = document.getElementById("drag-ghost")
    if (oldGhost) oldGhost.remove()
    this._isDragging = false

    const pileZone = this._renderer.getPileZone()
    const deckCard = this._renderer.getDraggableCard()

    // Double-tap on pile → slap
    if (pileZone) {
      let lastTapTime = 0

      const onPointerUp = (e) => {
        if (this._isDragging) return
        const now = Date.now()
        if (now - lastTapTime < 400) {
          lastTapTime = 0
          const player = this._state.game?.players[this._state.game?.player_idx]
          if (!this._state.cooldown && this._channel && player?.alive) {
            const me = this._state.game.player_idx
            const accent = playerFill(me)
            const avatar = document.getElementById(`player-avatar-${me}`)
            animate.featherBurst(pileZone, {
              baseColor: accent,
              count: 14,
              distanceMin: 32,
              distanceMax: 130,
              sizeMin: 8,
              sizeMax: 26,
            })
            if (avatar) {
              animate.featherBurst(avatar, {
                baseColor: accent,
                count: 10,
                distanceMin: 16,
                distanceMax: 52,
                sizeMin: 8,
                sizeMax: 18,
              })
            }
            this._channel.slap()
            animate.slapHit(pileZone.querySelector(".relative") || pileZone)
            audio.slapHit()
          }
        } else {
          lastTapTime = now
        }
      }

      pileZone.addEventListener("pointerup", onPointerUp)
      this._interactionCleanup.push(() => pileZone.removeEventListener("pointerup", onPointerUp))
    }

    // Drag deck card → pile to play
    if (deckCard && deckCard.dataset.canPlay === "true") {
      let dragGhost = null
      let offsetX = 0
      let offsetY = 0
      /** True once we fire card flip SFX this gesture (first entry over pile, or on release). */
      let pileFlipSoundPlayed = false

      const onPointerDown = (e) => {
        if (deckCard.dataset.canPlay !== "true" || this._state.cooldown) return
        e.preventDefault()
        deckCard.setPointerCapture(e.pointerId)
        const rect = deckCard.getBoundingClientRect()
        offsetX = e.clientX - rect.left
        offsetY = e.clientY - rect.top
        this._isDragging = false
        this._dragStartX = e.clientX
        this._dragStartY = e.clientY
        pileFlipSoundPlayed = false
      }

      const onPointerMove = (e) => {
        if (!deckCard.hasPointerCapture(e.pointerId)) return
        const dx = e.clientX - this._dragStartX
        const dy = e.clientY - this._dragStartY

        if (!this._isDragging && (Math.abs(dx) + Math.abs(dy)) > 10) {
          this._isDragging = true
          dragGhost = deckCard.cloneNode(true)
          dragGhost.id = "drag-ghost"
          dragGhost.removeAttribute("data-can-play")
          dragGhost.querySelector("#player-deck-count")?.removeAttribute("id")
          Object.assign(dragGhost.style, {
            position: "fixed",
            pointerEvents: "none",
            zIndex: "9999",
            width: `${deckCard.offsetWidth}px`,
            height: `${deckCard.offsetHeight}px`,
            opacity: "0.98",
            transform: "translateZ(0) scale(1.04)",
            transformOrigin: "center center",
            filter: "drop-shadow(0 14px 28px rgba(0,0,0,0.42))",
            transition: "none",
            overflow: "visible",
            boxSizing: "border-box",
          })
          document.body.appendChild(dragGhost)
          deckCard.style.opacity = "0.15"
          if (this._channel) this._channel.playIntent(true)
          if (this._state.game) {
            this._renderer.syncPlayerTurnGlow(this._state.game, this._aboutToPlayPlayerIdx())
          }
        }

        if (this._isDragging && dragGhost) {
          dragGhost.style.left = `${e.clientX - offsetX}px`
          dragGhost.style.top = `${e.clientY - offsetY}px`

          const pz = this._renderer.getPileZone()
          if (pz) {
            const r = pz.getBoundingClientRect()
            const over = e.clientX >= r.left && e.clientX <= r.right &&
                         e.clientY >= r.top && e.clientY <= r.bottom
            if (
              over &&
              !pileFlipSoundPlayed &&
              !this._state.cooldown &&
              this._channel
            ) {
              audio.cardPlay()
              pileFlipSoundPlayed = true
            }
            if (over) {
              pz.style.outline = "2px solid rgba(52, 211, 153, 0.55)"
              pz.style.outlineOffset = "6px"
              dragGhost.style.transform = "translateZ(0) scale(1.07)"
              dragGhost.style.filter = "drop-shadow(0 18px 36px rgba(16, 185, 129, 0.22)) drop-shadow(0 12px 24px rgba(0,0,0,0.45))"
            } else {
              pz.style.outline = ""
              pz.style.outlineOffset = ""
              dragGhost.style.transform = "translateZ(0) scale(1.04)"
              dragGhost.style.filter = "drop-shadow(0 14px 28px rgba(0,0,0,0.42))"
            }
          }
        }
      }

      const onPointerUp = (e) => {
        if (this._isDragging && dragGhost) {
          const pz = this._renderer.getPileZone()
          if (pz) {
            const r = pz.getBoundingClientRect()
            const over = e.clientX >= r.left && e.clientX <= r.right &&
                         e.clientY >= r.top && e.clientY <= r.bottom
            if (over && !this._state.cooldown && this._channel) {
              if (!pileFlipSoundPlayed) audio.cardPlay()
              this._channel.playTurn()
            }
            pz.style.outline = ""
            pz.style.outlineOffset = ""
          }
          dragGhost.remove()
          dragGhost = null
        }
        this._isDragging = false
        deckCard.style.opacity = ""
        if (this._channel) this._channel.playIntent(false)
        if (this._state.game) {
          this._renderer.syncPlayerTurnGlow(this._state.game, this._aboutToPlayPlayerIdx())
        }
        if (deckCard.hasPointerCapture(e.pointerId)) {
          deckCard.releasePointerCapture(e.pointerId)
        }
      }

      const onPointerCancel = () => {
        if (dragGhost) { dragGhost.remove(); dragGhost = null }
        this._isDragging = false
        deckCard.style.opacity = ""
        const pz = this._renderer.getPileZone()
        if (pz) { pz.style.outline = ""; pz.style.outlineOffset = "" }
        if (this._channel) this._channel.playIntent(false)
        if (this._state.game) {
          this._renderer.syncPlayerTurnGlow(this._state.game, this._aboutToPlayPlayerIdx())
        }
      }

      deckCard.addEventListener("pointerdown", onPointerDown)
      deckCard.addEventListener("pointermove", onPointerMove)
      deckCard.addEventListener("pointerup", onPointerUp)
      deckCard.addEventListener("pointercancel", onPointerCancel)

      this._interactionCleanup.push(() => {
        deckCard.removeEventListener("pointerdown", onPointerDown)
        deckCard.removeEventListener("pointermove", onPointerMove)
        deckCard.removeEventListener("pointerup", onPointerUp)
        deckCard.removeEventListener("pointercancel", onPointerCancel)
      })
    }
  },

  _syncSlapFreezeTimer() {
    if (this._slapFreezeIntervalId) {
      clearInterval(this._slapFreezeIntervalId)
      this._slapFreezeIntervalId = null
    }
    const fp = this._state.frozenPile
    if (!fp) return

    const tick = () => {
      const countdown = document.getElementById("slap-freeze-countdown")
      const ring = document.getElementById("slap-freeze-ring")
      if (!countdown && !ring) {
        if (this._slapFreezeIntervalId) {
          clearInterval(this._slapFreezeIntervalId)
          this._slapFreezeIntervalId = null
        }
        return
      }
      const left = Math.max(0, fp.endsAt - Date.now())
      const p = fp.durationMs > 0 ? Math.min(1, left / fp.durationMs) : 0
      if (countdown) countdown.textContent = `${(left / 1000).toFixed(1)}s`
      if (ring) {
        const c = Number.parseFloat(ring.dataset.circ || "94.248")
        ring.style.strokeDashoffset = String(c * (1 - p))
      }
      if (left <= 0 && this._slapFreezeIntervalId) {
        clearInterval(this._slapFreezeIntervalId)
        this._slapFreezeIntervalId = null
      }
    }
    tick()
    this._slapFreezeIntervalId = setInterval(tick, 50)
  },

  _lockViewport() {
    const main = this.el.closest("main")
    if (main) {
      this._origMainClass = main.className
      main.className = ""
      main.style.cssText = "height:100dvh;overflow:hidden;padding:0.5rem 0.75rem;touch-action:manipulation;overscroll-behavior:none;"
      const wrap = main.firstElementChild
      if (wrap) {
        this._origWrapClass = wrap.className
        wrap.className = "mx-auto max-w-2xl h-full"
      }
    }
    this.el.style.cssText = "height:100%;overflow:hidden;touch-action:manipulation;overscroll-behavior:none;"
    document.body.style.overflow = "hidden"
    document.body.style.position = "fixed"
    document.body.style.inset = "0"
    const vp = document.querySelector('meta[name="viewport"]')
    if (vp) {
      this._origViewport = vp.content
      vp.content = "width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no"
    }
  },

  _unlockViewport() {
    const main = this.el.closest("main")
    if (main) {
      if (this._origMainClass != null) main.className = this._origMainClass
      main.style.cssText = ""
      const wrap = main.firstElementChild
      if (wrap && this._origWrapClass != null) wrap.className = this._origWrapClass
    }
    document.body.style.overflow = ""
    document.body.style.position = ""
    document.body.style.inset = ""
    const vp = document.querySelector('meta[name="viewport"]')
    if (vp && this._origViewport) vp.content = this._origViewport
  },

  destroyed() {
    for (const fn of this._interactionCleanup) fn()
    this._interactionCleanup = []
    const ghost = document.getElementById("drag-ghost")
    if (ghost) ghost.remove()
    this._unlockViewport()
    if (this._channel) {
      this._channel.disconnect()
      this._channel = null
    }
    if (this._state.eventFlashTimer) clearTimeout(this._state.eventFlashTimer)
    if (this._state.cooldownTimer) clearTimeout(this._state.cooldownTimer)
    if (this._slapWindowIntervalId) {
      clearInterval(this._slapWindowIntervalId)
      this._slapWindowIntervalId = null
    }
    if (this._slapFreezeIntervalId) {
      clearInterval(this._slapFreezeIntervalId)
      this._slapFreezeIntervalId = null
    }
  },
}

export default Game
