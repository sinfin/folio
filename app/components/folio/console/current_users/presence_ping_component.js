window.Folio.Stimulus.register('f-c-current-users-presence-ping', class extends window.Stimulus.Controller {
  static values = {
    apiUrl: String,
    recordType: String,
    recordId: Number
  }

  connect () {
    this.boundOnVisibilityChange = () => this.onVisibilityChange()
    document.addEventListener('visibilitychange', this.boundOnVisibilityChange)
    this.pingUrl() // assert presence immediately, do not wait for the first interval
    this.startPinging()
  }

  disconnect () {
    this.stopPinging()
    document.removeEventListener('visibilitychange', this.boundOnVisibilityChange)
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
