window.Folio.Stimulus.register('f-c-links-control-bar', class extends window.Stimulus.Controller {
  static values = {
    json: Boolean,
    absoluteUrls: { type: Boolean, default: false },
    defaultCustomUrl: { type: Boolean, default: false },
  }

  onAddClick (e) {
    e.preventDefault()

    this.element.dispatchEvent(new CustomEvent('f-c-input-form-group-url:edit', {
      bubbles: true,
      detail: { json: this.jsonValue, absoluteUrls: this.absoluteUrlsValue, defaultCustomUrl: this.defaultCustomUrlValue }
    }))
  }
})
