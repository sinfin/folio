window.Folio.Stimulus.register('d-searches-show', class extends window.Stimulus.Controller {
  static targets = ['form', 'input', 'contentsWrap']
  static values = {
    loading: Boolean
  }

  disconnect () {
    this.abortLoad()
  }

  debouncedLoad = window.Folio.debounce(() => {
    const paramsHash = { q: this.inputTarget.value }

    const urlParams = new URLSearchParams(window.location.href)
    const tab = urlParams.get('tab')
    if (tab) paramsHash.tab = tab

    const url = window.Folio.addParamsToUrl(this.formTarget.action, paramsHash)

    this.abortLoad()
    this.abortController = new AbortController()

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
    console.log('onFormSubmit', e)
  }

  onInputFocus (e) {
    // swaps the cursor to the back
    const value = e.target.value
    e.target.value = ''
    e.target.value = value
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
