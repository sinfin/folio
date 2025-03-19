window.Folio.Stimulus.register('f-c-links-modal-url-picker', class extends window.Stimulus.Controller {
  static values = {
    valueLoading: Boolean,
    listLoading: Boolean,
    valuePresent: Boolean,
    filtering: Boolean,
    autofocusInput: Boolean,
    apiValueUrl: String,
    apiListUrl: String,
    absoluteUrls: { type: Boolean, default: false }
  }

  static targets = ['valueWrap', 'input', 'cancelButton', 'form', 'listContent']

  connect () {
    if (this.autofocusInputValue) {
      this.inputTarget.focus()

      const length = this.inputTarget.value.length
      this.inputTarget.setSelectionRange(length, length)
    }

    this.onQueryInput = Folio.debounce(() => {
      this.loadList()
    })
  }

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

    delete this.onQueryInput
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
    this.inputTarget.value = ""
    this.valuePresentValue = false
    this.dispatch('changed', { detail: { urlJson: { href: '', label: '' } } })
  }

  removeValue () {
    this.valuePresentValue = false
    this.valueWrapTarget.innerHTML = ''
  }

  onInputChange (e) {
    this.removeValue()

    const urlJson = { href: e.target.value }
    this.dispatch('changed', { detail: { urlJson } })
  }

  onFormChange (e) {
    this.markSelectsAndLoadList()
  }

  onFormSubmit (e) {
    e.preventDefault()
    this.markSelectsAndLoadList()
  }

  loadList () {
    const rawData = window.Folio.formToHash(this.formTarget)

    if (rawData.q && rawData.q.length < 3) {
      delete rawData.q
    }

    Object.keys(rawData).forEach((key) => {
      if (rawData[key] === '') {
        delete rawData[key]
      }
    })

    const json = JSON.stringify(rawData)

    if (json === "{}" && !this.lastLoadListJson) return
    if (json === this.lastLoadListJson) return

    this.lastLoadListJson = json

    const data = {
      absolute_urls: this.absoluteUrlsValue
    }

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

    for (const input of this.formTarget.querySelectorAll('.f-input--collection-remote-select')) {
      window.Folio.Input.CollectionRemoteSelect.clearValue(input)
    }

    this.markSelectsAndLoadList()
  }

  markSelectsAndLoadList () {
    for (const input of this.formTarget.querySelectorAll('.f-input--collection-remote-select')) {
      const wrap = input.closest('.f-c-links-modal-url-picker__list-filter')
      wrap.classList.toggle('f-c-links-modal-url-picker__list-filter--active', !!input.value)
    }

    this.loadList()
  }

  resetAdditionalFilter (e) {
    e.preventDefault()
    const input = e.target.closest('.f-c-links-modal-url-picker__list-filter').querySelector('.f-input--collection-remote-select')

    window.Folio.Input.CollectionRemoteSelect.clearValue(input)
  }
})
