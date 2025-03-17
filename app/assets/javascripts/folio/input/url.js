// respect changes in app/overrides/lib/simple_form/inputs/base_override.rb

window.Folio = window.Folio || {}
window.Folio.Input = window.Folio.Input || {}
window.Folio.Input.Url = window.Folio.Input.Url || {}

window.Folio.Input.Url.disposeFormGroup = (formGroup) => {
  const input = formGroup.querySelector('.form-control')

  formGroup.removeAttribute('data-controller')

  input.removeAttribute('data-f-c-input-form-group-url-target')

  const customHtml = formGroup.querySelector('.form-group__custom-html')
  if (customHtml) customHtml.remove()

  formGroup.removeAttribute('data-f-c-input-form-group-url-loaded-value')
  formGroup.removeAttribute('data-f-c-input-form-group-url-json-value')
  formGroup.removeAttribute('data-action')

  formGroup.classList.remove('f-c-input-form-group-url')
}

window.Folio.Input.Url.initFormGroup = (formGroup, opts = {}) => {
  const input = formGroup.querySelector('.form-control')

  input.setAttribute('data-f-c-input-form-group-url-target', 'input')

  formGroup.classList.add('f-c-input-form-group-url')
  formGroup.setAttribute('data-f-c-input-form-group-url-loaded-value', 'false')
  formGroup.setAttribute('data-f-c-input-form-group-url-json-value', opts.json ? 'true' : 'false')
  formGroup.setAttribute('data-action', 'f-c-input-form-group-url:edit->f-c-input-form-group-url#edit f-c-input-form-group-url:remove->f-c-input-form-group-url#remove')

  formGroup.insertAdjacentHTML('beforeend', `
    <div class="form-group__custom-html">
      <div class="f-c-input-form-group-url__inner">
        <div class="f-c-input-form-group-url__loader-wrap">
          <div class="folio-loader folio-loader--small f-c-input-form-group-url__loader"></div>
        </div>
        <div class="f-c-input-form-group-url__control-bar-wrap"></div>
    </div>
  `)

  formGroup.dataset.controller = 'f-c-input-form-group-url'
}

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
    const data = { json: this.jsonValue }

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

  edit (e) {
    const value = this.inputTarget.value
    let urlJson = {}

    if (this.jsonValue) {
      try {
        urlJson = JSON.parse(value)
      } catch (_e) {
      }
    } else {
      urlJson.href = value
    }

    const json = e.detail.json !== false

    document.querySelector('.f-c-links-modal').dispatchEvent(new window.CustomEvent('f-c-links-modal:open', { detail: { urlJson, json, trigger: this } }))
  }

  saveUrlJson (data) {
    let value

    if (this.jsonValue) {
      value = JSON.stringify(data)
    } else {
      value = data.href || ''
    }

    this.inputTarget.dataset.value = value
    this.inputTarget.value = value
    this.loadedValue = false

    this.inputTarget.dispatchEvent(new window.Event('change', { bubbles: true }))
  }

  remove () {
    this.saveUrlJson({})
  }
})
