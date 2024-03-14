//= require folio/add_params_to_url
//= require folio/debounce

window.Folio.Stimulus.register('d-searches-show', class extends window.Stimulus.Controller {
  static targets = ['form', 'input', 'contentsWrap']

  static values = {
    loading: Boolean
  }

  connect () {
    this.moveInputCursor()
  }

  disconnect () {
    this.abortLoad()
  }

  debouncedLoad = window.Folio.debounce(() => {
    const paramsHash = {}

    if (this.inputTarget.value) {
      paramsHash.q = this.inputTarget.value
    }

    const urlParams = new URLSearchParams(window.location.href)
    const tab = urlParams.get('tab')
    if (tab) paramsHash.tab = tab

    const url = Object.keys(paramsHash).length ? window.Folio.addParamsToUrl(this.formTarget.action, paramsHash) : this.formTarget.action

    this.abortLoad()
    this.abortController = new AbortController()

    if (window.Turbolinks) {
      window.Turbolinks.controller.replaceHistoryWithLocationAndRestorationIdentifier(url, window.Turbolinks.uuid())
    }

    window.Folio.Api.apiGet(url, null, this.abortController.signal).then((res) => {
      if (res && res.data) {
        this.contentsWrapTarget.innerHTML = res.data
      } else {
        throw new Error('No data')
      }
    }).catch((err) => {
      if (err.name === 'AbortError') return
      window.Dummy.Ui.Flash.alert(err.message)
    }).finally(() => {
      this.loadingValue = false
    })
  })

  load () {
    if (!this.loadingValue) this.loadingValue = true
    this.debouncedLoad()
  }

  onFormSubmit (e) {
    e.preventDefault()
    this.load()
  }

  onInputFocus () {
    this.moveInputCursor()
  }

  moveInputCursor () {
    const length = this.inputTarget.value.length
    this.inputTarget.setSelectionRange(length, length)
  }

  onInputInput (e) {
    this.load()
  }

  abortLoad () {
    if (this.abortController) {
      this.abortController.abort()
      this.abortController = null
    }
  }
})
