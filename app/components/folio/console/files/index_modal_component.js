window.Folio.Stimulus.register('f-c-files-index-modal', class extends window.Stimulus.Controller {
  static values = {
    turboFrameUrls: Object,
    turboFrameId: String
  }

  openWithType (e) {
    if (!e.detail.fileType) {
      window.alert('[Folio::Console::Files::IndexModalComponent] Missing fileType!')
      return
    }

    const url = this.turboFrameUrlsValue[e.detail.fileType]
    if (!url) {
      window.alert(`[Folio::Console::Files::IndexModalComponent] Missing URL for fileType ${e.detail.fileType}!`)
      return
    }

    const frame = this.element.querySelector('turbo-frame')
    frame.src = url
    frame.disabled = false

    window.Folio.Modal.open(this.element)
  }
})
