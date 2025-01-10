window.Folio.Stimulus.register('f-c-input-form-group-url', class extends window.Stimulus.Controller {
  static values = {
    loaded: Boolean,
    json: Boolean
  }

  static targets = ['input']

  static outlets = ['f-c-links-modal']

  disconnect () {
    if (this.abortController) {
      this.abortController.abort()
      delete this.abortController
    }
  }

  loadedValueChanged () {
    if (!this.loadedValue) {
      this.loadControlBar()
    }

    if (this.loadTimeout) {
      window.clearTimeout(this.loadTimeout)
    }
  }

  loadControlBar () {
    if (this.abortController) {
      return
    }

    if (this.loadTimeout) {
      window.clearTimeout(this.loadTimeout)
    }

    const baseUrl = '/console/api/links/control_bar'
    const data = {}

    if (this.jsonValue) {
      data.url_json = this.inputTarget.value || '{}'
    } else {
      data.href = this.inputTarget.value || ''
    }

    const url = window.Folio.addParamsToUrl(baseUrl, data)

    this.abortController = new AbortController()

    window.Folio.Api.apiGet(url, null, this.abortController.signal).then((res) => {
      if (res.data) {
        this.handleControlBarData(res.data)
        this.loadedValue = true
      } else {
        Promise.reject(new Error('No data in response'))
      }
    }).catch((e) => {
      this.loadTimeout = window.setTimeout(() => {
        this.loadControlBar()
      }, 1000)
    }).finally(() => {
      delete this.abortController
    })
  }

  handleControlBarData (data) {
    this.element.querySelector('.f-c-input-form-group-url__control-bar-wrap').innerHTML = data
  }

  edit () {
    const value = this.inputTarget.value
    let data = {}

    if (this.jsonValue) {
      try {
        data = JSON.parse(value)
      } catch (_e) {
      }
    } else {
      data.href = value
    }

    this.fCLinksModalOutlet.openWithData({ data, triggerController: this })
  }

  save (data) {
    if (this.jsonValue) {
      this.inputTarget.value = JSON.stringify(data)
    } else {
      this.inputTarget.value = data.href || ""
    }

    this.loadedValue = false

    this.inputTarget.dispatchEvent(new window.Event('change', { bubbles: true }))
  }

  remove () {
    this.save({})
  }
})
