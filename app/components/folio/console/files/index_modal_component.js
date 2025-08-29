window.Folio.Stimulus.register('f-c-files-index-modal', class extends window.Stimulus.Controller {
  static values = {
    turboFrameUrls: Object,
    turboFrameId: String
  }

  disconnect () {
    delete this.triggerElement
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

    if (!e.detail.trigger) {
      window.alert('[Folio::Console::Files::IndexModalComponent] Missing trigger element!')
      return
    }

    this.triggerElement = e.detail.trigger

    const frame = this.element.querySelector('turbo-frame')

    if (!frame.src || !frame.src.endsWith(url)) {
      frame.src = url
      frame.disabled = false
    }

    window.Folio.Modal.open(this.element)
  }

  onFileSelect (e) {
    if (!this.triggerElement) {
      window.alert('[Folio::Console::Files::IndexModalComponent] Missing trigger element!')
      return
    }

    if (!e.detail.fileId) {
      window.alert('[Folio::Console::Files::IndexModalComponent] Missing fileId in event detail!')
      return
    }

    this.triggerElement.dispatchEvent(new CustomEvent('f-c-files-index-modal:selectedFile', {
      detail: {
        fileId: e.detail.fileId
      }
    }))

    window.Folio.Modal.close(this.element)
  }

  onModalClosed () {
    delete this.triggerElement
  }
})
