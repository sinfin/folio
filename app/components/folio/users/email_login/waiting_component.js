window.Folio.Stimulus.register('f-users-email-login-waiting', class extends window.Stimulus.Controller {
  static targets = ['completionForm', 'check', 'status', 'resend', 'countdown', 'trustBrowser', 'spinner', 'continue']
  static values = {
    statusUrl: String,
    trustStorageKey: String,
    state: String,
    expiresAt: Number,
    resendAt: Number,
    expiredMessage: String,
    invalidMessage: String,
    waitingMessage: String,
    completingMessage: String,
    connectionErrorMessage: String,
    stalledAfter: { type: Number, default: 5000 }
  }

  connect () {
    this.restoreBrowserTrust()
    this.stopped = false
    this.submitting = false
    this.checkTarget.hidden = true
    this.continueTarget.hidden = true
    this.completedUrl = null
    window.clearTimeout(this.stallTimeout)
    this.spinnerTarget.hidden = !['waiting', 'approved', 'consumed'].includes(this.stateValue)
    this.tick()
    if (this.stopped) return
    this.clock = window.setInterval(() => this.tick(), 1000)
    this.poll()
  }

  restoreBrowserTrust () {
    try {
      const saved = window.sessionStorage.getItem(this.trustStorageKeyValue)
      if (saved !== null) this.trustBrowserTarget.checked = saved === '1'
      this.saveBrowserTrust()
    } catch (error) {
      // Without storage, do not silently restore the default consent after a reload.
      this.trustBrowserTarget.checked = false
    }
  }

  saveBrowserTrust () {
    try {
      window.sessionStorage.setItem(this.trustStorageKeyValue, this.trustBrowserTarget.checked ? '1' : '0')
    } catch (error) {
      this.trustBrowserTarget.checked = false
    }
  }

  disconnect () {
    this.stop()
    window.clearTimeout(this.stallTimeout)
  }

  stop () {
    this.stopped = true
    window.clearTimeout(this.timeout)
    window.clearInterval(this.clock)
    this.abortController?.abort()
  }

  visibilityChanged () {
    window.clearTimeout(this.timeout)
    if (!document.hidden) {
      this.tick()
      this.poll()
    }
  }

  pageShown () {
    if (this.stopped && ['waiting', 'approved', 'consumed'].includes(this.stateValue)) this.connect()
  }

  tick () {
    const waiting = ['waiting', 'approved'].includes(this.stateValue)
    const remaining = Math.max(0, Math.ceil(this.resendAtValue - Date.now() / 1000))
    this.resendTarget.disabled = this.stateValue !== 'waiting' || remaining > 0 || this.submitting
    this.checkTarget.disabled = !waiting || this.submitting
    this.countdownTarget.textContent = remaining > 0 && waiting ? `${remaining} s` : ''
    if (waiting && Date.now() / 1000 >= this.expiresAtValue) {
      this.stateValue = 'expired'
      this.statusTarget.textContent = this.expiredMessageValue
      this.spinnerTarget.hidden = true
      this.stop()
      this.resendTarget.disabled = true
      this.checkTarget.disabled = true
    }
  }

  async poll () {
    if (this.stopped || this.loading || document.hidden || this.submitting) return
    if (!['waiting', 'approved', 'consumed'].includes(this.stateValue)) return

    this.loading = true
    this.abortController = new window.AbortController()
    try {
      const response = await window.Folio.Api.apiGet(this.statusUrlValue, null, this.abortController.signal)
      if (this.stopped) return
      this.checkTarget.hidden = true
      const { state, url } = response.data
      this.stateValue = state
      if (url) {
        this.stop()
        this.showCompleting()
        this.completedUrl = url
        window.location.assign(url)
      } else if (state === 'approved') {
        this.submitting = true
        this.stop()
        this.showCompleting()
        this.completionFormTarget.requestSubmit()
      } else if (state !== 'waiting') {
        this.statusTarget.textContent = state === 'expired' ? this.expiredMessageValue : this.invalidMessageValue
        this.spinnerTarget.hidden = true
        this.stop()
        this.resendTarget.disabled = true
        this.checkTarget.disabled = true
      } else {
        this.statusTarget.textContent = this.waitingMessageValue
        this.spinnerTarget.hidden = false
      }
    } catch (error) {
      if (!this.stopped && error.name !== 'AbortError') {
        this.statusTarget.textContent = this.connectionErrorMessageValue
        this.spinnerTarget.hidden = true
        this.checkTarget.hidden = false
      }
    } finally {
      this.loading = false
      if (!this.stopped && !document.hidden) this.timeout = window.setTimeout(() => this.poll(), 3000)
    }
  }

  // Offers a manual step when the redirect or completion request does not finish in time.
  showCompleting () {
    this.statusTarget.textContent = this.completingMessageValue
    this.spinnerTarget.hidden = false
    window.clearTimeout(this.stallTimeout)
    this.stallTimeout = window.setTimeout(() => { this.continueTarget.hidden = false }, this.stalledAfterValue)
  }

  // Completion is idempotent: a completed sign-in in this browser redirects again.
  continueSignIn () {
    if (this.completedUrl) {
      window.location.assign(this.completedUrl)
    } else {
      this.completionFormTarget.requestSubmit()
    }
  }
})
