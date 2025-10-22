window.Folio.Stimulus.register('f-c-form-warnings', class extends window.Stimulus.Controller {
  static values = { key: String }

  connect () {
    if (this._shouldShowFromStorage()) this._reveal()
  }

  show () {
    this._markForNextRender()
    this._reveal()
  }

  _storageKey () {
    return `fCFormWarnings:${this.keyValue || window.location.pathname}`
  }

  _markForNextRender () {
    try { window.sessionStorage.setItem(this._storageKey(), '1') } catch (_) {}
  }

  _shouldShowFromStorage () {
    try {
      const key = this._storageKey()
      if (window.sessionStorage.getItem(key) === '1') {
        window.sessionStorage.removeItem(key)
        return true
      }
    } catch (_) {}
    return false
  }

  _reveal () {
    if (this.element.querySelector('li')) this.element.classList.remove('d-none')
  }
})
