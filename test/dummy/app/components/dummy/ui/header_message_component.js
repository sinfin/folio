window.Folio.Stimulus.register('d-ui-header-message', class extends window.Stimulus.Controller {
  static values = {
    cookie: String,
    loaded: { type: Boolean, default: false },
  }

  connect () {
    window.Folio.RemoteScripts.run('js-cookie', () => {
      this.loadedValue = true
    }, () => {})
  }

  close (e) {
    e.preventDefault()
    this.element.parentNode.removeChild(this.element)
    window.Cookies.set('hiddenHeaderMessage', this.cookieValue)
  }
})
