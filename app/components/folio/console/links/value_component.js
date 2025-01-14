window.Folio.Stimulus.register('f-c-links-value', class extends window.Stimulus.Controller {
  onEditClick (e) {
    e.preventDefault()
    this.element.dispatchEvent(new CustomEvent('f-c-input-form-group-url:edit', { bubbles: true }))
  }

  onRemoveClick (e) {
    e.preventDefault()
    this.element.dispatchEvent(new CustomEvent('f-c-input-form-group-url:remove', { bubbles: true }))
  }
})
