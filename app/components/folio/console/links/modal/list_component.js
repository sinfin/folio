window.Folio.Stimulus.register('f-c-links-modal-list', class extends window.Stimulus.Controller {
  onRecordClick (e) {
    e.preventDefault()
    this.dispatch("selectedRecord", { detail: { urlJson: JSON.parse(e.currentTarget.dataset.urlJson) } })
  }

  onRecordLinkClick (e) {
    e.stopPropagation()
  }
})
