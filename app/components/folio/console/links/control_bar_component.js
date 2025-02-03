window.Folio.Stimulus.register('f-c-links-control-bar', class extends window.Stimulus.Controller {
  static values = {
    json: Boolean
  }

  onAddClick (e) {
    e.preventDefault()

    this.element.dispatchEvent(new CustomEvent('f-c-input-form-group-url:edit', {
      bubbles: true,
      detail: { json: this.jsonValue }
    }))
  }
})
