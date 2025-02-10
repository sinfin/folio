window.FolioConsole = window.FolioConsole || {}
window.FolioConsole.HtmlAutoFormat = window.FolioConsole.HtmlAutoFormat || {}

window.Folio.Stimulus.register('f-c-html-auto-format-toggle', class extends window.Stimulus.Controller {
  static values = {
    enabled: Boolean,
    apiUrl: String,
  }

  enabledValueChanged () {
    window.FolioConsole.HtmlAutoFormat.enabled = this.enabledValue

    window.Folio.Api.apiPost(this.apiUrlValue, { html_auto_format: this.enabledValue })
  }

  booleanToggleInput (e) {
    this.enabledValue = e.detail.checked
  }
})
