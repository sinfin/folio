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
          return
        }

        if (value === this.originalValueValue) {
          return this.cancel()
        } else {
          return this.save()
        }
      }
    } else if (e.key === 'Escape') {
      if (value === this.originalValueValue) {
        return this.cancel()
      }
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

  cancel (e) {
    if (e) e.preventDefault()
    if (this.element.classList.contains('f-c-ui-ajax-input--loading')) return false

    if (this.cleave) {
      this.cleave.setRawValue(this.originalValueValue)
    } else {
      this.inputTarget.value = this.originalValueValue
    }

    this.element.classList.remove('f-c-ui-ajax-input--dirty')
    this.element.classList.remove('f-c-ui-ajax-input--success')
    this.element.classList.remove('f-c-ui-ajax-input--failure')

    this.dispatch('blur', { detail: { dirty: false } })
    this.inputTarget.dispatchEvent(new CustomEvent('f-c-ui-ajax-input:cancel', { bubbles: true }))
  }

  onBlur () {
    this.dispatch('blur', { detail: { dirty: this.element.classList.contains('f-c-ui-ajax-input--dirty') } })
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
      const rawData = {}
      rawData[name] = this.cleave ? this.cleave.getRawValue() : this.inputTarget.value

      // replace new lines if it's a string
      if (typeof rawData[name] === 'string') {
        rawData[name] = rawData[name].replace(/\r?\n/g, ' ')
      }

      // const data = window.Folio.formToHash(rawData)

      apiFn(this.urlValue, data).then((res) => {
        const key = name.replace(/^.+\[(.+)\]$/, '$1')

        let newValue, newLabel

        if (this.inputTarget.multiple) {
          // For multiselect, prefer API data if available, fallback to DOM
          selectedOptions  = Array.from(this.inputTarget.selectedOptions)
          newValue = res.data?.attributes?.[key] || res.data?.[key] || selectedOption.map.map(option => option.value)
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
