window.Folio.Stimulus.register('f-c-current-users-console-url-bar', class extends window.Stimulus.Controller {
  static values = {
    url: String
  }

  connect () {
    this.interval = window.setInterval(() => {
      const data = { url: window.location.href.split('?')[0] }
      window.Folio.Api.apiPost(this.urlValue, data)
    }, 10000)
  }

  disconnect () {
    window.clearInterval(this.interval)
  }
})
