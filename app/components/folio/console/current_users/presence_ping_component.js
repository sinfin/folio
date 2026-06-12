window.Folio.Stimulus.register('f-c-current-users-presence-ping', class extends window.Stimulus.Controller {
  static values = {
    apiUrl: String,
    presenceUrl: String,
    placementToken: String
  }

  connect () {
    this.boundOnVisibilityChange = () => this.onVisibilityChange()
    document.addEventListener('visibilitychange', this.boundOnVisibilityChange)
    this.startPinging()
  }

  disconnect () {
    this.stopPinging()
    document.removeEventListener('visibilitychange', this.boundOnVisibilityChange)
  }

  startPinging () {
    this.pingInterval = setInterval(() => {
      this.pingUrl()
    }, 10000)
  }

  stopPinging () {
    if (this.pingInterval) {
      clearInterval(this.pingInterval)
      this.pingInterval = null
    }
  }

  // refresh presence immediately when the editor returns to a backgrounded tab,
  // where the interval may have been throttled or frozen by the browser
  onVisibilityChange () {
    if (document.visibilityState === 'visible') this.pingUrl()
  }

  pingUrl () {
    if (this.apiUrlValue === 'dont_ping') return

    // canonical record presence URL (e.g. the edit URL) so the edit page and a
    // form re-rendered after a failed update track the editor under one URL
    const url = this.presenceUrlValue || window.location.href.split('?')[0]
    const data = { url }

    if (this.hasPlacementTokenValue) {
      data.placement_token = this.placementTokenValue
    }

    window.Folio.Api.apiPost(this.apiUrlValue, data).then((res) => {
      this.onPingResponse(res)
    }).catch(() => {})
  }

  onPingResponse (res) {
    if (!res || !res.data) return

    this.injectBar(res.data)

    // broadcast presence so an already-shown warning bar can react -
    // e.g. remove itself once the other user is no longer editing the url
    window.dispatchEvent(new CustomEvent('folio:console:presence-ping', { detail: res.data }))
  }

  // show the warning bar live for the editor who opened the page first (and so
  // had no bar at render time), once a second editor appears - no page reload
  injectBar (data) {
    if (!data.bar_html) return
    if (document.querySelector('.f-c-current-users-console-url-bar')) return

    this.element.insertAdjacentHTML('afterend', data.bar_html)
  }
})
