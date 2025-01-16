window.Folio.Stimulus.register('f-c-links-value', class extends window.Stimulus.Controller {
  static values = {
    json: Boolean
  }

  onEditClick (e) {
    e.preventDefault()
    this.element.dispatchEvent(new CustomEvent('f-c-input-form-group-url:edit', {
      bubbles: true,
      detail: { json: this.jsonValue }
    }))
  }

  onRemoveClick (e) {
    e.preventDefault()
    this.element.dispatchEvent(new CustomEvent('f-c-input-form-group-url:remove', {
      bubbles: true,
      detail: { json: this.jsonValue }
    }))
  }
})
