window.Folio.Stimulus.register('f-c-links-modal', class extends window.Stimulus.Controller {
  static values = {
    loading: Boolean,
    apiUrl: String
  }

  static targets = ['formWrap']

  disconnect () {
    this.triggerController = null

    if (this.loadTimeout) {
      window.clearTimeout(this.loadTimeout)
      this.loadTimeout = null
    }

    if (this.abortController) {
      this.abortController.abort()
      delete this.abortController
    }
  }

  openWithData ({ data, triggerController }) {
    this.triggerController = triggerController

    this.loadForm(data)

    window.Folio.Modal.open(this.element)
  }

  loadForm (data) {
    this.loadingValue = true
    this.formWrapTarget.innerHTML = ""

    if (this.abortController) {
      this.abortController.abort()
    }

    this.abortController = new AbortController()

    const url = window.Folio.addParamsToUrl(this.apiUrlValue, { url_json: JSON.stringify(data) })

    window.Folio.Api.apiGet(url, null, this.abortController.signal).then((res) => {
      if (res.data) {
        this.formWrapTarget.innerHTML = res.data
        this.loadingValue = false
      } else {
        Promise.reject(new Error('No data in response'))
      }
    }).catch((e) => {
      this.loadTimeout = window.setTimeout(() => {
        this.loadForm(data)
      }, 1000)
    }).finally(() => {
      delete this.abortController
    })
  }

  cancel () {
    window.Folio.Modal.close(this.element)
    this.formWrapTarget.innerHTML = ""
  }

  submit (e) {
    console.log(e.detail.data)
  }
})
