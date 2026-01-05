window.Folio.Stimulus.register('f-c-files-display-toggle', class extends window.Stimulus.Controller {
  static values = {
    apiUrl: String,
    enabled: Boolean
  }

  click (e) {
    this.enabledValue = e.params.enabled

    for (const toggle of document.querySelectorAll('.f-c-files-display-toggle')) {
      if (toggle !== this.element) {
        toggle.dataset.fCFilesDisplayToggleEnabledValue = String(this.enabledValue)
      }
    }

    for (const list of document.querySelectorAll('.f-file-list--view-changeable')) {
      list.dispatchEvent(new CustomEvent('f-c-files-display-toggle:table-view-change', { bubbles: true, detail: { images_table_view: this.enabledValue } }))
    }

    const data = { images_table_view: this.enabledValue }
    window.Folio.Api.apiPost(this.apiUrlValue, data)
  }
})
