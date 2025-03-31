//= require cleave.js/dist/cleave
//= require folio/form_to_hash

window.Folio.Stimulus.register('f-c-ui-ajax-input', class extends window.Stimulus.Controller {
  static targets = ['input', 'tooltip']

  static values = {
    cleave: Boolean,
    url: String,
    originalValue: String,
    method: String
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

  onKeyUp (e) {
    if (e.code === 'Enter' && this.inputTarget.tagName !== 'TEXTAREA') return this.save()

    if (this.element.classList.contains('f-c-ui-ajax-input--loading')) {
      e.preventDefault()
      e.stopPropagation()
      return false
    }

    this.element.classList.remove('f-c-ui-ajax-input--success')
    this.element.classList.remove('f-c-ui-ajax-input--failure')
    const value = this.cleave ? this.cleave.getRawValue() : this.inputTarget.value

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
  }

  onBlur () {
    this.dispatch('blur', { detail: { dirty: this.element.classList.contains('f-c-ui-ajax-input--dirty') } })
  }

  save (e) {
    if (e) e.preventDefault()

    if (this.element.classList.contains('f-c-ui-ajax-input--loading')) return false

    this.element.classList.add('f-c-ui-ajax-input--loading')

    const apiFn = this.methodValue === 'POST' ? window.Folio.Api.apiPost : window.Folio.Api.apiPatch

    const name = this.inputTarget.name

    const rawData = {}
    rawData[name] = this.cleave ? this.cleave.getRawValue() : this.inputTarget.value

    const data = window.Folio.formToHash(rawData)

    apiFn(this.urlValue, data).then((res) => {
      const key = name.replace(/^.+\[(.+)\]$/, '$1')

      if (this.cleave) {
        this.cleave.setRawValue(res.data[key])
      } else {
        this.inputTarget.value = res.data[key]
      }

      this.originalValueValue = res.data[key]
      this.inputTarget.blur()
      this.dispatch('success', { detail: { value: res.data[key] } })

      this.element.classList.add('f-c-ui-ajax-input--success')
      setTimeout(() => {
        if (this && this.element) {
          this.element.classList.remove('f-c-ui-ajax-input--success')
        }
      }, 3000)
    }).catch((err) => {
      this.tooltipTarget.innerHTML = err.message
      this.element.classList.add('f-c-ui-ajax-input--failure')
    }).finally(() => {
      this.element.classList.remove('f-c-ui-ajax-input--loading')
      this.element.classList.remove('f-c-ui-ajax-input--dirty')
    })
  }
})
