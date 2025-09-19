//= require folio/confirm
//= require folio/i18n

window.Folio.Stimulus.register('f-file-list-file', class extends window.Stimulus.Controller {
  static targets = ['imagePart', 'loader', 'checkbox']

  static values = {
    id: { type: String, default: '' },
    loadFromId: { type: Boolean, default: false },
    templateData: { type: String, default: '' },
    jwt: { type: String, default: '' },
    s3Path: { type: String, default: '' },
    fileType: String,
    templateUrl: { type: String, default: '' },
    editable: { type: Boolean, default: false },
    destroyable: { type: Boolean, default: false },
    selectable: { type: Boolean, default: false },
    batchActions: { type: Boolean, default: false },
    primaryAction: { type: String, default: '' },
    serializedFileJson: String
  }

  static ERROR_MESSAGES = {
    en: {
      failedToProcessFile: 'Failed to process file',
      failedToFinishUploading: 'Failed to finished uploading file',
      failedToDeleteFile: 'Failed to delete file'
    },
    cs: {
      failedToProcessFile: 'Nepodařilo se zpracovat soubor',
      failedToFinishUploading: 'Nepodařilo se dokončit nahrávání souboru',
      failedToDeleteFile: 'Nepodařilo se smazat soubor'
    }
  }

  connect () {
    if (this.loadFromIdValue) {
      this.reload({ handleErrors: true })
      return
    }

    if (this.templateDataValue) {
      this.fillTemplate()
    }

    if ((this.s3PathValue || this.jwtValue) && this.fileTypeValue) {
      this.pingApi()
      this.boundMessageBusCallback = this.messageBusCallbackForCreate.bind(this)
      this.element.addEventListener('f-file-list-file/message', this.boundMessageBusCallback)
    } else {
      this.boundMessageBusCallback = this.messageBusCallbackGeneric.bind(this)
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
    if (!this.hasImagePartTarget) return

    const data = JSON.parse(this.templateDataValue)

    if (data.preview) {
      const img = document.createElement('img')
      img.classList.add('f-file-list-file__image')
      img.src = data.preview
      this.imagePartTarget.appendChild(img)
    }
  }

  pingApi () {
    if (!this.s3PathValue && !this.jwtValue) return
    if (!this.fileTypeValue) return

    const data = {
      jwt: this.jwtValue,
      s3_path: this.s3PathValue,
      type: this.fileTypeValue,
      message_bus_client_id: window.MessageBus.clientId
    }

    window.Folio.Api.apiPost('/folio/api/s3/after', data).catch((error) => {
      this.catchCounter = this.catchCounter || 0
      this.catchCounter += 1

      if (this.catchCounter > 10) {
        this.errorFlashMessage(`${window.Folio.i18n(this.constructor.ERROR_MESSAGES, 'failedToProcessFile')}: ${error.message}`)
        this.removeParentOrElement()
      }

      if (this.timeout) window.clearTimeout(this.timeout)

      this.timeout = window.setTimeout(() => {
        this.pingApi()
      }, this.catchCounter * 500)
    })
  }

  errorFlashMessage (content) {
    this.element.dispatchEvent(new CustomEvent('folio:flash', {
      bubbles: true,
      detail: {
        flash: {
          content,
          variant: 'danger'
        }
      }
    }))
  }

  messageBusCallbackForCreate (event) {
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

  messageBusCallbackGeneric (event) {
    const message = event.detail.message

    if (message.type === 'Folio::Console::FileControllerBase/file_updated' ||
        message.type === 'Folio::ApplicationJob/file_update' ||
        (message.type === 'Folio::S3::CreateFileJob' && message.data.type === 'replace-success')) {
      this.reload({ handleErrors: false })
    }
  }

  reload ({ handleErrors = true, updatePagy = false, addToBatch = false }) {
    if (this.element.closest('.f-c-files-batch-form')) {
      return this.dispatch('reloadForm')
    }

    const url = new URL('/folio/api/s3/file_list_file', window.location.origin)
    url.searchParams.set('file_id', this.idValue)
    url.searchParams.set('file_type', this.fileTypeValue)
    url.searchParams.set('primary_action', this.primaryActionValue)
    url.searchParams.set('selectable', this.selectableValue)
    url.searchParams.set('batch_actions', this.batchActionsValue)
    url.searchParams.set('add_to_batch', addToBatch)
    url.searchParams.set('editable', this.editableValue)
    url.searchParams.set('destroyable', this.destroyableValue)

    window.Folio.Api.apiGet(url.toString()).catch((error) => {
      if (!handleErrors) return

      this.catchCounter = this.catchCounter || 0
      this.catchCounter += 1

      if (this.catchCounter > 10) throw error
      if (this.timeout) window.clearTimeout(this.timeout)

      this.timeout = window.setTimeout(() => {
        this.reload({ handleErrors, updatePagy })
      }, this.catchCounter * 500)
    }).catch((error) => {
      if (!handleErrors) return

      this.removeParentOrElement()
      this.errorFlashMessage(`${window.Folio.i18n(this.constructor.ERROR_MESSAGES, 'failedToProcessFile')}: ${error.message}`)
    }).then((response) => {
      if (this.element.parentNode) {
        // only replace if still in the DOM
        this.element.outerHTML = response.data
      }

      if (response.meta && response.meta.reload_batch_bar) {
        const batchBar = document.querySelector('.f-c-files-batch-bar')
        if (!batchBar) return
        batchBar.dispatchEvent(new CustomEvent('f-c-files-batch-bar:reload'))
      }

      if (updatePagy && window.FolioConsole && window.FolioConsole.Ui && window.FolioConsole.Ui.Pagy) {
        window.FolioConsole.Ui.Pagy.reload()
      }
    })
  }

  messageBusSuccess (data) {
    this.idValue = data.file_id
    this.reload({ handleErrors: true, updatePagy: true, addToBatch: this.batchActionsValue === true })
  }

  messageBusFailure (data) {
    this.errorFlashMessage(`${window.Folio.i18n(this.constructor.ERROR_MESSAGES, 'failedToFinishUploading')} - ${data.errors.join(', ')}`)
    this.removeParentOrElement()
  }

  edit (e) {
    e.preventDefault()
    this.openShowModal()
  }

  primaryAction (e) {
    e.preventDefault()

    if (this.primaryActionValue === 'index_for_modal') {
      this.dispatch('select', { detail: { fileId: this.idValue } })
    } else if (this.primaryActionValue === 'index_for_picker') {
      const batchBar = document.querySelector('.f-c-files-batch-bar')
      console.log('if', 'this.serialized...lue:', this.serializedFileJsonValue, 'batchBar:', batchBar, 'batchBar.hidden:', batchBar.hidden)
      if (this.serializedFileJsonValue && batchBar && batchBar.hidden) {
        this.element.dispatchEvent(new CustomEvent('f-c-file-placements-multi-picker-fields:addToPicker', {
          bubbles: true,
          detail: {
            files: [JSON.parse(this.serializedFileJsonValue)]
          }
        }))
      } else {
        this.toggleBatch(e)
      }
    } else if (this.primaryActionValue === 'index') {
      const batchBar = document.querySelector('.f-c-files-batch-bar')
      if (batchBar && !batchBar.hidden) {
        this.toggleBatch(e)
      } else {
        this.openShowModal()
      }
    }
  }

  openShowModal () {
    if (!this.idValue) return

    const modal = document.querySelector('.f-c-files-show-modal')
    if (!modal) return

    modal.dispatchEvent(new window.CustomEvent('f-c-files-show-modal:openForFileData', {
      detail: {
        fileData: {
          type: this.fileTypeValue,
          id: this.idValue
        }
      }
    }))
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
        // notify batch bar to reload
        const batchBar = document.querySelector('.f-c-files-batch-bar')
        if (batchBar) {
          batchBar.dispatchEvent(new CustomEvent('f-c-files-batch-bar:reload'))
        }

        for (const fileElement of document.querySelectorAll(`.f-file-list-file[data-f-file-list-file-id-value="${this.idValue}"]`)) {
          fileElement.dispatchEvent(new CustomEvent('f-file-list-file:deleted'))
        }
      }).catch((error) => {
        this.element.classList.remove('f-file-list-file--destroying')
        this.errorFlashMessage(`${window.Folio.i18n(this.constructor.ERROR_MESSAGES, 'failedToDeleteFile')}: ${error.message}`)
      })
    }, 'delete')
  }

  fileUpdated (_e) {
    this.reload({ handleErrors: true })
  }

  fileDeleted (_e) {
    this.removeParentOrElement()
  }

  toggleBatch (e) {
    for (const checkbox of this.element.querySelectorAll('.f-file-list-file-batch-checkbox')) {
      checkbox.dispatchEvent(new CustomEvent('f-file-list-file-batch-checkbox:toggle', { detail: { shiftKey: e.shiftKey } }))
    }
  }
})

if (window.Folio && window.Folio.MessageBus && window.Folio.MessageBus.callbacks) {
  window.Folio.MessageBus.callbacks['f-file-list-file'] = (message) => {
    if (!message) return
    let selector

    if (message.type === 'Folio::Console::FileControllerBase/file_updated' || message.type === 'Folio::ApplicationJob/file_update') {
      selector = `.f-file-list-file[data-f-file-list-file-id-value="${message.data.id}"]`
    } else if (message.type === 'Folio::S3::CreateFileJob') {
      selector = `.f-file-list-file[data-f-file-list-file-s3-path-value="${message.data.s3_path}"], .f-file-list-file[data-f-file-list-file-id-value="${message.data.file_id}"]`
    }

    if (!selector) return

    const files = document.querySelectorAll(selector)

    for (const file of files) {
      file.dispatchEvent(new CustomEvent('f-file-list-file/message', { detail: { message } }))
    }
  }
}
