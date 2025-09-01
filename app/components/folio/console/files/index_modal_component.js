window.Folio.Stimulus.register('f-c-files-index-modal', class extends window.Stimulus.Controller {
  static values = {
    turboFrameConfig: Object
  }

  static targets = ['type']

  disconnect () {
    delete this.triggerElement
  }

  openWithType (e) {
    if (!e.detail.fileType) {
      window.alert('[Folio::Console::Files::IndexModalComponent] Missing fileType!')
      return
    }

    if (!e.detail.trigger) {
      window.alert('[Folio::Console::Files::IndexModalComponent] Missing trigger element!')
      return
    }

    this.triggerElement = e.detail.trigger

    let typeElement

    this.typeTargets.forEach((typeTarget) => {
      const turboFrame = typeTarget.querySelector('turbo-frame')

      if (typeTarget.dataset.type === e.detail.fileType) {
        if (turboFrame.disabled) {
          turboFrame.disabled = false
        }

        typeTarget.hidden = false

        typeElement = typeTarget
      } else {
        if (!turboFrame.disabled) {
          turboFrame.disabled = true
        }

        typeTarget.hidden = true
      }
    })

    if (!typeElement) {
      window.alert(`[Folio::Console::Files::IndexModalComponent] Invalid fileType: ${e.detail.fileType}!`)
      return
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
