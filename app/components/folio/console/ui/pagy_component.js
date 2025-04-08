window.FolioConsole = window.FolioConsole || {}
window.FolioConsole.Ui = window.FolioConsole.Ui || {}
window.FolioConsole.Ui.Pagy = {}

window.FolioConsole.Ui.Pagy.reload = () => {
  for (const pagy of document.querySelectorAll('.f-c-ui-pagy')) {
    pagy.dispatchEvent(new CustomEvent('f-c-ui-pagy/reload'))
  }
}

window.Folio.Stimulus.register('f-c-ui-pagy', class extends window.Stimulus.Controller {
  static values = {
    reloadUrl: String
  }

  reload () {
    window.Folio.Api.apiGet(this.reloadUrlValue).then((res) => {
      if (res && res.data) {
        this.element.outerHTML = res.data
      }
    }).catch((e) => {
      console.error('Error reloading pagy:', e)
    })
  }
})
