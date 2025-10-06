window.Folio.Stimulus.register('f-input-embed-inner', class extends window.Stimulus.Controller {
  static values = {
    state: String
  }

  static targets = ['input', 'previewWrap', 'box']

  onInput (e) {
    this.updateStateBasedOnInputs()
  }

  stateValueChanged (to, from) {
    this.updatePreview()
  }

  updatePreview () {
    this.boxTarget.dispatchEvent(new CustomEvent('f-input-embed-inner:update', {
      detail: {
        state: this.stateValue,
        folioEmbedData: this.getFolioEmbedData()
      },
      bubbles: true
    }))
  }

  getFolioEmbedData () {
    return {}
  }
})
