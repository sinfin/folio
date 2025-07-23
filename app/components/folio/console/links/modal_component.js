window.Folio.Stimulus.register('f-c-links-modal', class extends window.Stimulus.Controller {
  static values = {
    json: Boolean,
    loading: Boolean,
    apiUrl: String,
    preferredLabel: String,
    disableLabel: { type: Boolean, default: false },
    absoluteUrls: { type: Boolean, default: false },
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

  openWithUrlJson ({ urlJson, trigger, json, absoluteUrls, preferredLabel, disableLabel }) {
    this.trigger = trigger
    this.preferredLabelValue = preferredLabel
    this.disableLabelValue = disableLabel === true
    this.jsonValue = json !== false
    this.absoluteUrlsValue = absoluteUrls === true

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
      absolute_urls: this.absoluteUrlsValue,
      preferred_label: this.preferredLabelValue,
      disable_label: this.disableLabelValue,
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
        absoluteUrls: e.detail.absoluteUrls,
        json: e.detail.json,
        disableLabel: e.detail.disableLabel,
        preferredLabel: e.detail.preferredLabel,
      })
    }
  }
})
