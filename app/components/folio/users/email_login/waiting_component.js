window.Folio.Stimulus.register('f-users-email-login-waiting', class extends window.Stimulus.Controller {
  static targets = ['completionForm', 'check', 'status', 'resend', 'countdown', 'trustBrowser', 'spinner', 'continue', 'codeInput', 'codeSubmit', 'codeError']
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
    codeUrl: String,
    codeFormatMessage: String,
    codeErrorMessage: String,
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
    this.codeInputTarget.disabled = !waiting || this.submitting
    this.codeSubmitTarget.disabled = !waiting || this.submitting || this.verifyingCode
    this.countdownTarget.textContent = remaining > 0 && waiting ? `${remaining} s` : ''
    if (waiting && Date.now() / 1000 >= this.expiresAtValue) this.showFinished('expired')
  }

  showFinished (state) {
    this.stateValue = state
    this.statusTarget.textContent = state === 'expired' ? this.expiredMessageValue : this.invalidMessageValue
    this.spinnerTarget.hidden = true
    this.stop()
    this.resendTarget.disabled = true
    this.countdownTarget.textContent = ''
    this.checkTarget.disabled = true
    this.codeInputTarget.disabled = true
    this.codeSubmitTarget.disabled = true
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
        this.showFinished(state)
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

  // Verifies the emailed code without reloading, so a typo keeps polling and the page state.
  // Without JavaScript the same button posts the form to the code endpoint.
  async submitCode (event) {
    if (!event.submitter || event.submitter !== this.codeSubmitTarget) return
    event.preventDefault()
    // rails-ujs would otherwise disable every submit button of the form.
    event.stopPropagation()
    if (this.submitting || this.verifyingCode) return

    const code = this.codeInputTarget.value.replace(/[\s\-\u2010-\u2015]/g, '')
    if (!/^\d{6}$/.test(code)) {
      this.showCodeError(this.codeFormatMessageValue)
      return
    }

    this.verifyingCode = true
    this.codeSubmitTarget.disabled = true
    try {
      const response = await window.Folio.Api.apiPost(this.codeUrlValue, {
        email_login_code: code,
        trust_browser: this.trustBrowserTarget.checked ? '1' : '0'
      })
      const { state, url } = response.data
      if (url) {
        this.hideCodeError()
        this.submitting = true
        this.stop()
        this.showCompleting()
        this.completedUrl = url
        window.location.assign(url)
      } else {
        if (state && !['waiting', 'approved'].includes(state)) this.showFinished(state)
        this.showCodeError(response.error)
      }
    } catch (error) {
      this.showCodeError(this.codeErrorMessageValue)
    } finally {
      this.verifyingCode = false
      if (!this.submitting && ['waiting', 'approved'].includes(this.stateValue)) this.tick()
    }
  }

  showCodeError (message) {
    this.codeErrorTarget.textContent = message
    this.codeErrorTarget.hidden = false
    this.codeInputTarget.classList.add('is-invalid')
    this.codeInputTarget.setAttribute('aria-invalid', 'true')
    if (!this.codeInputTarget.disabled) {
      this.codeInputTarget.focus()
      this.codeInputTarget.select()
    }
  }

  hideCodeError () {
    this.codeErrorTarget.textContent = ''
    this.codeErrorTarget.hidden = true
    this.codeInputTarget.classList.remove('is-invalid')
    this.codeInputTarget.removeAttribute('aria-invalid')
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
