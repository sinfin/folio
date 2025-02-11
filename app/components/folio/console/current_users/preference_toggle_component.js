window.Folio.Stimulus.register('f-c-current-users-preference-toggle', class extends window.Stimulus.Controller {
  static values = {
    enabled: Boolean,
    apiUrl: String,
    key: String,
    javascriptKey: String,
  }

  enabledValueChanged () {
    window.FolioConsole[this.javascriptKeyValue] = window.FolioConsole[this.javascriptKeyValue] || {}
    window.FolioConsole[this.javascriptKeyValue].enabled = this.enabledValue

    const data = {}
    data[this.keyValue] = this.enabledValue

    window.Folio.Api.apiPost(this.apiUrlValue, data)
  }

  booleanToggleInput (e) {
    this.enabledValue = e.detail.checked
  }
})
