window.Folio.Stimulus.register('f-c-current-users-preference-toggle', class extends window.Stimulus.Controller {
  static values = {
    enabled: { type: Number, default: -1 },
    apiUrl: String,
    key: String,
    javascriptKey: String
  }

  connect () {
    window.FolioConsole[this.javascriptKeyValue] = window.FolioConsole[this.javascriptKeyValue] || {}
    window.FolioConsole[this.javascriptKeyValue].enabled = this.enabledValue === 1
  }

  enabledValueChanged (value, previousValue) {
    if (value === previousValue) return

    window.FolioConsole[this.javascriptKeyValue] = window.FolioConsole[this.javascriptKeyValue] || {}
    window.FolioConsole[this.javascriptKeyValue].enabled = this.enabledValue === 1

    if (previousValue === -1) return

    if (window.FolioConsole[this.javascriptKeyValue].enabledChangeCallback) {
      window.FolioConsole[this.javascriptKeyValue].enabledChangeCallback()
    }

    const data = {}
    data[this.keyValue] = this.enabledValue === 1

    window.Folio.Api.apiPost(this.apiUrlValue, data)
  }

  booleanToggleInput (e) {
    this.enabledValue = e.detail.checked ? 1 : 0
  }

  stopPropagation (e) {
    e.stopPropagation()
  }
})
