// Global Cloudflare Turnstile

const renderTurnstile = () => {
  if (!window.turnstileSiteKey || typeof turnstile === 'undefined') return

  if (document.querySelector(".cf-turnstile")) {
    turnstile.render('.cf-turnstile', {
      sitekey: window.turnstileSiteKey,
      appearance: 'interaction-only'
    })
  }
}

const removeTurnstile = () => {
  if (typeof turnstile === 'undefined') return

  turnstile.remove()
}

window.onloadTurnstileCallback = () => {
  renderTurnstile()

  document.addEventListener("turbolinks:load", renderTurnstile)
  document.addEventListener("turbolinks:before-render", removeTurnstile)
}
