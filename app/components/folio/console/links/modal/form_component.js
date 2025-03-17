window.Folio.Stimulus.register('f-c-links-modal-form', class extends window.Stimulus.Controller {
  static targets = ['hrefInput', 'recordIdInput', 'recordTypeInput', 'labelInput']

  static values = {
    json: Boolean,
    preferredLabel: String
  }

  onSubmit (e) {
    e.preventDefault()
    const data = window.Folio.formToHash(e.target)

    let validHref = false

    if (data.href) {
      const trimmed = data.href.trim()

      if (data.href !== trimmed) {
        data.href = trimmed
      }

      // data.href must be a valid absolute/relative/anchor url
      const regex = /^(https?:\/\/\w+|\/|#\w+)/
      validHref = regex.test(data.href)
    }

    if (!validHref) {
      this.element.querySelector('.f-c-ui-tabs__nav-link[data-bs-target="#tab-custom_url"]').click()
      const input = this.element.querySelector('.f-c-links-modal-url-picker__href-input')
      window.FolioConsole.DangerBoxShadowBlink.blinkFormGroup(input.closest('.form-group'))
      input.focus()
      return
    }

    if (typeof data.target === 'object') {
      data.target = data.target[0]
    }

    if (data.record_id) {
      const idAsNumber = parseInt(data.record_id)
      if (idAsNumber) data.record_id = idAsNumber
    } else {
      delete data.record_id
      delete data.record_type
    }

    this.dispatch('submit', { detail: { data } })
  }

  changedInUrlPicker (e) {
    if (e.detail.urlJson) {
      this.hrefInputTarget.value = e.detail.urlJson.href

      if (this.jsonValue) {
        if (!this.preferredLabelValue && typeof e.detail.urlJson.label !== 'undefined') {
          this.labelInputTarget.value = e.detail.urlJson.label
        }

        if (e.detail.urlJson.record_id && e.detail.urlJson.record_type) {
          this.recordIdInputTarget.value = e.detail.urlJson.record_id
          this.recordTypeInputTarget.value = e.detail.urlJson.record_type
        } else {
          this.recordIdInputTarget.value = ''
          this.recordTypeInputTarget.value = ''
        }
      }
    }
  }
})
