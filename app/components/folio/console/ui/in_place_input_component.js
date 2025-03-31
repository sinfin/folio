window.Folio.Stimulus.register('f-c-ui-in-place-input', class extends window.Stimulus.Controller {
  static targets = ['content', 'inputWrap', 'contentWrap']

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
    this.contentTarget.innerHTML = e.detail.value || ''
  }

  toggle () {
    if (this.editingValue) {
      this.inputWrapTarget.style.minHeight = null
    } else {
      this.inputWrapTarget.style.minHeight = this.contentWrapTarget.offsetHeight + 'px'
    }

    this.editingValue = !this.editingValue
  }

  editingValueChanged (to, from) {
    if (to && typeof from !== 'undefined' && to !== from) {
      const input = this.element.querySelector('.f-c-ui-ajax-input__input')
      if (!input) return

      input.focus()
      input.setSelectionRange(-1, -1)
    }
  }
})
