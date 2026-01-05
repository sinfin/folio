window.Folio.Stimulus.register('f-form-auto-submit', class extends window.Stimulus.Controller {
  connect () {
    this.onChange = () => { this.element.requestSubmit() }
    this.element.addEventListener('change', this.onChange)
  }

  disconnect () {
    if (this.onChange) {
      this.element.removeEventListener('change', this.onChange)
      delete this.onChange
    }
  }
})
