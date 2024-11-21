window.Folio.Stimulus.register('f-captcha-turnstile', class extends window.Stimulus.Controller {
  static values = { siteKey: String }
  static targets = ["turnstileContainer"]

  connect() {
    if (!document.querySelector("#cloudflare-turnstile-script")) {
      this.loadTurnstileScript()
    } else {
      this.renderTurnstile()
    }

    document.addEventListener("turbolinks:load", this.renderTurnstile.bind(this))
    document.addEventListener("turbolinks:before-render", this.removeTurnstile.bind(this))
  }

  disconnect() {
    this.removeTurnstile()
  }

  loadTurnstileScript() {
    window.Folio.RemoteScripts.run({
      key: "turnstile",
      urls: ["https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit"]
    }, () => {
      this.renderTurnstile()
    }, () => {
      console.error("Failed to load Cloudflare Turnstile script")
    })
  }

  renderTurnstile() {
    if (!this.siteKeyValue || typeof turnstile === 'undefined') return

    const turnstileContainer = this.turnstileContainerTarget

    if (turnstileContainer && !turnstileContainer.innerHTML) {
      // Control the visibility of the iframe wrapper because even when the iframe is hidden,
      // the wrapper takes up unnecessary space and causes layout shifts
      const updateIframeWraperVisibility = (display) => {
        const iframeWrapper = turnstileContainer.querySelector(":scope > div")
        if (iframeWrapper) {
          iframeWrapper.style.display = display
        }
      }

      turnstile.render(turnstileContainer, {
        sitekey: this.siteKeyValue,
        appearance: 'interaction-only',
        'before-interactive-callback': () => { updateIframeWraperVisibility("block") },
      })

      updateIframeWraperVisibility("none")
    }
  }

  removeTurnstile() {
    if (typeof turnstile === 'undefined' || !this.turnstileContainerTarget.innerHTML) return

    turnstile.remove()
  }
})
