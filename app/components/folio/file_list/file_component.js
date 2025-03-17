//= require folio/confirm

window.Folio.Stimulus.register('f-file-list-file', class extends window.Stimulus.Controller {
  static targets = ['imageWrap', 'loader']

  static values = {
    templateData: { type: String, default: '' },
    s3Path: { type: String, default: '' },
    fileType: String,
    templateUrl: { type: String, default: '' }
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

    window.Folio.Api.apiPost('/folio/api/s3/after', data).catch((error) => {
      this.catchCounter = this.catchCounter || 0
      this.catchCounter += 1

      if (this.catchCounter > 10) {
        this.removeParentOrElement()
        window.alert(`Failed to process file: ${error.message}`)
      }

      if (this.timeout) window.clearTimeout(this.timeout)

      this.timeout = window.setTimeout(() => {
        this.pingApi()
      }, this.catchCounter * 500)
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
    if (!this.templateUrlValue) return

    const url = new URL(this.templateUrlValue, window.location.origin)
    url.searchParams.set('file_id', data.file_id)

    window.Folio.Api.apiGet(url.toString()).catch((error) => {
      this.catchCounter = this.catchCounter || 0
      this.catchCounter += 1

      if (this.catchCounter > 10) throw error
      if (this.timeout) window.clearTimeout(this.timeout)

      this.timeout = window.setTimeout(() => {
        this.messageBusSuccess(data)
      }, this.catchCounter * 500)
    }).catch((error) => {
      this.removeParentOrElement()
      window.alert(`Failed to process file: ${error.message}`)
    }).then((response) => {
      this.element.outerHTML = response.data
    })
  }

  messageBusFailure (data) {
    console.log('failure', data)
  }

  edit () {
    console.log('modal control click')
  }

  removeParentOrElement () {
    const parent = this.element.closest('.f-file-list__flex-item')

    if (parent) {
      parent.remove()
    } else {
      this.element.remove()
    }
  }

  destroy (e) {
    if (!e || !e.params || !e.params.url) return

    window.Folio.Confirm.confirm(() => {
      this.element.classList.add('f-file-list-file--destroying')

      window.Folio.Api.apiDelete(e.params.url).then(() => {
        this.removeParentOrElement()
      }).catch((error) => {
        this.element.classList.remove('f-file-list-file--destroying')
        window.alert(`Failed to delete file: ${error.message}`)
      })
    }, 'delete')
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
