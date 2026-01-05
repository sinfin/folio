//= require folio/input/embed/inner_component

window.Folio.Stimulus.register('f-input-embed', class extends window.Stimulus.Controller {
  static targets = ['input']

  onFolioEmbedDataChange (e) {
    this.inputTarget.value = JSON.stringify(e.detail.folioEmbedData)
    this.inputTarget.dispatchEvent(new Event('change', { bubbles: true }))
  }
})
