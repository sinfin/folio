//= require cleave.js/dist/cleave
//= require folio/form_to_hash

window.Folio.Stimulus.register('f-c-ui-ajax-input', class extends window.Stimulus.Controller {
  static targets = ['input', 'tooltip']

  static values = {
    cleave: Boolean,
    remote: Boolean,
    url: String,
    originalValue: String,
    method: String,
    useSavedIndicator: Boolean
  }

  // Delay for blur save when autocomplete dropdown is active
  // This allows click events on dropdown items to complete before saving.
  // 150ms is sufficient for most browsers to process the click event.
  static BLUR_SAVE_DELAY_MS = 150

  connect () {
    if (this.cleaveValue) {
      this.cleave = new window.Cleave(this.inputTarget, {
        numeral: true,
        numeralDecimalScale: 6,
        delimiter: ' '
      })
    }
  }

  disconnect () {
    // Clean up any pending blur timeout to prevent memory leaks
    if (this.blurTimeout) {
      window.clearTimeout(this.blurTimeout)
      delete this.blurTimeout
    }

    if (this.cleave) {
      this.cleave.destroy()
      delete this.cleave
    }
  }

  onKeyDownAndPress (e) {
    if (e.key === 'Enter') {
      e.stopPropagation()
      e.preventDefault()
    }
  }

  onKeyUp (e) {
    const value = this.cleave ? this.cleave.getRawValue() : this.inputTarget.value

    if (e.key === 'Enter') {
      const skipInTextarea = this.inputTarget.tagName === 'TEXTAREA' && e.shiftKey

      if (!skipInTextarea) {
        e.preventDefault()
        e.stopPropagation()

        if (this.inputTarget.getAttribute('data-f-input-autocomplete-has-active-dropdown-value') === 'true') {
          const active = document.querySelector('.f-input-autocomplete-dropdown .active')
          if (active) return
        }

        if (value === this.originalValueValue) {
          return this.cancel()
        } else {
          return this.save()
        }
      }
    } else if (e.key === 'Escape') {
      return this.cancel()
    }

    if (this.element.classList.contains('f-c-ui-ajax-input--loading')) {
      e.preventDefault()
      e.stopPropagation()
      return false
    }

    this.element.classList.remove('f-c-ui-ajax-input--success')
    this.element.classList.remove('f-c-ui-ajax-input--failure')

    if (value !== this.originalValueValue) {
      return this.element.classList.add('f-c-ui-ajax-input--dirty')
    } else {
      return this.element.classList.remove('f-c-ui-ajax-input--dirty')
    }
  }

  onAutocompleteSelected (e) {
    const value = this.cleave ? this.cleave.getRawValue() : this.inputTarget.value
    const dirty = this.element.classList.contains('f-c-ui-ajax-input--dirty')

    if (this.element.classList.contains('f-c-ui-ajax-input--loading')) {
      return false
    }

    // Save if value changed OR if input was dirty (user made changes before selecting)
    if (value !== this.originalValueValue || dirty) {
      this.element.classList.add('f-c-ui-ajax-input--dirty')
      // Cancel any pending blur timeout since we're saving now
      if (this.blurTimeout) {
        window.clearTimeout(this.blurTimeout)
        delete this.blurTimeout
      }
      // Mark that autocomplete triggered save to prevent blur from saving again
      this.autocompleteTriggeredSave = true
      this.save()
    }
  }

  cancel (e) {
    if (e) e.preventDefault()
    if (this.element.classList.contains('f-c-ui-ajax-input--loading')) return false

    if (this.blurTimeout) {
      window.clearTimeout(this.blurTimeout)
      delete this.blurTimeout
    }

    if (this.cleave) {
      this.cleave.setRawValue(this.originalValueValue)
    } else {
      this.inputTarget.value = this.originalValueValue
    }

    this.element.classList.remove('f-c-ui-ajax-input--dirty')
    this.element.classList.remove('f-c-ui-ajax-input--success')
    this.element.classList.remove('f-c-ui-ajax-input--failure')

    this.inputTarget.blur()
    this.inputTarget.dispatchEvent(new CustomEvent('f-c-ui-ajax-input:cancel', { bubbles: true }))
  }

  onBlur () {
    // Skip blur save if autocomplete already triggered a save
    if (this.autocompleteTriggeredSave) {
      const failure = this.element.classList.contains('f-c-ui-ajax-input--failure')
      this.dispatch('blur', { detail: { dirty: false, failure } })
      return
    }

    const dirty = this.element.classList.contains('f-c-ui-ajax-input--dirty')
    const hasActiveDropdown = this.inputTarget.getAttribute('data-f-input-autocomplete-has-active-dropdown-value') === 'true'

    if (dirty) {
      if (hasActiveDropdown) {
        return this.handleDelayedBlurSave()
      } else {
        return this.save()
      }
    }

    // Input is not dirty - clear any pending timeout and close the editor
    if (this.blurTimeout) {
      window.clearTimeout(this.blurTimeout)
      delete this.blurTimeout
    }

    const failure = this.element.classList.contains('f-c-ui-ajax-input--failure')

    this.dispatch('blur', { detail: { dirty, failure } })
  }

  handleDelayedBlurSave () {
    // Delay save to allow click on dropdown item to complete first
    // When clicking an autocomplete item, blur fires before the click completes.
    // This delay ensures the click can finish and select the item before we save.
    const valueBeforeBlur = this.cleave ? this.cleave.getRawValue() : this.inputTarget.value
    this.blurTimeout = window.setTimeout(() => {
      // Check if dropdown closed and value changed (autocomplete selected an item)
      const stillOpen = this.inputTarget.getAttribute('data-f-input-autocomplete-has-active-dropdown-value') === 'true'
      const valueAfterBlur = this.cleave ? this.cleave.getRawValue() : this.inputTarget.value
      const valueChanged = valueBeforeBlur !== valueAfterBlur

      // Only save if dropdown is still open (user clicked elsewhere) or value didn't change
      if (stillOpen || !valueChanged) {
        this.save()
      }
      delete this.blurTimeout
    }, this.constructor.BLUR_SAVE_DELAY_MS)
  }

  save (e) {
    if (e) e.preventDefault()

    if (this.element.classList.contains('f-c-ui-ajax-input--loading')) return false

    if (this.remoteValue) {
      this.element.classList.add('f-c-ui-ajax-input--loading')

      const apiFn = this.methodValue === 'POST' ? window.Folio.Api.apiPost : window.Folio.Api.apiPatch

      const name = this.inputTarget.name

      let data

      if (this.inputTarget.multiple) {
        const selectedValues = Array.from(this.inputTarget.selectedOptions).map(option => option.value)
        const [mainKey, subKey] = name.split('[')

        data = { [mainKey]: { [subKey.replace(']', '')]: selectedValues } }
      } else {
        const rawData = { [name]: this.cleave ? this.cleave.getRawValue() : this.inputTarget.value }
        data = window.Folio.formToHash(rawData)
      }

      data._trigger = 'f-c-ui-ajax-input'

      apiFn(this.urlValue, data).then((res) => {
        const key = name.replace(/^.+\[(.+)\]$/, '$1')

        let newValue, newLabel

        if (this.inputTarget.multiple) {
          // For multiselect, prefer API data if available, fallback to DOM
          const selectedOptions = Array.from(this.inputTarget.selectedOptions)
          newValue = res.data?.attributes?.[key] || res.data?.[key] || selectedOptions.map(option => option.value)
          newLabel = selectedOptions.map(option => option.text).join(', ')
        } else {
          newValue = res.data?.attributes?.[key] || res.data?.[key] || ''
          newLabel = res.meta?.labels?.[key] || null
        }

        this.successCallback(newValue, newLabel)
      }).catch((err) => {
        this.tooltipTarget.innerHTML = err.message
        this.element.classList.add('f-c-ui-ajax-input--failure')
      }).finally(() => {
        this.element.classList.remove('f-c-ui-ajax-input--loading')
        this.element.classList.remove('f-c-ui-ajax-input--dirty')
      })
    } else {
      this.successCallback(this.cleave ? this.cleave.getRawValue() : this.inputTarget.value)
    }
  }

  successCallback (newValue, newLabel) {
    if (this.cleave) {
      this.cleave.setRawValue(newValue)
    } else {
      this.inputTarget.value = newValue
    }

    this.originalValueValue = newValue

    // Clear autocomplete flag after save completes (more reliable than setTimeout)
    if (this.autocompleteTriggeredSave) {
      delete this.autocompleteTriggeredSave
    }

    this.inputTarget.blur()
    this.inputTarget.dispatchEvent(new CustomEvent('f-c-ui-ajax-input:success', { bubbles: true, detail: { value: newValue, label: newLabel } }))

    if (this.useSavedIndicatorValue) {
      this.element.classList.add('f-c-ui-ajax-input--success')
      setTimeout(() => {
        if (this && this.element && this.element.parentNode) {
          this.element.classList.remove('f-c-ui-ajax-input--success')
        }
      }, 3000)
    }
  }

  setValueFromEvent (e) {
    if (!e.detail || typeof e.detail.value !== 'string') return

    if (this.blurTimeout) {
      window.clearTimeout(this.blurTimeout)
      delete this.blurTimeout
    }

    this.element.classList.remove('f-c-ui-ajax-input--dirty')
    this.element.classList.remove('f-c-ui-ajax-input--success')
    this.element.classList.remove('f-c-ui-ajax-input--failure')

    if (this.cleave) {
      this.cleave.setRawValue(e.detail.value)
    } else {
      this.inputTarget.value = e.detail.value
    }

    this.originalValueValue = e.detail.value
  }
})
