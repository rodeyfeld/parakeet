/**
 * Browser theme preference (shared with inline script in root.html.heex).
 * Storage key must match root script.
 */
export const THEME_STORAGE_KEY = "phx:theme"

/** @returns {"system" | "light" | "dark"} */
export function getThemePreference() {
  const p = localStorage.getItem(THEME_STORAGE_KEY)
  if (p === "light" || p === "dark" || p === "system") return p
  return "system"
}

/** Effective light/dark for Tailwind `dark:` (always "light" | "dark"). */
export function getEffectiveTheme() {
  const p = getThemePreference()
  if (p === "light") return "light"
  if (p === "dark") return "dark"
  return window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light"
}

export function setThemePreference(pref) {
  if (pref === "system") {
    localStorage.removeItem(THEME_STORAGE_KEY)
  } else {
    localStorage.setItem(THEME_STORAGE_KEY, pref)
  }
  if (typeof window.parakeetApplyTheme === "function") {
    window.parakeetApplyTheme()
  }
}

export function cycleThemePreference() {
  const order = ["system", "light", "dark"]
  const cur = getThemePreference()
  const i = Math.max(0, order.indexOf(cur))
  setThemePreference(order[(i + 1) % order.length])
}

/** Label + glyph for compact theme controls */
export function themeControlPresentation() {
  const pref = getThemePreference()
  if (pref === "light") {
    return { label: "Theme: light", glyph: "☀" }
  }
  if (pref === "dark") {
    return { label: "Theme: dark", glyph: "☾" }
  }
  return { label: "Theme: system", glyph: "◐" }
}
