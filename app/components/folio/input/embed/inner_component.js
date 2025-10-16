window.Folio.Stimulus.register('f-input-embed-inner', class extends window.Stimulus.Controller {
  static values = {
    state: String,
    supportedTypes: Object,
    folioEmbedData: Object
  }

  static targets = ['input', 'previewWrap', 'box']

  connect () {
    this.handleFolioEmbedDataChange = true
  }

  onInput (e) {
    this.updateStateBasedOnInputs()
  }

  stateValueChanged (to, from) {
    this.updatePreview()
  }

  folioEmbedDataValueChanged (to, from) {
    if (!this.handleFolioEmbedDataChange) return

    this.updatePreview()
    this.dispatchInputUpdate()
  }

  dispatchInputUpdate () {
    this.dispatch('folio-embed-data-changed', {
      detail: {
        folioEmbedData: this.folioEmbedDataValue
      }
    })
  }

  updateStateBasedOnInputs () {
    const inputValue = this.inputTarget.value.trim()

    if (!inputValue) {
      this.stateValue = 'blank'
      this.folioEmbedDataValue = { active: false }
      return
    }

    // Check if it's HTML (contains HTML tags)
    if (/<[^>]+>/.test(inputValue)) {
      this.stateValue = 'valid-html'
      this.folioEmbedDataValue = {
        active: true,
        html: inputValue
      }
      return
    }

    // Check if it's a supported URL
    const detectedType = this.detectUrlType(inputValue)
    if (detectedType) {
      this.stateValue = 'valid-url'
      this.folioEmbedDataValue = {
        active: true,
        type: detectedType,
        url: inputValue
      }
    } else {
      this.stateValue = 'invalid-url'
      this.folioEmbedDataValue = { active: false }
    }
  }

  detectUrlType (url) {
    for (const [type, regexSource] of Object.entries(this.supportedTypesValue)) {
      const regex = new RegExp(regexSource)
      if (regex.test(url)) {
        return type
      }
    }
    return null
  }

  updatePreview () {
    this.boxTarget.dispatchEvent(new CustomEvent('f-input-embed-inner:update', {
      detail: {
        state: this.stateValue,
        folioEmbedData: this.folioEmbedDataValue
      },
      bubbles: true
    }))
  }

  getFolioEmbedData () {
    return this.folioEmbedDataValue
  }
})
