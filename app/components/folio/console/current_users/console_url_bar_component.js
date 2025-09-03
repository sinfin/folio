window.Folio.Stimulus.register('f-c-current-users-console-url-bar', class extends window.Stimulus.Controller {
  static values = {
    apiUrl: String
  }

  connect() {
    this.startUrlPinging()
  }

  disconnect() {
    this.stopUrlPinging()
  }

  startUrlPinging() {
    this.urlPingInterval = setInterval(() => {
      this.pingUrl()
    }, 10000)
  }

  stopUrlPinging() {
    if (this.urlPingInterval) {
      clearInterval(this.urlPingInterval)
      this.urlPingInterval = null
    }
  }

  pingUrl() {
    const currentUrl = window.location.href.split('?')[0]
    
    window.Folio.Api.apiPost(this.apiUrlValue, { url: currentUrl })
  }
})
