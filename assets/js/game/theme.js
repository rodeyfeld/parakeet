/**
 * Color system: player identity vs. rules-engine / timing UI.
 * - Player fills are only for seats (avatar ring, deck backs, challenge tint, event-flash icon/name).
 * - MECHANIC is reserved for turn state, play wind-up, stats, timers — never use for playerFill().
 */

/** One distinct hue per seat (avatars, deck chrome, pile challenge glow, event-flash identity). */
export const PLAYER_FILLS = [
  "#ec4899", // pink
  "#3b82f6", // blue
  "#a855f7", // violet
  "#06b6d4", // cyan
  "#d946ef", // fuchsia
]

export function playerFill(idx) {
  return PLAYER_FILLS[idx] ?? "#a1a1aa"
}

/** Rules / feedback — must not repeat any PLAYER_FILLS hue role. */
export const MECHANIC = {
  /** Avatar ring while it’s your turn and you have not started a play (wind-up). */
  turnAwaitingPlay: "#86efac",
  /** Dragging to play, or server play_intent (bot pre-play). */
  playIntent: "#f97316",
  /** Hand count + after winning cards from a slap. */
  handDeltaGain: "#4ade80",
  /** Hand count − after a bad slap penalty. */
  handDeltaLoss: "#f87171",
  /** Deck back when no player context. */
  neutralDeck: "#64748b",
  /** Pile drop-zone outline while dragging a card over it. */
  dragPileOutline: "rgba(249, 115, 22, 0.55)",
}
