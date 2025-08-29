window.Folio.Stimulus.register('f-c-files-index-modal', class extends window.Stimulus.Controller {
  static values = {
    turboFrameUrls: Object,
    turboFrameId: String
  }

  static targets = ['body']

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

    for (const turboFrame of this.element.querySelectorAll('turbo-frame')) {
      turboFrame.remove()
    }

    this.bodyTarget.insertAdjacentHTML('afterbegin', `<turbo-frame id="${this.turboFrameIdValue}" src="${url}" data-f-c-files-picker-target="turboFrame"></turbo-frame>`)

    window.Folio.Modal.open(this.element)
  }
})
