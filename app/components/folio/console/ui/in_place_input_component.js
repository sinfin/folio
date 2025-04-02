window.Folio.Stimulus.register('f-c-ui-in-place-input', class extends window.Stimulus.Controller {
  static targets = ['content', 'inputWrap', 'contentWrap']

  static values = {
    editing: Boolean,
    hasAutocomplete: Boolean
  }

  onBlur (e) {
    if (e.detail && !e.detail.dirty) {
      if (this.hasAutocompleteValue) {
        const input = this.element.querySelector('.f-c-ui-ajax-input__input')

        if (input && input.getAttribute('data-f-input-autocomplete-has-active-dropdown-value') === 'true') {
          return
        }
      }

      this.editingValue = false
    }
  }

  onSuccess (e) {
    this.contentTarget.innerHTML = e.detail.value || ''
    this.editingValue = false
    this.element.classList.add('f-c-ui-in-place-input--success')

    window.setTimeout(() => {
      this.element.classList.remove('f-c-ui-in-place-input--success')
    }, 1000)
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
