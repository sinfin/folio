window.Folio.Stimulus.register('f-c-ui-in-place-input', class extends window.Stimulus.Controller {
  static targets = ['content', 'inputWrap', 'contentWrap', 'contentInner', 'warning']

  static values = {
    editing: Boolean,
    hasAutocomplete: Boolean
  }

  onCancel (e) {
    this.editingValue = false
  }

  onBlur (e) {
    if (e.detail && !e.detail.dirty && !e.detail.failure) {
      if (this.hasAutocompleteValue) {
        const input = this.inputWrapTarget.querySelector('.f-c-ui-ajax-input__input')
        if (input) {
          const hasActiveDropdown = input.getAttribute('data-f-input-autocomplete-has-active-dropdown-value') === 'true'
          if (hasActiveDropdown) {
            // Delay closing to allow click on dropdown item to complete first
            // When clicking an autocomplete item, blur fires before the click completes.
            window.setTimeout(() => {
              const stillOpen = input.getAttribute('data-f-input-autocomplete-has-active-dropdown-value') === 'true'
              const ajaxInput = input.closest('.f-c-ui-ajax-input')
              const isLoading = ajaxInput && ajaxInput.classList.contains('f-c-ui-ajax-input--loading')

              if (stillOpen) {
                // Dropdown still open - user clicked elsewhere, close it and the editor
                input.dispatchEvent(new CustomEvent('f-input-autocomplete:closeDropdown', { bubbles: true }))
                this.editingValue = false
              } else if (!isLoading) {
                // Dropdown closed and not loading - item was clicked but no save triggered
                // (e.g., selected same value), close the editor
                this.editingValue = false
              }
              // If isLoading, save is in progress - let onSuccess handle closing
            }, 150)
            return
          } else {
            // No active dropdown - close immediately
            input.dispatchEvent(new CustomEvent('f-input-autocomplete:closeDropdown', { bubbles: true }))
          }
        }
      }

      // When input is not dirty, close immediately regardless of dropdown state
      // The dropdown check is only relevant when there are changes to save
      this.editingValue = false
    }
  }

  onSuccess (e) {
    this.contentTarget.innerHTML = e.detail.label || e.detail.value || ''
    this.contentInnerTarget.title = e.detail.label || e.detail.value || ''
    this.editingValue = false
    this.element.classList.add('f-c-ui-in-place-input--success')

    if (this.hasWarningTarget && (e.detail.label || e.detail.value)) {
      this.warningTarget.remove()
    }

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
      const input = this.inputWrapTarget.querySelector('.f-c-ui-ajax-input__input')
      if (!input) return

      input.focus()
      if (input.tagName === 'INPUT') {
        input.setSelectionRange(-1, -1)
      } else if (input.tagName === 'TEXTAREA') {
        input.setSelectionRange(-1, -1)
        input.dispatchEvent(new CustomEvent('autosize:update'))
      }
    }
  }

  setValueFromEvent (e) {
    if (!e.detail || typeof e.detail.value !== 'string') return

    this.editingValue = false
    this.contentTarget.innerHTML = e.detail.value || ''
    this.contentInnerTarget.title = e.detail.value || ''

    const inputWrap = this.element.querySelector('.f-c-ui-ajax-input')
    inputWrap.dispatchEvent(new window.CustomEvent('f-c-ui-ajax-input:setValue', {
      detail: { value: e.detail.value }
    }))
  }
})
