window.Folio.Stimulus.register('f-captcha-turnstile', class extends window.Stimulus.Controller {
  static values = {
    siteKey: String,
    appearance: String,
    submitButtonClassName: String,
  }

  connect() {
    this.loadTurnstileScript()

    if (this.submitButtonClassNameValue) {
      this.disableSubmitButton()
    }
  }

  disconnect() {
    this.removeTurnstile()

    if (this.submitButtonClassNameValue) {
      this.enableSubmitButton()
    }
  }

  loadTurnstileScript() {
    window.Folio.RemoteScripts.run({
      key: "turnstile",
      urls: ["https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit"]
    }, () => {
      this.renderTurnstile()
    }, () => {
      console.error("Failed to load Cloudflare Turnstile script")

      if (this.submitButtonClassNameValue) {
        this.enableSubmitButton()
      }
    })
  }

  renderTurnstile() {
    if (!this.siteKeyValue || typeof turnstile === 'undefined') return

    const turnstileContainer = this.element

    if (turnstileContainer && !turnstileContainer.innerHTML) {
      const turnstileOptions = {
        sitekey: this.siteKeyValue,
        language: document.documentElement.lang,
        appearance: this.appearanceValue,
        'before-interactive-callback': () => { turnstileContainer.style.display = "block" },
      }

      // Only add callbacks if we need to disable submit button
      if (this.submitButtonClassNameValue) {
        turnstileOptions['callback'] = (token) => { this.onTurnstileSuccess(token) }
        turnstileOptions['error-callback'] = () => { this.onTurnstileError() }
        turnstileOptions['expired-callback'] = () => { this.onTurnstileExpired() }
      }

      turnstile.render(turnstileContainer, turnstileOptions)

      // Control the visibility of the turnstileContainer because even when the iframe is hidden,
      // it's wrapper takes up unnecessary space and causes layout shifts
      if (this.appearanceValue === "interaction-only") {
        turnstileContainer.style.display = "none"
      }
    }
  }

  removeTurnstile() {
    if (typeof turnstile === 'undefined' || !this.element.innerHTML) return

    turnstile.remove()
  }

  onTurnstileSuccess(token) {
    this.enableSubmitButton()
  }

  onTurnstileError() {
    this.disableSubmitButton()
  }

  onTurnstileExpired() {
    this.disableSubmitButton()
  }

  findSubmitButton() {
    const form = this.element.closest('form')
    if (form) {
      return form.querySelector(`.${this.submitButtonClassNameValue}`)
    }
    return null
  }

  disableSubmitButton() {
    const submitButton = this.findSubmitButton()
    if (submitButton) {
      submitButton.disabled = true
      submitButton.setAttribute('disabled', 'disabled')
    }
  }

  enableSubmitButton() {
    const submitButton = this.findSubmitButton()
    if (submitButton) {
      submitButton.disabled = false
      submitButton.removeAttribute('disabled')
    }
  }
})
