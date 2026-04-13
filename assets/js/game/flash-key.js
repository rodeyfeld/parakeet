import { cardIdentityKey } from "./cards"

/** Same window as `updateState` skipping duplicate `setEventFlash`. */
export const EVENT_FLASH_DEDUPE_MS = 750

/** After a pile win: play/slap lockout + frozen pile “next round” countdown (ms). */
export const EVENT_FLASH_MS = 2000

/**
 * Single identity for an event flash (pile win toast + SFX + animation).
 * Include winner_idx / pile_size so duplicate payloads always match even if detail text varies.
 */
export function flashEventDedupeKey(flash) {
  if (!flash) return null
  const slapPart = flash.slap_cards?.map(cardIdentityKey).join("|") ?? ""
  const ch = flash.challenge_card ? cardIdentityKey(flash.challenge_card) : ""
  return [
    flash.type,
    flash.label ?? "",
    flash.detail ?? "",
    String(flash.winner_idx ?? ""),
    String(flash.pile_size ?? ""),
    slapPart,
    ch,
  ].join("|")
}
