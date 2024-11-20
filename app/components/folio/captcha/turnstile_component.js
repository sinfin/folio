window.Folio.Stimulus.register('f-captcha-turnstile', class extends window.Stimulus.Controller {
  static values = { siteKey: String }

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
    document.removeEventListener("turbolinks:load", this.renderTurnstile.bind(this))
    document.removeEventListener("turbolinks:before-render", this.removeTurnstile.bind(this))
  }

  loadTurnstileScript() {
    const script = document.createElement("script")
    Object.assign(script, {
      id: "cloudflare-turnstile-script",
      src: "https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit",
      async: true,
      defer: true,
    })

    document.head.appendChild(script)

    script.onload = () => { this.renderTurnstile() }
    script.onerror = () => { console.error("Failed to load Cloudflare Turnstile script") }
  }

  renderTurnstile() {
    if (!this.siteKeyValue || typeof turnstile === 'undefined') return

    // TODO: handle more than one turnstile on the page (login modal is rendered everywhere)
    const turnstileContainer = document.querySelector(".cf-turnstile")

    if (turnstileContainer && !turnstileContainer.innerHTML) {
      // Control the visibility of the iframe wrapper because even when the iframe is hidden,
      // the wrapper takes up unnecessary space and causes layout shifts
      const updateIframeWraperVisibility = (display) => {
        const iframeWrapper = document.querySelector(".cf-turnstile > div")
        if (iframeWrapper) {
          iframeWrapper.style.display = display
        }
      }

      turnstile.render('.cf-turnstile', {
        sitekey: this.siteKeyValue,
        appearance: 'interaction-only',
        'before-interactive-callback': () => { updateIframeWraperVisibility("block") },
      })

      updateIframeWraperVisibility("none")
    }
  }

  removeTurnstile() {
    if (typeof turnstile === 'undefined'
        || !document.querySelector(".cf-turnstile").innerHTML) return

    turnstile.remove()
  }
})
