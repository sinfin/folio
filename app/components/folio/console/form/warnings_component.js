window.Folio.Stimulus.register('f-c-form-warnings', class extends window.Stimulus.Controller {
  static values = { recordKey: String }

  connect () {
    this._reveal()
  }

  show () {
    this._markForNextRender()
    this._reveal()
  }

  _storageKey () {
    return `fCFormWarnings:${this.recordKeyValue || window.location.pathname}`
  }

  _markForNextRender () {
    try { window.sessionStorage.setItem(this._storageKey(), '1') } catch (_) {}
  }

  _reveal () {
    if (this.element.querySelector('li')) this.element.classList.remove('d-none')
  }
})
