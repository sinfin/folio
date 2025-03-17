window.Folio.Stimulus.register('f-file-list-file', class extends window.Stimulus.Controller {
  static targets = ['imageWrap', 'loader']

  static values = {
    templateData: { type: String, default: '' },
    s3Path: { type: String, default: '' },
    fileType: String
  }

  connect () {
    if (this.templateDataValue) {
      this.fillTemplate()
    }

    if (this.s3PathValue && this.fileTypeValue) {
      this.pingApi()
      this.boundMessageBusCallback = this.messageBusCallback.bind(this)
      this.element.addEventListener('f-file-list-file/message', this.boundMessageBusCallback)
    }
  }

  disconnect () {
    if (this.timeout) {
      window.clearTimeout(this.timeout)
    }

    if (this.boundMessageBusCallback) {
      this.element.removeEventListener('f-file-list-file/message', this.boundMessageBusCallback)
      delete this.boundMessageBusCallback
    }
  }

  fillTemplate () {
    const data = JSON.parse(this.templateDataValue)

    if (data.preview) {
      const img = document.createElement('img')
      img.classList.add('f-file-list-file__image')
      img.src = data.preview
      this.imageWrapTarget.appendChild(img)
    }
  }

  pingApi () {
    if (!this.s3PathValue) return
    if (!this.fileTypeValue) return

    const data = {
      s3_path: this.s3PathValue,
      type: this.fileTypeValue
    }

    window.Folio.Api.apiPost('/folio/api/s3/after', data).catch(() => {
      this.timeoutRunner = this.timeoutRunner || 500
      this.timeoutRunner += 500

      if (this.timeout) window.clearTimeout(this.timeout)

      this.timeout = window.setTimeout(() => {
        this.pingApi()
      }, this.timeoutRunner)
    })
  }

  messageBusCallback (event) {
    const message = event.detail.message
    if (message.type !== 'Folio::S3::CreateFileJob') return
    switch (message.data.type) {
      case 'success':
        this.messageBusSuccess(message.data)
        break
      case 'failure':
        this.messageBusFailure(message.data)
        break
    }
  }

  messageBusSuccess (data) {
    const url = new URL('/folio/api/s3/file_list_file', window.location.origin)
    url.searchParams.set('file_type', data.file_type)
    url.searchParams.set('file_id', data.file_id)

    window.Folio.Api.apiGet(url.toString()).catch(() => {
      this.timeoutRunner = this.timeoutRunner || 500
      this.timeoutRunner += 500

      if (this.timeout) window.clearTimeout(this.timeout)

      this.timeout = window.setTimeout(() => {
        this.messageBusSuccess(data)
      }, this.timeoutRunner)
    }).then((response) => {
      this.element.outerHTML = response.data
    })
  }

  messageBusFailure (data) {
    console.log('failure', data)
  }
})

if (window.Folio && window.Folio.MessageBus && window.Folio.MessageBus.callbacks) {
  window.Folio.MessageBus.callbacks['f-file-list-file'] = (message) => {
    if (!message) return
    if (message.type !== 'Folio::S3::CreateFileJob') return

    const selector = `.f-file-list-file[data-f-file-list-file-s3-path-value="${message.data.s3_path}"]`
    const files = document.querySelectorAll(selector)

    for (const file of files) {
      file.dispatchEvent(new CustomEvent('f-file-list-file/message', { detail: { message } }))
    }
  }
}
