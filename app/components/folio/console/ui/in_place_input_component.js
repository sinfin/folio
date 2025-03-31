window.Folio.Stimulus.register('f-c-ui-in-place-input', class extends window.Stimulus.Controller {
  static targets = ['content']

  static values = {
    editing: Boolean
  }

  onBlur (e) {
    if (e.detail && !e.detail.dirty) {
      this.editingValue = false
    }
  }

  onSuccess (e) {
    this.editingValue = false
    this.contentTarget.innerHTML = e.detail.value
  }

  toggle () {
    this.editingValue = !this.editingValue

    if (this.editingValue) {
      const input = this.element.querySelector('.f-c-ui-ajax-input__input')
      if (!input) return

      input.focus()
      input.setSelectionRange(-1, -1)
    }
  }
})
