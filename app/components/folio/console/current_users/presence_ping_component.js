window.Folio.Stimulus.register('f-c-current-users-presence-ping', class extends window.Stimulus.Controller {
  static values = {
    apiUrl: String,
    clearUrl: String,
    recordType: String,
    recordId: Number
  }

  connect () {
    this.boundOnVisibilityChange = () => this.onVisibilityChange()
    this.boundOnPagehide = () => this.clearPresence()
    document.addEventListener('visibilitychange', this.boundOnVisibilityChange)
    window.addEventListener('pagehide', this.boundOnPagehide)
    this.pingUrl() // assert presence immediately, do not wait for the first interval
    this.startPinging()
  }

  disconnect () {
    this.stopPinging()
    document.removeEventListener('visibilitychange', this.boundOnVisibilityChange)
    window.removeEventListener('pagehide', this.boundOnPagehide)
  }

  startPinging () {
    this.pingInterval = setInterval(() => { this.pingUrl() }, 10000)
  }

  stopPinging () {
    if (this.pingInterval) {
      clearInterval(this.pingInterval)
      this.pingInterval = null
    }
  }

  onVisibilityChange () {
    if (document.visibilityState === 'visible') this.pingUrl()
  }

  clearPresence () {
    if (!navigator.sendBeacon || !this.hasClearUrlValue || this.clearUrlValue === '') return

    const data = new URLSearchParams()
    data.append('record_type', this.recordTypeValue)
    data.append('record_id', this.recordIdValue)
    const csrf = document.querySelector('meta[name="csrf-token"]')
    if (csrf) data.append('authenticity_token', csrf.getAttribute('content'))

    navigator.sendBeacon(this.clearUrlValue, data)
  }

  pingUrl () {
    if (this.apiUrlValue === 'dont_ping') return

    const data = { record_type: this.recordTypeValue, record_id: this.recordIdValue }
    window.Folio.Api.apiPost(this.apiUrlValue, data).then((res) => {
      this.onPingResponse(res)
    }).catch(() => {})
  }

  onPingResponse (res) {
    if (!res || !res.data) return
    this.injectBar(res.data)
    window.dispatchEvent(new CustomEvent('folio:console:presence-ping', { detail: res.data }))
  }

  injectBar (data) {
    if (!data.bar_html) return
    if (document.querySelector('.f-c-current-users-console-url-bar')) return
    this.element.insertAdjacentHTML('afterend', data.bar_html)
  }
})
