window.Folio.Stimulus.register('f-c-links-modal-url-picker', class extends window.Stimulus.Controller {
  static values = {
    valueLoading: Boolean,
    listLoading: Boolean,
    valuePresent: Boolean,
    filtering: Boolean,
    apiValueUrl: String,
    apiListUrl: String
  }

  static targets = ['valueWrap', 'input', 'cancelButton', 'form', 'listContent']

  disconnect () {
    if (this.listLoadTimeout) {
      window.clearTimeout(this.listLoadTimeout)
      this.listLoadTimeout = null
    }

    if (this.listAbortController) {
      this.listAbortController.abort()
      delete this.listAbortController
    }

    if (this.valueLoadTimeout) {
      window.clearTimeout(this.valueLoadTimeout)
      this.valueLoadTimeout = null
    }

    if (this.valueAbortController) {
      this.valueAbortController.abort()
      delete this.valueAbortController
    }
  }

  selectedRecord (e) {
    this.inputTarget.value = e.detail.urlJson.href
    this.loadValue(e.detail.urlJson)
    this.dispatch('changed', { detail: { urlJson: e.detail.urlJson } })
  }

  loadValue (urlJson) {
    this.valueLoadingValue = true
    this.valueWrapTarget.innerHTML = ''

    if (this.valueAbortController) {
      this.valueAbortController.abort()
    }

    this.valueAbortController = new AbortController()

    const url = window.Folio.addParamsToUrl(this.apiValueUrlValue, { url_json: JSON.stringify(urlJson) })

    window.Folio.Api.apiGet(url, null, this.valueAbortController.signal).then((res) => {
      this.valueWrapTarget.innerHTML = res.data || ''
      this.valuePresentValue = !!res.data
      this.valueLoadingValue = false
    }).catch((e) => {
      this.valueLoadTimeout = window.setTimeout(() => {
        this.loadValue(urlJson)
      }, 1000)
    }).finally(() => {
      delete this.valueAbortController
    })
  }

  edit () {
    this.valuePresentValue = false
  }

  remove () {
    this.valuePresentValue = false
    this.dispatch('changed', { detail: { urlJson: { href: '', label: '' } } })
  }

  input (e) {
    this.dispatch('changed', { detail: { urlJson: { href: e.target.value } } })
  }

  onFormChange (e) {
    this.loadList()
  }

  onFormSubmit (e) {
    e.preventDefault()
    this.loadList()
  }

  loadList () {
    const rawData = window.Folio.formToHash(this.formTarget)
    const data = {}
    let filtering = false

    for (const key in rawData) {
      if (rawData[key]) {
        filtering = true
        data[key] = rawData[key]
      }
    }

    this.filteringValue = filtering

    this.listLoadingValue = true

    if (this.listAbortController) {
      this.listAbortController.abort()
    }

    this.listAbortController = new AbortController()

    const url = window.Folio.addParamsToUrl(this.apiListUrlValue, data)

    window.Folio.Api.apiGet(url, null, this.listAbortController.signal).then((res) => {
      this.listContentTarget.innerHTML = res.data || ''
      this.listLoadingValue = false
    }).catch((e) => {
      this.listLoadTimeout = window.setTimeout(() => {
        this.loadList()
      }, 1000)
    }).finally(() => {
      delete this.listAbortController
    })
  }

  cancelFilters () {
    this.formTarget.reset()
    this.loadList()
  }
})
