window.Folio.Stimulus.register('f-c-links-modal', class extends window.Stimulus.Controller {
  static values = {
    json: Boolean,
    loading: Boolean,
    apiUrl: String,
    preferredLabel: String,
  }

  static targets = ['formWrap']

  disconnect () {
    this.trigger = null

    if (this.loadTimeout) {
      window.clearTimeout(this.loadTimeout)
      this.loadTimeout = null
    }

    if (this.abortController) {
      this.abortController.abort()
      delete this.abortController
    }
  }

  openWithUrlJson ({ urlJson, trigger, json, preferredLabel }) {
    this.trigger = trigger
    this.preferredLabelValue = preferredLabel
    this.jsonValue = json !== false

    this.loadForm(urlJson)

    window.Folio.Modal.open(this.element)
  }

  loadForm (urlJson) {
    this.loadingValue = true
    this.formWrapTarget.innerHTML = ''

    if (this.abortController) {
      this.abortController.abort()
    }

    this.abortController = new AbortController()

    const url = window.Folio.addParamsToUrl(this.apiUrlValue, {
      url_json: JSON.stringify(urlJson),
      json: this.jsonValue,
      preferred_label: this.preferredLabelValue,
    })

    window.Folio.Api.apiGet(url, null, this.abortController.signal).then((res) => {
      if (res.data) {
        this.formWrapTarget.innerHTML = res.data
        this.loadingValue = false
      } else {
        Promise.reject(new Error('No data in response'))
      }
    }).catch((e) => {
      this.loadTimeout = window.setTimeout(() => {
        this.loadForm(urlJson)
      }, 1000)
    }).finally(() => {
      delete this.abortController
    })
  }

  cancel () {
    window.Folio.Modal.close(this.element)
    this.formWrapTarget.innerHTML = ''
  }

  submit (e) {
    if (this.trigger) {
      this.trigger.saveUrlJson(e.detail.data)
      this.trigger = null
    }

    window.Folio.Modal.close(this.element)
    this.formWrapTarget.innerHTML = ''
  }

  onOpen (e) {
    if (e.detail && e.detail.urlJson) {
      this.openWithUrlJson({
        urlJson: e.detail.urlJson,
        trigger: e.detail.trigger,
        json: e.detail.json,
        preferredLabel: e.detail.preferredLabel,
      })
    }
  }
})
