window.Folio.Stimulus.register('f-c-ui-turbo-frame-with-loader', class extends window.Stimulus.Controller {
  static targets = ['errorStatus']

  onFrameRender () {
    this.element.classList.remove('f-c-ui-turbo-frame-with-loader--error')
  }

  onFrameMissing (e) {
    if (e && e.detail && e.detail.response) {
      this.errorStatusTarget.innerText = `${e.detail.response.status}: ${e.detail.response.statusText}`
    } else {
      this.errorStatusTarget.innerText = ''
    }

    this.element.classList.add('f-c-ui-turbo-frame-with-loader--error')
  }
})
