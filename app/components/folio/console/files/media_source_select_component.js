window.Folio.Stimulus.register('f-c-files-media-source-select', class extends window.Stimulus.Controller {
  connect () {
    this.boundOnSelect2Change = this.onSelect2Change.bind(this)
    this.element.addEventListener('folio_select2_change', this.boundOnSelect2Change)
  }

  disconnect () {
    if (this.boundOnSelect2Change) {
      this.element.removeEventListener('folio_select2_change', this.boundOnSelect2Change)
    }
  }

  onSelect2Change () {
    const form = this.element.querySelector('form')
    if (form) {
      form.requestSubmit()
    }
  }
})
