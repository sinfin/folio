window.Folio.Stimulus.register('f-users-email-login-confirmation', class extends window.Stimulus.Controller {
  static targets = ['status', 'retry', 'continue', 'spinner']
  static values = { url: String, connectionError: String, stalledAfter: { type: Number, default: 5000 } }

  connect () {
    this.token = window.location.hash ? window.location.hash.slice(1) : null
    if (window.location.hash) window.history.replaceState(null, '', window.location.pathname + window.location.search)
    this.prepare()
  }

  disconnect () {
    this.abortController?.abort()
    window.clearTimeout(this.stallTimeout)
    this.token = null
  }

  async prepare () {
    if (this.loading) return
    this.loading = true
    this.retryTarget.hidden = true
    this.continueTarget.hidden = true
    this.spinnerTarget.hidden = false
    this.watchStall()
    const abortController = this.abortController = new window.AbortController()
    try {
      const body = this.token === null ? { approve: '1' } : { email_login_token: this.token, approve: '1' }
      const response = await window.Folio.Api.apiPost(this.urlValue, body, abortController.signal)
      this.token = null
      if (response.data.url) {
        // Keep the stall timer running: the redirect itself may hang.
        this.completedUrl = response.data.url
        window.location.assign(response.data.url)
      } else {
        window.clearTimeout(this.stallTimeout)
        this.element.outerHTML = response.data
      }
    } catch (error) {
      if (error.name !== 'AbortError' && abortController === this.abortController) {
        window.clearTimeout(this.stallTimeout)
        this.spinnerTarget.hidden = true
        this.continueTarget.hidden = true
        this.statusTarget.textContent = this.connectionErrorValue
        this.retryTarget.hidden = false
      }
    } finally {
      if (abortController === this.abortController) this.loading = false
    }
  }

  // Offered when sign-in does not finish in time. The server answers a repeated
  // request for an already completed sign-in with the same redirect.
  continue () {
    if (this.completedUrl) {
      window.location.assign(this.completedUrl)
    } else {
      this.abortController?.abort()
      this.loading = false
      this.prepare()
    }
  }

  watchStall () {
    window.clearTimeout(this.stallTimeout)
    this.stallTimeout = window.setTimeout(() => { this.continueTarget.hidden = false }, this.stalledAfterValue)
  }
})
