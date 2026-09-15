window.Folio.Stimulus.register('f-users-email-login-confirmation', class extends window.Stimulus.Controller {
  static targets = ['status', 'retry']
  static values = { url: String, connectionError: String }

  connect () {
    this.token = window.location.hash ? window.location.hash.slice(1) : null
    if (window.location.hash) window.history.replaceState(null, '', window.location.pathname + window.location.search)
    this.prepare()
  }

  disconnect () {
    this.abortController?.abort()
    this.token = null
  }

  async prepare () {
    if (this.loading) return
    this.loading = true
    this.retryTarget.hidden = true
    this.abortController = new window.AbortController()
    try {
      const body = this.token === null ? {} : { email_login_token: this.token }
      const response = await window.Folio.Api.apiPost(this.urlValue, body, this.abortController.signal)
      this.token = null
      this.element.outerHTML = response.data
    } catch (error) {
      if (error.name !== 'AbortError') {
        this.statusTarget.textContent = this.connectionErrorValue
        this.retryTarget.hidden = false
      }
    } finally {
      this.loading = false
    }
  }
})
