window.Folio.Stimulus.register('f-captcha-turnstile', class extends window.Stimulus.Controller {
  static values = {
    siteKey: String,
    appearance: String
  }

  connect () {
    this.loadTurnstileScript()
  }

  disconnect () {
    this.removeTurnstile()
  }

  loadTurnstileScript () {
    window.Folio.RemoteScripts.run({
      key: 'turnstile',
      urls: ['https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit']
    }, () => {
      this.renderTurnstile()
    }, () => {
      console.error('Failed to load Cloudflare Turnstile script')
    })
  }

  renderTurnstile () {
    if (!this.siteKeyValue || typeof window.turnstile === 'undefined') return

    const turnstileContainer = this.element

    if (turnstileContainer && !turnstileContainer.innerHTML) {
      window.turnstile.render(turnstileContainer, {
        sitekey: this.siteKeyValue,
        language: document.documentElement.lang,
        appearance: this.appearanceValue,
        'before-interactive-callback': () => { turnstileContainer.style.display = 'block' }
      })

      // Control the visibility of the turnstileContainer because even when the iframe is hidden,
      // it's wrapper takes up unnecessary space and causes layout shifts
      if (this.appearanceValue === 'interaction-only') {
        turnstileContainer.style.display = 'none'
      }
    }
  }

  removeTurnstile () {
    if (typeof window.turnstile === 'undefined' || !this.element.innerHTML) return

    window.turnstile.remove()
  }
})
