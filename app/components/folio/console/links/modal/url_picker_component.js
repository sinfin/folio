window.Folio.Stimulus.register('f-c-links-modal-url-picker', class extends window.Stimulus.Controller {
  static values = {
    loading: Boolean,
    present: Boolean,
    apiUrl: String
  }

  static targets = ["valueWrap", "input"]

  disconnect () {
    if (this.loadTimeout) {
      window.clearTimeout(this.loadTimeout)
      this.loadTimeout = null
    }

    if (this.abortController) {
      this.abortController.abort()
      delete this.abortController
    }
  }

  selectedRecord (e) {
    this.inputTarget.value = e.detail.urlJson.href
    this.loadValue(e.detail.urlJson)
    this.dispatch("changed", { detail: { urlJson: e.detail.urlJson }})
  }

  loadValue (urlJson) {
    this.loadingValue = true
    this.valueWrapTarget.innerHTML = ""

    if (this.abortController) {
      this.abortController.abort()
    }

    this.abortController = new AbortController()

    const url = window.Folio.addParamsToUrl(this.apiUrlValue, { url_json: JSON.stringify(urlJson) })

    window.Folio.Api.apiGet(url, null, this.abortController.signal).then((res) => {
      this.valueWrapTarget.innerHTML = res.data || ""
      this.presentValue = !!res.data
      this.loadingValue = false
    }).catch((e) => {
      this.loadTimeout = window.setTimeout(() => {
        this.loadValue(urlJson)
      }, 1000)
    }).finally(() => {
      delete this.abortController
    })

  }

  edit () {
    this.presentValue = false
  }

  remove () {
    this.presentValue = false
    this.dispatch("changed", { detail: { urlJson: { href: "", label: "" } }})
  }

  input (e) {
    this.dispatch("changed", { detail: { urlJson: { href: e.target.value } }})
  }
})
