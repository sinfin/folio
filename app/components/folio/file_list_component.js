window.Folio.Stimulus.register('f-file-list', class extends window.Stimulus.Controller {
  static values = {
    fileType: String,
    reloadPagy: { type: Boolean, default: false }
  }

  static targets = ['fileTemplate', 'uppy', 'blank', 'thead', 'flexItem']

  connect () {
    // don't handle flexItem targets 64 times on load
    window.setTimeout(() => { this.handleFlexItemTargets = true }, 0)
  }

  uppyUploadSuccess (event) {
    const { file } = event.detail

    const fileElement = this.fileTemplateTarget.content.children[0].cloneNode(true)
    fileElement.dataset.fFileListFileTemplateDataValue = JSON.stringify({
      preview: file.preview
    })

    fileElement.dataset.fFileListFileAwsFileHandlerIdValue = file.id
    fileElement.dataset.fFileListFileS3PathValue = file.s3_path
    fileElement.dataset.fFileListFileFileTypeValue = this.fileTypeValue
    fileElement.querySelector('.f-file-list-file__info-file-name').innerText = file.name

    this.prependFileElement(fileElement)
  }

  tableViewChange (e) {
    if (!this.element.classList.contains('f-file-list--view-changeable')) return

    const asTable = !!e.detail.images_table_view

    this.element.classList.toggle('f-file-list--view-grid', !asTable)
    this.element.classList.toggle('f-file-list--view-table', asTable)
  }

  handleCountChange ({ updatePagy }) {
    if (!this.handleFlexItemTargets) return
    this.blankTarget.hidden = this.flexItemTargets.length > 0

    if (updatePagy && this.reloadPagyValue && window.FolioConsole && window.FolioConsole.Ui && window.FolioConsole.Ui.Pagy) {
      window.FolioConsole.Ui.Pagy.reload()
    }
  }

  flexItemTargetConnected () {
    this.handleCountChange({ updatePagy: false })
  }

  flexItemTargetDisconnected () {
    this.handleCountChange({ updatePagy: true })
  }

  onMessage (e) {
    if (!e || !e.detail || !e.detail.message) return

    if (e.detail.message.type === 'Folio::File/created_manually' && e.detail.message.data.id) {
      const fileId = e.detail.message.data.id

      if (this.element.querySelector(`.f-file-list-file[data-f-file-list-file-id-value="${fileId}"]`)) {
        // don't add if a file with this id already exists
        return
      }

      const fileElement = this.fileTemplateTarget.content.children[0].cloneNode(true)
      fileElement.dataset.fFileListFileIdValue = fileId
      fileElement.dataset.fFileListFileLoadFromIdValue = fileId
      this.prependFileElement(fileElement)
    }
  }

  prependFileElement (fileElement) {
    const flexItem = document.createElement('div')
    flexItem.classList.add('f-file-list__flex-item')
    flexItem.dataset.fFileListTarget = 'flexItem'
    flexItem.appendChild(fileElement)

    this.theadTarget.insertAdjacentElement('afterend', flexItem)
  }
})

if (window.Folio && window.Folio.MessageBus && window.Folio.MessageBus.callbacks) {
  window.Folio.MessageBus.callbacks['f-file-list'] = (message) => {
    if (!message) return
    let selector

    if (message.type === 'Folio::File/created_manually') {
      selector = `.f-file-list[data-f-file-list-file-type-value="${message.data.type}"]`
    }

    if (!selector) return

    const fileLists = document.querySelectorAll(selector)

    for (const fileList of fileLists) {
      fileList.dispatchEvent(new CustomEvent('f-file-list/message', { detail: { message } }))
    }
  }
}
