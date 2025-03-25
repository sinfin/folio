//= require folio/confirm

window.Folio.Stimulus.register('f-c-files-show', class extends window.Stimulus.Controller {
  static values = {
    loading: Boolean,
    fileType: String,
    id: String,
    showUrl: String
  }

  disconnect () {
    this.abortAjaxRequest()
    delete this.replacingFileData

    if (this.pingTimeout) {
      window.clearTimeout(this.pingTimeout)
    }
  }

  abortAjaxRequest () {
    if (this.abortController) {
      this.abortController.abort()
      delete this.abortController
    }
  }

  onDestroyClick (e) {
    if (!e || !e.params || !e.params.url) return
    if (this.replacingFileData) return

    window.Folio.Confirm.confirm(() => {
      this.abortAjaxRequest()
      this.loadingValue = true

      this.abortController = new AbortController()

      window.Folio.Api.apiDelete(e.params.url, null, this.abortController.signal).then(() => {
        this.element.dispatchEvent(new CustomEvent('f-c-files-show/deleted', { bubbles: true, detail: { id: this.idValue } }))
        this.dispatch('deleted')
      }).catch((error) => {
        window.alert(`Could not delete file: ${error.message}`)
      }).finally(() => {
        this.loadingValue = false
        delete this.abortController
      })
    }, 'delete')
  }

  uppyUploadSuccess (event) {
    this.loadingValue = true
    this.replacingFileData = {
      s3_path: new URL(event.detail.result.uploadURL).pathname.replace(/^\//, ''),
      type: this.fileTypeValue,
      existing_id: this.idValue
    }

    this.pingS3After()
  }

  pingS3After () {
    window.Folio.Api.apiPost('/folio/api/s3/after', this.replacingFileData).catch((error) => {
      this.pingCatchCounter = this.pingCatchCounter || 0
      this.pingCatchCounter += 1

      if (this.pingCatchCounter > 10) {
        window.alert(`Failed to process file: ${error.message}`)
      }

      if (this.pingTimeout) window.clearTimeout(this.pingTimeout)

      this.pingTimeout = window.setTimeout(() => {
        this.pingS3After()
      }, this.pingCatchCounter * 500)
    })
  }

  messageBusCallback (event) {
    const message = event.detail.message
    if (message.type !== 'Folio::S3::CreateFileJob') return
    switch (message.data.type) {
      case 'replace-success':
        this.messageBusSuccess()
        break
      case 'replace-failure':
        this.messageBusFailure(message.data)
        break
    }
  }

  messageBusSuccess (data) {
    this.element.dispatchEvent(new CustomEvent('f-c-files-show-modal/show-file', {
      bubbles: true,
      detail: {
        id: this.idValue,
        url: this.showUrlValue
      }
    }))
  }

  messageBusFailure (data) {
    this.loadingValue = false
    delete this.replacingFileData
    window.alert(`Could not replace file: ${data.error}`)
  }
})

if (window.Folio && window.Folio.MessageBus && window.Folio.MessageBus.callbacks) {
  window.Folio.MessageBus.callbacks['f-c-files-show'] = (message) => {
    if (!message) return
    if (message.type !== 'Folio::S3::CreateFileJob') return

    const selector = `.f-c-files-show[data-f-c-files-show-id-value="${message.data.file_id}"]`
    const targets = document.querySelectorAll(selector)

    for (const target of targets) {
      target.dispatchEvent(new CustomEvent('f-c-files-show/message', { detail: { message } }))
    }
  }
}
